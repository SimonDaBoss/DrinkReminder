import CoreData
import Foundation

@MainActor
protocol HydrationReminderRefreshing: AnyObject {
    func hydrationStateDidChange()
}

@MainActor
final class ReminderManager: HydrationReminderRefreshing {
    private let context: NSManagedObjectContext
    private let hydrationTracker: HydrationTrackingService
    private let scheduler: any NotificationScheduling
    private let clock: any Clock
    private var calendar: Calendar

    init(
        context: NSManagedObjectContext,
        hydrationTracker: HydrationTrackingService,
        scheduler: any NotificationScheduling,
        clock: any Clock = SystemClock(),
        calendar: Calendar = .autoupdatingCurrent
    ) {
        self.context = context
        self.hydrationTracker = hydrationTracker
        self.scheduler = scheduler
        self.clock = clock
        self.calendar = calendar
    }

    convenience init(
        context: NSManagedObjectContext,
        hydrationTracker: HydrationTrackingService
    ) {
        self.init(
            context: context,
            hydrationTracker: hydrationTracker,
            scheduler: NotificationScheduler()
        )
    }

    func registerNotificationCategories() {
        scheduler.registerCategories()
    }

    func authorizationState() async -> NotificationAuthorizationState {
        await scheduler.authorizationState()
    }

    func requestAuthorization() async throws -> NotificationAuthorizationState {
        try await scheduler.requestAuthorization()
    }

    func preferences() throws -> ReminderPreferences {
        let entity = try fetchPreferencesEntity()
        return ReminderPreferences(
            isEnabled: entity.isEnabled,
            intervalMinutes: Int(entity.intervalMinutes),
            startMinute: Int(entity.startMinute),
            endMinute: Int(entity.endMinute),
            activeWeekdays: Int(entity.activeWeekdays),
            soundEnabled: entity.soundEnabled,
            snoozeMinutes: Int(entity.snoozeMinutes)
        )
    }

    func save(_ preferences: ReminderPreferences) async throws {
        let entity = try fetchPreferencesEntity()
        entity.isEnabled = preferences.isEnabled
        entity.intervalMinutes = Int32(preferences.intervalMinutes)
        entity.startMinute = Int32(preferences.startMinute)
        entity.endMinute = Int32(preferences.endMinute)
        entity.activeWeekdays = Int16(preferences.activeWeekdays)
        entity.soundEnabled = preferences.soundEnabled
        entity.snoozeMinutes = Int32(preferences.snoozeMinutes)

        do {
            try context.save()
            try await refreshSchedule()
        } catch {
            context.rollback()
            throw error
        }
    }

    func refreshSchedule() async throws {
        let preferences = try preferences()
        let authorization = await scheduler.authorizationState()
        let summary = try hydrationTracker.todaySummary()

        guard preferences.isEnabled,
              authorization.canSchedule,
              !summary.isGoalReached else {
            await scheduler.cancelHydrationReminders()
            return
        }

        let lastLogAt = try hydrationTracker.logs(for: clock.now).last?.loggedAt
        let dates = ReminderDateGenerator.dates(
            preferences: preferences,
            now: clock.now,
            lastLogAt: lastLogAt,
            calendar: calendar
        )
        let configuration = try hydrationTracker.configuration()
        let remainingML = max(summary.goalML - summary.totalML, 0)
        let defaultContainer = configuration.presets.first(where: \.isDefault)?.name.lowercased()
            ?? "usual drink"

        let items = dates.enumerated().map { index, date in
            let body: String
            if summary.progress >= 0.75 {
                body = "Only \(VolumeDisplayFormatter.string(milliliters: remainingML, unit: configuration.displayUnit)) left to reach today's goal."
            } else if index.isMultiple(of: 2) {
                body = "Water break! One \(defaultContainer) gets you closer to today's goal."
            } else {
                body = "Your buddy is ready for a refreshing sip."
            }

            return NotificationScheduleItem(
                identifier: NotificationConstants.reminderIdentifierPrefix
                    + String(Int(date.timeIntervalSince1970)),
                date: date,
                title: "Water break 💧",
                body: body,
                soundEnabled: preferences.soundEnabled
            )
        }
        try await scheduler.replaceHydrationReminders(with: items)
    }

    func scheduleTestNotification(soundEnabled: Bool) async throws {
        try await scheduler.scheduleTestNotification(soundEnabled: soundEnabled)
    }

    func scheduleSnooze() async throws {
        let preferences = try preferences()
        let summary = try hydrationTracker.todaySummary()
        guard !summary.isGoalReached else { return }
        try await scheduler.scheduleSnooze(
            minutes: preferences.snoozeMinutes,
            soundEnabled: preferences.soundEnabled
        )
    }

    func hydrationStateDidChange() {
        Task { [weak self] in
            try? await self?.refreshSchedule()
        }
    }

    private func fetchPreferencesEntity() throws -> ReminderPreferencesEntity {
        let request = NSFetchRequest<ReminderPreferencesEntity>(entityName: "ReminderPreferencesEntity")
        request.fetchLimit = 1
        guard let preferences = try context.fetch(request).first else {
            throw PersistenceError.missingPreferences
        }
        return preferences
    }
}
