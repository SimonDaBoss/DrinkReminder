import CoreData
import Foundation

@objc(ContainerPresetEntity)
final class ContainerPresetEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var name: String
    @NSManaged var volumeML: Double
    @NSManaged var symbolName: String
    @NSManaged var sortOrder: Int16
    @NSManaged var isDefault: Bool
    @NSManaged var createdAt: Date
}
