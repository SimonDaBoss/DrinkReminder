import CoreData
import XCTest
@testable import DrinkReminder

final class AppSettingsServiceTests: XCTestCase {
    @MainActor
    func testCompletingOnboardingPersistsPersonalizationAndDefaultContainer() throws {
        let fixture = try makeFixture()
        let initial = try fixture.settings.snapshot()
        let bottle = try XCTUnwrap(initial.presets.first(where: { $0.name == "Bottle" }))

        try fixture.settings.completeOnboarding(OnboardingSelection(
            displayName: "  Simon  ",
            dailyGoalML: 2_750,
            displayUnit: .milliliters,
            defaultPresetID: bottle.id,
            petName: "  Ripple  ",
            petSpecies: .otter
        ))

        let result = try fixture.settings.snapshot()
        XCTAssertTrue(result.onboardingCompleted)
        XCTAssertEqual(result.displayName, "Simon")
        XCTAssertEqual(result.dailyGoalML, 2_750, accuracy: 0.001)
        XCTAssertEqual(result.displayUnit, .milliliters)
        XCTAssertEqual(result.petIdentity, PetIdentity(name: "Ripple", species: .otter))
        XCTAssertEqual(result.presets.filter(\.isDefault).map(\.name), ["Bottle"])
        XCTAssertEqual(result.defaultDrinkAmountML, bottle.volumeML, accuracy: 0.001)
    }

    @MainActor
    func testGoalChangeUpdatesTodayButPreservesHistoricalSnapshot() throws {
        let fixture = try makeFixture()
        let yesterday = makeDate(day: 15, hour: 12, calendar: fixture.calendar)
        let today = makeDate(day: 16, hour: 12, calendar: fixture.calendar)

        let yesterdayTracker = HydrationTrackingService(
            context: fixture.persistence.viewContext,
            clock: FixedClock(now: yesterday),
            calendar: fixture.calendar
        )
        _ = try yesterdayTracker.logWater(volumeML: 500, source: .quickAdd)
        _ = try fixture.tracker.logWater(volumeML: 500, source: .quickAdd)

        let snapshot = try fixture.settings.snapshot()
        let defaultID = try XCTUnwrap(snapshot.presets.first(where: \.isDefault)?.id)
        try fixture.settings.saveSettings(
            displayName: nil,
            dailyGoalML: 3_000,
            displayUnit: .milliliters,
            defaultPresetID: defaultID,
            petName: "Puddle",
            petSpecies: .droplet,
            appearance: .dark,
            hapticsEnabled: false
        )

        XCTAssertEqual(try XCTUnwrap(fixture.tracker.summary(for: yesterday)).goalML, snapshot.dailyGoalML, accuracy: 0.001)
        XCTAssertEqual(try XCTUnwrap(fixture.tracker.summary(for: today)).goalML, 3_000, accuracy: 0.001)
        let saved = try fixture.settings.snapshot()
        XCTAssertEqual(saved.appearance, .dark)
        XCTAssertFalse(saved.hapticsEnabled)
        XCTAssertEqual(saved.petIdentity.species, .droplet)
    }

    @MainActor
    func testContainerCRUDMaintainsOneUsualContainer() throws {
        let fixture = try makeFixture()

        let jarID = try fixture.settings.saveContainer(
            id: nil,
            name: " Jar ",
            volumeML: 600,
            symbolName: "waterbottle"
        )
        try fixture.settings.setDefaultContainer(id: jarID)

        var result = try fixture.settings.snapshot()
        XCTAssertEqual(result.presets.first(where: { $0.id == jarID })?.name, "Jar")
        XCTAssertEqual(result.presets.filter(\.isDefault).map(\.id), [jarID])
        XCTAssertEqual(result.defaultDrinkAmountML, 600, accuracy: 0.001)

        _ = try fixture.settings.saveContainer(
            id: jarID,
            name: "Big Jar",
            volumeML: 700,
            symbolName: "waterbottle.fill"
        )
        result = try fixture.settings.snapshot()
        XCTAssertEqual(result.presets.first(where: { $0.id == jarID })?.volumeML, 700)
        XCTAssertEqual(result.defaultDrinkAmountML, 700, accuracy: 0.001)

        try fixture.settings.deleteContainer(id: jarID)
        result = try fixture.settings.snapshot()
        XCTAssertNil(result.presets.first(where: { $0.id == jarID }))
        XCTAssertEqual(result.presets.filter(\.isDefault).count, 1)
    }

    @MainActor
    func testResetRecreatesDefaultsAndRequiresOnboarding() throws {
        let fixture = try makeFixture()
        let initial = try fixture.settings.snapshot()
        let defaultID = try XCTUnwrap(initial.presets.first(where: \.isDefault)?.id)
        try fixture.settings.completeOnboarding(OnboardingSelection(
            displayName: "Simon",
            dailyGoalML: 2_000,
            displayUnit: .milliliters,
            defaultPresetID: defaultID,
            petName: "Ripple",
            petSpecies: .otter
        ))
        _ = try fixture.tracker.logWater(volumeML: 500, source: .quickAdd)

        try fixture.settings.resetAllData()

        let reset = try fixture.settings.snapshot()
        XCTAssertFalse(reset.onboardingCompleted)
        XCTAssertNil(reset.displayName)
        XCTAssertEqual(reset.petIdentity, PetIdentity(name: "Puddle", species: .axolotl))
        XCTAssertEqual(reset.presets.count, 4)
        XCTAssertTrue(try fixture.tracker.recentHistory().isEmpty)
    }

    @MainActor
    private func makeFixture() throws -> (
        persistence: PersistenceController,
        tracker: HydrationTrackingService,
        settings: AppSettingsService,
        calendar: Calendar
    ) {
        let persistence = try PersistenceController(inMemory: true)
        try PersistenceBootstrapper(context: persistence.viewContext).prepareDefaults()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "America/Los_Angeles"))
        let today = makeDate(day: 16, hour: 12, calendar: calendar)
        let tracker = HydrationTrackingService(
            context: persistence.viewContext,
            clock: FixedClock(now: today),
            calendar: calendar
        )
        let settings = AppSettingsService(
            context: persistence.viewContext,
            hydrationTracker: tracker
        )
        return (persistence, tracker, settings, calendar)
    }

    private func makeDate(day: Int, hour: Int, calendar: Calendar) -> Date {
        calendar.date(from: DateComponents(
            year: 2026,
            month: 8,
            day: day,
            hour: hour
        ))!
    }
}
