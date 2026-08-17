import CoreData
import XCTest
@testable import DrinkReminder

final class ReminderManagerTests: XCTestCase {
    @MainActor
    func testRefreshSchedulesFriendlyReminders() async throws {
        let fixture = try makeFixture(goalML: 2_000)
        fixture.scheduler.authorization = .authorized

        try await fixture.manager.refreshSchedule()

        XCTAssertFalse(fixture.scheduler.replacedItems.isEmpty)
        XCTAssertEqual(fixture.scheduler.replacedItems.first?.date, try makeDate(10, 0, calendar: fixture.calendar))
        XCTAssertTrue(fixture.scheduler.replacedItems.first?.body.contains("cup") == true)
        XCTAssertTrue(fixture.scheduler.replacedItems.allSatisfy(\.soundEnabled))
    }

    @MainActor
    func testLoggingWaterMovesNextReminderOneFullInterval() async throws {
        let fixture = try makeFixture(goalML: 2_000)
        fixture.scheduler.authorization = .authorized
        _ = try fixture.tracker.logWater(volumeML: 250, source: .quickAdd)

        try await fixture.manager.refreshSchedule()

        XCTAssertEqual(fixture.scheduler.replacedItems.first?.date, try makeDate(10, 30, calendar: fixture.calendar))
    }

    @MainActor
    func testCompletingGoalCancelsRemainingReminders() async throws {
        let fixture = try makeFixture(goalML: 200)
        fixture.scheduler.authorization = .authorized
        _ = try fixture.tracker.logWater(volumeML: 250, source: .quickAdd)

        try await fixture.manager.refreshSchedule()

        XCTAssertEqual(fixture.scheduler.cancelCount, 1)
        XCTAssertTrue(fixture.scheduler.replacedItems.isEmpty)
    }

    @MainActor
    private func makeFixture(
        goalML: Double
    ) throws -> (
        persistence: PersistenceController,
        tracker: HydrationTrackingService,
        scheduler: NotificationSchedulerSpy,
        manager: ReminderManager,
        calendar: Calendar
    ) {
        let persistence = try PersistenceController(inMemory: true)
        try PersistenceBootstrapper(context: persistence.viewContext).prepareDefaults()

        let appRequest = NSFetchRequest<AppPreferencesEntity>(entityName: "AppPreferencesEntity")
        let appPreferences = try XCTUnwrap(persistence.viewContext.fetch(appRequest).first)
        appPreferences.dailyGoalML = goalML

        let reminderRequest = NSFetchRequest<ReminderPreferencesEntity>(entityName: "ReminderPreferencesEntity")
        let reminderPreferences = try XCTUnwrap(persistence.viewContext.fetch(reminderRequest).first)
        reminderPreferences.isEnabled = true
        reminderPreferences.intervalMinutes = 60
        reminderPreferences.startMinute = 8 * 60
        reminderPreferences.endMinute = 12 * 60
        reminderPreferences.activeWeekdays = 0b111_1111
        try persistence.viewContext.save()

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "America/Los_Angeles"))
        let now = try makeDate(9, 30, calendar: calendar)
        let tracker = HydrationTrackingService(
            context: persistence.viewContext,
            clock: FixedClock(now: now),
            calendar: calendar
        )
        let scheduler = NotificationSchedulerSpy()
        let manager = ReminderManager(
            context: persistence.viewContext,
            hydrationTracker: tracker,
            scheduler: scheduler,
            clock: FixedClock(now: now),
            calendar: calendar
        )
        return (persistence, tracker, scheduler, manager, calendar)
    }

    private func makeDate(_ hour: Int, _ minute: Int, calendar: Calendar) throws -> Date {
        try XCTUnwrap(calendar.date(from: DateComponents(
            year: 2026,
            month: 8,
            day: 17,
            hour: hour,
            minute: minute
        )))
    }
}

@MainActor
private final class NotificationSchedulerSpy: NotificationScheduling {
    var authorization: NotificationAuthorizationState = .notDetermined
    private(set) var replacedItems: [NotificationScheduleItem] = []
    private(set) var cancelCount = 0
    private(set) var testCount = 0
    private(set) var snoozeCount = 0

    func registerCategories() {}

    func authorizationState() async -> NotificationAuthorizationState {
        authorization
    }

    func requestAuthorization() async throws -> NotificationAuthorizationState {
        authorization
    }

    func replaceHydrationReminders(with items: [NotificationScheduleItem]) async throws {
        replacedItems = items
    }

    func cancelHydrationReminders() async {
        cancelCount += 1
        replacedItems = []
    }

    func scheduleTestNotification(soundEnabled: Bool) async throws {
        testCount += 1
    }

    func scheduleSnooze(minutes: Int, soundEnabled: Bool) async throws {
        snoozeCount += 1
    }
}
