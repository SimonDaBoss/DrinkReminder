import XCTest
@testable import DrinkReminder

final class StreakCalculatorTests: XCTestCase {
    func testCurrentStreakRemainsActiveWhileTodayIsInProgress() throws {
        let calendar = try makeCalendar()
        let today = makeDate(day: 16, calendar: calendar)
        let days = [
            summary(day: "2026-08-13", completed: true),
            summary(day: "2026-08-14", completed: true),
            summary(day: "2026-08-15", completed: true),
            summary(day: "2026-08-16", completed: false)
        ]

        let result = StreakCalculator.statistics(from: days, today: today, calendar: calendar)

        XCTAssertEqual(result.current, 3)
        XCTAssertEqual(result.longest, 3)
        XCTAssertEqual(result.successfulDays, 3)
    }

    func testCompletingTodayExtendsCurrentStreak() throws {
        let calendar = try makeCalendar()
        let today = makeDate(day: 16, calendar: calendar)
        let days = [
            summary(day: "2026-08-14", completed: true),
            summary(day: "2026-08-15", completed: true),
            summary(day: "2026-08-16", completed: true)
        ]

        let result = StreakCalculator.statistics(from: days, today: today, calendar: calendar)

        XCTAssertEqual(result.current, 3)
        XCTAssertEqual(result.longest, 3)
    }

    func testMissedDayBreaksCurrentButPreservesLongestStreak() throws {
        let calendar = try makeCalendar()
        let today = makeDate(day: 16, calendar: calendar)
        let days = [
            summary(day: "2026-08-10", completed: true),
            summary(day: "2026-08-11", completed: true),
            summary(day: "2026-08-12", completed: true),
            summary(day: "2026-08-15", completed: true)
        ]

        let result = StreakCalculator.statistics(from: days, today: today, calendar: calendar)

        XCTAssertEqual(result.current, 1)
        XCTAssertEqual(result.longest, 3)
        XCTAssertEqual(result.successfulDays, 4)
    }

    private func summary(day: String, completed: Bool) -> HydrationSummary {
        HydrationSummary(
            dayIdentifier: day,
            totalML: completed ? 1_000 : 500,
            goalML: 1_000,
            goalReachedAt: completed ? Date(timeIntervalSince1970: 1) : nil
        )
    }

    private func makeCalendar() throws -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "America/Los_Angeles"))
        return calendar
    }

    private func makeDate(day: Int, calendar: Calendar) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 8, day: day, hour: 12))!
    }
}
