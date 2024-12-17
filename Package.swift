// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift_websocket",
    dependencies: [
        // .package(url: "https://github.com/vapor/websocket-kit", from: "2.15.0"),
        .package(url: "https://git.aparoksha.dev/aparoksha/adwaita-swift", branch: "main"),
        .package(url: "https://github.com/hummingbird-project/swift-websocket", from: "1.1.1"),
        .package(url: "https://github.com/alfianlosari/ChatGPTSwift", from: "2.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "swift_websocket",
            dependencies: [
                // .product(name: "WebSocketKit", package: "websocket-kit"),
                .product(name: "Adwaita", package: "adwaita-swift"),
                .product(name: "WSClient", package: "swift-websocket"),
                .product(name: "ChatGPTSwift", package: "ChatGPTSwift"),
            ])
    ]
)
