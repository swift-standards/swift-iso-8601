// swift-tools-version: 6.2

import PackageDescription

extension String {
    static let iso8601: Self = "ISO 8601"
}

extension Target.Dependency {
    static var iso8601: Self { .target(name: .iso8601) }
    static var standards: Self { .product(name: "Standards", package: "swift-standards") }
    static var time: Self {
        .product(
            name: "StandardTime",
            package: "swift-standards"
        )
    }
    static var incits_4_1986: Self { .product(name: "INCITS 4 1986", package: "swift-incits-4-1986") }
    static var standardsTestSupport: Self { .product(name: "StandardsTestSupport", package: "swift-standards") }
}

let package = Package(
    name: "swift-iso-8601",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .tvOS(.v26),
        .watchOS(.v26),
        .visionOS(.v26),
    ],
    products: [
        .library(name: .iso8601, targets: [.iso8601]),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-standards/swift-standards", from: "0.10.0"),
        .package(url: "https://github.com/swift-standards/swift-incits-4-1986", from: "0.6.2"),
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

extension String {
    var tests: Self { self + " Tests" }
    var foundation: Self { self + " Foundation" }
}

for target in package.targets where ![.system, .binary, .plugin].contains(target.type) {
    let existing = target.swiftSettings ?? []
    target.swiftSettings = existing + [
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility")
    ]
}
