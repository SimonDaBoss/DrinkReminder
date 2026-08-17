import CoreData
import XCTest
@testable import DrinkReminder

@MainActor
final class HydrationTrackingServiceTests: XCTestCase {
    private var persistence: PersistenceController!
    private var calendar: Calendar!

    override func setUpWithError() throws {
        persistence = try PersistenceController(inMemory: true)
        try PersistenceBootstrapper(context: persistence.viewContext).prepareDefaults()

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "America/Los_Angeles"))
        self.calendar = calendar
    }

    override func tearDown() {
        persistence = nil
        calendar = nil
    }

    func testLoggingWaterPersistsLogAndUpdatesSummary() throws {
        try setDailyGoal(2_000)
        let now = makeDate(year: 2026, month: 8, day: 16, hour: 9)
        let service = HydrationTrackingService(
            context: persistence.viewContext,
            clock: FixedClock(now: now),
            calendar: calendar
        )

        let result = try service.logWater(volumeML: 500, source: .quickAdd)

        XCTAssertEqual(result.summary.dayIdentifier, "2026-08-16")
        XCTAssertEqual(result.summary.totalML, 500, accuracy: 0.001)
        XCTAssertEqual(result.summary.goalML, 2_000, accuracy: 0.001)
        XCTAssertEqual(result.summary.progress, 0.25, accuracy: 0.001)
        XCTAssertFalse(result.crossedHalfway)
        XCTAssertFalse(result.reachedGoal)

        let logs = try service.logs(for: now)
        XCTAssertEqual(logs.count, 1)
        XCTAssertEqual(logs.first?.volumeML, 500)
        XCTAssertEqual(logs.first?.source, .quickAdd)
    }

    func testMilestonesOnlyReportWhenThresholdIsCrossed() throws {
        try setDailyGoal(1_000)
        let now = makeDate(year: 2026, month: 8, day: 16, hour: 10)
        let service = HydrationTrackingService(
            context: persistence.viewContext,
            clock: FixedClock(now: now),
            calendar: calendar
        )

        let first = try service.logWater(volumeML: 400, source: .custom)
        let second = try service.logWater(volumeML: 200, source: .custom)
        let third = try service.logWater(volumeML: 500, source: .custom)
        let fourth = try service.logWater(volumeML: 100, source: .custom)

        XCTAssertFalse(first.crossedHalfway)
        XCTAssertTrue(second.crossedHalfway)
        XCTAssertFalse(second.reachedGoal)
        XCTAssertFalse(third.crossedHalfway)
        XCTAssertTrue(third.reachedGoal)
        XCTAssertNotNil(third.summary.goalReachedAt)
        XCTAssertFalse(fourth.reachedGoal)
        XCTAssertEqual(fourth.summary.totalML, 1_200, accuracy: 0.001)
    }

    func testNewDayCreatesSeparateRecordAndPreservesHistory() throws {
        try setDailyGoal(2_000)
        let firstDate = makeDate(year: 2026, month: 8, day: 16, hour: 23, minute: 50)
        let firstService = HydrationTrackingService(
            context: persistence.viewContext,
            clock: FixedClock(now: firstDate),
            calendar: calendar
        )
        _ = try firstService.logWater(volumeML: 1_000, source: .preset)

        try setDailyGoal(2_500)
        let secondDate = makeDate(year: 2026, month: 8, day: 17, hour: 0, minute: 10)
        let secondService = HydrationTrackingService(
            context: persistence.viewContext,
            clock: FixedClock(now: secondDate),
            calendar: calendar
        )
        _ = try secondService.logWater(volumeML: 300, source: .notification)

        let firstDay = try XCTUnwrap(secondService.summary(for: firstDate))
        let secondDay = try XCTUnwrap(secondService.summary(for: secondDate))
        XCTAssertEqual(firstDay.totalML, 1_000, accuracy: 0.001)
        XCTAssertEqual(firstDay.goalML, 2_000, accuracy: 0.001)
        XCTAssertEqual(secondDay.totalML, 300, accuracy: 0.001)
        XCTAssertEqual(secondDay.goalML, 2_500, accuracy: 0.001)

        let history = try secondService.recentHistory()
        XCTAssertEqual(history.map(\.dayIdentifier), ["2026-08-17", "2026-08-16"])
    }

    func testRejectsNonPositiveAndNonFiniteVolumes() throws {
        let now = makeDate(year: 2026, month: 8, day: 16, hour: 12)
        let service = HydrationTrackingService(
            context: persistence.viewContext,
            clock: FixedClock(now: now),
            calendar: calendar
        )

        for invalidVolume in [0, -1, .infinity, .nan] {
            XCTAssertThrowsError(
                try service.logWater(volumeML: invalidVolume, source: .custom)
            ) { error in
                XCTAssertEqual(error as? HydrationTrackingError, .invalidVolume)
            }
        }
        XCTAssertTrue(try service.recentHistory().isEmpty)
    }

    private func setDailyGoal(_ value: Double) throws {
        let request = NSFetchRequest<AppPreferencesEntity>(entityName: "AppPreferencesEntity")
        let preferences = try XCTUnwrap(persistence.viewContext.fetch(request).first)
        preferences.dailyGoalML = value
        try persistence.viewContext.save()
    }

    private func makeDate(
        year: Int,
        month: Int,
        day: Int,
        hour: Int,
        minute: Int = 0
    ) -> Date {
        calendar.date(from: DateComponents(
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute
        ))!
    }
}
