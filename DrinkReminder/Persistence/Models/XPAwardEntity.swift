import CoreData
import Foundation

@objc(XPAwardEntity)
final class XPAwardEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var eventKey: String
    @NSManaged var amount: Int64
    @NSManaged var reasonRawValue: String
    @NSManaged var awardedAt: Date
    @NSManaged var dayIdentifier: String?
}

extension XPAwardEntity {
    var reason: XPAwardReason {
        get { XPAwardReason(rawValue: reasonRawValue) ?? .waterLog }
        set { reasonRawValue = newValue.rawValue }
    }
}
