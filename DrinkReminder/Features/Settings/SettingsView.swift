import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @ObservedObject var reminderViewModel: ReminderViewModel
    let onSettingsChanged: () -> Void
    let onContainerChanged: () -> Void
    let onReset: () -> Void

    @State private var isShowingReminders = false
    @State private var isShowingPrivacy = false
    @State private var isConfirmingReset = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Profile") {
                    TextField("Your name (optional)", text: $viewModel.displayName)
                        .textContentType(.name)
                }

                Section {
                    Picker("Units", selection: Binding(
                        get: { viewModel.displayUnit },
                        set: { viewModel.setDisplayUnit($0) }
                    )) {
                        Text("Ounces").tag(VolumeUnit.ounces)
                        Text("Milliliters").tag(VolumeUnit.milliliters)
                    }

                    HStack {
                        Text("Daily goal")
                        Spacer()
                        TextField(
                            "Goal",
                            value: $viewModel.dailyGoalDisplayValue,
                            format: .number.precision(.fractionLength(0))
                        )
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 100)
                        Text(viewModel.displayUnit.symbol)
                            .foregroundStyle(.secondary)
                    }

                    NavigationLink {
                        ContainerPresetsView(viewModel: viewModel) {
                            onContainerChanged()
                        }
                    } label: {
                        LabeledContent(
                            "Usual container",
                            value: viewModel.presets.first(where: { $0.id == viewModel.defaultPresetID })?.name ?? "Choose"
                        )
                    }
                } header: {
                    Text("Hydration")
                } footer: {
                    Text("Goal changes apply to today and future days. Past daily goals stay unchanged.")
                }

                Section("Reminders") {
                    Button {
                        isShowingReminders = true
                    } label: {
                        Label("Schedule & test notifications", systemImage: "bell.badge")
                    }
                }

                Section("Your Pet") {
                    TextField("Pet name", text: $viewModel.petName)

                    Picker("Species", selection: $viewModel.petSpecies) {
                        Label("Axolotl", systemImage: "water.waves").tag(PetSpecies.axolotl)
                        Label("Otter", systemImage: "pawprint.fill").tag(PetSpecies.otter)
                        Label("Droplet", systemImage: "drop.fill").tag(PetSpecies.droplet)
                    }
                }

                Section("Experience") {
                    Picker("Appearance", selection: $viewModel.appearance) {
                        Text("System").tag(AppAppearance.system)
                        Text("Light").tag(AppAppearance.light)
                        Text("Dark").tag(AppAppearance.dark)
                    }
                    Toggle("Haptic feedback", isOn: $viewModel.hapticsEnabled)
                }

                Section("Privacy & Data") {
                    Button("Privacy") { isShowingPrivacy = true }

                    Button("Reset All Data", role: .destructive) {
                        isConfirmingReset = true
                    }
                }

                if let statusMessage = viewModel.statusMessage {
                    Section {
                        Label(statusMessage, systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if viewModel.save() {
                            onSettingsChanged()
                        }
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .task { viewModel.load() }
        .sheet(isPresented: $isShowingReminders) {
            ReminderSettingsView(viewModel: reminderViewModel)
        }
        .sheet(isPresented: $isShowingPrivacy) {
            PrivacyView()
        }
        .confirmationDialog(
            "Reset Water Pet?",
            isPresented: $isConfirmingReset,
            titleVisibility: .visible
        ) {
            Button("Reset All Data", role: .destructive) {
                Task {
                    if await viewModel.resetAllData() {
                        onReset()
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently removes hydration logs, settings, and pet progress from this device, then returns to setup.")
        }
        .alert(
            "Settings Problem",
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
}
