import Foundation
import AppKit
import CoreGraphics
import opencv2

extension SwiftAutoGUI {
    
    // MARK: Image Recognition
    
    /// Locate an image on the screen and return its position
    ///
    /// - Parameters:
    ///   - imagePath: Path to the image file to search for
    ///   - grayscale: Convert to grayscale for faster matching (currently ignored, for future implementation)
    ///   - confidence: Matching confidence threshold (0.0-1.0). If nil, uses exact matching (0.95 by default)
    ///   - region: Limit search to specific screen region. If nil, searches entire screen
    /// - Returns: CGRect with location (x, y, width, height) if found, nil otherwise
    ///
    /// This method uses OpenCV's template matching algorithm to find images on the screen with high accuracy,
    /// similar to PyAutoGUI. The confidence parameter allows for fuzzy matching where 1.0 means exact match
    /// and lower values allow for slight differences.
    ///
    /// The method properly handles Retina displays by converting pixel coordinates to points.
    ///
    /// Example:
    /// ```swift
    /// // Basic usage
    /// if let buttonRect = SwiftAutoGUI.locateOnScreen("button.png") {
    ///     print("Found at: \(buttonRect)")
    ///     SwiftAutoGUI.move(to: CGPoint(x: buttonRect.midX, y: buttonRect.midY))
    ///     SwiftAutoGUI.leftClick()
    /// }
    ///
    /// // With confidence threshold
    /// if let location = SwiftAutoGUI.locateOnScreen("button.png", confidence: 0.9) {
    ///     // Found with 90% confidence
    /// }
    ///
    /// // Search in specific region for better performance
    /// let searchRegion = CGRect(x: 0, y: 0, width: 500, height: 500)
    /// if let location = SwiftAutoGUI.locateOnScreen("button.png", region: searchRegion) {
    ///     // Found within the specified region
    /// }
    /// ```
    public static func locateOnScreen(
        _ imagePath: String,
        grayscale: Bool = false,
        confidence: Double? = nil,
        region: CGRect? = nil
    ) async throws -> CGRect? {
        // Load the needle image
        guard let needleImage = NSImage(contentsOfFile: imagePath) else {
            print("SwiftAutoGUI: Could not load image from path: \(imagePath)")
            return nil
        }

        // Take screenshot of the region or entire screen
        let screenshot: NSImage?
        if let region = region {
            screenshot = try await self.screenshot(region: region)
        } else {
            screenshot = try await self.screenshot()
        }

        guard let haystackImage = screenshot else {
            print("SwiftAutoGUI: Could not capture screenshot")
            return nil
        }

        // Perform image matching
        return findImageInImage(needle: needleImage, haystack: haystackImage, confidence: confidence, searchRegion: region)
    }
    
    /// Locate an image on the screen and return its center point
    ///
    /// - Parameters:
    ///   - imagePath: Path to the image file to search for
    ///   - grayscale: Convert to grayscale for faster matching (currently ignored, for future implementation)
    ///   - confidence: Matching confidence threshold (0.0-1.0). If nil, uses exact matching (0.95 by default)
    ///   - region: Limit search to specific screen region. If nil, searches entire screen
    /// - Returns: CGPoint with center coordinates if found, nil otherwise
    ///
    /// This is a convenience wrapper around `locateOnScreen()` that returns the center point of the found image
    /// instead of the full rectangle. This is particularly useful when you want to click on the center of
    /// an image.
    ///
    /// Example:
    /// ```swift
    /// // Basic usage - click on the center of a button
    /// if let buttonCenter = SwiftAutoGUI.locateCenterOnScreen("button.png") {
    ///     SwiftAutoGUI.move(to: buttonCenter)
    ///     SwiftAutoGUI.leftClick()
    /// }
    ///
    /// // With confidence threshold
    /// if let center = SwiftAutoGUI.locateCenterOnScreen("button.png", confidence: 0.9) {
    ///     // Found with 90% confidence
    ///     SwiftAutoGUI.move(to: center)
    /// }
    ///
    /// // Search in specific region for better performance
    /// let searchRegion = CGRect(x: 0, y: 0, width: 500, height: 500)
    /// if let center = SwiftAutoGUI.locateCenterOnScreen("button.png", region: searchRegion) {
    ///     // Found within the specified region
    ///     SwiftAutoGUI.leftClick()
    /// }
    /// ```
    public static func locateCenterOnScreen(
        _ imagePath: String,
        grayscale: Bool = false,
        confidence: Double? = nil,
        region: CGRect? = nil
    ) async throws -> CGPoint? {
        // Use locateOnScreen to find the image
        guard let rect = try await locateOnScreen(imagePath, grayscale: grayscale, confidence: confidence, region: region) else {
            return nil
        }

        // Return the center point of the found rectangle
        return CGPoint(x: rect.midX, y: rect.midY)
    }
    
    /// Locate all instances of an image on the screen and return their positions
    ///
    /// - Parameters:
    ///   - imagePath: Path to the image file to search for
    ///   - grayscale: Convert to grayscale for faster matching (currently ignored, for future implementation)
    ///   - confidence: Matching confidence threshold (0.0-1.0). If nil, uses exact matching (0.95 by default)
    ///   - region: Limit search to specific screen region. If nil, searches entire screen
    /// - Returns: Array of CGRect with locations (x, y, width, height) of all found instances, empty array if none found
    ///
    /// This method uses OpenCV's template matching algorithm to find all instances of an image on the screen.
    /// It applies non-maximum suppression to avoid duplicate detections of the same object.
    ///
    /// Example:
    /// ```swift
    /// // Find all buttons on screen
    /// let buttons = SwiftAutoGUI.locateAllOnScreen("button.png")
    /// for (index, button) in buttons.enumerated() {
    ///     print("Button \(index) found at: \(button)")
    ///     SwiftAutoGUI.move(to: CGPoint(x: button.midX, y: button.midY))
    ///     SwiftAutoGUI.leftClick()
    ///     Thread.sleep(forTimeInterval: 0.5)
    /// }
    ///
    /// // Find all matches with confidence threshold
    /// let closeButtons = SwiftAutoGUI.locateAllOnScreen("close_button.png", confidence: 0.85)
    /// print("Found \(closeButtons.count) close buttons")
    ///
    /// // Search in specific region for better performance
    /// let searchRegion = CGRect(x: 0, y: 0, width: 800, height: 600)
    /// let icons = SwiftAutoGUI.locateAllOnScreen("icon.png", region: searchRegion)
    /// ```
    public static func locateAllOnScreen(
        _ imagePath: String,
        grayscale: Bool = false,
        confidence: Double? = nil,
        region: CGRect? = nil
    ) async throws -> [CGRect] {
        // Load the needle image
        guard let needleImage = NSImage(contentsOfFile: imagePath) else {
            print("SwiftAutoGUI: Could not load image from path: \(imagePath)")
            return []
        }

        // Take screenshot of the region or entire screen
        let screenshot: NSImage?
        if let region = region {
            screenshot = try await self.screenshot(region: region)
        } else {
            screenshot = try await self.screenshot()
        }

        guard let haystackImage = screenshot else {
            print("SwiftAutoGUI: Could not capture screenshot")
            return []
        }

        // Perform image matching to find all instances
        return findAllImagesInImage(needle: needleImage, haystack: haystackImage, confidence: confidence, searchRegion: region)
    }
    
    // MARK: Private Helper Methods
    
    /// Find needle image within haystack image using OpenCV template matching
    private static func findImageInImage(
        needle: NSImage,
        haystack: NSImage,
        confidence: Double?,
        searchRegion: CGRect?
    ) -> CGRect? {
        // Use OpenCV for template matching
        // Convert NSImages to OpenCV Mat format
        guard let needleMat = needle.toMat(),
              let haystackMat = haystack.toMat() else {
            print("SwiftAutoGUI: Could not convert images to OpenCV Mat")
            return nil
        }
        
        // Apply search region if specified
        let searchMat: Mat
        let regionOffset: CGPoint
        
        if let region = searchRegion {
            let rect = Rect2i(
                x: Int32(region.origin.x),
                y: Int32(region.origin.y),
                width: Int32(region.width),
                height: Int32(region.height)
            )
            searchMat = Mat(mat: haystackMat, rect: rect)
            regionOffset = region.origin
        } else {
            searchMat = haystackMat
            regionOffset = .zero
        }
        
        // Perform template matching using OpenCV
        let result = Mat()
        Imgproc.matchTemplate(
            image: searchMat,
            templ: needleMat,
            result: result,
            method: TemplateMatchModes.TM_CCOEFF_NORMED  // Normalized correlation coefficient
        )
        
        // Find the best match
        let minMaxResult = Core.minMaxLoc(result)
        let maxVal = minMaxResult.maxVal
        let maxLoc = minMaxResult.maxLoc
        
        let threshold = confidence ?? 0.95
        print("SwiftAutoGUI: OpenCV template matching - best score: \(maxVal) at (\(maxLoc.x), \(maxLoc.y)), threshold: \(threshold)")
        
        if maxVal >= threshold {
            // Get screen scale factor
            let screen = NSScreen.main ?? NSScreen.screens[0]
            let scaleFactor = screen.backingScaleFactor
            
            print("SwiftAutoGUI: Screen scale factor: \(scaleFactor)")
            print("SwiftAutoGUI: Needle size: \(needleMat.cols())x\(needleMat.rows())")
            print("SwiftAutoGUI: Haystack size: \(haystackMat.cols())x\(haystackMat.rows())")
            
            // Convert OpenCV coordinates to CGRect
            // OpenCV works with actual pixels, we need to convert to points for macOS
            let pixelRect = CGRect(
                x: CGFloat(maxLoc.x) + regionOffset.x,
                y: CGFloat(maxLoc.y) + regionOffset.y,
                width: CGFloat(needleMat.cols()),
                height: CGFloat(needleMat.rows())
            )
            
            // Convert from pixels to points (logical coordinates)
            let pointRect = CGRect(
                x: pixelRect.origin.x / scaleFactor,
                y: pixelRect.origin.y / scaleFactor,
                width: pixelRect.width / scaleFactor,
                height: pixelRect.height / scaleFactor
            )
            
            print("SwiftAutoGUI: OpenCV found image at pixels: \(pixelRect), points: \(pointRect)")
            return pointRect
        }
        
        return nil
    }
    
    /// Find all instances of needle image within haystack image using OpenCV template matching
    private static func findAllImagesInImage(
        needle: NSImage,
        haystack: NSImage,
        confidence: Double?,
        searchRegion: CGRect?
    ) -> [CGRect] {
        // Convert NSImages to OpenCV Mat format
        guard let needleMat = needle.toMat(),
              let haystackMat = haystack.toMat() else {
            print("SwiftAutoGUI: Could not convert images to OpenCV Mat")
            return []
        }
        
        // Apply search region if specified
        let searchMat: Mat
        let regionOffset: CGPoint
        
        if let region = searchRegion {
            let rect = Rect2i(
                x: Int32(region.origin.x),
                y: Int32(region.origin.y),
                width: Int32(region.width),
                height: Int32(region.height)
            )
            searchMat = Mat(mat: haystackMat, rect: rect)
            regionOffset = region.origin
        } else {
            searchMat = haystackMat
            regionOffset = .zero
        }
        
        // Perform template matching using OpenCV
        let result = Mat()
        Imgproc.matchTemplate(
            image: searchMat,
            templ: needleMat,
            result: result,
            method: TemplateMatchModes.TM_CCOEFF_NORMED  // Normalized correlation coefficient
        )
        
        let threshold = confidence ?? 0.95
        var matches: [CGRect] = []
        
        // Get screen scale factor
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let scaleFactor = screen.backingScaleFactor
        
        // Find all matches above threshold
        var resultData = [Float](repeating: 0, count: Int(result.rows() * result.cols()))
        _ = try? result.get(row: 0, col: 0, data: &resultData)
        
        let templateWidth = needleMat.cols()
        let templateHeight = needleMat.rows()
        
        // Create a copy of result to track which areas we've already processed
        var processedMask = Array(repeating: false, count: resultData.count)
        
        while true {
            // Find the maximum value and its location
            var maxVal: Float = -1
            var maxIdx = -1
            
            for i in 0..<resultData.count {
                if !processedMask[i] && resultData[i] > maxVal {
                    maxVal = resultData[i]
                    maxIdx = i
                }
            }
            
            // If no more matches above threshold, break
            if maxVal < Float(threshold) || maxIdx == -1 {
                break
            }
            
            // Calculate coordinates from the index
            let y = maxIdx / Int(result.cols())
            let x = maxIdx % Int(result.cols())
            
            // Convert OpenCV coordinates to CGRect
            let pixelRect = CGRect(
                x: CGFloat(x) + regionOffset.x,
                y: CGFloat(y) + regionOffset.y,
                width: CGFloat(templateWidth),
                height: CGFloat(templateHeight)
            )
            
            // Convert from pixels to points (logical coordinates)
            let pointRect = CGRect(
                x: pixelRect.origin.x / scaleFactor,
                y: pixelRect.origin.y / scaleFactor,
                width: pixelRect.width / scaleFactor,
                height: pixelRect.height / scaleFactor
            )
            
            matches.append(pointRect)
            
            // Apply non-maximum suppression: mark nearby pixels as processed
            // to avoid detecting the same object multiple times
            let suppressionRadius = min(templateWidth, templateHeight) / 2
            
            for dy in -suppressionRadius...suppressionRadius {
                for dx in -suppressionRadius...suppressionRadius {
                    let ny = y + Int(dy)
                    let nx = x + Int(dx)
                    
                    if ny >= 0 && ny < Int(result.rows()) && nx >= 0 && nx < Int(result.cols()) {
                        let idx = ny * Int(result.cols()) + nx
                        processedMask[idx] = true
                    }
                }
            }
        }
        
        print("SwiftAutoGUI: Found \(matches.count) matches with confidence >= \(threshold)")
        return matches
    }
}

// MARK: - NSImage to OpenCV Mat conversion
extension NSImage {
    func toMat() -> Mat? {
        guard let cgImage = self.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }
        
        let width = cgImage.width
        let height = cgImage.height
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        
        var rawData = [UInt8](repeating: 0, count: height * bytesPerRow)
        
        guard let context = CGContext(
            data: &rawData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        // Create OpenCV Mat from the raw pixel data
        let mat = Mat(rows: Int32(height), cols: Int32(width), type: CvType.CV_8UC4)
        _ = try? mat.put(row: 0, col: 0, data: rawData)
        
        // Convert RGBA to BGR (OpenCV's default color format)
        let bgrMat = Mat()
        Imgproc.cvtColor(src: mat, dst: bgrMat, code: ColorConversionCodes.COLOR_RGBA2BGR)
        
        return bgrMat
    }
}