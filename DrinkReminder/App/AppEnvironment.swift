import Combine
import Foundation

@MainActor
final class AppEnvironment: ObservableObject {
    let persistence: PersistenceController
    let hydrationTracker: HydrationTrackingService
    let reminderManager: ReminderManager
    let homeViewModel: HomeViewModel
    let reminderViewModel: ReminderViewModel

    @Published private(set) var startupError: String?

    init(inMemory: Bool = false) {
        do {
            let persistence = try PersistenceController(inMemory: inMemory)
            try PersistenceBootstrapper(context: persistence.viewContext).prepareDefaults()
            self.persistence = persistence
            let hydrationTracker = HydrationTrackingService(context: persistence.viewContext)
            self.hydrationTracker = hydrationTracker
            let reminderManager = ReminderManager(
                context: persistence.viewContext,
                hydrationTracker: hydrationTracker
            )
            self.reminderManager = reminderManager
            self.homeViewModel = HomeViewModel(
                hydrationTracker: hydrationTracker,
                haptics: HapticClient(),
                reminderRefresher: reminderManager
            )
            self.reminderViewModel = ReminderViewModel(manager: reminderManager)
            reminderManager.registerNotificationCategories()
        } catch {
            // Keeping an in-memory store available lets the app explain a disk failure
            // instead of terminating before it can present UI.
            let fallback = try! PersistenceController(inMemory: true)
            try? PersistenceBootstrapper(context: fallback.viewContext).prepareDefaults()
            self.persistence = fallback
            let hydrationTracker = HydrationTrackingService(context: fallback.viewContext)
            self.hydrationTracker = hydrationTracker
            let reminderManager = ReminderManager(
                context: fallback.viewContext,
                hydrationTracker: hydrationTracker
            )
            self.reminderManager = reminderManager
            self.homeViewModel = HomeViewModel(
                hydrationTracker: hydrationTracker,
                haptics: HapticClient(),
                reminderRefresher: reminderManager
            )
            self.reminderViewModel = ReminderViewModel(manager: reminderManager)
            reminderManager.registerNotificationCategories()
            self.startupError = error.localizedDescription
        }
    }

    func handleNotificationAction(_ identifier: String) async {
        do {
            switch identifier {
            case NotificationConstants.Action.drank:
                let configuration = try hydrationTracker.configuration()
                _ = try hydrationTracker.logWater(
                    volumeML: configuration.defaultDrinkAmountML,
                    source: .notification
                )
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
}
