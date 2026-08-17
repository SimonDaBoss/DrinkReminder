import SwiftUI

struct OnboardingView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    let onComplete: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.89, green: 0.97, blue: 1),
                    Color(red: 0.95, green: 0.93, blue: 1),
                    Color(.systemBackground)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 18) {
                progressHeader

                ScrollView {
                    stepContent
                        .frame(maxWidth: 560)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 8)
                }
                .scrollIndicators(.hidden)

                controls
                    .padding(.horizontal, 24)
                    .padding(.bottom, 12)
            }
        }
        .animation(
            reduceMotion ? nil : .easeInOut(duration: 0.25),
            value: viewModel.step
        )
        .alert(
            "Couldn’t Finish Setup",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "Please try again.")
        }
    }

    private var progressHeader: some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: "drop.fill")
                    .foregroundStyle(.blue)
                Text("Water Pet")
                    .font(.headline)
                Spacer()
                Text("\(viewModel.step + 1) of \(OnboardingViewModel.finalStep + 1)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            ProgressView(
                value: Double(viewModel.step + 1),
                total: Double(OnboardingViewModel.finalStep + 1)
            )
            .tint(.blue)
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
    }

    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.step {
        case 0: welcomeStep
        case 1: goalStep
        case 2: containerStep
        case 3: reminderStep
        default: petStep
        }
    }

    private var welcomeStep: some View {
        setupCard {
            Image(systemName: "drop.circle.fill")
                .font(.system(size: 92))
                .symbolRenderingMode(.palette)
                .foregroundStyle(.white, .blue)

            title("Meet your new hydration buddy", subtitle: "A tiny pet makes remembering water feel a little more human. Setup takes less than a minute.")

            VStack(alignment: .leading, spacing: 8) {
                Text("What should we call you? (optional)")
                    .font(.subheadline.weight(.semibold))
                TextField("Your name", text: $viewModel.displayName)
                    .textContentType(.name)
                    .padding(14)
                    .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    private var goalStep: some View {
        setupCard {
            Image(systemName: "target")
                .font(.system(size: 62))
                .foregroundStyle(.blue)

            title("Choose a comfortable goal", subtitle: "You can change this anytime. Water Pet tracks estimates, so it doesn’t need to be laboratory-perfect.")

            Picker("Volume unit", selection: Binding(
                get: { viewModel.displayUnit },
                set: { viewModel.setDisplayUnit($0) }
            )) {
                Text("Ounces").tag(VolumeUnit.ounces)
                Text("Milliliters").tag(VolumeUnit.milliliters)
            }
            .pickerStyle(.segmented)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                TextField("Goal", value: $viewModel.goalDisplayValue, format: .number.precision(.fractionLength(0)))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 46, weight: .bold, design: .rounded))
                    .frame(maxWidth: 170)
                Text(viewModel.displayUnit.symbol)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                ForEach(viewModel.goalSuggestions, id: \.self) { suggestion in
                    Button("\(suggestion.formatted(.number.precision(.fractionLength(0)))) \(viewModel.displayUnit.symbol)") {
                        viewModel.goalDisplayValue = suggestion
                    }
                    .buttonStyle(.bordered)
                    .tint(viewModel.goalDisplayValue == suggestion ? .blue : .secondary)
                }
            }
        }
    }

    private var containerStep: some View {
        setupCard {
            Image(systemName: "waterbottle.fill")
                .font(.system(size: 62))
                .foregroundStyle(.cyan)

            title("What do you usually drink from?", subtitle: "Pick the closest match. Later, logging can be as simple as “I drank my bottle” or “about half.”")

            VStack(spacing: 10) {
                ForEach(viewModel.presets) { preset in
                    Button {
                        viewModel.selectedPresetID = preset.id
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: preset.symbolName)
                                .font(.title2)
                                .foregroundStyle(.blue)
                                .frame(width: 34)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(preset.name)
                                    .font(.headline)
                                Text(VolumeDisplayFormatter.string(
                                    milliliters: preset.volumeML,
                                    unit: viewModel.displayUnit
                                ))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: viewModel.selectedPresetID == preset.id ? "checkmark.circle.fill" : "circle")
                                .font(.title2)
                                .foregroundStyle(viewModel.selectedPresetID == preset.id ? .blue : .secondary)
                        }
                        .padding(14)
                        .background(
                            viewModel.selectedPresetID == preset.id ? Color.blue.opacity(0.1) : Color.secondary.opacity(0.07),
                            in: RoundedRectangle(cornerRadius: 16)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var reminderStep: some View {
        setupCard {
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 62))
                .foregroundStyle(.indigo)

            title("Want a gentle nudge?", subtitle: "Permission is requested only when you continue with reminders on. You can test and fine-tune them later in Settings.")

            Toggle("Hydration reminders", isOn: $viewModel.remindersEnabled)
                .font(.headline)

            VStack(spacing: 14) {
                Stepper(
                    "Every \(viewModel.reminderIntervalMinutes) minutes",
                    value: $viewModel.reminderIntervalMinutes,
                    in: 30...240,
                    step: 15
                )
                DatePicker("Start", selection: $viewModel.reminderStartTime, displayedComponents: .hourAndMinute)
                DatePicker("End", selection: $viewModel.reminderEndTime, displayedComponents: .hourAndMinute)
            }
            .disabled(!viewModel.remindersEnabled)
            .opacity(viewModel.remindersEnabled ? 1 : 0.45)
        }
    }

    private var petStep: some View {
        setupCard {
            PetCharacterView(mood: .happy, species: viewModel.petSpecies)
                .frame(height: 145)

            title("Choose your buddy", subtitle: "Your pet reacts to today’s hydration. Progression and unlocks arrive in a later phase.")

            HStack(spacing: 10) {
                ForEach(PetSpecies.allCases, id: \.self) { species in
                    Button {
                        viewModel.petSpecies = species
                    } label: {
                        VStack(spacing: 7) {
                            Image(systemName: speciesSymbol(species))
                                .font(.title2)
                            Text(speciesName(species))
                                .font(.caption.weight(.semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .foregroundStyle(viewModel.petSpecies == species ? .white : .primary)
                        .background(
                            viewModel.petSpecies == species ? Color.blue : Color.secondary.opacity(0.09),
                            in: RoundedRectangle(cornerRadius: 15)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            TextField("Pet name", text: $viewModel.petName)
                .padding(14)
                .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private var controls: some View {
        HStack(spacing: 12) {
            if viewModel.canGoBack {
                Button("Back") { viewModel.goBack() }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
            }

            Button {
                if viewModel.isFinalStep {
                    Task {
                        if await viewModel.finish() {
                            onComplete()
                        }
                    }
                } else {
                    viewModel.goForward()
                }
            } label: {
                HStack {
                    if viewModel.isWorking {
                        ProgressView().tint(.white)
                    }
                    Text(viewModel.isFinalStep ? "Start caring for my pet" : "Continue")
                    if !viewModel.isFinalStep {
                        Image(systemName: "arrow.right")
                    }
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(viewModel.isWorking)
        }
        .frame(maxWidth: 560)
    }

    private func setupCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 22, content: content)
            .padding(24)
            .frame(maxWidth: .infinity)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .stroke(.white.opacity(0.55), lineWidth: 1)
            }
    }

    private func title(_ title: String, subtitle: String) -> some View {
        VStack(spacing: 9) {
            Text(title)
                .font(.system(.title, design: .rounded, weight: .bold))
                .multilineTextAlignment(.center)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private func speciesName(_ species: PetSpecies) -> String {
        switch species {
        case .axolotl: return "Axolotl"
        case .otter: return "Otter"
        case .droplet: return "Droplet"
        }
    }

    private func speciesSymbol(_ species: PetSpecies) -> String {
        switch species {
        case .axolotl: return "water.waves"
        case .otter: return "pawprint.fill"
        case .droplet: return "drop.fill"
        }
    }
}
