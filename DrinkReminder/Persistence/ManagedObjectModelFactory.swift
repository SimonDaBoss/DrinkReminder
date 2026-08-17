import CoreData
import Foundation

enum ManagedObjectModelFactory {
    static let model = makeModel()

    private static func makeModel() -> NSManagedObjectModel {
        let userProfile = entity("UserProfileEntity", UserProfileEntity.self, attributes: [
            attribute("id", .UUIDAttributeType),
            attribute("displayName", .stringAttributeType, optional: true),
            attribute("onboardingCompleted", .booleanAttributeType, defaultValue: false),
            attribute("createdAt", .dateAttributeType)
        ])

        let hydrationDay = entity("HydrationDayEntity", HydrationDayEntity.self, attributes: [
            attribute("id", .UUIDAttributeType),
            attribute("dayIdentifier", .stringAttributeType),
            attribute("dayStart", .dateAttributeType),
            attribute("timeZoneIdentifier", .stringAttributeType),
            attribute("goalML", .doubleAttributeType),
            attribute("totalML", .doubleAttributeType, defaultValue: 0.0),
            attribute("goalReachedAt", .dateAttributeType, optional: true)
        ])
        hydrationDay.uniquenessConstraints = [["dayIdentifier"]]

        let waterLog = entity("WaterLogEntity", WaterLogEntity.self, attributes: [
            attribute("id", .UUIDAttributeType),
            attribute("loggedAt", .dateAttributeType),
            attribute("volumeML", .doubleAttributeType),
            attribute("sourceRawValue", .stringAttributeType),
            attribute("presetID", .UUIDAttributeType, optional: true)
        ])

        let containerPreset = entity("ContainerPresetEntity", ContainerPresetEntity.self, attributes: [
            attribute("id", .UUIDAttributeType),
            attribute("name", .stringAttributeType),
            attribute("volumeML", .doubleAttributeType),
            attribute("symbolName", .stringAttributeType),
            attribute("sortOrder", .integer16AttributeType),
            attribute("isDefault", .booleanAttributeType, defaultValue: false),
            attribute("createdAt", .dateAttributeType)
        ])

        let reminderPreferences = entity("ReminderPreferencesEntity", ReminderPreferencesEntity.self, attributes: [
            attribute("id", .UUIDAttributeType),
            attribute("isEnabled", .booleanAttributeType, defaultValue: false),
            attribute("intervalMinutes", .integer32AttributeType, defaultValue: 60),
            attribute("startMinute", .integer32AttributeType, defaultValue: 480),
            attribute("endMinute", .integer32AttributeType, defaultValue: 1_320),
            attribute("activeWeekdays", .integer16AttributeType, defaultValue: 127),
            attribute("soundEnabled", .booleanAttributeType, defaultValue: true),
            attribute("snoozeMinutes", .integer32AttributeType, defaultValue: 15)
        ])

        let petProfile = entity("PetProfileEntity", PetProfileEntity.self, attributes: [
            attribute("id", .UUIDAttributeType),
            attribute("name", .stringAttributeType),
            attribute("speciesRawValue", .stringAttributeType),
            attribute("totalXP", .integer64AttributeType, defaultValue: 0),
            attribute("lastInteractionAt", .dateAttributeType, optional: true)
        ])

        let xpAward = entity("XPAwardEntity", XPAwardEntity.self, attributes: [
            attribute("id", .UUIDAttributeType),
            attribute("eventKey", .stringAttributeType),
            attribute("amount", .integer64AttributeType),
            attribute("reasonRawValue", .stringAttributeType),
            attribute("awardedAt", .dateAttributeType),
            attribute("dayIdentifier", .stringAttributeType, optional: true)
        ])
        xpAward.uniquenessConstraints = [["eventKey"]]

        let cosmeticUnlock = entity("CosmeticUnlockEntity", CosmeticUnlockEntity.self, attributes: [
            attribute("id", .UUIDAttributeType),
            attribute("cosmeticIdentifier", .stringAttributeType),
            attribute("category", .stringAttributeType),
            attribute("unlockedAt", .dateAttributeType),
            attribute("isEquipped", .booleanAttributeType, defaultValue: false)
        ])
        cosmeticUnlock.uniquenessConstraints = [["cosmeticIdentifier"]]

        let appPreferences = entity("AppPreferencesEntity", AppPreferencesEntity.self, attributes: [
            attribute("id", .UUIDAttributeType),
            attribute("dailyGoalML", .doubleAttributeType),
            attribute("displayUnitRawValue", .stringAttributeType),
            attribute("defaultDrinkAmountML", .doubleAttributeType),
            attribute("appearanceRawValue", .stringAttributeType),
            attribute("hapticsEnabled", .booleanAttributeType, defaultValue: true)
        ])

        let logsRelationship = relationship(
            "logs",
            destination: waterLog,
            toMany: true,
            deleteRule: .cascadeDeleteRule
        )
        let dayRelationship = relationship(
            "day",
            destination: hydrationDay,
            toMany: false,
            deleteRule: .nullifyDeleteRule,
            optional: false
        )
        logsRelationship.inverseRelationship = dayRelationship
        dayRelationship.inverseRelationship = logsRelationship
        hydrationDay.properties.append(logsRelationship)
        waterLog.properties.append(dayRelationship)

        let model = NSManagedObjectModel()
        model.entities = [
            userProfile,
            hydrationDay,
            waterLog,
            containerPreset,
            reminderPreferences,
            petProfile,
            xpAward,
            cosmeticUnlock,
            appPreferences
        ]
        return model
    }

    private static func entity(
        _ name: String,
        _ type: NSManagedObject.Type,
        attributes: [NSAttributeDescription]
    ) -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = name
        entity.managedObjectClassName = NSStringFromClass(type)
        entity.properties = attributes
        return entity
    }

    private static func attribute(
        _ name: String,
        _ type: NSAttributeType,
        optional: Bool = false,
        defaultValue: Any? = nil
    ) -> NSAttributeDescription {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = type
        attribute.isOptional = optional
        attribute.defaultValue = defaultValue
        return attribute
    }

    private static func relationship(
        _ name: String,
        destination: NSEntityDescription,
        toMany: Bool,
        deleteRule: NSDeleteRule,
        optional: Bool = true
    ) -> NSRelationshipDescription {
        let relationship = NSRelationshipDescription()
        relationship.name = name
        relationship.destinationEntity = destination
        relationship.minCount = optional ? 0 : 1
        relationship.maxCount = toMany ? 0 : 1
        relationship.isOptional = optional
        relationship.isOrdered = false
        relationship.deleteRule = deleteRule
        return relationship
    }
}
