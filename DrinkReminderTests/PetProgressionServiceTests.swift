import CoreData
import XCTest
@testable import DrinkReminder

final class PetProgressionServiceTests: XCTestCase {
    @MainActor
    func testLogsAndMilestonesAwardXPExactlyOnce() throws {
        let fixture = try makeFixture()

        let first = try fixture.tracker.logWater(volumeML: 400, source: .quickAdd)
        XCTAssertEqual(try fixture.progression.record(first).earnedXP, 5)

        let halfway = try fixture.tracker.logWater(volumeML: 200, source: .quickAdd)
        XCTAssertEqual(try fixture.progression.record(halfway).earnedXP, 15)

        let goal = try fixture.tracker.logWater(volumeML: 400, source: .quickAdd)
        XCTAssertEqual(try fixture.progression.record(goal).earnedXP, 30)

        let snapshot = try fixture.progression.snapshot()
        XCTAssertEqual(snapshot.pet.totalXP, 50)
        XCTAssertEqual(snapshot.pet.level, 1)
        XCTAssertEqual(snapshot.streak.current, 1)
        XCTAssertEqual(try fixture.progression.snapshot().pet.totalXP, 50)
    }

    @MainActor
    func testConsecutiveGoalAddsStreakBonus() throws {
        let fixture = try makeFixture()
        let firstGoal = try fixture.tracker.logWater(volumeML: 1_000, source: .quickAdd)
        XCTAssertEqual(try fixture.progression.record(firstGoal).earnedXP, 40)

        fixture.clock.now = makeDate(day: 17, calendar: fixture.calendar)
        let secondGoal = try fixture.tracker.logWater(volumeML: 1_000, source: .quickAdd)
        XCTAssertEqual(try fixture.progression.record(secondGoal).earnedXP, 45)

        let snapshot = try fixture.progression.snapshot()
        XCTAssertEqual(snapshot.pet.totalXP, 85)
        XCTAssertEqual(snapshot.streak.current, 2)
        XCTAssertEqual(snapshot.streak.longest, 2)
    }

    @MainActor
    func testUndoRemovesWaterAndMilestoneAwards() throws {
        let fixture = try makeFixture()
        let goal = try fixture.tracker.logWater(volumeML: 1_000, source: .quickAdd)
        _ = try fixture.progression.record(goal)
        XCTAssertEqual(try fixture.progression.snapshot().pet.totalXP, 40)

        _ = try fixture.tracker.undoWaterLog(id: goal.logID)
        let result = try fixture.progression.reconcileAfterUndo()

        XCTAssertEqual(result.pet.totalXP, 0)
        XCTAssertEqual(result.streak, .empty)
    }

    func testLevelAndEvolutionThresholdsAreCentralized() {
        XCTAssertEqual(PetProgressionRules.progress(totalXP: 0).level, 1)
        XCTAssertEqual(PetProgressionRules.progress(totalXP: 399).evolutionStage, .baby)
        XCTAssertEqual(PetProgressionRules.progress(totalXP: 400).evolutionStage, .growing)
        XCTAssertEqual(PetProgressionRules.progress(totalXP: 900).evolutionStage, .evolved)
        XCTAssertEqual(PetProgressionRules.progress(totalXP: 1_900).evolutionStage, .advanced)
    }

    @MainActor
    private func makeFixture() throws -> (
        persistence: PersistenceController,
        tracker: HydrationTrackingService,
        progression: PetProgressionService,
        clock: MutableProgressionClock,
        calendar: Calendar
    ) {
        let persistence = try PersistenceController(inMemory: true)
        try PersistenceBootstrapper(context: persistence.viewContext).prepareDefaults()
        let preferencesRequest = NSFetchRequest<AppPreferencesEntity>(entityName: "AppPreferencesEntity")
        let preferences = try XCTUnwrap(persistence.viewContext.fetch(preferencesRequest).first)
        preferences.dailyGoalML = 1_000
        try persistence.viewContext.save()

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "America/Los_Angeles"))
        let clock = MutableProgressionClock(now: makeDate(day: 16, calendar: calendar))
        return (
            persistence,
            HydrationTrackingService(
                context: persistence.viewContext,
                clock: clock,
                calendar: calendar
            ),
            PetProgressionService(
                context: persistence.viewContext,
                clock: clock,
                calendar: calendar
            ),
            clock,
            calendar
        )
    }

    private func makeDate(day: Int, calendar: Calendar) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 8, day: day, hour: 12))!
    }
}

private final class MutableProgressionClock: Clock {
    var now: Date

    init(now: Date) {
        self.now = now
    }
}
