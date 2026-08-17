import SwiftUI

struct PetCharacterView: View {
    let mood: PetMood
    var species: PetSpecies = .axolotl
    var evolutionStage: EvolutionStage = .baby

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isFloating = false

    var body: some View {
        ZStack {
            if mood == .celebrating || mood == .happy {
                celebrationDrops
                    .opacity(mood == .happy ? 0.72 : 1)
                    .transition(.scale.combined(with: .opacity))
            }

            headDetails
            bodyShape
            stageAccent

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
        .scaleEffect((mood == .celebrating ? 1.08 : 1) * stageScale)
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
                        colors: bodyColors,
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
        let isJoyful = mood == .happy || mood == .celebrating
        return ZStack(alignment: .topLeading) {
            Circle()
                .fill(Color(red: 0.08, green: 0.17, blue: 0.28))
                .frame(width: 17, height: isJoyful ? 7 : 20)

            if !isJoyful {
                Circle()
                    .fill(.white.opacity(0.9))
                    .frame(width: 6, height: 6)
                    .offset(x: 3, y: 3)
            }
        }
    }

    @ViewBuilder
    private var mouth: some View {
        if mood == .celebrating {
            Ellipse()
                .fill(Color(red: 0.08, green: 0.17, blue: 0.28))
                .frame(width: 24, height: 22)
        } else if mood == .happy || mood == .excited {
            PetSmileShape()
                .stroke(
                    Color(red: 0.08, green: 0.17, blue: 0.28),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .frame(width: 32, height: 17)
        } else if mood == .drinking {
            Circle()
                .fill(Color(red: 0.08, green: 0.17, blue: 0.28))
                .frame(width: 10, height: 10)
        } else {
            Capsule()
                .fill(Color(red: 0.08, green: 0.17, blue: 0.28))
                .frame(width: 30, height: 6)
        }
    }

    private var gills: some View {
        HStack(spacing: 100) {
            gillCluster.rotationEffect(.degrees(-12))
            gillCluster.rotationEffect(.degrees(12)).scaleEffect(x: -1)
        }
        .offset(y: -8)
    }

    @ViewBuilder
    private var headDetails: some View {
        switch species {
        case .axolotl:
            gills
        case .otter:
            HStack(spacing: 76) {
                Circle().frame(width: 34, height: 34)
                Circle().frame(width: 34, height: 34)
            }
            .foregroundStyle(Color(red: 0.45, green: 0.29, blue: 0.2))
            .offset(y: -42)
        case .droplet:
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(red: 0.36, green: 0.72, blue: 1))
                .frame(width: 42, height: 42)
                .rotationEffect(.degrees(45))
                .offset(y: -55)
        }
    }

    private var bodyColors: [Color] {
        switch species {
        case .axolotl:
            return [Color(red: 0.48, green: 0.88, blue: 0.96), .cyan]
        case .otter:
            return [Color(red: 0.72, green: 0.51, blue: 0.34), Color(red: 0.48, green: 0.3, blue: 0.2)]
        case .droplet:
            return [Color(red: 0.45, green: 0.85, blue: 1), Color(red: 0.25, green: 0.55, blue: 1)]
        }
    }

    @ViewBuilder
    private var stageAccent: some View {
        switch evolutionStage {
        case .baby:
            EmptyView()
        case .growing:
            Image(systemName: "leaf.fill")
                .foregroundStyle(.green)
                .offset(x: 42, y: -49)
        case .evolved:
            Image(systemName: "star.fill")
                .foregroundStyle(.yellow)
                .offset(x: 44, y: -51)
        case .advanced:
            Image(systemName: "crown.fill")
                .font(.title2)
                .foregroundStyle(.yellow)
                .offset(y: -67)
        }
    }

    private var stageScale: CGFloat {
        switch evolutionStage {
        case .baby: return 0.94
        case .growing: return 0.98
        case .evolved: return 1.02
        case .advanced: return 1.05
        }
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

private struct PetSmileShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY),
            control: CGPoint(x: rect.midX, y: rect.maxY)
        )
        return path
    }
}
