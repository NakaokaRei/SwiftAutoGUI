import Foundation
import AppKit
import CoreGraphics
import ScreenCaptureKit

extension SwiftAutoGUI {

    // MARK: Screenshot Functions

    /// Take a screenshot of the entire screen
    ///
    /// - Returns: NSImage containing the screenshot, or nil if failed
    /// - Throws: ScreenCaptureKit errors if capture fails
    ///
    /// Example:
    /// ```swift
    /// do {
    ///     if let screenshot = try await SwiftAutoGUI.screenshot() {
    ///         // Use the screenshot image
    ///     }
    /// } catch {
    ///     print("Screenshot failed: \(error)")
    /// }
    /// ```
    public static func screenshot() async throws -> NSImage? {
        guard let screen = NSScreen.main else { return nil }

        // Get shareable content
        let content = try await SCShareableContent.current

        // Find the main display
        guard let display = content.displays.first else { return nil }

        // Create content filter for the display
        let filter = SCContentFilter(display: display, excludingWindows: [])

        // Create configuration
        let config = SCStreamConfiguration()
        // display.width and display.height are in logical points, convert to pixels
        config.width = Int(CGFloat(display.width) * screen.backingScaleFactor)
        config.height = Int(CGFloat(display.height) * screen.backingScaleFactor)
        config.scalesToFit = false
        config.showsCursor = false

        // Capture the screenshot
        let cgImage = try await SCScreenshotManager.captureImage(
            contentFilter: filter,
            configuration: config
        )

        // Convert to NSImage with proper size
        let scaleFactor = screen.backingScaleFactor
        let size = NSSize(
            width: CGFloat(cgImage.width) / scaleFactor,
            height: CGFloat(cgImage.height) / scaleFactor
        )

        return NSImage(cgImage: cgImage, size: size)
    }

    /// Take a screenshot of a specific region
    ///
    /// - Parameter region: The region to capture as CGRect
    /// - Returns: NSImage containing the screenshot of the region, or nil if failed
    /// - Throws: ScreenCaptureKit errors if capture fails
    ///
    /// Example:
    /// ```swift
    /// let region = CGRect(x: 100, y: 100, width: 200, height: 200)
    /// do {
    ///     if let screenshot = try await SwiftAutoGUI.screenshot(region: region) {
    ///         // Use the screenshot image
    ///     }
    /// } catch {
    ///     print("Screenshot failed: \(error)")
    /// }
    /// ```
    public static func screenshot(region: CGRect) async throws -> NSImage? {
        guard let screen = NSScreen.main else { return nil }

        // Get shareable content
        let content = try await SCShareableContent.current

        // Find the main display
        guard let display = content.displays.first else { return nil }

        // Create content filter for the display
        let filter = SCContentFilter(display: display, excludingWindows: [])

        // Create configuration
        let config = SCStreamConfiguration()
        config.width = Int(region.width * screen.backingScaleFactor)
        config.height = Int(region.height * screen.backingScaleFactor)
        config.sourceRect = region
        config.scalesToFit = false
        config.showsCursor = false

        // Capture the screenshot
        let cgImage = try await SCScreenshotManager.captureImage(
            contentFilter: filter,
            configuration: config
        )

        // Convert to NSImage with proper size
        let scaleFactor = screen.backingScaleFactor
        let size = NSSize(
            width: CGFloat(cgImage.width) / scaleFactor,
            height: CGFloat(cgImage.height) / scaleFactor
        )

        return NSImage(cgImage: cgImage, size: size)
    }

    /// Take a screenshot and save it to a file
    ///
    /// - Parameters:
    ///   - imageFilename: The path where to save the screenshot
    ///   - region: Optional region to capture. If nil, captures entire screen
    /// - Returns: True if successfully saved, false otherwise
    /// - Throws: ScreenCaptureKit errors if capture fails
    ///
    /// Example:
    /// ```swift
    /// do {
    ///     // Save full screenshot
    ///     try await SwiftAutoGUI.screenshot(imageFilename: "screenshot.png")
    ///
    ///     // Save region screenshot
    ///     let region = CGRect(x: 0, y: 0, width: 500, height: 500)
    ///     try await SwiftAutoGUI.screenshot(imageFilename: "region.png", region: region)
    /// } catch {
    ///     print("Screenshot failed: \(error)")
    /// }
    /// ```
    @discardableResult
    public static func screenshot(imageFilename: String, region: CGRect? = nil) async throws -> Bool {
        let image: NSImage?

        if let region = region {
            image = try await screenshot(region: region)
        } else {
            image = try await screenshot()
        }

        guard let screenshotImage = image else { return false }

        return saveImage(screenshotImage, to: imageFilename)
    }

    /// Get the size of the main screen
    ///
    /// - Returns: A tuple containing (width, height) of the main screen
    ///
    /// Example:
    /// ```swift
    /// let (width, height) = SwiftAutoGUI.size()
    /// print("Screen size: \(width)x\(height)")
    /// ```
    public static func size() -> (width: CGFloat, height: CGFloat) {
        guard let screen = NSScreen.main else { return (0, 0) }
        let frame = screen.frame
        return (frame.width, frame.height)
    }

    /// Get the color of a pixel at the specified coordinates
    ///
    /// - Parameters:
    ///   - x: The x coordinate
    ///   - y: The y coordinate
    /// - Returns: NSColor of the pixel at the specified coordinates, or nil if failed
    /// - Throws: ScreenCaptureKit errors if capture fails
    ///
    /// Example:
    /// ```swift
    /// do {
    ///     if let color = try await SwiftAutoGUI.pixel(x: 100, y: 200) {
    ///         print("Pixel color: \(color)")
    ///     }
    /// } catch {
    ///     print("Pixel capture failed: \(error)")
    /// }
    /// ```
    public static func pixel(x: Int, y: Int) async throws -> NSColor? {
        let rect = CGRect(x: x, y: y, width: 1, height: 1)

        guard let image = try await screenshot(region: rect) else {
            return nil
        }

        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            return nil
        }

        return bitmap.colorAt(x: 0, y: 0)
    }

    // MARK: Private Helper Functions

    /// Save an NSImage to a file
    private static func saveImage(_ image: NSImage, to path: String) -> Bool {
        guard let tiffData = image.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData) else {
            return false
        }

        let url = URL(fileURLWithPath: path)
        let fileType: NSBitmapImageRep.FileType

        switch url.pathExtension.lowercased() {
        case "png":
            fileType = .png
        case "jpg", "jpeg":
            fileType = .jpeg
        case "gif":
            fileType = .gif
        case "bmp":
            fileType = .bmp
        case "tiff", "tif":
            fileType = .tiff
        default:
            fileType = .png
        }

        guard let data = bitmapImage.representation(using: fileType, properties: [:]) else {
            return false
        }

        do {
            try data.write(to: url)
            return true
        } catch {
            return false
        }
    }
}
