import Foundation

struct LocalDay: Equatable {
    let identifier: String
    let start: Date
    let timeZoneIdentifier: String

    init(containing date: Date, calendar: Calendar) {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let year = components.year ?? 0
        let month = components.month ?? 0
        let day = components.day ?? 0

        self.identifier = String(format: "%04d-%02d-%02d", year, month, day)
        self.start = calendar.startOfDay(for: date)
        self.timeZoneIdentifier = calendar.timeZone.identifier
    }
}
