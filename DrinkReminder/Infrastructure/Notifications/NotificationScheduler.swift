import Foundation
import UserNotifications

@MainActor
protocol NotificationScheduling {
    func registerCategories()
    func authorizationState() async -> NotificationAuthorizationState
    func requestAuthorization() async throws -> NotificationAuthorizationState
    func replaceHydrationReminders(with items: [NotificationScheduleItem]) async throws
    func cancelHydrationReminders() async
    func scheduleTestNotification(soundEnabled: Bool) async throws
    func scheduleSnooze(minutes: Int, soundEnabled: Bool) async throws
}

@MainActor
final class NotificationScheduler: NotificationScheduling {
    private let center: UNUserNotificationCenter
    private let calendar: Calendar

    init(
        center: UNUserNotificationCenter = .current(),
        calendar: Calendar = .autoupdatingCurrent
    ) {
        self.center = center
        self.calendar = calendar
    }

    func registerCategories() {
        let drank = UNNotificationAction(
            identifier: NotificationConstants.Action.drank,
            title: "Drank It",
            options: []
        )
        let snooze = UNNotificationAction(
            identifier: NotificationConstants.Action.snooze,
            title: "Remind Me Later",
            options: []
        )
        let skip = UNNotificationAction(
            identifier: NotificationConstants.Action.skip,
            title: "Skip",
            options: []
        )
        let category = UNNotificationCategory(
            identifier: NotificationConstants.categoryIdentifier,
            actions: [drank, snooze, skip],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        center.setNotificationCategories([category])
    }

    func authorizationState() async -> NotificationAuthorizationState {
        let settings = await center.notificationSettings()
        return map(settings.authorizationStatus)
    }

    func requestAuthorization() async throws -> NotificationAuthorizationState {
        _ = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        return await authorizationState()
    }

    func replaceHydrationReminders(with items: [NotificationScheduleItem]) async throws {
        await removePendingRequests(withPrefixes: [NotificationConstants.reminderIdentifierPrefix])

        for item in items {
            let content = notificationContent(
                title: item.title,
                body: item.body,
                soundEnabled: item.soundEnabled
            )
            var components = calendar.dateComponents(
                [.year, .month, .day, .hour, .minute, .second],
                from: item.date
            )
            components.timeZone = calendar.timeZone
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            try await center.add(UNNotificationRequest(
                identifier: item.identifier,
                content: content,
                trigger: trigger
            ))
        }
    }

    func cancelHydrationReminders() async {
        await removePendingRequests(withPrefixes: [
            NotificationConstants.reminderIdentifierPrefix,
            NotificationConstants.snoozeIdentifierPrefix
        ])
    }

    func scheduleTestNotification(soundEnabled: Bool) async throws {
        let content = notificationContent(
            title: "Water Pet test 💧",
            body: "It works! Your hydration reminders are ready.",
            soundEnabled: soundEnabled
        )
        let request = UNNotificationRequest(
            identifier: NotificationConstants.testIdentifierPrefix + UUID().uuidString,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
        )
        try await center.add(request)
    }

    func scheduleSnooze(minutes: Int, soundEnabled: Bool) async throws {
        let content = notificationContent(
            title: "Ready for that water break?",
            body: "Your buddy saved this reminder for you.",
            soundEnabled: soundEnabled
        )
        let request = UNNotificationRequest(
            identifier: NotificationConstants.snoozeIdentifierPrefix + UUID().uuidString,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(
                timeInterval: TimeInterval(max(minutes, 1) * 60),
                repeats: false
            )
        )
        try await center.add(request)
    }

    private func notificationContent(
        title: String,
        body: String,
        soundEnabled: Bool
    ) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.categoryIdentifier = NotificationConstants.categoryIdentifier
        content.sound = soundEnabled ? .default : nil
        return content
    }

    private func removePendingRequests(withPrefixes prefixes: [String]) async {
        let requests = await center.pendingNotificationRequests()
        let identifiers = requests
            .map(\.identifier)
            .filter { identifier in prefixes.contains { identifier.hasPrefix($0) } }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    private func map(_ status: UNAuthorizationStatus) -> NotificationAuthorizationState {
        switch status {
        case .authorized, .ephemeral:
            return .authorized
        case .provisional:
            return .provisional
        case .denied:
            return .denied
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .notDetermined
        }
    }
}
