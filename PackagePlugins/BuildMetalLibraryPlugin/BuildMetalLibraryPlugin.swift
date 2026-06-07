import Foundation
import PackagePlugin

@main
struct BuildMetalLibraryPlugin: CommandPlugin {
    func performCommand(
        context: PluginContext,
        arguments: [String]
    ) async throws {
        let unsupportedArguments = unsupportedArguments(in: arguments)
        guard unsupportedArguments.isEmpty else {
            Diagnostics.error(
                "build-metal-library received unsupported arguments: "
                    + unsupportedArguments.joined(separator: " ")
            )
            return
        }

        let packageURL = context.package.directoryURL
        let sourceURL = packageURL.appending(
            path: "Sources/ImageRecognition/Shaders/TemplateMatching.metal"
        )
        let outputURL = packageURL.appending(
            path: "Sources/ImageRecognition/Resources/TemplateMatching.metallib"
        )
        let workDirectoryURL = context.pluginWorkDirectoryURL.appending(
            path: "BuildMetalLibrary",
            directoryHint: .isDirectory
        )
        let airURL = workDirectoryURL.appending(path: "TemplateMatching.air")

        try FileManager.default.createDirectory(
            at: workDirectoryURL,
            withIntermediateDirectories: true
        )
        try FileManager.default.createDirectory(
            at: outputURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        try runXcrun(
            [
                "-sdk", "macosx",
                "metal",
                "-c",
                "-target", "air64-apple-macos26.0",
                sourceURL.path,
                "-o", airURL.path,
            ],
            step: "Compile TemplateMatching.metal"
        )
        try runXcrun(
            [
                "-sdk", "macosx",
                "metallib",
                airURL.path,
                "-o", outputURL.path,
            ],
            step: "Link TemplateMatching.metallib"
        )

        print("Generated \(outputURL.path)")
    }

    private func unsupportedArguments(in arguments: [String]) -> [String] {
        var unsupported: [String] = []
        var index = 0

        while index < arguments.count {
            let argument = arguments[index]
            if argument == "--target", index + 1 < arguments.count {
                index += 2
            } else if argument.hasPrefix("--target=") {
                index += 1
            } else {
                unsupported.append(argument)
                index += 1
            }
        }

        return unsupported
    }

    private func runXcrun(
        _ arguments: [String],
        step: String
    ) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        process.arguments = arguments
        process.standardOutput = FileHandle.standardOutput
        process.standardError = FileHandle.standardError

        print("\(step)...")
        try process.run()
        process.waitUntilExit()

        guard process.terminationReason == .exit,
              process.terminationStatus == 0 else {
            throw MetalLibraryPluginError.commandFailed(
                step: step,
                status: process.terminationStatus
            )
        }
    }
}

private enum MetalLibraryPluginError: Error, CustomStringConvertible {
    case commandFailed(step: String, status: Int32)

    var description: String {
        switch self {
        case .commandFailed(let step, let status):
            "\(step) failed with exit status \(status). "
                + "Install Xcode's Metal Toolchain component and try again."
        }
    }
}
