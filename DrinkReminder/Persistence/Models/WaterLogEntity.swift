import CoreData
import Foundation

@objc(WaterLogEntity)
final class WaterLogEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var loggedAt: Date
    @NSManaged var volumeML: Double
    @NSManaged var sourceRawValue: String
    @NSManaged var presetID: UUID?
    @NSManaged var day: HydrationDayEntity
}

extension WaterLogEntity {
    var source: WaterLogSource {
        get { WaterLogSource(rawValue: sourceRawValue) ?? .custom }
        set { sourceRawValue = newValue.rawValue }
    }
}
