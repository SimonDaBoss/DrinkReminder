import SwiftUI

struct RootView: View {
    @EnvironmentObject private var environment: AppEnvironment

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "drop.fill")
                .font(.system(size: 56))
                .foregroundStyle(.blue)
                .accessibilityHidden(true)

            Text("Water Pet")
                .font(.largeTitle.bold())

            Text("Hydration foundation ready")
                .font(.headline)
                .foregroundStyle(.secondary)

            if let startupError = environment.startupError {
                Text("Local storage could not be opened. Changes will only last for this session. \(startupError)")
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .accessibilityLabel("Storage error. Changes will only last for this session.")
            }
        }
        .padding(32)
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
            .environmentObject(AppEnvironment())
    }
}
