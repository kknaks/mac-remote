// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MacHelper",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .target(
            name: "MacHelperLib",
            path: "Sources/MacHelperLib"
        ),
        .executableTarget(
            name: "MacHelper",
            dependencies: ["MacHelperLib"],
            path: "Sources/MacHelper"
        ),
        .testTarget(
            name: "MacHelperTests",
            dependencies: ["MacHelperLib"],
            path: "Tests"
        ),
    ]
)
