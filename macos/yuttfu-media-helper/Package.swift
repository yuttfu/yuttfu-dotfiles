// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "YuttfuMediaHelper",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "YuttfuMediaCore", targets: ["YuttfuMediaCore"]),
        .executable(name: "yuttfu-media-helper", targets: ["YuttfuMediaHelper"]),
        .executable(name: "yuttfu-media-core-tests", targets: ["YuttfuMediaCoreTests"]),
    ],
    targets: [
        .target(name: "YuttfuMediaCore"),
        .executableTarget(
            name: "YuttfuMediaHelper",
            dependencies: ["YuttfuMediaCore"]
        ),
        .executableTarget(
            name: "YuttfuMediaCoreTests",
            dependencies: ["YuttfuMediaCore"],
            path: "Tests/YuttfuMediaCoreTests"
        ),
    ]
)
