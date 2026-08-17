import Combine
import Foundation

@MainActor
final class ReminderViewModel: ObservableObject {
    @Published var isEnabled = false
    @Published var intervalMinutes = 60
    @Published var startTime = Date()
    @Published var endTime = Date()
    @Published var activeWeekdays = 0b111_1111
    @Published var soundEnabled = true
    @Published private(set) var authorizationState: NotificationAuthorizationState = .notDetermined
    @Published private(set) var isWorking = false
    @Published var statusMessage: String?
    @Published var errorMessage: String?

    private let manager: ReminderManager
    private var calendar: Calendar
    private var snoozeMinutes = 15

    init(
        manager: ReminderManager,
        calendar: Calendar = .autoupdatingCurrent
    ) {
        self.manager = manager
        self.calendar = calendar
    }

    var authorizationDescription: String {
        switch authorizationState {
        case .notDetermined: return "Not requested"
        case .denied: return "Disabled in iPhone Settings"
        case .authorized: return "Allowed"
        case .provisional: return "Delivering quietly"
        }
    }

    func isWeekdayActive(_ weekday: Int) -> Bool {
        activeWeekdays & (1 << (weekday - 1)) != 0
    }

    func toggleWeekday(_ weekday: Int) {
        let mask = 1 << (weekday - 1)
        if isWeekdayActive(weekday) {
            activeWeekdays &= ~mask
        } else {
            activeWeekdays |= mask
        }
    }

    func load() async {
        do {
            let preferences = try manager.preferences()
            isEnabled = preferences.isEnabled
            intervalMinutes = preferences.intervalMinutes
            startTime = date(forMinuteOfDay: preferences.startMinute)
            endTime = date(forMinuteOfDay: preferences.endMinute)
            activeWeekdays = preferences.activeWeekdays
            soundEnabled = preferences.soundEnabled
            snoozeMinutes = preferences.snoozeMinutes
            authorizationState = await manager.authorizationState()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func save() async -> Bool {
        guard activeWeekdays != 0 else {
            errorMessage = "Choose at least one reminder day."
            return false
        }

        let startMinute = minuteOfDay(for: startTime)
        let endMinute = minuteOfDay(for: endTime)
        guard startMinute < endMinute else {
            errorMessage = "Reminder end time must be later than the start time."
            return false
        }

        isWorking = true
        defer { isWorking = false }

        do {
            if isEnabled && !authorizationState.canSchedule {
                authorizationState = try await manager.requestAuthorization()
                guard authorizationState.canSchedule else {
                    isEnabled = false
                    try await manager.save(makePreferences(
                        isEnabled: false,
                        startMinute: startMinute,
                        endMinute: endMinute
                    ))
                    errorMessage = "Notifications are disabled. Allow them in iPhone Settings to turn on reminders."
                    return false
                }
            }

            try await manager.save(makePreferences(
                isEnabled: isEnabled,
                startMinute: startMinute,
                endMinute: endMinute
            ))
            statusMessage = isEnabled ? "Reminder schedule updated." : "Reminders turned off."
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func sendTestNotification() async {
        isWorking = true
        defer { isWorking = false }

        do {
            if !authorizationState.canSchedule {
                authorizationState = try await manager.requestAuthorization()
            }
            guard authorizationState.canSchedule else {
                errorMessage = "Notifications are disabled. Allow them in iPhone Settings, then try again."
                return
            }

            try await manager.scheduleTestNotification(soundEnabled: soundEnabled)
            statusMessage = "Test scheduled. Keep the app open or switch away—it will arrive in about 10 seconds."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func minuteOfDay(for date: Date) -> Int {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }

    private func date(forMinuteOfDay minute: Int) -> Date {
        let startOfToday = calendar.startOfDay(for: Date())
        return calendar.date(byAdding: .minute, value: minute, to: startOfToday) ?? startOfToday
    }

    private func makePreferences(
        isEnabled: Bool,
        startMinute: Int,
        endMinute: Int
    ) -> ReminderPreferences {
        ReminderPreferences(
            isEnabled: isEnabled,
            intervalMinutes: intervalMinutes,
            startMinute: startMinute,
            endMinute: endMinute,
            activeWeekdays: activeWeekdays,
            soundEnabled: soundEnabled,
            snoozeMinutes: snoozeMinutes
        )
    }
}
