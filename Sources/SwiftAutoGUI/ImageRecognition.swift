import Foundation
import AppKit
import Vision
import CoreGraphics

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
    
    /// Find needle image within haystack image using Vision framework
    private static func findImageInImage(
        needle: NSImage,
        haystack: NSImage,
        confidence: Double?,
        searchRegion: CGRect?
    ) -> CGRect? {
        // Convert NSImages to CGImages
        guard let needleCGImage = needle.cgImage(forProposedRect: nil, context: nil, hints: nil),
              let haystackCGImage = haystack.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            print("SwiftAutoGUI: Could not convert images to CGImage")
            return nil
        }
        
        // Create CIImages for Vision framework
        let needleCIImage = CIImage(cgImage: needleCGImage)
        let haystackCIImage = CIImage(cgImage: haystackCGImage)
        
        var foundRect: CGRect?
        
        // Create Vision request
        let request = VNTranslationalImageRegistrationRequest(targetedCIImage: needleCIImage) { request, error in
            if let error = error {
                print("SwiftAutoGUI: Vision request error: \(error)")
                return
            }
            
            guard let observation = request.results?.first as? VNImageTranslationAlignmentObservation else {
                return
            }
            
            // Check confidence if specified
            if let requiredConfidence = confidence {
                if observation.confidence < Float(requiredConfidence) {
                    return
                }
            }
            
            // Calculate the found rectangle
            let transform = observation.alignmentTransform
            let needleSize = needleCIImage.extent.size
            let haystackSize = haystackCIImage.extent.size
            
            // Apply transform to find the location
            var rect = CGRect(origin: .zero, size: needleSize)
            rect = rect.applying(transform)
            
            print("SwiftAutoGUI: Vision raw transform: \(transform)")
            print("SwiftAutoGUI: Vision raw rect after transform: \(rect)")
            print("SwiftAutoGUI: Haystack size: \(haystackSize)")
            
            // VNTranslationalImageRegistrationRequest returns the translation in pixels
            // Vision framework appears to return negative y values when matching images
            // We need to convert this to proper screen coordinates
            rect.origin.x = transform.tx
            
            // If ty is negative, it means the distance from the bottom of the screen
            if transform.ty < 0 {
                rect.origin.y = haystackSize.height + transform.ty - needleSize.height
            } else {
                rect.origin.y = haystackSize.height - transform.ty - needleSize.height
            }
            rect.size = needleSize
            
            print("SwiftAutoGUI: Vision adjusted rect: \(rect)")
            
            // Adjust coordinates if we were searching in a region
            if let region = searchRegion {
                rect.origin.x += region.origin.x
                rect.origin.y += region.origin.y
            }
            
            foundRect = rect
        }
        
        // Perform the image recognition
        let handler = VNImageRequestHandler(ciImage: haystackCIImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            print("SwiftAutoGUI: Failed to perform image recognition: \(error)")
            return nil
        }
        
        // If Vision approach didn't work, try template matching
        if foundRect == nil {
            foundRect = templateMatch(needle: needleCGImage, haystack: haystackCGImage, confidence: confidence, searchRegion: searchRegion)
        }
        
        return foundRect
    }
    
    /// Perform template matching using pixel comparison (fallback)
    private static func templateMatch(
        needle: CGImage,
        haystack: CGImage,
        confidence: Double?,
        searchRegion: CGRect?
    ) -> CGRect? {
        let needleWidth = needle.width
        let needleHeight = needle.height
        let haystackWidth = haystack.width
        let haystackHeight = haystack.height
        
        // Simple template matching by comparing pixels
        // This is a basic implementation - could be optimized with Core Image filters
        
        // Create bitmap contexts
        guard let needleContext = createBitmapContext(for: needle),
              let haystackContext = createBitmapContext(for: haystack),
              let needleData = needleContext.data,
              let haystackData = haystackContext.data else {
            return nil
        }
        
        // Draw images into contexts
        needleContext.draw(needle, in: CGRect(x: 0, y: 0, width: needleWidth, height: needleHeight))
        haystackContext.draw(haystack, in: CGRect(x: 0, y: 0, width: haystackWidth, height: haystackHeight))
        
        let needlePixels = needleData.bindMemory(to: UInt8.self, capacity: needleWidth * needleHeight * 4)
        let haystackPixels = haystackData.bindMemory(to: UInt8.self, capacity: haystackWidth * haystackHeight * 4)
        
        var bestMatch: (x: Int, y: Int, score: Double) = (0, 0, 0)
        
        // Search area
        let searchStartX = searchRegion != nil ? Int(searchRegion!.origin.x) : 0
        let searchStartY = searchRegion != nil ? Int(searchRegion!.origin.y) : 0
        let searchEndX = searchRegion != nil ? Int(searchRegion!.origin.x + searchRegion!.width) : haystackWidth - needleWidth
        let searchEndY = searchRegion != nil ? Int(searchRegion!.origin.y + searchRegion!.height) : haystackHeight - needleHeight
        
        // Slide the needle over the haystack
        let step = confidence != nil && confidence! < 0.9 ? 2 : 1  // Skip pixels for lower confidence
        
        for y in stride(from: searchStartY, to: min(searchEndY, haystackHeight - needleHeight) + 1, by: step) {
            for x in stride(from: searchStartX, to: min(searchEndX, haystackWidth - needleWidth) + 1, by: step) {
                let score = compareImages(
                    needlePixels: needlePixels,
                    haystackPixels: haystackPixels,
                    needleWidth: needleWidth,
                    needleHeight: needleHeight,
                    haystackWidth: haystackWidth,
                    offsetX: x,
                    offsetY: y
                )
                
                if score > bestMatch.score {
                    bestMatch = (x, y, score)
                    
                    // Early exit if we found a perfect match
                    if score >= 0.99 {
                        break
                    }
                }
            }
            
            // Early exit from outer loop if perfect match found
            if bestMatch.score >= 0.99 {
                break
            }
        }
        
        // Check if match meets confidence threshold
        let threshold = confidence ?? 0.95  // Default to 95% match
        
        print("SwiftAutoGUI: Template matching - best score: \(bestMatch.score) at (\(bestMatch.x), \(bestMatch.y)), threshold: \(threshold)")
        
        if bestMatch.score >= threshold {
            // CGWindowListCreateImage uses top-left origin, same as CGDisplayMoveCursorToPoint
            // No coordinate transformation needed
            let rect = CGRect(x: bestMatch.x, y: bestMatch.y, width: needleWidth, height: needleHeight)
            print("SwiftAutoGUI: Template matching found image at: \(rect)")
            return rect
        }
        
        return nil
    }
    
    /// Create a bitmap context for an image
    private static func createBitmapContext(for image: CGImage) -> CGContext? {
        let width = image.width
        let height = image.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        
        return CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        )
    }
    
    /// Compare needle image with a region of haystack image
    private static func compareImages(
        needlePixels: UnsafeMutablePointer<UInt8>,
        haystackPixels: UnsafeMutablePointer<UInt8>,
        needleWidth: Int,
        needleHeight: Int,
        haystackWidth: Int,
        offsetX: Int,
        offsetY: Int
    ) -> Double {
        var matchCount = 0
        let totalPixels = needleWidth * needleHeight
        let tolerance: UInt8 = 5  // Allow slight color differences
        
        for y in 0..<needleHeight {
            for x in 0..<needleWidth {
                let needleIndex = (y * needleWidth + x) * 4
                let haystackIndex = ((y + offsetY) * haystackWidth + (x + offsetX)) * 4
                
                // Compare RGBA values
                let rDiff = abs(Int(needlePixels[needleIndex]) - Int(haystackPixels[haystackIndex]))
                let gDiff = abs(Int(needlePixels[needleIndex + 1]) - Int(haystackPixels[haystackIndex + 1]))
                let bDiff = abs(Int(needlePixels[needleIndex + 2]) - Int(haystackPixels[haystackIndex + 2]))
                
                if rDiff <= tolerance && gDiff <= tolerance && bDiff <= tolerance {
                    matchCount += 1
                }
            }
        }
        
        return Double(matchCount) / Double(totalPixels)
    }
}