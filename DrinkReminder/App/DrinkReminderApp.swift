import SwiftUI

@main
struct DrinkReminderApp: App {
    @StateObject private var environment = AppEnvironment()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(environment)
                .environment(\.managedObjectContext, environment.persistence.viewContext)
        }
    }
}
