// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MacHelper",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "MacHelper",
            path: "Sources"
        ),
        .testTarget(
            name: "MacHelperTests",
            dependencies: ["MacHelper"],
            path: "Tests"
        ),
    ]
)
