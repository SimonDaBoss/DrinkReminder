import SwiftUI

struct RootView: View {
    @EnvironmentObject private var environment: AppEnvironment

    var body: some View {
        Group {
            if environment.onboardingCompleted {
                MainTabView(
                    homeViewModel: environment.homeViewModel,
                    reminderViewModel: environment.reminderViewModel,
                    settingsViewModel: environment.settingsViewModel,
                    storageWarning: environment.startupError,
                    onSettingsChanged: environment.refreshAppState,
                    onContainerChanged: environment.refreshHomeState,
                    onReset: environment.handleDataReset
                )
            } else {
                OnboardingView(
                    viewModel: environment.onboardingViewModel,
                    onComplete: environment.refreshAppState
                )
            }
        }
        .preferredColorScheme(preferredColorScheme)
    }

    private var preferredColorScheme: ColorScheme? {
        switch environment.appearance {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
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
