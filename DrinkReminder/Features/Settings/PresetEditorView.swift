import SwiftUI

struct PresetEditorView: View {
    let preset: ContainerPreset?
    let unit: VolumeUnit
    let onSave: (UUID?, String, Double, String) -> Bool

    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var amount: Double
    @State private var symbolName: String

    private let symbols = ["drop", "cup.and.saucer", "waterbottle", "waterbottle.fill"]

    init(
        preset: ContainerPreset?,
        unit: VolumeUnit,
        onSave: @escaping (UUID?, String, Double, String) -> Bool
    ) {
        self.preset = preset
        self.unit = unit
        self.onSave = onSave
        _name = State(initialValue: preset?.name ?? "")
        _amount = State(initialValue: preset.map {
            VolumeConverter.displayValue(fromMilliliters: $0.volumeML, unit: unit)
        } ?? (unit == .ounces ? 16 : 500))
        _symbolName = State(initialValue: preset?.symbolName ?? "waterbottle")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Container") {
                    TextField("Name", text: $name)

                    HStack {
                        Text("Amount")
                        Spacer()
                        TextField(
                            "Amount",
                            value: $amount,
                            format: .number.precision(.fractionLength(0...1))
                        )
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 110)
                        Text(unit.symbol)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Icon") {
                    HStack(spacing: 16) {
                        ForEach(symbols, id: \.self) { symbol in
                            Button {
                                symbolName = symbol
                            } label: {
                                Image(systemName: symbol)
                                    .font(.title2)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 11)
                                    .foregroundStyle(symbolName == symbol ? .white : .blue)
                                    .background(
                                        symbolName == symbol ? Color.blue : Color.blue.opacity(0.1),
                                        in: RoundedRectangle(cornerRadius: 12)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle(preset == nil ? "New Container" : "Edit Container")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if onSave(preset?.id, name, amount, symbolName) {
                            dismiss()
                        }
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
