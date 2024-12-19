// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GTKChatGPT",
    dependencies: [
        .package(url: "https://git.aparoksha.dev/aparoksha/adwaita-swift", branch: "main"),
        .package(url: "https://github.com/alfianlosari/ChatGPTSwift", from: "2.4.4"),
    ],
    targets: [
        .executableTarget(
            name: "GTKChatGPT",
            dependencies: [
                .product(name: "Adwaita", package: "adwaita-swift"),
                .product(name: "ChatGPTSwift", package: "ChatGPTSwift"),
            ])
    ]
)
