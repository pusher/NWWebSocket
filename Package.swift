// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "NWWebSocket",
    platforms: [.iOS("15.0"),
                .macOS("12.0"),
                .tvOS("15.0"),
                .watchOS("9.0")],
    products: [
        .library(
            name: "NWWebSocket",
            targets: ["NWWebSocket"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "NWWebSocket",
            dependencies: []),
        .testTarget(
            name: "NWWebSocketTests",
            dependencies: ["NWWebSocket"]),
    ]
)
