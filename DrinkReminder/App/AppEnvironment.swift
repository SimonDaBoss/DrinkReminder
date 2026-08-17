import Combine
import Foundation

@MainActor
final class AppEnvironment: ObservableObject {
    let persistence: PersistenceController
    let hydrationTracker: HydrationTrackingService

    @Published private(set) var startupError: String?

    init() {
        do {
            let persistence = try PersistenceController()
            try PersistenceBootstrapper(context: persistence.viewContext).prepareDefaults()
            self.persistence = persistence
            self.hydrationTracker = HydrationTrackingService(context: persistence.viewContext)
        } catch {
            // Keeping an in-memory store available lets the app explain a disk failure
            // instead of terminating before it can present UI.
            let fallback = try! PersistenceController(inMemory: true)
            self.persistence = fallback
            self.hydrationTracker = HydrationTrackingService(context: fallback.viewContext)
            self.startupError = error.localizedDescription
        }
    }
}
