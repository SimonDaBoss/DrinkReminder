import CoreData
import Foundation

@objc(HydrationDayEntity)
final class HydrationDayEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var dayIdentifier: String
    @NSManaged var dayStart: Date
    @NSManaged var timeZoneIdentifier: String
    @NSManaged var goalML: Double
    @NSManaged var totalML: Double
    @NSManaged var goalReachedAt: Date?
    @NSManaged var logs: Set<WaterLogEntity>
}

extension HydrationDayEntity {
    var summary: HydrationSummary {
        HydrationSummary(
            dayIdentifier: dayIdentifier,
            totalML: totalML,
            goalML: goalML,
            goalReachedAt: goalReachedAt
        )
    }
}
