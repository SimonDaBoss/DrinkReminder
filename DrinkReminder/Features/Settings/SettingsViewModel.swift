import Combine
import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var displayName = ""
    @Published var dailyGoalDisplayValue = 0.0
    @Published var displayUnit: VolumeUnit = .ounces
    @Published var defaultPresetID: UUID?
    @Published var petName = "Puddle"
    @Published var petSpecies: PetSpecies = .axolotl
    @Published var appearance: AppAppearance = .system
    @Published var hapticsEnabled = true
    @Published private(set) var presets: [ContainerPreset] = []
    @Published private(set) var isWorking = false
    @Published var statusMessage: String?
    @Published var errorMessage: String?

    private let settingsService: AppSettingsService
    private let reminderManager: ReminderManager

    init(
        settingsService: AppSettingsService,
        reminderManager: ReminderManager
    ) {
        self.settingsService = settingsService
        self.reminderManager = reminderManager
    }

    func load() {
        do {
            let snapshot = try settingsService.snapshot()
            displayName = snapshot.displayName ?? ""
            displayUnit = snapshot.displayUnit
            dailyGoalDisplayValue = VolumeConverter.displayValue(
                fromMilliliters: snapshot.dailyGoalML,
                unit: snapshot.displayUnit
            )
            defaultPresetID = snapshot.presets.first(where: \.isDefault)?.id
            petName = snapshot.petIdentity.name
            petSpecies = snapshot.petIdentity.species
            appearance = snapshot.appearance
            hapticsEnabled = snapshot.hapticsEnabled
            presets = snapshot.presets
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func setDisplayUnit(_ unit: VolumeUnit) {
        guard unit != displayUnit else { return }
        let milliliters = VolumeConverter.milliliters(
            from: dailyGoalDisplayValue,
            unit: displayUnit
        )
        displayUnit = unit
        dailyGoalDisplayValue = VolumeConverter.displayValue(
            fromMilliliters: milliliters,
            unit: unit
        ).rounded()
    }

    func save() -> Bool {
        guard let defaultPresetID else {
            errorMessage = AppSettingsError.invalidContainer.localizedDescription
            return false
        }

        do {
            try settingsService.saveSettings(
                displayName: displayName,
                dailyGoalML: VolumeConverter.milliliters(
                    from: dailyGoalDisplayValue,
                    unit: displayUnit
                ),
                displayUnit: displayUnit,
                defaultPresetID: defaultPresetID,
                petName: petName,
                petSpecies: petSpecies,
                appearance: appearance,
                hapticsEnabled: hapticsEnabled
            )
            load()
            statusMessage = "Settings saved."
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func saveContainer(
        id: UUID?,
        name: String,
        displayAmount: Double,
        symbolName: String
    ) -> Bool {
        do {
            let savedID = try settingsService.saveContainer(
                id: id,
                name: name,
                volumeML: VolumeConverter.milliliters(from: displayAmount, unit: displayUnit),
                symbolName: symbolName
            )
            try refreshContainers()
            if defaultPresetID == nil {
                defaultPresetID = savedID
            }
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func deleteContainer(id: UUID) {
        do {
            try settingsService.deleteContainer(id: id)
            try refreshContainers()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func setDefaultContainer(id: UUID) {
        do {
            try settingsService.setDefaultContainer(id: id)
            try refreshContainers()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func resetAllData() async -> Bool {
        isWorking = true
        defer { isWorking = false }

        do {
            try settingsService.resetAllData()
            try await reminderManager.refreshSchedule()
            load()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    private func refreshContainers() throws {
        let snapshot = try settingsService.snapshot()
        presets = snapshot.presets
        defaultPresetID = snapshot.presets.first(where: \.isDefault)?.id
    }
}
