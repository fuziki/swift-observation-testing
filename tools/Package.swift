// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "tools",
    dependencies: [
        .package(url: "https://github.com/realm/SwiftLint", from: "0.57.0"),
        .package(url: "https://github.com/nicklockwood/SwiftFormat", from: "0.54.0"),
    ],
    targets: []
)
