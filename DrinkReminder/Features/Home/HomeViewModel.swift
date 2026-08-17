import Combine
import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    struct UndoState: Equatable {
        let logID: UUID
        let amountML: Double
    }

    @Published private(set) var summary: HydrationSummary?
    @Published private(set) var presets: [ContainerPreset] = []
    @Published private(set) var displayUnit: VolumeUnit = .ounces
    @Published private(set) var defaultDrinkAmountML: Double = 0
    @Published private(set) var petMood: PetMood = .idle
    @Published private(set) var undoState: UndoState?
    @Published var errorMessage: String?

    private let hydrationTracker: HydrationTrackingService
    private let haptics: any HapticProviding
    private weak var reminderRefresher: (any HydrationReminderRefreshing)?
    private var hapticsEnabled = true
    private var reactionTask: Task<Void, Never>?
    private var undoDismissTask: Task<Void, Never>?

    init(
        hydrationTracker: HydrationTrackingService,
        haptics: any HapticProviding,
        reminderRefresher: (any HydrationReminderRefreshing)? = nil
    ) {
        self.hydrationTracker = hydrationTracker
        self.haptics = haptics
        self.reminderRefresher = reminderRefresher
    }

    convenience init(hydrationTracker: HydrationTrackingService) {
        self.init(hydrationTracker: hydrationTracker, haptics: HapticClient())
    }

    var progress: Double {
        summary?.progress ?? 0
    }

    var consumedText: String {
        VolumeDisplayFormatter.string(
            milliliters: summary?.totalML ?? 0,
            unit: displayUnit
        )
    }

    var goalText: String {
        VolumeDisplayFormatter.string(
            milliliters: summary?.goalML ?? 0,
            unit: displayUnit
        )
    }

    var preferredAmountText: String {
        VolumeDisplayFormatter.string(
            milliliters: defaultDrinkAmountML,
            unit: displayUnit
        )
    }

    var preferredContainerName: String {
        presets.first(where: \.isDefault)?.name.lowercased() ?? "usual drink"
    }

    var progressPercentText: String {
        progress.formatted(.percent.precision(.fractionLength(0)))
    }

    var encouragementText: String {
        guard let summary else { return "Getting today ready…" }
        if summary.isGoalReached {
            return "Daily goal complete!"
        }

        let remaining = max(summary.goalML - summary.totalML, 0)
        if progress >= 0.75 {
            return "Only \(VolumeDisplayFormatter.string(milliliters: remaining, unit: displayUnit)) to go"
        } else if progress >= 0.5 {
            return "More than halfway there"
        } else if progress > 0 {
            return "Every sip helps your buddy grow"
        } else {
            return "Start with one refreshing sip"
        }
    }

    func load() {
        do {
            let configuration = try hydrationTracker.configuration()
            displayUnit = configuration.displayUnit
            defaultDrinkAmountML = configuration.defaultDrinkAmountML
            hapticsEnabled = configuration.hapticsEnabled
            presets = configuration.presets
            summary = try hydrationTracker.todaySummary()
            petMood = restingMood
            reminderRefresher?.hydrationStateDidChange()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func logPreferredAmount() {
        let defaultPreset = presets.first(where: \.isDefault)
        logWater(
            volumeML: defaultDrinkAmountML,
            source: defaultPreset == nil ? .quickAdd : .preset,
            presetID: defaultPreset?.id
        )
    }

    func logEstimatedFraction(_ fraction: Double) {
        guard fraction.isFinite, fraction > 0 else { return }
        logWater(volumeML: defaultDrinkAmountML * fraction, source: .quickAdd)
    }

    func log(preset: ContainerPreset) {
        logWater(volumeML: preset.volumeML, source: .preset, presetID: preset.id)
    }

    func logCustom(displayAmount: Double) {
        let volumeML = VolumeConverter.milliliters(from: displayAmount, unit: displayUnit)
        logWater(volumeML: volumeML, source: .custom)
    }

    func undoLastLog() {
        guard let undoState else { return }

        do {
            summary = try hydrationTracker.undoWaterLog(id: undoState.logID)
            self.undoState = nil
            undoDismissTask?.cancel()
            petMood = restingMood
            if hapticsEnabled {
                haptics.undoCompleted()
            }
            reminderRefresher?.hydrationStateDidChange()
        } catch {
            errorMessage = error.localizedDescription
            self.undoState = nil
        }
    }

    func dismissUndo() {
        undoState = nil
        undoDismissTask?.cancel()
    }

    private func logWater(
        volumeML: Double,
        source: WaterLogSource,
        presetID: UUID? = nil
    ) {
        do {
            let result = try hydrationTracker.logWater(
                volumeML: volumeML,
                source: source,
                presetID: presetID
            )
            summary = result.summary
            undoState = UndoState(logID: result.logID, amountML: result.loggedAmountML)
            if hapticsEnabled {
                haptics.waterLogged(reachedGoal: result.reachedGoal)
            }
            react(to: result)
            scheduleUndoDismissal()
            reminderRefresher?.hydrationStateDidChange()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private var restingMood: PetMood {
        guard let summary else { return .idle }
        if summary.isGoalReached { return .happy }
        if summary.progress >= 0.75 { return .excited }
        return .idle
    }

    private func react(to result: HydrationLogResult) {
        reactionTask?.cancel()
        if result.reachedGoal {
            petMood = .celebrating
        } else if result.crossedHalfway {
            petMood = .excited
        } else {
            petMood = .drinking
        }

        reactionTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 1_100_000_000)
            guard !Task.isCancelled else { return }
            self?.petMood = self?.restingMood ?? .idle
        }
    }

    private func scheduleUndoDismissal() {
        undoDismissTask?.cancel()
        undoDismissTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            guard !Task.isCancelled else { return }
            self?.undoState = nil
        }
    }
}
