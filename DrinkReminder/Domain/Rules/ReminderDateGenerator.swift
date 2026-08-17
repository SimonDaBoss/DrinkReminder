import Foundation

enum ReminderDateGenerator {
    static func dates(
        preferences: ReminderPreferences,
        now: Date,
        lastLogAt: Date?,
        calendar: Calendar,
        maximumCount: Int = 56,
        horizonDays: Int = 14
    ) -> [Date] {
        guard preferences.isEnabled,
              preferences.intervalMinutes > 0,
              preferences.startMinute < preferences.endMinute,
              maximumCount > 0,
              horizonDays > 0 else {
            return []
        }

        var dates: [Date] = []
        let todayStart = calendar.startOfDay(for: now)
        let interval = TimeInterval(preferences.intervalMinutes * 60)

        for dayOffset in 0..<horizonDays {
            guard dates.count < maximumCount,
                  let dayStart = calendar.date(byAdding: .day, value: dayOffset, to: todayStart) else {
                break
            }

            let weekday = calendar.component(.weekday, from: dayStart)
            guard preferences.isActive(on: weekday),
                  let configuredStart = calendar.date(
                    byAdding: .minute,
                    value: preferences.startMinute,
                    to: dayStart
                  ),
                  let configuredEnd = calendar.date(
                    byAdding: .minute,
                    value: preferences.endMinute,
                    to: dayStart
                  ) else {
                continue
            }

            var candidate = configuredStart
            if dayOffset == 0 {
                if let lastLogAt, calendar.isDate(lastLogAt, inSameDayAs: now) {
                    candidate = max(configuredStart, lastLogAt.addingTimeInterval(interval))
                } else {
                    while candidate <= now {
                        candidate = candidate.addingTimeInterval(interval)
                    }
                }
            }

            while candidate <= configuredEnd && dates.count < maximumCount {
                if candidate > now {
                    dates.append(candidate)
                }
                candidate = candidate.addingTimeInterval(interval)
            }
        }

        return dates
    }
}
