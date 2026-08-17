import SwiftUI

struct ContainerPresetsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    let onChanged: () -> Void

    @State private var editorPreset: ContainerPreset?
    @State private var isShowingEditor = false

    var body: some View {
        List {
            Section {
                ForEach(viewModel.presets) { preset in
                    Button {
                        viewModel.setDefaultContainer(id: preset.id)
                        onChanged()
                    } label: {
                        HStack(spacing: 13) {
                            Image(systemName: preset.symbolName)
                                .foregroundStyle(.blue)
                                .frame(width: 28)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(preset.name)
                                    .foregroundStyle(.primary)
                                Text(VolumeDisplayFormatter.string(
                                    milliliters: preset.volumeML,
                                    unit: viewModel.displayUnit
                                ))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if preset.id == viewModel.defaultPresetID {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.blue)
                                    .accessibilityLabel("Usual container")
                            }
                        }
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            viewModel.deleteContainer(id: preset.id)
                            onChanged()
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }

                        Button {
                            editorPreset = preset
                            isShowingEditor = true
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
                }
            } footer: {
                Text("Tap a container to make it your usual quick-add amount. Swipe to edit or delete it.")
            }
        }
        .navigationTitle("Containers")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    editorPreset = nil
                    isShowingEditor = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add container")
            }
        }
        .sheet(isPresented: $isShowingEditor) {
            PresetEditorView(
                preset: editorPreset,
                unit: viewModel.displayUnit
            ) { id, name, amount, symbol in
                let saved = viewModel.saveContainer(
                    id: id,
                    name: name,
                    displayAmount: amount,
                    symbolName: symbol
                )
                if saved { onChanged() }
                return saved
            }
        }
    }
}
