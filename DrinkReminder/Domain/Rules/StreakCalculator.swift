import Foundation

enum StreakCalculator {
    static func statistics(
        from days: [HydrationSummary],
        today: Date,
        calendar: Calendar
    ) -> StreakStatistics {
        let completedIdentifiers = Set(days.filter(\.isGoalReached).map(\.dayIdentifier))
        guard !completedIdentifiers.isEmpty else { return .empty }

        let todayIdentifier = LocalDay(containing: today, calendar: calendar).identifier
        let currentAnchor: Date
        if completedIdentifiers.contains(todayIdentifier) {
            currentAnchor = today
        } else {
            currentAnchor = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        }

        var current = 0
        var cursor = currentAnchor
        while completedIdentifiers.contains(LocalDay(containing: cursor, calendar: calendar).identifier) {
            current += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }

        let sortedDates = completedIdentifiers.compactMap(date(from:)).sorted()
        var longest = 0
        var running = 0
        var previous: Date?
        for date in sortedDates {
            if let previous,
               utcCalendar.dateComponents([.day], from: previous, to: date).day == 1 {
                running += 1
            } else {
                running = 1
            }
            longest = max(longest, running)
            previous = date
        }

        return StreakStatistics(
            current: current,
            longest: longest,
            successfulDays: completedIdentifiers.count
        )
    }

    private static var utcCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private static func date(from identifier: String) -> Date? {
        let parts = identifier.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return utcCalendar.date(from: DateComponents(
            year: parts[0],
            month: parts[1],
            day: parts[2]
        ))
    }
}
