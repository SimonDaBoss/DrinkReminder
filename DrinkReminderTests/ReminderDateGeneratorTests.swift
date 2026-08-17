import XCTest
@testable import DrinkReminder

final class ReminderDateGeneratorTests: XCTestCase {
    func testGeneratesOnlyFutureTimesWithinConfiguredHours() throws {
        let calendar = try makeCalendar()
        let now = try makeDate(2026, 8, 17, 9, 30, calendar: calendar)
        let preferences = ReminderPreferences(
            isEnabled: true,
            intervalMinutes: 60,
            startMinute: 8 * 60,
            endMinute: 12 * 60,
            activeWeekdays: 0b111_1111,
            soundEnabled: true,
            snoozeMinutes: 15
        )

        let dates = ReminderDateGenerator.dates(
            preferences: preferences,
            now: now,
            lastLogAt: nil,
            calendar: calendar,
            maximumCount: 3
        )

        XCTAssertEqual(try dates.map { try hourAndMinute($0, calendar: calendar) }, ["10:00", "11:00", "12:00"])
    }

    func testRecentLogResetsNextReminderInterval() throws {
        let calendar = try makeCalendar()
        let now = try makeDate(2026, 8, 17, 9, 50, calendar: calendar)
        let lastLog = try makeDate(2026, 8, 17, 9, 45, calendar: calendar)
        let preferences = ReminderPreferences(
            isEnabled: true,
            intervalMinutes: 60,
            startMinute: 8 * 60,
            endMinute: 12 * 60,
            activeWeekdays: 0b111_1111,
            soundEnabled: true,
            snoozeMinutes: 15
        )

        let dates = ReminderDateGenerator.dates(
            preferences: preferences,
            now: now,
            lastLogAt: lastLog,
            calendar: calendar,
            maximumCount: 2
        )

        XCTAssertEqual(try dates.map { try hourAndMinute($0, calendar: calendar) }, ["10:45", "11:45"])
    }

    func testInactiveDaysAreSkipped() throws {
        let calendar = try makeCalendar()
        let monday = try makeDate(2026, 8, 17, 9, 0, calendar: calendar)
        var preferences = ReminderPreferences(
            isEnabled: true,
            intervalMinutes: 60,
            startMinute: 8 * 60,
            endMinute: 10 * 60,
            activeWeekdays: 0,
            soundEnabled: true,
            snoozeMinutes: 15
        )
        preferences.setActive(true, weekday: 3) // Tuesday

        let dates = ReminderDateGenerator.dates(
            preferences: preferences,
            now: monday,
            lastLogAt: nil,
            calendar: calendar,
            maximumCount: 1
        )

        let first = try XCTUnwrap(dates.first)
        XCTAssertEqual(calendar.component(.weekday, from: first), 3)
        XCTAssertEqual(try hourAndMinute(first, calendar: calendar), "08:00")
    }

    private func makeCalendar() throws -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "America/Los_Angeles"))
        return calendar
    }

    private func makeDate(
        _ year: Int,
        _ month: Int,
        _ day: Int,
        _ hour: Int,
        _ minute: Int,
        calendar: Calendar
    ) throws -> Date {
        try XCTUnwrap(calendar.date(from: DateComponents(
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute
        )))
    }

    private func hourAndMinute(_ date: Date, calendar: Calendar) throws -> String {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        return String(format: "%02d:%02d", try XCTUnwrap(components.hour), try XCTUnwrap(components.minute))
    }
}
