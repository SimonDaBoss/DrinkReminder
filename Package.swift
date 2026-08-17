// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "DrinkReminder",
    platforms: [
        .iOS(.v17),
        .macOS(.v13)
    ],
    products: [
        .executable(name: "DrinkReminder", targets: ["DrinkReminder"])
    ],
    targets: [
        .executableTarget(
            name: "DrinkReminder",
            path: "DrinkReminder"
        ),
        .testTarget(
            name: "DrinkReminderTests",
            dependencies: ["DrinkReminder"],
            path: "DrinkReminderTests"
        )
    ]
)
