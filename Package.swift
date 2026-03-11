// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "swift-observation-testing",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .tvOS(.v17),
        .watchOS(.v10)
    ],
    products: [
        .library(
            name: "ObservationTesting",
            targets: ["ObservationTesting"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-clocks", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "ObservationTesting",
            dependencies: [
                .product(name: "Clocks", package: "swift-clocks")
            ]
        ),
        .testTarget(
            name: "ObservationTestingTests",
            dependencies: ["ObservationTesting"]
        ),
    ]
)
