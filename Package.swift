// swift-tools-version: 6.3

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
        .library(
            name: "Parser Machine Core Primitives",
            targets: ["Parser Machine Core Primitives"]
        ),
        .library(
            name: "Parser Machine Memoization Primitives",
            targets: ["Parser Machine Memoization Primitives"]
        ),
        .library(
            name: "Parser Machine Compile Primitives",
            targets: ["Parser Machine Compile Primitives"]
        ),
        .library(
            name: "Parser Machine Combinator Primitives",
            targets: ["Parser Machine Combinator Primitives"]
        ),
        .library(
            name: "Parser Machine Parse Primitives",
            targets: ["Parser Machine Parse Primitives"]
        ),
        .library(
            name: "Parser Machine Primitives Test Support",
            targets: ["Parser Machine Primitives Test Support"]
        ),
    ],
    dependencies: [
        .package(path: "../swift-parser-primitives"),
        .package(path: "../swift-stack-primitives"),
        .package(path: "../swift-slab-primitives"),
        .package(path: "../swift-identity-primitives"),
        .package(path: "../swift-machine-primitives"),
    ],
    targets: [
        // MARK: - Core

        .target(
            name: "Parser Machine Core Primitives",
            dependencies: [
                .product(name: "Parser Primitives", package: "swift-parser-primitives"),
                .product(name: "Identity Primitives", package: "swift-identity-primitives"),
                .product(name: "Machine Primitives", package: "swift-machine-primitives"),
                .product(name: "Stack Primitives", package: "swift-stack-primitives"),
                .product(name: "Slab Primitives", package: "swift-slab-primitives"),
            ]
        ),

        // MARK: - Memoization

        .target(
            name: "Parser Machine Memoization Primitives",
            dependencies: [
                "Parser Machine Core Primitives",
            ]
        ),

        // MARK: - Compile

        .target(
            name: "Parser Machine Compile Primitives",
            dependencies: [
                "Parser Machine Core Primitives",
            ]
        ),

        // MARK: - Combinator

        .target(
            name: "Parser Machine Combinator Primitives",
            dependencies: [
                "Parser Machine Core Primitives",
            ]
        ),

        // MARK: - Parse

        .target(
            name: "Parser Machine Parse Primitives",
            dependencies: [
                "Parser Machine Core Primitives",
                "Parser Machine Memoization Primitives",
                "Parser Machine Compile Primitives",
            ]
        ),

        // MARK: - Umbrella

        .target(
            name: "Parser Machine Primitives",
            dependencies: [
                "Parser Machine Core Primitives",
                "Parser Machine Memoization Primitives",
                "Parser Machine Compile Primitives",
                "Parser Machine Combinator Primitives",
                "Parser Machine Parse Primitives",
            ]
        ),

        // MARK: - Tests

        .testTarget(
            name: "Parser Machine Core Primitives Tests",
            dependencies: [
                "Parser Machine Core Primitives",
            ]
        ),

        .testTarget(
            name: "Parser Machine Memoization Primitives Tests",
            dependencies: [
                "Parser Machine Memoization Primitives",
                .product(name: "Identity Primitives Test Support", package: "swift-identity-primitives"),
            ]
        ),

        .testTarget(
            name: "Parser Machine Compile Primitives Tests",
            dependencies: [
                "Parser Machine Compile Primitives",
                "Parser Machine Combinator Primitives",
                .product(name: "Parser Primitives Test Support", package: "swift-parser-primitives"),
            ]
        ),

        .testTarget(
            name: "Parser Machine Combinator Primitives Tests",
            dependencies: [
                "Parser Machine Combinator Primitives",
                .product(name: "Parser Primitives Test Support", package: "swift-parser-primitives"),
            ]
        ),

        .testTarget(
            name: "Parser Machine Parse Primitives Tests",
            dependencies: [
                "Parser Machine Parse Primitives",
                "Parser Machine Combinator Primitives",
                .product(name: "Parser Primitives Test Support", package: "swift-parser-primitives"),
            ]
        ),

        .testTarget(
            name: "Parser Machine Equivalence Tests",
            dependencies: [
                "Parser Machine Compile Primitives",
                "Parser Machine Combinator Primitives",
                .product(name: "Parser Primitives Test Support", package: "swift-parser-primitives"),
            ]
        ),

        // MARK: - Test Support
        .target(
            name: "Parser Machine Primitives Test Support",
            dependencies: [
                "Parser Machine Primitives",
                .product(name: "Parser Primitives Test Support", package: "swift-parser-primitives"),
                .product(name: "Identity Primitives Test Support", package: "swift-identity-primitives"),
            ],
            path: "Tests/Support"
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
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("LifetimeDependence"),
        .enableExperimentalFeature("Lifetimes"),
        .enableExperimentalFeature("SuppressedAssociatedTypes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
        .enableUpcomingFeature("LifetimeDependence"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
