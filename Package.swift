// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "HangulSearch",
    platforms: [
        .iOS(.v11),
        .macOS(.v10_13),
        .watchOS(.v4),
        .tvOS(.v11)
    ],
    products: [
        .library(
            name: "HangulSearch",
            targets: ["HangulSearch"]),
    ],
    targets: [
        .target(
            name: "HangulSearch"),
        .testTarget(
            name: "HangulSearchTests",
            dependencies: ["HangulSearch"],
            resources: [.copy("MockData/people.json")]
        ),
    ]
)
