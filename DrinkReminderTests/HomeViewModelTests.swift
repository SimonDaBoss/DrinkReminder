import CoreData
import XCTest
@testable import DrinkReminder

final class HomeViewModelTests: XCTestCase {
    @MainActor
    func testPreferredLoggingUpdatesProgressAndCanBeUndone() throws {
        let fixture = try makeFixture(goalML: 1_000, defaultAmountML: 250)
        let haptics = HapticSpy()
        let viewModel = HomeViewModel(
            hydrationTracker: fixture.service,
            haptics: haptics
        )

        viewModel.load()
        viewModel.logPreferredAmount()

        XCTAssertEqual(viewModel.summary?.totalML, 250)
        XCTAssertEqual(viewModel.progress, 0.25, accuracy: 0.001)
        XCTAssertEqual(viewModel.petMood, .drinking)
        XCTAssertNotNil(viewModel.undoState)
        XCTAssertEqual(haptics.waterLoggedGoalValues, [false])

        viewModel.undoLastLog()

        XCTAssertEqual(viewModel.summary?.totalML, 0)
        XCTAssertNil(viewModel.undoState)
        XCTAssertEqual(haptics.undoCount, 1)
    }

    @MainActor
    func testCustomLoggingConvertsDisplayOuncesToMilliliters() throws {
        let fixture = try makeFixture(goalML: 2_000, defaultAmountML: 250)
        let viewModel = HomeViewModel(
            hydrationTracker: fixture.service,
            haptics: HapticSpy()
        )

        viewModel.load()
        viewModel.logCustom(displayAmount: 10)

        XCTAssertEqual(
            viewModel.summary?.totalML ?? 0,
            VolumeConverter.milliliters(from: 10, unit: .ounces),
            accuracy: 0.000_001
        )
    }

    @MainActor
    func testGoalCompletionTriggersCelebrationHaptic() throws {
        let fixture = try makeFixture(goalML: 200, defaultAmountML: 250)
        let haptics = HapticSpy()
        let viewModel = HomeViewModel(
            hydrationTracker: fixture.service,
            haptics: haptics
        )

        viewModel.load()
        viewModel.logPreferredAmount()

        XCTAssertEqual(viewModel.petMood, .celebrating)
        XCTAssertEqual(haptics.waterLoggedGoalValues, [true])
        XCTAssertEqual(viewModel.encouragementText, "Goal complete — Puddle is happy!")

        viewModel.load()
        XCTAssertEqual(viewModel.petMood, .happy)
    }

    @MainActor
    func testFewSipsUsesQuarterOfUsualContainer() throws {
        let fixture = try makeFixture(goalML: 1_000, defaultAmountML: 400)
        let viewModel = HomeViewModel(
            hydrationTracker: fixture.service,
            haptics: HapticSpy()
        )

        viewModel.load()
        viewModel.logEstimatedFraction(0.25)

        XCTAssertEqual(viewModel.summary?.totalML, 100)
        XCTAssertEqual(viewModel.preferredContainerName, "cup")
    }

    @MainActor
    private func makeFixture(
        goalML: Double,
        defaultAmountML: Double
    ) throws -> (persistence: PersistenceController, service: HydrationTrackingService) {
        let persistence = try PersistenceController(inMemory: true)
        try PersistenceBootstrapper(context: persistence.viewContext).prepareDefaults()

        let request = NSFetchRequest<AppPreferencesEntity>(entityName: "AppPreferencesEntity")
        let preferences = try XCTUnwrap(persistence.viewContext.fetch(request).first)
        preferences.dailyGoalML = goalML
        preferences.defaultDrinkAmountML = defaultAmountML
        preferences.displayUnit = .ounces
        try persistence.viewContext.save()

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "America/Los_Angeles"))
        let date = try XCTUnwrap(calendar.date(from: DateComponents(
            year: 2026,
            month: 8,
            day: 16,
            hour: 10
        )))
        let service = HydrationTrackingService(
            context: persistence.viewContext,
            clock: FixedClock(now: date),
            calendar: calendar
        )
        return (persistence, service)
    }
}

@MainActor
private final class HapticSpy: HapticProviding {
    private(set) var waterLoggedGoalValues: [Bool] = []
    private(set) var undoCount = 0

    func waterLogged(reachedGoal: Bool) {
        waterLoggedGoalValues.append(reachedGoal)
    }

    func undoCompleted() {
        undoCount += 1
    }
}
