// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "YuttfuCalendarPanel",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "YuttfuCalendarCore", targets: ["YuttfuCalendarCore"]),
        .executable(name: "yuttfu-calendar-panel", targets: ["YuttfuCalendarPanel"]),
        .executable(name: "yuttfu-calendar-core-tests", targets: ["YuttfuCalendarCoreTests"]),
    ],
    targets: [
        .target(name: "YuttfuCalendarCore"),
        .executableTarget(
            name: "YuttfuCalendarPanel",
            dependencies: ["YuttfuCalendarCore"]
        ),
        .executableTarget(
            name: "YuttfuCalendarCoreTests",
            dependencies: ["YuttfuCalendarCore"],
            path: "Tests/YuttfuCalendarCoreTests"
        ),
    ]
)
