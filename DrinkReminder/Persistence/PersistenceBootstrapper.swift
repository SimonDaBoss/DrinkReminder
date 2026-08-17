import CoreData
import Foundation

@MainActor
struct PersistenceBootstrapper {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func prepareDefaults() throws {
        let now = Date()

        if try fetchCount(for: "UserProfileEntity") == 0 {
            let profile = UserProfileEntity(context: context)
            profile.id = UUID()
            profile.displayName = nil
            profile.onboardingCompleted = false
            profile.createdAt = now
        }

        if try fetchCount(for: "AppPreferencesEntity") == 0 {
            let preferences = AppPreferencesEntity(context: context)
            preferences.id = UUID()
            preferences.dailyGoalML = VolumeConverter.milliliters(from: 80, unit: .ounces)
            preferences.displayUnit = .ounces
            preferences.defaultDrinkAmountML = VolumeConverter.milliliters(from: 12, unit: .ounces)
            preferences.appearance = .system
            preferences.hapticsEnabled = true
        }

        if try fetchCount(for: "ReminderPreferencesEntity") == 0 {
            let reminders = ReminderPreferencesEntity(context: context)
            reminders.id = UUID()
            reminders.isEnabled = false
            reminders.intervalMinutes = 60
            reminders.startMinute = 8 * 60
            reminders.endMinute = 22 * 60
            reminders.activeWeekdays = 0b111_1111
            reminders.soundEnabled = true
            reminders.snoozeMinutes = 15
        }

        if try fetchCount(for: "PetProfileEntity") == 0 {
            let pet = PetProfileEntity(context: context)
            pet.id = UUID()
            pet.name = "Puddle"
            pet.species = .axolotl
            pet.totalXP = 0
            pet.lastInteractionAt = nil
        }

        if try fetchCount(for: "ContainerPresetEntity") == 0 {
            makePreset(name: "Glass", ounces: 8, symbolName: "drop", order: 0)
            makePreset(name: "Cup", ounces: 12, symbolName: "cup.and.saucer", order: 1, isDefault: true)
            makePreset(name: "Bottle", ounces: 16, symbolName: "waterbottle", order: 2)
            makePreset(name: "Large Bottle", ounces: 24, symbolName: "waterbottle.fill", order: 3)
        }

        if context.hasChanges {
            try context.save()
        }
    }

    private func fetchCount(for entityName: String) throws -> Int {
        try context.count(for: NSFetchRequest<NSFetchRequestResult>(entityName: entityName))
    }

    private func makePreset(
        name: String,
        ounces: Double,
        symbolName: String,
        order: Int16,
        isDefault: Bool = false
    ) {
        let preset = ContainerPresetEntity(context: context)
        preset.id = UUID()
        preset.name = name
        preset.volumeML = VolumeConverter.milliliters(from: ounces, unit: .ounces)
        preset.symbolName = symbolName
        preset.sortOrder = order
        preset.isDefault = isDefault
        preset.createdAt = Date()
    }
}
