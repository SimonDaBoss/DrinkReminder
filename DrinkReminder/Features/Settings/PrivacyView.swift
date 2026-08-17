import SwiftUI

struct PrivacyView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    privacyRow(
                        icon: "iphone",
                        title: "Stored on this device",
                        detail: "Your hydration logs, pet, and preferences stay in the app’s local data store."
                    )
                    privacyRow(
                        icon: "chart.bar.xaxis",
                        title: "No analytics account",
                        detail: "This version does not require an account and does not include third-party analytics."
                    )
                    privacyRow(
                        icon: "bell",
                        title: "Notifications are optional",
                        detail: "Reminder permission can be changed anytime in iOS Settings."
                    )
                }

                Section {
                    Text("Reset All Data in Settings removes the app’s local hydration history and personalization.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Privacy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func privacyRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 5)
    }
}
