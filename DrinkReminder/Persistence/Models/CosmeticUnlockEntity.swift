import CoreData
import Foundation

@objc(CosmeticUnlockEntity)
final class CosmeticUnlockEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var cosmeticIdentifier: String
    @NSManaged var category: String
    @NSManaged var unlockedAt: Date
    @NSManaged var isEquipped: Bool
}
