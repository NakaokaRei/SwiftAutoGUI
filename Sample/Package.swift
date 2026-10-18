// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "SampleFeatures",
    platforms: [.macOS("27.0")],
    products: [
        .library(name: "AIGenerationDemoFeature", targets: ["AIGenerationDemoFeature"]),
        .library(name: "ActionsDemoFeature", targets: ["ActionsDemoFeature"]),
        .library(name: "AgentDemoFeature", targets: ["AgentDemoFeature"]),
        .library(name: "AppleScriptFeature", targets: ["AppleScriptFeature"]),
        .library(name: "BrowserDemoFeature", targets: ["BrowserDemoFeature"]),
        .library(name: "DialogDemoFeature", targets: ["DialogDemoFeature"]),
        .library(name: "ImageRecognitionFeature", targets: ["ImageRecognitionFeature"]),
        .library(name: "InputObserverFeature", targets: ["InputObserverFeature"]),
        .library(name: "KeyboardDemoFeature", targets: ["KeyboardDemoFeature"]),
        .library(name: "KeyboardLayoutFeature", targets: ["KeyboardLayoutFeature"]),
        .library(name: "MouseControlFeature", targets: ["MouseControlFeature"]),
        .library(name: "PixelDetectionFeature", targets: ["PixelDetectionFeature"]),
        .library(name: "SampleSupport", targets: ["SampleSupport"]),
        .library(name: "ScreenContextFeature", targets: ["ScreenContextFeature"]),
        .library(name: "ScreenshotFeature", targets: ["ScreenshotFeature"]),
        .library(name: "ScrollingDemoFeature", targets: ["ScrollingDemoFeature"]),
        .library(name: "TextTypingFeature", targets: ["TextTypingFeature"]),
    ],
    dependencies: [
        .package(path: ".."),
        .package(
            url: "https://github.com/pointfreeco/swift-composable-architecture", exact: "1.26.0"),
    ],
    targets: [
        .target(
            name: "AIGenerationDemoFeature",
            dependencies: [
                .product(name: "SwiftAutoGUI", package: "SwiftAutoGUI"),
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                "SampleSupport",
            ]),
        .target(
            name: "ActionsDemoFeature",
            dependencies: [
                .product(name: "SwiftAutoGUI", package: "SwiftAutoGUI"),
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                "SampleSupport",
            ]),
        .target(
            name: "AgentDemoFeature",
            dependencies: [
                .product(name: "SwiftAutoGUI", package: "SwiftAutoGUI"),
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                "SampleSupport",
            ]),
        .target(
            name: "AppleScriptFeature",
            dependencies: [
                .product(name: "SwiftAutoGUI", package: "SwiftAutoGUI"),
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                "SampleSupport",
            ]),
        .target(
            name: "BrowserDemoFeature",
            dependencies: [
                .product(name: "SwiftAutoGUI", package: "SwiftAutoGUI"),
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                "SampleSupport", .product(name: "SwiftAutoGUIBrowser", package: "SwiftAutoGUI"),
            ]),
        .target(
            name: "DialogDemoFeature",
            dependencies: [
                .product(name: "SwiftAutoGUI", package: "SwiftAutoGUI"),
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                "SampleSupport",
            ]),
        .target(
            name: "ImageRecognitionFeature",
            dependencies: [
                .product(name: "SwiftAutoGUI", package: "SwiftAutoGUI"),
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                "SampleSupport",
            ]),
        .target(
            name: "InputObserverFeature",
            dependencies: [
                .product(name: "SwiftAutoGUI", package: "SwiftAutoGUI"),
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                "SampleSupport",
            ]),
        .target(
            name: "KeyboardDemoFeature",
            dependencies: [
                .product(name: "SwiftAutoGUI", package: "SwiftAutoGUI"),
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                "SampleSupport",
            ]),
        .target(
            name: "KeyboardLayoutFeature",
            dependencies: [
                .product(name: "SwiftAutoGUI", package: "SwiftAutoGUI"),
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                "SampleSupport",
            ]),
        .target(
            name: "MouseControlFeature",
            dependencies: [
                .product(name: "SwiftAutoGUI", package: "SwiftAutoGUI"),
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                "SampleSupport",
            ]),
        .target(
            name: "PixelDetectionFeature",
            dependencies: [
                .product(name: "SwiftAutoGUI", package: "SwiftAutoGUI"),
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                "SampleSupport",
            ]),
        .target(
            name: "SampleSupport",
            dependencies: [
                .product(name: "SwiftAutoGUI", package: "SwiftAutoGUI"),
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ]),
        .target(
            name: "ScreenContextFeature",
            dependencies: [
                .product(name: "SwiftAutoGUI", package: "SwiftAutoGUI"),
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                "SampleSupport",
            ]),
        .target(
            name: "ScreenshotFeature",
            dependencies: [
                .product(name: "SwiftAutoGUI", package: "SwiftAutoGUI"),
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                "SampleSupport",
            ]),
        .target(
            name: "ScrollingDemoFeature",
            dependencies: [
                .product(name: "SwiftAutoGUI", package: "SwiftAutoGUI"),
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                "SampleSupport",
            ]),
        .target(
            name: "TextTypingFeature",
            dependencies: [
                .product(name: "SwiftAutoGUI", package: "SwiftAutoGUI"),
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                "SampleSupport",
            ]),
        .testTarget(name: "AgentDemoFeatureTests", dependencies: ["AgentDemoFeature"]),
        .testTarget(
            name: "SampleFeatureTests",
            dependencies: [
                "AIGenerationDemoFeature", "ActionsDemoFeature", "AgentDemoFeature",
                "AppleScriptFeature",
                "BrowserDemoFeature", "DialogDemoFeature", "ImageRecognitionFeature",
                "InputObserverFeature", "KeyboardDemoFeature", "KeyboardLayoutFeature",
                "MouseControlFeature", "PixelDetectionFeature", "SampleSupport",
                "ScreenContextFeature",
                "ScreenshotFeature", "ScrollingDemoFeature", "TextTypingFeature",
            ]),
    ]
)
