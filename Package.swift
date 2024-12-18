// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "XCAChatGPT",
    dependencies: [
        .package(url: "https://git.aparoksha.dev/aparoksha/adwaita-swift", branch: "main"),
        // .package(url: "https://github.com/hummingbird-project/swift-websocket", from: "1.1.1"),
        .package(url: "https://github.com/alfianlosari/ChatGPTSwift", from: "2.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "XCAChatGPT",
            dependencies: [
                .product(name: "Adwaita", package: "adwaita-swift"),
                // .product(name: "WSClient", package: "swift-websocket"),
                .product(name: "ChatGPTSwift", package: "ChatGPTSwift"),
            ])
    ]
)
