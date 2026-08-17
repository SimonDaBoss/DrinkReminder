import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    @ObservedObject var reminderViewModel: ReminderViewModel
    let storageWarning: String?

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var isShowingCustomAmount = false
    @State private var isShowingReminders = false

    private var columns: [GridItem] {
        if dynamicTypeSize.isAccessibilitySize {
            return [GridItem(.flexible())]
        }
        return [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                background

                ScrollView {
                    VStack(spacing: 22) {
                        header

                        if let storageWarning {
                            storageWarningView(storageWarning)
                        }

                        PetEnvironmentCard(
                            progress: viewModel.progress,
                            mood: viewModel.petMood,
                            species: viewModel.petIdentity.species,
                            evolutionStage: viewModel.progression.pet.evolutionStage,
                            progressPercentText: viewModel.progressPercentText
                        )

                        hydrationSummary
                        ProgressionCard(progression: viewModel.progression)
                        quickAddSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 28)
                }
                .scrollIndicators(.hidden)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .safeAreaInset(edge: .bottom) {
            if let undoState = viewModel.undoState {
                undoBanner(undoState)
                    .padding(.horizontal, 18)
                    .padding(.bottom, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(
            reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.82),
            value: viewModel.undoState
        )
        .sheet(isPresented: $isShowingCustomAmount) {
            CustomWaterSheet(unit: viewModel.displayUnit) { amount in
                viewModel.logCustom(displayAmount: amount)
            }
        }
        .sheet(isPresented: $isShowingReminders) {
            ReminderSettingsView(viewModel: reminderViewModel)
        }
        .alert(
            "Couldn’t Update Hydration",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "Please try again.")
        }
        .task {
            viewModel.load()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                viewModel.load()
            }
        }
    }

    private var background: some View {
        LinearGradient(
            colors: colorScheme == .dark
                ? [
                    Color(red: 0.05, green: 0.11, blue: 0.18),
                    Color(red: 0.09, green: 0.09, blue: 0.18),
                    Color(.systemBackground)
                ]
                : [
                    Color(red: 0.94, green: 0.98, blue: 1),
                    Color(red: 0.96, green: 0.97, blue: 1),
                    Color(.systemBackground)
                ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("TODAY")
                    .font(.caption.weight(.bold))
                    .tracking(1.4)
                    .foregroundStyle(.secondary)
                Text("Keep \(viewModel.petIdentity.name) happy")
                    .font(.system(.title, design: .rounded, weight: .bold))
            }

            Spacer()

            Button {
                isShowingReminders = true
            } label: {
                Image(systemName: "bell.circle.fill")
                    .font(.system(size: 38))
                    .foregroundStyle(.blue)
            }
            .accessibilityLabel("Hydration reminder settings")
        }
    }

    private var hydrationSummary: some View {
        VStack(spacing: 9) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(viewModel.consumedText)
                    .font(.system(.title, design: .rounded, weight: .bold))
                Text("of \(viewModel.goalText)")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Today, \(viewModel.consumedText) of \(viewModel.goalText)")

            Text(viewModel.encouragementText)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var quickAddSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("What did you drink?")
                .font(.title3.bold())

            Button {
                viewModel.logPreferredAmount()
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.22))
                            .frame(width: 44, height: 44)
                        Image(systemName: "plus")
                            .font(.headline.bold())
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("I drank my \(viewModel.preferredContainerName)")
                            .font(.headline)
                        Text("About \(viewModel.preferredAmountText)")
                            .font(.caption)
                            .opacity(0.82)
                    }

                    Spacer()
                    Image(systemName: "drop.fill")
                }
                .foregroundStyle(.white)
                .padding(16)
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(colors: [.blue, .indigo], startPoint: .leading, endPoint: .trailing),
                    in: RoundedRectangle(cornerRadius: 22, style: .continuous)
                )
                .shadow(color: .blue.opacity(0.24), radius: 14, y: 8)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.defaultDrinkAmountML <= 0)
            .accessibilityLabel("I drank my \(viewModel.preferredContainerName), about \(viewModel.preferredAmountText)")

            HStack(spacing: 12) {
                estimateButton("A few sips", fraction: 0.25, systemImage: "drop")
                estimateButton("About half", fraction: 0.5, systemImage: "circle.lefthalf.filled")
            }

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(viewModel.presets.filter { !$0.isDefault }) { preset in
                    QuickAddPresetButton(preset: preset, unit: viewModel.displayUnit) {
                        viewModel.log(preset: preset)
                    }
                }

                Button {
                    isShowingCustomAmount = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.title3)
                            .foregroundStyle(.purple)
                            .frame(width: 30)

                        Text("Different")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Spacer(minLength: 0)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, minHeight: 70)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add a custom water amount")
            }
        }
    }

    private func estimateButton(
        _ title: String,
        fraction: Double,
        systemImage: String
    ) -> some View {
        Button {
            viewModel.logEstimatedFraction(fraction)
        } label: {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(.thinMaterial, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityHint("Uses your usual \(viewModel.preferredContainerName) as an estimate")
    }

    private func undoBanner(_ undoState: HomeViewModel.UndoState) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)

            Text("Added \(VolumeDisplayFormatter.string(milliliters: undoState.amountML, unit: viewModel.displayUnit))")
                .font(.subheadline.weight(.semibold))

            if viewModel.lastXPGain > 0 {
                Text("+\(viewModel.lastXPGain) XP")
                    .font(.caption.bold())
                    .foregroundStyle(.purple)
            }

            Spacer()

            Button("Undo") {
                viewModel.undoLastLog()
            }
            .font(.subheadline.bold())

            Button {
                viewModel.dismissUndo()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption.bold())
            }
            .accessibilityLabel("Dismiss")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .background(.regularMaterial, in: Capsule())
        .overlay { Capsule().stroke(.white.opacity(0.4), lineWidth: 1) }
        .shadow(color: .black.opacity(0.12), radius: 16, y: 8)
    }

    private func storageWarningView(_ message: String) -> some View {
        Label {
            Text("Using temporary storage: \(message)")
                .font(.footnote)
        } icon: {
            Image(systemName: "exclamationmark.triangle.fill")
        }
        .foregroundStyle(.orange)
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
    }
}
