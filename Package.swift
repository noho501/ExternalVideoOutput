// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "ExternalVideoOutput",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "ExternalVideoOutput",
            targets: ["ExternalVideoOutput"]
        )
    ],
    targets: [
        .target(
            name: "ExternalVideoOutput",
            dependencies: []
        ),
        .testTarget(
            name: "ExternalVideoOutputTests",
            dependencies: ["ExternalVideoOutput"]
        )
    ]
)
