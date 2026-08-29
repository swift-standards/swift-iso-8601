// swift-tools-version: 6.4

import PackageDescription

extension String {
    static let iso8601: Self = "ISO 8601"
}

extension Target.Dependency {
    static var iso8601: Self { .target(name: .iso8601) }
    static var standards: Self {
        .product(name: "Standard Library Extensions", package: "swift-standard-library-extensions")
    }
    static var time: Self {
        .product(
            name: "Time",
            package: "swift-time"
        )
    }
    static var asciiPrimitives: Self {
        .product(name: "ASCII", package: "swift-ascii")
    }
    static var asciiDecimalParser: Self {
        .product(name: "ASCII Decimal Parser", package: "swift-ascii-parser")
    }
    static var byteParser: Self {
        .product(name: "Byte Parser", package: "swift-byte-parser")
    }
}

let package = Package(
    name: "swift-iso-8601",
    platforms: [
        .macOS(.v27),
        .iOS(.v27),
        .tvOS(.v27),
        .watchOS(.v27),
        .visionOS(.v27),
    ],
    products: [
        .library(name: "ISO 8601", targets: ["ISO 8601"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/swift-atoms/swift-standard-library-extensions.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-time.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-ascii.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-parser.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-ascii-parser.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-byte-parser.git",
            branch: "main"
        ),
    ],
    targets: [
        .target(
            name: "ISO 8601",
            dependencies: [
                .standards,
                .time,
                .asciiPrimitives,
                .asciiDecimalParser,
                .byteParser,
                .product(name: "Parser", package: "swift-parser"),
            ]
        ),
        .testTarget(
            name: "ISO 8601 Tests",
            dependencies: [
                "ISO 8601"
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

extension String {
    var tests: Self { self + " Tests" }
    var foundation: Self { self + " Foundation" }
}

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("Lifetimes"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
