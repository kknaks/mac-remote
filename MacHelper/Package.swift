// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MacHelper",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/httpswift/swifter.git", from: "1.5.0"),
    ],
    targets: [
        .target(
            name: "MacHelperLib",
            dependencies: [
                .product(name: "Swifter", package: "swifter"),
            ],
            path: "Sources/MacHelperLib"
        ),
        .executableTarget(
            name: "MacHelper",
            dependencies: ["MacHelperLib"],
            path: "Sources/MacHelper"
        ),
        .executableTarget(
            name: "MacHelperApp",
            dependencies: ["MacHelperLib"],
            path: "Sources/MacHelperApp",
            exclude: ["Info.plist"],
            resources: [.copy("Resources/MenuBarIcon.png"),
                        .copy("Resources/MenuBarIcon@2x.png"),
                        .copy("Resources/MenuBarIcon@3x.png")]
        ),
        .testTarget(
            name: "MacHelperTests",
            dependencies: ["MacHelperLib"],
            path: "Tests"
        ),
    ]
)
