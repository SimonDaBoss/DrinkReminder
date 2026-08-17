import CoreData
import Foundation

@objc(UserProfileEntity)
final class UserProfileEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var displayName: String?
    @NSManaged var onboardingCompleted: Bool
    @NSManaged var createdAt: Date
}
