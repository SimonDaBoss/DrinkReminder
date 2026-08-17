// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "DrinkReminder",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "DrinkReminder", targets: ["DrinkReminder"])
    ],
    targets: [
        .target(
            name: "DrinkReminder",
            path: "DrinkReminder",
            exclude: [
                "App",
                "Features/Home/Components",
                "Features/Home/CustomWaterSheet.swift",
                "Features/Home/HomeView.swift",
                "Features/Onboarding/OnboardingView.swift",
                "Features/Reminders/ReminderSettingsView.swift",
                "Features/Settings/ContainerPresetsView.swift",
                "Features/Settings/PresetEditorView.swift",
                "Features/Settings/PrivacyView.swift",
                "Features/Settings/SettingsView.swift"
            ]
        ),
        .testTarget(
            name: "DrinkReminderTests",
            dependencies: ["DrinkReminder"],
            path: "DrinkReminderTests"
        )
    ]
)
