// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "IterableSDK",
    platforms: [.iOS(.v10)],
    products: [
        // The external product of our package is an importable
        // library that has the same name as the package itself:
        .library(
            name: "IterableSDK",
            targets: ["IterableSDK"]
        ),
        .library(
            name: "IterableAppExtensions",
            targets: ["IterableAppExtensions"]
        ),
    ],
    targets: [
        .target(name: "IterableSDK",
                path: "swift-sdk",
                exclude: ["Info.plist"],
                resources: [
                    .process("Resources"),
                ]),
        .target(name: "IterableAppExtensions",
                path: "notification-extension",
                exclude: ["Info.plist"]),
    ]
)
