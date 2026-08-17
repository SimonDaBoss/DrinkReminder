import CoreData
import Foundation

@MainActor
final class AppSettingsService: PetProfileProviding {
    private let context: NSManagedObjectContext
    private let hydrationTracker: HydrationTrackingService

    init(
        context: NSManagedObjectContext,
        hydrationTracker: HydrationTrackingService
    ) {
        self.context = context
        self.hydrationTracker = hydrationTracker
    }

    func snapshot() throws -> AppSettingsSnapshot {
        let profile = try fetchOne(UserProfileEntity.self, entityName: "UserProfileEntity")
        let preferences = try fetchOne(AppPreferencesEntity.self, entityName: "AppPreferencesEntity")
        let pet = try fetchOne(PetProfileEntity.self, entityName: "PetProfileEntity")

        return AppSettingsSnapshot(
            displayName: profile.displayName,
            onboardingCompleted: profile.onboardingCompleted,
            dailyGoalML: preferences.dailyGoalML,
            displayUnit: preferences.displayUnit,
            defaultDrinkAmountML: preferences.defaultDrinkAmountML,
            appearance: preferences.appearance,
            hapticsEnabled: preferences.hapticsEnabled,
            petIdentity: PetIdentity(name: pet.name, species: pet.species),
            presets: try fetchPresets()
        )
    }

    func petIdentity() throws -> PetIdentity {
        let pet = try fetchOne(PetProfileEntity.self, entityName: "PetProfileEntity")
        return PetIdentity(name: pet.name, species: pet.species)
    }

    func completeOnboarding(_ selection: OnboardingSelection) throws {
        try validateGoal(selection.dailyGoalML)
        guard selection.petName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else {
            throw AppSettingsError.missingRequiredData
        }

        let profile = try fetchOne(UserProfileEntity.self, entityName: "UserProfileEntity")
        let preferences = try fetchOne(AppPreferencesEntity.self, entityName: "AppPreferencesEntity")
        let pet = try fetchOne(PetProfileEntity.self, entityName: "PetProfileEntity")
        let presets = try fetchPresetEntities()
        guard let defaultPreset = presets.first(where: { $0.id == selection.defaultPresetID }) else {
            throw AppSettingsError.invalidContainer
        }

        profile.displayName = normalizedOptionalName(selection.displayName)
        profile.onboardingCompleted = true
        preferences.dailyGoalML = selection.dailyGoalML
        preferences.displayUnit = selection.displayUnit
        preferences.defaultDrinkAmountML = defaultPreset.volumeML
        pet.name = selection.petName.trimmingCharacters(in: .whitespacesAndNewlines)
        pet.species = selection.petSpecies
        setDefaultPreset(selection.defaultPresetID, among: presets)

        try saveAndUpdateTodayGoal(selection.dailyGoalML)
    }

    func saveSettings(
        displayName: String?,
        dailyGoalML: Double,
        displayUnit: VolumeUnit,
        defaultPresetID: UUID,
        petName: String,
        petSpecies: PetSpecies,
        appearance: AppAppearance,
        hapticsEnabled: Bool
    ) throws {
        try validateGoal(dailyGoalML)
        let trimmedPetName = petName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPetName.isEmpty else { throw AppSettingsError.missingRequiredData }

        let profile = try fetchOne(UserProfileEntity.self, entityName: "UserProfileEntity")
        let preferences = try fetchOne(AppPreferencesEntity.self, entityName: "AppPreferencesEntity")
        let pet = try fetchOne(PetProfileEntity.self, entityName: "PetProfileEntity")
        let presets = try fetchPresetEntities()
        guard let defaultPreset = presets.first(where: { $0.id == defaultPresetID }) else {
            throw AppSettingsError.invalidContainer
        }

        profile.displayName = normalizedOptionalName(displayName)
        preferences.dailyGoalML = dailyGoalML
        preferences.displayUnit = displayUnit
        preferences.defaultDrinkAmountML = defaultPreset.volumeML
        preferences.appearance = appearance
        preferences.hapticsEnabled = hapticsEnabled
        pet.name = trimmedPetName
        pet.species = petSpecies
        setDefaultPreset(defaultPresetID, among: presets)

        try saveAndUpdateTodayGoal(dailyGoalML)
    }

    @discardableResult
    func saveContainer(
        id: UUID?,
        name: String,
        volumeML: Double,
        symbolName: String
    ) throws -> UUID {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { throw AppSettingsError.invalidContainerName }
        guard volumeML.isFinite, volumeML > 0 else { throw AppSettingsError.invalidContainer }

        let presets = try fetchPresetEntities()
        let preset: ContainerPresetEntity
        if let id, let existing = presets.first(where: { $0.id == id }) {
            preset = existing
        } else {
            preset = ContainerPresetEntity(context: context)
            preset.id = id ?? UUID()
            preset.createdAt = Date()
            preset.sortOrder = (presets.map(\.sortOrder).max() ?? -1) + 1
            preset.isDefault = presets.isEmpty
        }
        preset.name = trimmedName
        preset.volumeML = volumeML
        preset.symbolName = symbolName
        try context.save()

        if preset.isDefault {
            let preferences = try fetchOne(AppPreferencesEntity.self, entityName: "AppPreferencesEntity")
            preferences.defaultDrinkAmountML = volumeML
            try context.save()
        }
        return preset.id
    }

    func deleteContainer(id: UUID) throws {
        let presets = try fetchPresetEntities()
        guard presets.count > 1 else { throw AppSettingsError.cannotDeleteLastContainer }
        guard let preset = presets.first(where: { $0.id == id }) else { return }

        let wasDefault = preset.isDefault
        context.delete(preset)
        if wasDefault, let replacement = presets.first(where: { $0.id != id }) {
            replacement.isDefault = true
            let preferences = try fetchOne(AppPreferencesEntity.self, entityName: "AppPreferencesEntity")
            preferences.defaultDrinkAmountML = replacement.volumeML
        }
        try context.save()
    }

    func setDefaultContainer(id: UUID) throws {
        let presets = try fetchPresetEntities()
        guard let selected = presets.first(where: { $0.id == id }) else {
            throw AppSettingsError.invalidContainer
        }
        setDefaultPreset(id, among: presets)
        let preferences = try fetchOne(AppPreferencesEntity.self, entityName: "AppPreferencesEntity")
        preferences.defaultDrinkAmountML = selected.volumeML
        try context.save()
    }

    func resetAllData() throws {
        let entityNames = [
            "WaterLogEntity",
            "HydrationDayEntity",
            "XPAwardEntity",
            "CosmeticUnlockEntity",
            "ContainerPresetEntity",
            "ReminderPreferencesEntity",
            "PetProfileEntity",
            "AppPreferencesEntity",
            "UserProfileEntity"
        ]

        for entityName in entityNames {
            let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
            for object in try context.fetch(request) {
                context.delete(object)
            }
        }
        try context.save()
        try PersistenceBootstrapper(context: context).prepareDefaults()
    }

    private func fetchPresets() throws -> [ContainerPreset] {
        try fetchPresetEntities().map {
            ContainerPreset(
                id: $0.id,
                name: $0.name,
                volumeML: $0.volumeML,
                symbolName: $0.symbolName,
                isDefault: $0.isDefault
            )
        }
    }

    private func fetchPresetEntities() throws -> [ContainerPresetEntity] {
        let request = NSFetchRequest<ContainerPresetEntity>(entityName: "ContainerPresetEntity")
        request.sortDescriptors = [NSSortDescriptor(key: "sortOrder", ascending: true)]
        return try context.fetch(request)
    }

    private func fetchOne<T: NSManagedObject>(
        _ type: T.Type,
        entityName: String
    ) throws -> T {
        let request = NSFetchRequest<T>(entityName: entityName)
        request.fetchLimit = 1
        guard let value = try context.fetch(request).first else {
            throw AppSettingsError.missingRequiredData
        }
        return value
    }

    private func setDefaultPreset(
        _ selectedID: UUID,
        among presets: [ContainerPresetEntity]
    ) {
        for preset in presets {
            preset.isDefault = preset.id == selectedID
        }
    }

    private func saveAndUpdateTodayGoal(_ goalML: Double) throws {
        do {
            try context.save()
            try hydrationTracker.updateTodayGoal(goalML)
        } catch {
            context.rollback()
            throw error
        }
    }

    private func validateGoal(_ goalML: Double) throws {
        guard goalML.isFinite, goalML > 0 else { throw AppSettingsError.invalidGoal }
    }

    private func normalizedOptionalName(_ value: String?) -> String? {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }
}
