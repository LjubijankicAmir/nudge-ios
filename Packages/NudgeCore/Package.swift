// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "NudgeCore",
    platforms: [.iOS(.v18)],
    products: [
        .library(name: "NudgeCore", targets: ["NudgeCore"])
    ],
    targets: [
        // Deliberately dependency-free and SwiftUI-free: this module is linked by
        // the app extensions, which run under a single-digit-MB memory budget.
        .target(
            name: "NudgeCore",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "NudgeCoreTests",
            dependencies: ["NudgeCore"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ]
)
