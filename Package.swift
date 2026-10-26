// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BioSyncWatch",
    platforms: [
        .watchOS(.v10),
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "BioSyncKit",
            targets: ["BioSyncKit"]
        ),
    ],
    targets: [
        .target(
            name: "BioSyncKit",
            path: "Sources"
        ),
        .testTarget(
            name: "BioSyncKitTests",
            dependencies: ["BioSyncKit"],
            path: "Tests"
        )
    ]
)
