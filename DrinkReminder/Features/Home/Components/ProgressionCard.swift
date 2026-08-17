import SwiftUI

struct ProgressionCard: View {
    let progression: ProgressionSnapshot

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                metric(
                    icon: "flame.fill",
                    color: .orange,
                    value: "\(progression.streak.current)",
                    label: progression.streak.current == 1 ? "day streak" : "day streak"
                )

                Divider().frame(height: 40)

                metric(
                    icon: "star.fill",
                    color: .yellow,
                    value: "Level \(progression.pet.level)",
                    label: stageName
                )

                Divider().frame(height: 40)

                metric(
                    icon: "trophy.fill",
                    color: .indigo,
                    value: "\(progression.streak.successfulDays)",
                    label: "goals met"
                )
            }

            VStack(spacing: 6) {
                HStack {
                    Label(
                        "Best streak: \(progression.streak.longest) days",
                        systemImage: "medal.fill"
                    )
                    Spacer()
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

                HStack {
                    Text("\(progression.pet.xpIntoLevel) / \(progression.pet.xpNeededForNextLevel) XP")
                    Spacer()
                    Text("\(progression.pet.totalXP) total")
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

                ProgressView(value: progression.pet.levelProgress)
                    .tint(.purple)
            }
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "Level \(progression.pet.level), \(progression.pet.totalXP) total XP, "
                + "\(progression.streak.current) day streak, \(progression.streak.successfulDays) goals met"
        )
    }

    private func metric(
        icon: String,
        color: Color,
        value: String,
        label: String
    ) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(value)
                .font(.subheadline.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }

    private var stageName: String {
        switch progression.pet.evolutionStage {
        case .baby: return "Baby"
        case .growing: return "Growing"
        case .evolved: return "Evolved"
        case .advanced: return "Advanced"
        }
    }
}
