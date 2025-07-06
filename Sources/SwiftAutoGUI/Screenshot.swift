import Foundation
import AppKit
import CoreGraphics

extension SwiftAutoGUI {
    
    // MARK: Screenshot Functions
    
    /// Take a screenshot of the entire screen
    ///
    /// - Returns: NSImage containing the screenshot, or nil if failed
    ///
    /// Example:
    /// ```swift
    /// if let screenshot = SwiftAutoGUI.screenshot() {
    ///     // Use the screenshot image
    /// }
    /// ```
    public static func screenshot() -> NSImage? {
        guard let screen = NSScreen.main else { return nil }
        let screenRect = screen.frame
        
        guard let cgImage = CGWindowListCreateImage(
            screenRect,
            .optionOnScreenOnly,
            kCGNullWindowID,
            .bestResolution
        ) else {
            return nil
        }
        
        let size = NSSize(width: cgImage.width, height: cgImage.height)
        return NSImage(cgImage: cgImage, size: size)
    }
    
    /// Take a screenshot of a specific region
    ///
    /// - Parameter region: The region to capture as CGRect
    /// - Returns: NSImage containing the screenshot of the region, or nil if failed
    ///
    /// Example:
    /// ```swift
    /// let region = CGRect(x: 100, y: 100, width: 200, height: 200)
    /// if let screenshot = SwiftAutoGUI.screenshot(region: region) {
    ///     // Use the screenshot image
    /// }
    /// ```
    public static func screenshot(region: CGRect) -> NSImage? {
        guard let cgImage = CGWindowListCreateImage(
            region,
            .optionOnScreenOnly,
            kCGNullWindowID,
            .bestResolution
        ) else {
            return nil
        }
        
        let size = NSSize(width: cgImage.width, height: cgImage.height)
        return NSImage(cgImage: cgImage, size: size)
    }
    
    /// Take a screenshot and save it to a file
    ///
    /// - Parameters:
    ///   - imageFilename: The path where to save the screenshot
    ///   - region: Optional region to capture. If nil, captures entire screen
    /// - Returns: True if successfully saved, false otherwise
    ///
    /// Example:
    /// ```swift
    /// // Save full screenshot
    /// SwiftAutoGUI.screenshot(imageFilename: "screenshot.png")
    /// 
    /// // Save region screenshot
    /// let region = CGRect(x: 0, y: 0, width: 500, height: 500)
    /// SwiftAutoGUI.screenshot(imageFilename: "region.png", region: region)
    /// ```
    @discardableResult
    public static func screenshot(imageFilename: String, region: CGRect? = nil) -> Bool {
        let image: NSImage?
        
        if let region = region {
            image = screenshot(region: region)
        } else {
            image = screenshot()
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
    ///
    /// Example:
    /// ```swift
    /// if let color = SwiftAutoGUI.pixel(x: 100, y: 200) {
    ///     print("Pixel color: \(color)")
    /// }
    /// ```
    public static func pixel(x: Int, y: Int) -> NSColor? {
        let rect = CGRect(x: x, y: y, width: 1, height: 1)
        
        guard let cgImage = CGWindowListCreateImage(
            rect,
            .optionOnScreenOnly,
            kCGNullWindowID,
            .bestResolution
        ) else {
            return nil
        }
        
        let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: 1, height: 1))
        
        guard let tiffData = nsImage.tiffRepresentation,
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