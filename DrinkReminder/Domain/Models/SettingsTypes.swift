import Foundation

struct AppSettingsSnapshot: Equatable {
    let displayName: String?
    let onboardingCompleted: Bool
    let dailyGoalML: Double
    let displayUnit: VolumeUnit
    let defaultDrinkAmountML: Double
    let appearance: AppAppearance
    let hapticsEnabled: Bool
    let petIdentity: PetIdentity
    let presets: [ContainerPreset]
}

struct OnboardingSelection: Equatable {
    let displayName: String?
    let dailyGoalML: Double
    let displayUnit: VolumeUnit
    let defaultPresetID: UUID
    let petName: String
    let petSpecies: PetSpecies
}

enum AppSettingsError: LocalizedError, Equatable {
    case invalidGoal
    case invalidContainer
    case invalidContainerName
    case invalidReminderHours
    case cannotDeleteLastContainer
    case missingRequiredData

    var errorDescription: String? {
        switch self {
        case .invalidGoal:
            return "Choose a daily goal greater than zero."
        case .invalidContainer:
            return "Choose a container with a volume greater than zero."
        case .invalidContainerName:
            return "Give this container a name."
        case .invalidReminderHours:
            return "Choose an end time after the reminder start time."
        case .cannotDeleteLastContainer:
            return "Keep at least one container for quick logging."
        case .missingRequiredData:
            return "The local settings store is incomplete."
        }
    }
}
