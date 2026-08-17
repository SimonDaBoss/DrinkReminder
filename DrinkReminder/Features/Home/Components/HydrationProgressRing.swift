import SwiftUI

struct HydrationProgressRing: View {
    let progress: Double

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Circle()
                .stroke(.white.opacity(0.42), lineWidth: 13)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [.cyan, .blue, .indigo, .cyan],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 13, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: .blue.opacity(0.25), radius: 8, y: 3)
                .animation(
                    reduceMotion ? nil : .spring(response: 0.55, dampingFraction: 0.8),
                    value: progress
                )
        }
        .accessibilityHidden(true)
    }
}
