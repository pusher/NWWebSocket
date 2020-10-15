// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "NWWebSocket",
    platforms: [.iOS("13.0"), .macOS("10.15"), .tvOS("13.0")],
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
