import CoreData
import Foundation

enum VerificationFailure: Error {
    case unexpected(String)
}

@main
struct Phase1Verification {
    @MainActor
    static func main() throws {
        let persistence = try PersistenceController(inMemory: true)
        let bootstrapper = PersistenceBootstrapper(context: persistence.viewContext)
        try bootstrapper.prepareDefaults()
        try bootstrapper.prepareDefaults()

        let presetCount = try persistence.viewContext.count(
            for: NSFetchRequest<NSFetchRequestResult>(entityName: "ContainerPresetEntity")
        )
        try expect(presetCount == 4, "Bootstrap should create four presets exactly once.")

        let preferencesRequest = NSFetchRequest<AppPreferencesEntity>(entityName: "AppPreferencesEntity")
        let preferences = try persistence.viewContext.fetch(preferencesRequest).first
        try expect(preferences != nil, "Bootstrap should create application preferences.")
        preferences?.dailyGoalML = 1_000
        try persistence.viewContext.save()

        var calendar = Calendar(identifier: .gregorian)
        guard let timeZone = TimeZone(identifier: "America/Los_Angeles") else {
            throw VerificationFailure.unexpected("Test timezone is unavailable.")
        }
        calendar.timeZone = timeZone

        let firstDate = try date(
            year: 2026,
            month: 8,
            day: 16,
            hour: 23,
            minute: 50,
            calendar: calendar
        )
        let firstService = HydrationTrackingService(
            context: persistence.viewContext,
            clock: FixedClock(now: firstDate),
            calendar: calendar
        )
        let firstLog = try firstService.logWater(volumeML: 600, source: .quickAdd)
        try expect(firstLog.crossedHalfway, "The halfway crossing should be detected.")
        try expect(!firstLog.reachedGoal, "The goal should not be reached at 600 mL.")

        preferences?.dailyGoalML = 1_500
        try persistence.viewContext.save()

        let secondDate = try date(
            year: 2026,
            month: 8,
            day: 17,
            hour: 0,
            minute: 10,
            calendar: calendar
        )
        let secondService = HydrationTrackingService(
            context: persistence.viewContext,
            clock: FixedClock(now: secondDate),
            calendar: calendar
        )
        _ = try secondService.logWater(volumeML: 250, source: .notification)

        let history = try secondService.recentHistory()
        try expect(history.count == 2, "Day rollover should preserve both hydration days.")
        try expect(history[0].goalML == 1_500, "The new day should snapshot the new goal.")
        try expect(history[1].goalML == 1_000, "The prior day's goal snapshot should remain unchanged.")
        try expect(history[1].totalML == 600, "The prior day's total should remain unchanged.")

        print("Phase 1 verification passed")
    }

    private static func expect(_ condition: @autoclosure () -> Bool, _ message: String) throws {
        guard condition() else { throw VerificationFailure.unexpected(message) }
    }

    private static func date(
        year: Int,
        month: Int,
        day: Int,
        hour: Int,
        minute: Int,
        calendar: Calendar
    ) throws -> Date {
        guard let date = calendar.date(from: DateComponents(
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute
        )) else {
            throw VerificationFailure.unexpected("Could not construct verification date.")
        }
        return date
    }
}
