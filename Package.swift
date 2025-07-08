// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftAutoGUI",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "SwiftAutoGUI",
            targets: ["SwiftAutoGUI"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
        .package(url: "https://github.com/yeatse/opencv-spm.git", from: "4.9.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "SwiftAutoGUI",
            dependencies: [
                .product(name: "OpenCV", package: "opencv-spm")
            ]),
        .testTarget(
            name: "SwiftAutoGUITests",
            dependencies: ["SwiftAutoGUI"]),
    ]
)
