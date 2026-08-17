import CoreData
import Foundation

@objc(AppPreferencesEntity)
final class AppPreferencesEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var dailyGoalML: Double
    @NSManaged var displayUnitRawValue: String
    @NSManaged var defaultDrinkAmountML: Double
    @NSManaged var appearanceRawValue: String
    @NSManaged var hapticsEnabled: Bool
}

extension AppPreferencesEntity {
    var displayUnit: VolumeUnit {
        get { VolumeUnit(rawValue: displayUnitRawValue) ?? .ounces }
        set { displayUnitRawValue = newValue.rawValue }
    }

    var appearance: AppAppearance {
        get { AppAppearance(rawValue: appearanceRawValue) ?? .system }
        set { appearanceRawValue = newValue.rawValue }
    }
}
