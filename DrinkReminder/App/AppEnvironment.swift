import Combine
import Foundation

@MainActor
final class AppEnvironment: ObservableObject {
    private struct Dependencies {
        let persistence: PersistenceController
        let hydrationTracker: HydrationTrackingService
        let settingsService: AppSettingsService
        let progressionService: PetProgressionService
        let reminderManager: ReminderManager
        let homeViewModel: HomeViewModel
        let reminderViewModel: ReminderViewModel
        let onboardingViewModel: OnboardingViewModel
        let settingsViewModel: SettingsViewModel
        let snapshot: AppSettingsSnapshot
    }

    let persistence: PersistenceController
    let hydrationTracker: HydrationTrackingService
    let settingsService: AppSettingsService
    let progressionService: PetProgressionService
    let reminderManager: ReminderManager
    let homeViewModel: HomeViewModel
    let reminderViewModel: ReminderViewModel
    let onboardingViewModel: OnboardingViewModel
    let settingsViewModel: SettingsViewModel

    @Published private(set) var startupError: String?
    @Published private(set) var onboardingCompleted = false
    @Published private(set) var appearance: AppAppearance = .system

    init(inMemory: Bool = false) {
        let dependencies: Dependencies
        let startupError: String?

        do {
            dependencies = try Self.makeDependencies(inMemory: inMemory)
            startupError = nil
        } catch {
            // Keeping an in-memory store available lets the app explain a disk failure
            // instead of terminating before it can present UI.
            dependencies = try! Self.makeDependencies(inMemory: true)
            startupError = error.localizedDescription
        }

        self.persistence = dependencies.persistence
        self.hydrationTracker = dependencies.hydrationTracker
        self.settingsService = dependencies.settingsService
        self.progressionService = dependencies.progressionService
        self.reminderManager = dependencies.reminderManager
        self.homeViewModel = dependencies.homeViewModel
        self.reminderViewModel = dependencies.reminderViewModel
        self.onboardingViewModel = dependencies.onboardingViewModel
        self.settingsViewModel = dependencies.settingsViewModel
        self.onboardingCompleted = dependencies.snapshot.onboardingCompleted
        self.appearance = dependencies.snapshot.appearance
        self.startupError = startupError
        dependencies.reminderManager.registerNotificationCategories()
    }

    func refreshAppState() {
        do {
            let snapshot = try settingsService.snapshot()
            onboardingCompleted = snapshot.onboardingCompleted
            appearance = snapshot.appearance
            homeViewModel.load()
            settingsViewModel.load()
        } catch {
            startupError = error.localizedDescription
        }
    }

    func refreshHomeState() {
        homeViewModel.load()
    }

    func handleDataReset() {
        onboardingViewModel.reload()
        refreshAppState()
    }

    func handleNotificationAction(_ identifier: String) async {
        do {
            switch identifier {
            case NotificationConstants.Action.drank:
                let configuration = try hydrationTracker.configuration()
                let result = try hydrationTracker.logWater(
                    volumeML: configuration.defaultDrinkAmountML,
                    source: .notification
                )
                _ = try progressionService.record(result)
                homeViewModel.load()
                try await reminderManager.refreshSchedule()

            case NotificationConstants.Action.snooze:
                try await reminderManager.scheduleSnooze()

            case NotificationConstants.Action.skip:
                break

            default:
                break
            }
        } catch {
            homeViewModel.errorMessage = error.localizedDescription
        }
    }

    private static func makeDependencies(inMemory: Bool) throws -> Dependencies {
        let persistence = try PersistenceController(inMemory: inMemory)
        try PersistenceBootstrapper(context: persistence.viewContext).prepareDefaults()
        let hydrationTracker = HydrationTrackingService(context: persistence.viewContext)
        let settingsService = AppSettingsService(
            context: persistence.viewContext,
            hydrationTracker: hydrationTracker
        )
        let snapshot = try settingsService.snapshot()
        let progressionService = PetProgressionService(context: persistence.viewContext)
        let reminderManager = ReminderManager(
            context: persistence.viewContext,
            hydrationTracker: hydrationTracker
        )
        let homeViewModel = HomeViewModel(
            hydrationTracker: hydrationTracker,
            haptics: HapticClient(),
            reminderRefresher: reminderManager,
            petProfileProvider: settingsService,
            progressionService: progressionService
        )

        return Dependencies(
            persistence: persistence,
            hydrationTracker: hydrationTracker,
            settingsService: settingsService,
            progressionService: progressionService,
            reminderManager: reminderManager,
            homeViewModel: homeViewModel,
            reminderViewModel: ReminderViewModel(manager: reminderManager),
            onboardingViewModel: OnboardingViewModel(
                settingsService: settingsService,
                reminderManager: reminderManager,
                initial: snapshot
            ),
            settingsViewModel: SettingsViewModel(
                settingsService: settingsService,
                reminderManager: reminderManager
            ),
            snapshot: snapshot
        )
    }
}
