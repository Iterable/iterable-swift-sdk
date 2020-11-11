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
        .binaryTarget(name: "IterableSDK",
                      url: "https://github.com/Iterable/swift-sdk/releases/download/6.2.15/IterableSDK.xcframework.zip",
                      checksum: "4ac30cc9b678c555ada254b9dd57d72778ebbce12b7d0b4da3b52937a199703a"),
        .binaryTarget(name: "IterableAppExtensions",
                      url: "https://github.com/Iterable/swift-sdk/releases/download/6.2.15/IterableAppExtensions.xcframework.zip",
                      checksum: "401eef0dc84173aaeb1a6e93b841d99409202d0b311bab0cc7c2aee3aee3e54e"),
    ]
)
