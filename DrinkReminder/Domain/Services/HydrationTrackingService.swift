import CoreData
import Foundation

enum HydrationTrackingError: LocalizedError, Equatable {
    case invalidVolume
    case invalidDailyGoal
    case logNotFound

    var errorDescription: String? {
        switch self {
        case .invalidVolume:
            return "Water volume must be a finite amount greater than zero."
        case .invalidDailyGoal:
            return "The daily hydration goal must be greater than zero."
        case .logNotFound:
            return "That water entry is no longer available to undo."
        }
    }
}

@MainActor
final class HydrationTrackingService {
    private let context: NSManagedObjectContext
    private let clock: any Clock
    private var calendar: Calendar

    init(
        context: NSManagedObjectContext,
        clock: any Clock = SystemClock(),
        calendar: Calendar = .autoupdatingCurrent
    ) {
        self.context = context
        self.clock = clock
        self.calendar = calendar
    }

    @discardableResult
    func logWater(
        volumeML: Double,
        source: WaterLogSource,
        presetID: UUID? = nil
    ) throws -> HydrationLogResult {
        guard volumeML.isFinite, volumeML > 0 else {
            throw HydrationTrackingError.invalidVolume
        }

        let timestamp = clock.now
        let day = try fetchOrCreateDay(containing: timestamp)
        guard day.goalML.isFinite, day.goalML > 0 else {
            throw HydrationTrackingError.invalidDailyGoal
        }

        let previousTotal = day.totalML
        let newTotal = previousTotal + volumeML

        let log = WaterLogEntity(context: context)
        log.id = UUID()
        log.loggedAt = timestamp
        log.volumeML = volumeML
        log.source = source
        log.presetID = presetID
        log.day = day

        day.totalML = newTotal
        let crossedHalfway = previousTotal < day.goalML * 0.5 && newTotal >= day.goalML * 0.5
        let reachedGoal = previousTotal < day.goalML && newTotal >= day.goalML
        if reachedGoal && day.goalReachedAt == nil {
            day.goalReachedAt = timestamp
        }

        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }

        return HydrationLogResult(
            logID: log.id,
            summary: day.summary,
            loggedAmountML: volumeML,
            crossedHalfway: crossedHalfway,
            reachedGoal: reachedGoal
        )
    }

    func undoWaterLog(id: UUID) throws -> HydrationSummary {
        let request = NSFetchRequest<WaterLogEntity>(entityName: "WaterLogEntity")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1

        guard let log = try context.fetch(request).first else {
            throw HydrationTrackingError.logNotFound
        }

        let day = log.day
        let remainingLogs = day.logs
            .filter { $0.id != id && !$0.isDeleted }
            .sorted { $0.loggedAt < $1.loggedAt }

        context.delete(log)
        day.totalML = remainingLogs.reduce(0) { $0 + $1.volumeML }
        day.goalReachedAt = goalReachedDate(in: remainingLogs, goalML: day.goalML)

        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
        return day.summary
    }

    func configuration() throws -> HydrationConfiguration {
        let preferences = try fetchPreferences()
        let request = NSFetchRequest<ContainerPresetEntity>(entityName: "ContainerPresetEntity")
        request.sortDescriptors = [
            NSSortDescriptor(key: "sortOrder", ascending: true),
            NSSortDescriptor(key: "createdAt", ascending: true)
        ]
        let presets = try context.fetch(request).map {
            ContainerPreset(
                id: $0.id,
                name: $0.name,
                volumeML: $0.volumeML,
                symbolName: $0.symbolName,
                isDefault: $0.isDefault
            )
        }

        return HydrationConfiguration(
            displayUnit: preferences.displayUnit,
            defaultDrinkAmountML: preferences.defaultDrinkAmountML,
            hapticsEnabled: preferences.hapticsEnabled,
            presets: presets
        )
    }

    func todaySummary() throws -> HydrationSummary {
        try fetchOrCreateDay(containing: clock.now).summary
    }

    func summary(for date: Date) throws -> HydrationSummary? {
        let localDay = LocalDay(containing: date, calendar: calendar)
        return try fetchDay(identifier: localDay.identifier)?.summary
    }

    func recentHistory(limit: Int = 7) throws -> [HydrationSummary] {
        guard limit > 0 else { return [] }

        let request = NSFetchRequest<HydrationDayEntity>(entityName: "HydrationDayEntity")
        request.sortDescriptors = [NSSortDescriptor(key: "dayStart", ascending: false)]
        request.fetchLimit = limit
        return try context.fetch(request).map(\.summary)
    }

    func logs(for date: Date) throws -> [WaterLogEntity] {
        let localDay = LocalDay(containing: date, calendar: calendar)
        guard let day = try fetchDay(identifier: localDay.identifier) else { return [] }
        return day.logs.sorted { $0.loggedAt < $1.loggedAt }
    }

    private func fetchOrCreateDay(containing date: Date) throws -> HydrationDayEntity {
        let localDay = LocalDay(containing: date, calendar: calendar)
        if let existing = try fetchDay(identifier: localDay.identifier) {
            return existing
        }

        let preferences = try fetchPreferences()
        guard preferences.dailyGoalML.isFinite, preferences.dailyGoalML > 0 else {
            throw HydrationTrackingError.invalidDailyGoal
        }

        let day = HydrationDayEntity(context: context)
        day.id = UUID()
        day.dayIdentifier = localDay.identifier
        day.dayStart = localDay.start
        day.timeZoneIdentifier = localDay.timeZoneIdentifier
        day.goalML = preferences.dailyGoalML
        day.totalML = 0
        day.goalReachedAt = nil

        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
        return day
    }

    private func fetchDay(identifier: String) throws -> HydrationDayEntity? {
        let request = NSFetchRequest<HydrationDayEntity>(entityName: "HydrationDayEntity")
        request.predicate = NSPredicate(format: "dayIdentifier == %@", identifier)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    private func fetchPreferences() throws -> AppPreferencesEntity {
        let request = NSFetchRequest<AppPreferencesEntity>(entityName: "AppPreferencesEntity")
        request.fetchLimit = 1
        guard let preferences = try context.fetch(request).first else {
            throw PersistenceError.missingPreferences
        }
        return preferences
    }

    private func goalReachedDate(in logs: [WaterLogEntity], goalML: Double) -> Date? {
        var runningTotal = 0.0
        for log in logs {
            runningTotal += log.volumeML
            if runningTotal >= goalML {
                return log.loggedAt
            }
        }
        return nil
    }
}
