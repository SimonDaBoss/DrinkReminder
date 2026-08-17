import Combine
import Foundation

@MainActor
final class AppEnvironment: ObservableObject {
    let persistence: PersistenceController
    let hydrationTracker: HydrationTrackingService
    let homeViewModel: HomeViewModel

    @Published private(set) var startupError: String?

    init(inMemory: Bool = false) {
        do {
            let persistence = try PersistenceController(inMemory: inMemory)
            try PersistenceBootstrapper(context: persistence.viewContext).prepareDefaults()
            self.persistence = persistence
            let hydrationTracker = HydrationTrackingService(context: persistence.viewContext)
            self.hydrationTracker = hydrationTracker
            self.homeViewModel = HomeViewModel(hydrationTracker: hydrationTracker)
        } catch {
            // Keeping an in-memory store available lets the app explain a disk failure
            // instead of terminating before it can present UI.
            let fallback = try! PersistenceController(inMemory: true)
            try? PersistenceBootstrapper(context: fallback.viewContext).prepareDefaults()
            self.persistence = fallback
            let hydrationTracker = HydrationTrackingService(context: fallback.viewContext)
            self.hydrationTracker = hydrationTracker
            self.homeViewModel = HomeViewModel(hydrationTracker: hydrationTracker)
            self.startupError = error.localizedDescription
        }
    }
}
