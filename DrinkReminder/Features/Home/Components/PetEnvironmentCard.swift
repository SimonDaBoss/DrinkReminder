import SwiftUI

struct PetEnvironmentCard: View {
    let progress: Double
    let mood: PetMood
    let species: PetSpecies
    let evolutionStage: EvolutionStage
    let progressPercentText: String

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(environmentGradient)

            Circle()
                .fill(.white.opacity(0.22))
                .frame(width: 210, height: 210)
                .blur(radius: 2)
                .offset(x: 100, y: -110)

            environmentDetails

            VStack(spacing: 4) {
                ZStack {
                    HydrationProgressRing(progress: progress)
                        .frame(width: 210, height: 210)

                    PetCharacterView(
                        mood: mood,
                        species: species,
                        evolutionStage: evolutionStage
                    )
                }

                Text(progressPercentText)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .contentTransition(.numericText())
            }
            .padding(.vertical, 24)
        }
        .frame(minHeight: 310)
        .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .stroke(.white.opacity(0.45), lineWidth: 1)
        }
        .shadow(color: .blue.opacity(0.12), radius: 24, y: 12)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Water Pet hydration progress")
        .accessibilityValue(progressPercentText)
    }

    private var environmentGradient: LinearGradient {
        let colors: [Color]
        switch progress {
        case ..<0.25:
            colors = [Color(red: 0.92, green: 0.91, blue: 0.82), Color(red: 0.76, green: 0.89, blue: 0.91)]
        case ..<0.5:
            colors = [Color(red: 0.74, green: 0.94, blue: 0.86), Color(red: 0.65, green: 0.87, blue: 0.96)]
        case ..<0.75:
            colors = [Color(red: 0.58, green: 0.91, blue: 0.88), Color(red: 0.48, green: 0.78, blue: 0.98)]
        case ..<1:
            colors = [Color(red: 0.48, green: 0.86, blue: 0.94), Color(red: 0.47, green: 0.67, blue: 0.98)]
        default:
            colors = [Color(red: 0.51, green: 0.91, blue: 0.82), Color(red: 0.48, green: 0.68, blue: 1)]
        }
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    @ViewBuilder
    private var environmentDetails: some View {
        if progress >= 0.25 {
            HStack(alignment: .bottom) {
                plant.scaleEffect(progress >= 0.5 ? 1 : 0.72, anchor: .bottom)
                Spacer()
                plant.scaleEffect(progress >= 0.75 ? 1.12 : 0.78, anchor: .bottom)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 18)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .transition(.scale(scale: 0.7, anchor: .bottom).combined(with: .opacity))
        }
    }

    private var plant: some View {
        ZStack(alignment: .bottom) {
            Capsule()
                .fill(.green.opacity(0.72))
                .frame(width: 8, height: 52)

            HStack(spacing: 3) {
                Ellipse().rotationEffect(.degrees(34))
                Ellipse().rotationEffect(.degrees(-34))
            }
            .foregroundStyle(.green)
            .frame(width: 43, height: 28)
            .offset(y: -24)
        }
        .frame(width: 52, height: 65)
    }
}
