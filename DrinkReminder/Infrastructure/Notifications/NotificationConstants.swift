import Foundation

enum NotificationConstants {
    static let categoryIdentifier = "HYDRATION_REMINDER"
    static let reminderIdentifierPrefix = "hydration.reminder."
    static let snoozeIdentifierPrefix = "hydration.snooze."
    static let testIdentifierPrefix = "hydration.test."

    enum Action {
        static let drank = "HYDRATION_DRANK"
        static let snooze = "HYDRATION_SNOOZE"
        static let skip = "HYDRATION_SKIP"
    }
}
