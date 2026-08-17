import CoreData
import Foundation

@objc(ReminderPreferencesEntity)
final class ReminderPreferencesEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var isEnabled: Bool
    @NSManaged var intervalMinutes: Int32
    @NSManaged var startMinute: Int32
    @NSManaged var endMinute: Int32
    @NSManaged var activeWeekdays: Int16
    @NSManaged var soundEnabled: Bool
    @NSManaged var snoozeMinutes: Int32
}
