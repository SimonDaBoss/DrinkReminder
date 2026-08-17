import Combine
import Foundation

@MainActor
final class OnboardingViewModel: ObservableObject {
    static let finalStep = 4

    @Published var step = 0
    @Published var displayName = ""
    @Published var displayUnit: VolumeUnit
    @Published var goalDisplayValue: Double
    @Published private(set) var presets: [ContainerPreset]
    @Published var selectedPresetID: UUID
    @Published var remindersEnabled = true
    @Published var reminderIntervalMinutes = 60
    @Published var reminderStartTime: Date
    @Published var reminderEndTime: Date
    @Published var petName: String
    @Published var petSpecies: PetSpecies
    @Published private(set) var isWorking = false
    @Published var errorMessage: String?

    private let settingsService: AppSettingsService
    private let reminderManager: ReminderManager
    private var calendar: Calendar

    init(
        settingsService: AppSettingsService,
        reminderManager: ReminderManager,
        initial: AppSettingsSnapshot,
        calendar: Calendar = .autoupdatingCurrent
    ) {
        self.settingsService = settingsService
        self.reminderManager = reminderManager
        self.calendar = calendar
        self.displayName = initial.displayName ?? ""
        self.displayUnit = initial.displayUnit
        self.goalDisplayValue = VolumeConverter.displayValue(
            fromMilliliters: initial.dailyGoalML,
            unit: initial.displayUnit
        )
        self.presets = initial.presets
        self.selectedPresetID = initial.presets.first(where: \.isDefault)?.id
            ?? initial.presets.first?.id
            ?? UUID()
        self.petName = initial.petIdentity.name
        self.petSpecies = initial.petIdentity.species

        let startOfToday = calendar.startOfDay(for: Date())
        self.reminderStartTime = calendar.date(byAdding: .hour, value: 8, to: startOfToday) ?? Date()
        self.reminderEndTime = calendar.date(byAdding: .hour, value: 22, to: startOfToday) ?? Date()
    }

    var canGoBack: Bool { step > 0 }
    var isFinalStep: Bool { step == Self.finalStep }

    var selectedPreset: ContainerPreset? {
        presets.first(where: { $0.id == selectedPresetID })
    }

    var goalSuggestions: [Double] {
        displayUnit == .ounces ? [64, 80, 96] : [2_000, 2_500, 3_000]
    }

    func reload() {
        do {
            let initial = try settingsService.snapshot()
            step = 0
            displayName = initial.displayName ?? ""
            displayUnit = initial.displayUnit
            goalDisplayValue = VolumeConverter.displayValue(
                fromMilliliters: initial.dailyGoalML,
                unit: initial.displayUnit
            )
            presets = initial.presets
            selectedPresetID = initial.presets.first(where: \.isDefault)?.id
                ?? initial.presets.first?.id
                ?? UUID()
            petName = initial.petIdentity.name
            petSpecies = initial.petIdentity.species
            remindersEnabled = true
            reminderIntervalMinutes = 60

            let startOfToday = calendar.startOfDay(for: Date())
            reminderStartTime = calendar.date(byAdding: .hour, value: 8, to: startOfToday) ?? Date()
            reminderEndTime = calendar.date(byAdding: .hour, value: 22, to: startOfToday) ?? Date()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func setDisplayUnit(_ unit: VolumeUnit) {
        guard unit != displayUnit else { return }
        let milliliters = VolumeConverter.milliliters(from: goalDisplayValue, unit: displayUnit)
        displayUnit = unit
        goalDisplayValue = VolumeConverter.displayValue(fromMilliliters: milliliters, unit: unit).rounded()
    }

    func goForward() {
        step = min(step + 1, Self.finalStep)
    }

    func goBack() {
        step = max(step - 1, 0)
    }

    func finish() async -> Bool {
        guard let selectedPreset else {
            errorMessage = AppSettingsError.invalidContainer.localizedDescription
            return false
        }
        let goalML = VolumeConverter.milliliters(from: goalDisplayValue, unit: displayUnit)
        guard goalML.isFinite, goalML > 0 else {
            errorMessage = AppSettingsError.invalidGoal.localizedDescription
            return false
        }
        let reminderStartMinute = minuteOfDay(reminderStartTime)
        let reminderEndMinute = minuteOfDay(reminderEndTime)
        guard !remindersEnabled || reminderStartMinute < reminderEndMinute else {
            errorMessage = AppSettingsError.invalidReminderHours.localizedDescription
            return false
        }

        isWorking = true
        defer { isWorking = false }

        do {
            var reminderPreferences = try reminderManager.preferences()
            reminderPreferences.isEnabled = remindersEnabled
            reminderPreferences.intervalMinutes = reminderIntervalMinutes
            reminderPreferences.startMinute = reminderStartMinute
            reminderPreferences.endMinute = reminderEndMinute

            if remindersEnabled {
                let authorization = try await reminderManager.requestAuthorization()
                reminderPreferences.isEnabled = authorization.canSchedule
            }
            try await reminderManager.save(reminderPreferences)

            try settingsService.completeOnboarding(OnboardingSelection(
                displayName: displayName,
                dailyGoalML: goalML,
                displayUnit: displayUnit,
                defaultPresetID: selectedPreset.id,
                petName: petName,
                petSpecies: petSpecies
            ))
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    private func minuteOfDay(_ date: Date) -> Int {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }
}
