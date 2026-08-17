import SwiftUI

struct PetCharacterView: View {
    let mood: PetMood

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isFloating = false

    var body: some View {
        ZStack {
            if mood == .celebrating {
                celebrationDrops
                    .transition(.scale.combined(with: .opacity))
            }

            gills
            bodyShape

            if mood == .drinking {
                Image(systemName: "drop.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
                    .offset(x: 49, y: 39)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(width: 170, height: 150)
        .offset(y: reduceMotion ? 0 : (isFloating ? -4 : 4))
        .scaleEffect(mood == .celebrating ? 1.08 : 1)
        .animation(
            reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.58),
            value: mood
        )
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                isFloating = true
            }
        }
        .accessibilityHidden(true)
    }

    private var bodyShape: some View {
        ZStack {
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.48, green: 0.88, blue: 0.96), .cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 126, height: 112)
                .shadow(color: .blue.opacity(0.2), radius: 12, y: 8)

            HStack(spacing: 37) {
                eye
                eye
            }
            .offset(y: -12)

            mouth
                .offset(y: 23)

            Circle()
                .fill(.pink.opacity(0.42))
                .frame(width: 19, height: 11)
                .offset(x: -39, y: 18)

            Circle()
                .fill(.pink.opacity(0.42))
                .frame(width: 19, height: 11)
                .offset(x: 39, y: 18)
        }
    }

    private var eye: some View {
        ZStack(alignment: .topLeading) {
            Circle()
                .fill(Color(red: 0.08, green: 0.17, blue: 0.28))
                .frame(width: 17, height: mood == .happy || mood == .celebrating ? 7 : 20)

            if mood != .happy && mood != .celebrating {
                Circle()
                    .fill(.white.opacity(0.9))
                    .frame(width: 6, height: 6)
                    .offset(x: 3, y: 3)
            }
        }
    }

    private var mouth: some View {
        Capsule()
            .fill(Color(red: 0.08, green: 0.17, blue: 0.28))
            .frame(
                width: mood == .celebrating ? 24 : 30,
                height: mood == .celebrating ? 22 : 6
            )
    }

    private var gills: some View {
        HStack(spacing: 100) {
            gillCluster.rotationEffect(.degrees(-12))
            gillCluster.rotationEffect(.degrees(12)).scaleEffect(x: -1)
        }
        .offset(y: -8)
    }

    private var gillCluster: some View {
        VStack(spacing: -3) {
            Capsule().frame(width: 43, height: 13).rotationEffect(.degrees(-24))
            Capsule().frame(width: 48, height: 13)
            Capsule().frame(width: 43, height: 13).rotationEffect(.degrees(24))
        }
        .foregroundStyle(Color(red: 1, green: 0.55, blue: 0.67))
    }

    private var celebrationDrops: some View {
        ZStack {
            Image(systemName: "sparkles").offset(x: -68, y: -54)
            Image(systemName: "drop.fill").offset(x: 64, y: -60)
            Image(systemName: "star.fill").offset(x: 74, y: 49)
            Image(systemName: "sparkle").offset(x: -72, y: 51)
        }
        .font(.title3)
        .foregroundStyle(.yellow)
    }
}
