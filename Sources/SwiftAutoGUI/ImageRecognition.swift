import Foundation
import AppKit
import CoreGraphics
import opencv2

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

extension SwiftAutoGUI {
    
    // MARK: Image Recognition
    
    /// Locate an image on the screen and return its position
    ///
    /// - Parameters:
    ///   - imagePath: Path to the image file to search for
    ///   - grayscale: Convert to grayscale for faster matching (currently ignored, for future implementation)
    ///   - confidence: Matching confidence threshold (0.0-1.0). If nil, uses exact matching
    ///   - region: Limit search to specific screen region. If nil, searches entire screen
    /// - Returns: CGRect with location (x, y, width, height) if found, nil otherwise
    ///
    /// Example:
    /// ```swift
    /// if let buttonRect = SwiftAutoGUI.locateOnScreen("button.png") {
    ///     print("Found at: \(buttonRect)")
    ///     SwiftAutoGUI.click(x: buttonRect.midX, y: buttonRect.midY)
    /// }
    /// ```
    public static func locateOnScreen(
        _ imagePath: String,
        grayscale: Bool = false,
        confidence: Double? = nil,
        region: CGRect? = nil
    ) -> CGRect? {
        // Load the needle image
        guard let needleImage = NSImage(contentsOfFile: imagePath) else {
            print("SwiftAutoGUI: Could not load image from path: \(imagePath)")
            return nil
        }
        
        // Take screenshot of the region or entire screen
        let screenshot: NSImage?
        if let region = region {
            screenshot = self.screenshot(region: region)
        } else {
            screenshot = self.screenshot()
        }
        
        guard let haystackImage = screenshot else {
            print("SwiftAutoGUI: Could not capture screenshot")
            return nil
        }
        
        // Perform image matching
        return findImageInImage(needle: needleImage, haystack: haystackImage, confidence: confidence, searchRegion: region)
    }
    
    // MARK: Private Helper Methods
    
    /// Find needle image within haystack image using OpenCV template matching
    private static func findImageInImage(
        needle: NSImage,
        haystack: NSImage,
        confidence: Double?,
        searchRegion: CGRect?
    ) -> CGRect? {
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
            // Convert OpenCV coordinates to CGRect
            let rect = CGRect(
                x: CGFloat(maxLoc.x) + regionOffset.x,
                y: CGFloat(maxLoc.y) + regionOffset.y,
                width: CGFloat(needleMat.cols()),
                height: CGFloat(needleMat.rows())
            )
            print("SwiftAutoGUI: OpenCV found image at: \(rect)")
            return rect
        }
        
        return nil
    }
}