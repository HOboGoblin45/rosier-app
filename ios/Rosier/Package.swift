// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Rosier",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "RosierCore",
            targets: ["RosierCore"]
        ),
        .library(
            name: "RosierUI",
            targets: ["RosierUI"]
        ),
        .executable(
            name: "Rosier",
            targets: ["RosierApp"]
        ),
    ],
    dependencies: [
        // All functionality leverages Apple frameworks for MVP
        // No external dependencies needed
    ],
    targets: [
        // MARK: - Core Framework
        // Business logic, models, services, design system, extensions, coordinators
        .target(
            name: "RosierCore",
            dependencies: [],
            path: "Sources",
            exclude: [
                "Views",
                "ViewModels",
                "App",
                "Resources",
            ],
            sources: [
                "Models",
                "Services",
                "DesignSystem",
                "Extensions",
                "CoreData",
                "Coordinators",
            ],
            resources: [
                .process("Resources"),
            ],
            swiftSettings: [
                .unsafeFlags(["-suppress-warnings"], .when(configuration: .release)),
            ],
            linkerSettings: [
                .linkedFramework("CoreData"),
                .linkedFramework("CloudKit"),
                .linkedFramework("UserNotifications"),
                .linkedFramework("BackgroundTasks"),
            ]
        ),

        // MARK: - UI Framework
        // All views and view models
        .target(
            name: "RosierUI",
            dependencies: ["RosierCore"],
            path: "Sources",
            exclude: [
                "Models",
                "Services",
                "DesignSystem",
                "Extensions",
                "CoreData",
                "Coordinators",
                "App",
                "Resources",
            ],
            sources: [
                "Views",
                "ViewModels",
            ],
            swiftSettings: [
                .unsafeFlags(["-suppress-warnings"], .when(configuration: .release)),
            ]
        ),

        // MARK: - App Target
        // Application entry point and delegates
        .executableTarget(
            name: "RosierApp",
            dependencies: ["RosierCore", "RosierUI"],
            path: "Sources/App",
            resources: [
                .process("Resources"),
            ],
            swiftSettings: [
                .unsafeFlags(["-suppress-warnings"], .when(configuration: .release)),
            ],
            linkerSettings: [
                .linkedFramework("UIKit"),
            ]
        ),

        // MARK: - Unit Tests
        .testTarget(
            name: "RosierTests",
            dependencies: ["RosierCore", "RosierUI"],
            path: "Tests/RosierTests",
            sources: [""]
        ),
    ]
)
