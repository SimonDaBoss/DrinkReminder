import SwiftUI

struct QuickAddPresetButton: View {
    let preset: ContainerPreset
    let unit: VolumeUnit
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: preset.symbolName)
                    .font(.title3)
                    .foregroundStyle(.blue)
                    .frame(width: 30, height: 30)

                VStack(alignment: .leading, spacing: 2) {
                    Text(preset.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(VolumeDisplayFormatter.string(milliliters: preset.volumeML, unit: unit))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 70)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add one \(preset.name), \(VolumeDisplayFormatter.string(milliliters: preset.volumeML, unit: unit))")
    }
}
