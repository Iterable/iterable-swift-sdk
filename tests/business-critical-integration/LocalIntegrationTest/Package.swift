// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "LocalIntegrationTest",
    platforms: [
        .iOS(.v14)
    ],
    dependencies: [
        .package(path: "../../../")
    ],
    targets: [
        .target(
            name: "LocalIntegrationTest",
            dependencies: ["IterableSDK"],
            path: "Sources"
        ),
        .testTarget(
            name: "LocalIntegrationTestTests",
            dependencies: ["LocalIntegrationTest"],
            path: "Tests"
        )
    ]
)
