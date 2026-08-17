import SwiftUI

struct ReminderSettingsView: View {
    @ObservedObject var viewModel: ReminderViewModel

    @Environment(\.dismiss) private var dismiss
    private let weekdays = [2, 3, 4, 5, 6, 7, 1]
    private let calendar = Calendar.autoupdatingCurrent

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Hydration reminders", isOn: $viewModel.isEnabled)

                    LabeledContent("Permission", value: viewModel.authorizationDescription)
                        .foregroundStyle(
                            viewModel.authorizationState == .denied ? .red : .secondary
                        )
                } footer: {
                    Text("Reminders stop for the day as soon as you reach your goal.")
                }

                Section("Schedule") {
                    Stepper(
                        "Every \(viewModel.intervalMinutes) minutes",
                        value: $viewModel.intervalMinutes,
                        in: 30...240,
                        step: 15
                    )

                    DatePicker(
                        "Start",
                        selection: $viewModel.startTime,
                        displayedComponents: .hourAndMinute
                    )
                    DatePicker(
                        "End",
                        selection: $viewModel.endTime,
                        displayedComponents: .hourAndMinute
                    )

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Active days")
                            .font(.subheadline)

                        HStack(spacing: 8) {
                            ForEach(weekdays, id: \.self) { weekday in
                                dayButton(weekday)
                            }
                        }
                    }

                    Toggle("Sound", isOn: $viewModel.soundEnabled)
                }
                .disabled(!viewModel.isEnabled)

                Section("Test") {
                    Button {
                        Task { await viewModel.sendTestNotification() }
                    } label: {
                        Label("Send Test in 10 Seconds", systemImage: "bell.badge")
                    }
                    .disabled(viewModel.isWorking)

                    if let statusMessage = viewModel.statusMessage {
                        Text(statusMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Reminders")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            if await viewModel.save() {
                                dismiss()
                            }
                        }
                    }
                    .disabled(viewModel.isWorking)
                }
            }
        }
        .task { await viewModel.load() }
        .interactiveDismissDisabled(viewModel.isWorking)
        .alert(
            "Reminder Problem",
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

    private func dayButton(_ weekday: Int) -> some View {
        let isActive = viewModel.isWeekdayActive(weekday)
        let fullName = calendar.weekdaySymbols[weekday - 1]
        let shortName = String(fullName.prefix(1))

        return Button {
            viewModel.toggleWeekday(weekday)
        } label: {
            Text(shortName)
                .font(.caption.bold())
                .frame(maxWidth: .infinity)
                .frame(height: 34)
                .foregroundStyle(isActive ? .white : .primary)
                .background(isActive ? Color.blue : Color.secondary.opacity(0.12), in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(fullName)
        .accessibilityValue(isActive ? "On" : "Off")
    }
}
