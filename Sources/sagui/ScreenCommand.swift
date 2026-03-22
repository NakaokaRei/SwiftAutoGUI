import ArgumentParser
import SwiftAutoGUI
import AppKit

/// Screen information and capture commands for the sagui CLI.
///
/// Provides subcommands for querying screen dimensions, taking screenshots,
/// reading pixel colors, and locating images on screen.
///
/// ## Usage
///
/// ```bash
/// # Get screen dimensions
/// sagui screen size
///
/// # Take a screenshot
/// sagui screen screenshot --output capture.png
///
/// # Get pixel color at coordinates
/// sagui screen pixel --x 100 --y 200
///
/// # Find an image on screen
/// sagui screen locate button.png
/// sagui screen locate-center button.png
/// ```
///
/// ## Topics
///
/// ### Subcommands
/// - ``Size``
/// - ``Screenshot``
/// - ``Pixel``
/// - ``Locate``
/// - ``LocateCenter``
struct ScreenCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "screen",
        abstract: "Screen information and capture commands.",
        subcommands: [Size.self, Screenshot.self, Pixel.self, Locate.self, LocateCenter.self]
    )
}

extension ScreenCommand {
    /// Print the main screen dimensions.
    ///
    /// Outputs the width and height in pixels separated by a space.
    ///
    /// ```bash
    /// sagui screen size
    /// # Output: 1920.0 1080.0
    /// ```
    struct Size: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Print the main screen dimensions."
        )

        func run() async throws {
            let (width, height) = SwiftAutoGUI.size()
            print("\(width) \(height)")
        }
    }

    /// Take a screenshot and save it to a file.
    ///
    /// Captures the full screen or a specified region and saves it as a PNG image.
    /// On success, prints the output file path.
    ///
    /// ```bash
    /// sagui screen screenshot                                    # Save as screenshot.png
    /// sagui screen screenshot --output capture.png               # Custom filename
    /// sagui screen screenshot --region 0,0,500,500               # Capture a region
    /// ```
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

    /// Get the color of a pixel at given screen coordinates.
    ///
    /// Outputs the RGBA components as integers (0–255) separated by spaces.
    ///
    /// ```bash
    /// sagui screen pixel --x 100 --y 200
    /// # Output: 255 128 64 255
    /// ```
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

    /// Find an image on screen and print its bounding rectangle.
    ///
    /// Searches the current screen for a matching image using template matching.
    /// Outputs the position and size as `x y width height`.
    ///
    /// ```bash
    /// sagui screen locate button.png
    /// sagui screen locate button.png --confidence 0.9
    /// # Output: 120.0 340.0 50.0 30.0
    /// ```
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

    /// Find an image on screen and print its center point.
    ///
    /// Searches the current screen for a matching image and outputs the center
    /// coordinates as `x y`.
    ///
    /// ```bash
    /// sagui screen locate-center button.png
    /// sagui screen locate-center button.png --confidence 0.9
    /// # Output: 145.0 355.0
    /// ```
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

/// An error type for runtime failures in sagui commands.
struct RuntimeError: Error, CustomStringConvertible {
    let description: String
    init(_ description: String) {
        self.description = description
    }
}
