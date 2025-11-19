// swift-tools-version:6.2

import PackageDescription

extension String {
    static let iso8601: Self = "ISO 8601"
}

extension String { var tests: Self { self + " Tests" } }

extension Target.Dependency {
    static var iso8601: Self { .target(name: .iso8601) }
    static var standards: Self { .product(name: "Standards", package: "swift-standards") }
    static var time: Self {
        .product(
            name: "Time",
            package: "swift-standards",
            moduleAliases: ["Time": "StandardTime"]
        )
    }
    static var incits_4_1986: Self { .product(name: "INCITS 4 1986", package: "swift-incits-4-1986") }
    static var standardsTestSupport: Self { .product(name: "StandardsTestSupport", package: "swift-standards") }
}

let package = Package(
    name: "swift-iso-8601",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
        .tvOS(.v18),
        .watchOS(.v11)
    ],
    products: [
        .library(name: .iso8601, targets: [.iso8601]),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-standards/swift-standards", from: "0.1.0"),
        .package(url: "https://github.com/swift-standards/swift-incits-4-1986", from: "0.1.0")
    ],
    targets: [
        .target(
            name: .iso8601,
            dependencies: [
                .standards,
                .time,
                .incits_4_1986
            ]
        ),
        .testTarget(
            name: .iso8601.tests,
            dependencies: [
                .iso8601,
                .time,  // Needed for Time.Error in test expectations
                .incits_4_1986,
                .standardsTestSupport
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
