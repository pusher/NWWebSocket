// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "NWWebSocket",
    platforms: [.iOS("13.0"),
                .macOS("10.15"),
                .tvOS("13.0"),
                .watchOS("6.0")],
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
