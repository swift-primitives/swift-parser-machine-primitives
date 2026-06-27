// swift-tools-version: 6.3.1

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
            name: "Parser Machine Program Primitives",
            targets: ["Parser Machine Program Primitives"]
        ),
        .library(
            name: "Parser Machine Runtime Primitives",
            targets: ["Parser Machine Runtime Primitives"]
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
        .package(url: "https://github.com/swift-primitives/swift-parser-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-stack-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-tagged-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-machine-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-input-primitives.git", branch: "main"),
    ],
    targets: [
        // MARK: - Program (IR)

        .target(
            name: "Parser Machine Program Primitives",
            dependencies: [
                .product(name: "Parser Primitives", package: "swift-parser-primitives"),
                .product(name: "Tagged Primitives", package: "swift-tagged-primitives"),
                .product(name: "Machine Primitives", package: "swift-machine-primitives"),
                .product(name: "Input Primitives", package: "swift-input-primitives"),
            ]
        ),

        // MARK: - Runtime (execution)

        .target(
            name: "Parser Machine Runtime Primitives",
            dependencies: [
                "Parser Machine Program Primitives",
                .product(name: "Parser Primitives", package: "swift-parser-primitives"),
                .product(name: "Tagged Primitives", package: "swift-tagged-primitives"),
                .product(name: "Machine Primitives", package: "swift-machine-primitives"),
                .product(name: "Stack Primitives", package: "swift-stack-primitives"),
                .product(name: "Input Primitives", package: "swift-input-primitives"),
            ]
        ),

        // MARK: - Memoization

        .target(
            name: "Parser Machine Memoization Primitives",
            dependencies: [
                "Parser Machine Program Primitives",
                "Parser Machine Runtime Primitives",
                .product(name: "Input Primitives", package: "swift-input-primitives"),
            ]
        ),

        // MARK: - Compile

        .target(
            name: "Parser Machine Compile Primitives",
            dependencies: [
                "Parser Machine Program Primitives",
                "Parser Machine Runtime Primitives",
                .product(name: "Input Primitives", package: "swift-input-primitives"),
            ]
        ),

        // MARK: - Combinator

        .target(
            name: "Parser Machine Combinator Primitives",
            dependencies: [
                "Parser Machine Program Primitives",
                "Parser Machine Runtime Primitives",
                .product(name: "Input Primitives", package: "swift-input-primitives"),
            ]
        ),

        // MARK: - Parse

        .target(
            name: "Parser Machine Parse Primitives",
            dependencies: [
                "Parser Machine Runtime Primitives",
                "Parser Machine Memoization Primitives",
                "Parser Machine Compile Primitives",
                .product(name: "Input Primitives", package: "swift-input-primitives"),
            ]
        ),

        // MARK: - Umbrella

        .target(
            name: "Parser Machine Primitives",
            dependencies: [
                "Parser Machine Program Primitives",
                "Parser Machine Runtime Primitives",
                "Parser Machine Memoization Primitives",
                "Parser Machine Compile Primitives",
                "Parser Machine Combinator Primitives",
                "Parser Machine Parse Primitives",
            ]
        ),

        // MARK: - Tests

        .testTarget(
            name: "Parser Machine Program Primitives Tests",
            dependencies: [
                "Parser Machine Program Primitives",
            ]
        ),

        .testTarget(
            name: "Parser Machine Memoization Primitives Tests",
            dependencies: [
                "Parser Machine Memoization Primitives",
                .product(name: "Tagged Primitives Test Support", package: "swift-tagged-primitives"),
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
                .product(name: "Tagged Primitives Test Support", package: "swift-tagged-primitives"),
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
