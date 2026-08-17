import Foundation

#if canImport(UIKit)
import UIKit
#endif

@MainActor
protocol HapticProviding {
    func waterLogged(reachedGoal: Bool)
    func undoCompleted()
}

@MainActor
final class HapticClient: HapticProviding {
    func waterLogged(reachedGoal: Bool) {
        #if canImport(UIKit)
        if reachedGoal {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } else {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.8)
        }
        #endif
    }

    func undoCompleted() {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }
}
