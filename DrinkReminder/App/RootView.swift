import SwiftUI

struct RootView: View {
    @EnvironmentObject private var environment: AppEnvironment

    var body: some View {
        HomeView(
            viewModel: environment.homeViewModel,
            reminderViewModel: environment.reminderViewModel,
            storageWarning: environment.startupError
        )
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        let environment = AppEnvironment(inMemory: true)
        _ = try? environment.hydrationTracker.logWater(volumeML: 1_250, source: .quickAdd)

        return RootView()
            .environmentObject(environment)
    }
}
