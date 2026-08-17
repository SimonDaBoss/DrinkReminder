import CoreData
import Foundation

@objc(PetProfileEntity)
final class PetProfileEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var name: String
    @NSManaged var speciesRawValue: String
    @NSManaged var totalXP: Int64
    @NSManaged var lastInteractionAt: Date?
}

extension PetProfileEntity {
    var species: PetSpecies {
        get { PetSpecies(rawValue: speciesRawValue) ?? .axolotl }
        set { speciesRawValue = newValue.rawValue }
    }
}
