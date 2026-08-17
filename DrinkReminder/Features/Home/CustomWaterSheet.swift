import SwiftUI

struct CustomWaterSheet: View {
    let unit: VolumeUnit
    let onSave: (Double) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var amount: Double
    @FocusState private var isAmountFocused: Bool

    init(unit: VolumeUnit, onSave: @escaping (Double) -> Void) {
        self.unit = unit
        self.onSave = onSave
        _amount = State(initialValue: unit == .ounces ? 12 : 350)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 26) {
                ZStack {
                    Circle()
                        .fill(.blue.opacity(0.12))
                        .frame(width: 82, height: 82)
                    Image(systemName: "drop.fill")
                        .font(.system(size: 38))
                        .foregroundStyle(.blue)
                }
                .accessibilityHidden(true)

                VStack(spacing: 8) {
                    Text("How much water?")
                        .font(.title2.bold())
                    Text("Enter the amount you just drank. An estimate is totally fine.")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    TextField("Amount", value: $amount, format: .number.precision(.fractionLength(0...1)))
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.trailing)
                        .textFieldStyle(.plain)
                        .keyboardType(.decimalPad)
                        .focused($isAmountFocused)
                        .frame(maxWidth: 170)
                        .accessibilityLabel("Water amount")

                    Text(unit.symbol)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 18)
                .padding(.horizontal, 24)
                .background(.quaternary.opacity(0.55), in: RoundedRectangle(cornerRadius: 22, style: .continuous))

                Button {
                    onSave(amount)
                    dismiss()
                } label: {
                    Label("Add Water", systemImage: "plus")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.roundedRectangle(radius: 20))
                .disabled(!amount.isFinite || amount <= 0)

                Spacer(minLength: 0)
            }
            .padding(24)
            .navigationTitle("Custom Amount")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { isAmountFocused = false }
                }
            }
        }
        .presentationDetents([.medium])
        .onAppear { isAmountFocused = true }
    }
}
