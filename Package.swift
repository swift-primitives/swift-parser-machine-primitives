// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "swift-parser-machine-primitives",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .tvOS(.v26),
        .watchOS(.v26),
        .visionOS(.v26)
    ],
    products: [
        .library(
            name: "Parser Machine Primitives",
            targets: ["Parser Machine Primitives"]
        ),
    ],
    dependencies: [
        .package(path: "../swift-parser-primitives"),
        .package(path: "../swift-input-primitives"),
        .package(path: "../swift-stack-primitives"),
        .package(path: "../swift-slab-primitives"),
        .package(path: "../swift-identity-primitives"),
        .package(path: "../swift-ownership-primitives"),
        .package(path: "../swift-machine-primitives"),
    ],
    targets: [
        .target(
            name: "Parser Machine Primitives",
            dependencies: [
                .product(name: "Parser Primitives", package: "swift-parser-primitives"),
                .product(name: "Input Primitives", package: "swift-input-primitives"),
                .product(name: "Stack Primitives", package: "swift-stack-primitives"),
                .product(name: "Slab Primitives", package: "swift-slab-primitives"),
                .product(name: "Identity Primitives", package: "swift-identity-primitives"),
                .product(name: "Ownership Primitives", package: "swift-ownership-primitives"),
                .product(name: "Machine Primitives", package: "swift-machine-primitives")
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableExperimentalFeature("Lifetimes"),
        .enableExperimentalFeature("SuppressedAssociatedTypes"),
        .enableExperimentalFeature("SuppressedAssociatedTypesWithDefaults"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
