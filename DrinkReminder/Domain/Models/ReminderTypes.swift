import Foundation

enum NotificationAuthorizationState: Equatable {
    case notDetermined
    case denied
    case authorized
    case provisional

    var canSchedule: Bool {
        self == .authorized || self == .provisional
    }
}

struct ReminderPreferences: Equatable {
    var isEnabled: Bool
    var intervalMinutes: Int
    var startMinute: Int
    var endMinute: Int
    var activeWeekdays: Int
    var soundEnabled: Bool
    var snoozeMinutes: Int

    func isActive(on weekday: Int) -> Bool {
        guard (1...7).contains(weekday) else { return false }
        return activeWeekdays & (1 << (weekday - 1)) != 0
    }

    mutating func setActive(_ isActive: Bool, weekday: Int) {
        guard (1...7).contains(weekday) else { return }
        let mask = 1 << (weekday - 1)
        if isActive {
            activeWeekdays |= mask
        } else {
            activeWeekdays &= ~mask
        }
    }
}

struct NotificationScheduleItem: Equatable {
    let identifier: String
    let date: Date
    let title: String
    let body: String
    let soundEnabled: Bool
}
