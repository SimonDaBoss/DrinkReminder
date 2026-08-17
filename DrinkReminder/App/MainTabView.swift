import SwiftUI

struct MainTabView: View {
    @ObservedObject var homeViewModel: HomeViewModel
    @ObservedObject var reminderViewModel: ReminderViewModel
    @ObservedObject var settingsViewModel: SettingsViewModel
    let storageWarning: String?
    let onSettingsChanged: () -> Void
    let onContainerChanged: () -> Void
    let onReset: () -> Void

    var body: some View {
        TabView {
            HomeView(
                viewModel: homeViewModel,
                reminderViewModel: reminderViewModel,
                storageWarning: storageWarning
            )
            .tabItem {
                Label("Today", systemImage: "drop.fill")
            }

            SettingsView(
                viewModel: settingsViewModel,
                reminderViewModel: reminderViewModel,
                onSettingsChanged: onSettingsChanged,
                onContainerChanged: onContainerChanged,
                onReset: onReset
            )
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
        }
        .tint(.blue)
    }
}
