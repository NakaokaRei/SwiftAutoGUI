import ArgumentParser
import SwiftAutoGUI
import AppKit

struct ScreenCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "screen",
        abstract: "Screen information and capture commands.",
        subcommands: [Size.self, Screenshot.self, Pixel.self, Locate.self, LocateCenter.self]
    )
}

extension ScreenCommand {
    struct Size: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Print the main screen dimensions."
        )

        func run() async throws {
            let (width, height) = SwiftAutoGUI.size()
            print("\(width) \(height)")
        }
    }

    struct Screenshot: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Take a screenshot and save to file."
        )

        @Option(help: "Output file path (default: screenshot.png).")
        var output: String = "screenshot.png"

        @Option(help: "Capture region as x,y,width,height (e.g., 0,0,500,500).")
        var region: String?

        func run() async throws {
            var rect: CGRect?
            if let region {
                let parts = region.split(separator: ",").compactMap { Double($0) }
                guard parts.count == 4 else {
                    throw ValidationError("Region must be x,y,width,height (e.g., 0,0,500,500).")
                }
                rect = CGRect(x: parts[0], y: parts[1], width: parts[2], height: parts[3])
            }

            let success = try await SwiftAutoGUI.screenshot(imageFilename: output, region: rect)
            if success {
                print(output)
            } else {
                throw RuntimeError("Failed to save screenshot.")
            }
        }
    }

    struct Pixel: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Get the color of a pixel at given coordinates."
        )

        @Option(help: "X coordinate.")
        var x: Int

        @Option(help: "Y coordinate.")
        var y: Int

        func run() async throws {
            guard let color = try await SwiftAutoGUI.pixel(x: x, y: y) else {
                throw RuntimeError("Failed to get pixel color.")
            }
            let r = Int(color.redComponent * 255)
            let g = Int(color.greenComponent * 255)
            let b = Int(color.blueComponent * 255)
            let a = Int(color.alphaComponent * 255)
            print("\(r) \(g) \(b) \(a)")
        }
    }

    struct Locate: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Find an image on screen and print its position."
        )

        @Argument(help: "Path to the image file to search for.")
        var imagePath: String

        @Option(help: "Matching confidence threshold (0.0-1.0).")
        var confidence: Double?

        func run() async throws {
            guard let rect = try await SwiftAutoGUI.locateOnScreen(imagePath, confidence: confidence) else {
                throw RuntimeError("Image not found on screen.")
            }
            print("\(rect.origin.x) \(rect.origin.y) \(rect.width) \(rect.height)")
        }
    }

    struct LocateCenter: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "locate-center",
            abstract: "Find an image on screen and print its center point."
        )

        @Argument(help: "Path to the image file to search for.")
        var imagePath: String

        @Option(help: "Matching confidence threshold (0.0-1.0).")
        var confidence: Double?

        func run() async throws {
            guard let point = try await SwiftAutoGUI.locateCenterOnScreen(imagePath, confidence: confidence) else {
                throw RuntimeError("Image not found on screen.")
            }
            print("\(point.x) \(point.y)")
        }
    }
}

struct RuntimeError: Error, CustomStringConvertible {
    let description: String
    init(_ description: String) {
        self.description = description
    }
}
