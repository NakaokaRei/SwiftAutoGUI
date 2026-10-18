// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "SampleFeatures",
    platforms: [.macOS("27.0")],
    products: [.library(name: "AgentDemoFeature", targets: ["AgentDemoFeature"])],
    dependencies: [
        .package(path: ".."),
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", exact: "1.26.0"),
    ],
    targets: [
        .target(name: "AgentDemoFeature", dependencies: [
            .product(name: "SwiftAutoGUI", package: "SwiftAutoGUI"),
            .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
        ]),
        .testTarget(name: "AgentDemoFeatureTests", dependencies: ["AgentDemoFeature"]),
    ]
)
