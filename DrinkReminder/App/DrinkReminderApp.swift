import SwiftUI

@main
struct DrinkReminderApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var environment: AppEnvironment

    init() {
        let environment = AppEnvironment()
        _environment = StateObject(wrappedValue: environment)
        AppDelegate.environment = environment
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(environment)
                .environment(\.managedObjectContext, environment.persistence.viewContext)
        }
    }
}
