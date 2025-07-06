import Foundation
import AppKit
import CoreGraphics
import Vision

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
    
    /// Find image using Vision framework with feature detection
    private static func findImageUsingVision(
        needle: CGImage,
        haystack: CGImage,
        confidence: Double?,
        searchRegion: CGRect?
    ) -> CGRect? {
        // For Vision framework, we'll use a different approach:
        // 1. Extract distinctive features from the needle image
        // 2. Find those features in the haystack
        // 3. Calculate the best matching region
        
        let needleWidth = needle.width
        let needleHeight = needle.height
        let haystackWidth = haystack.width
        let haystackHeight = haystack.height
        
        // If needle is too large compared to haystack, it won't be found
        if needleWidth > haystackWidth || needleHeight > haystackHeight {
            return nil
        }
        
        // Use Core Image context for optimized processing
        let context = CIContext(options: [.useSoftwareRenderer: false])
        
        // For now, fall back to our optimized template matching
        // Vision framework doesn't have direct template matching, but we can optimize our approach
        return optimizedTemplateMatch(
            needle: needle,
            haystack: haystack,
            confidence: confidence,
            searchRegion: searchRegion,
            context: context
        )
    }
    
    /// Optimized template matching using Core Image for preprocessing
    private static func optimizedTemplateMatch(
        needle: CGImage,
        haystack: CGImage,
        confidence: Double?,
        searchRegion: CGRect?,
        context: CIContext
    ) -> CGRect? {
        let needleWidth = needle.width
        let needleHeight = needle.height
        let haystackWidth = haystack.width
        let haystackHeight = haystack.height
        
        // Create buffers
        let needleSize = needleWidth * needleHeight * 4
        let haystackSize = haystackWidth * haystackHeight * 4
        
        var needleBuffer = [UInt8](repeating: 0, count: needleSize)
        var haystackBuffer = [UInt8](repeating: 0, count: haystackSize)
        
        // Get pixel data
        guard let needleData = needle.dataProvider?.data,
              let haystackData = haystack.dataProvider?.data else { return nil }
        
        CFDataGetBytes(needleData, CFRange(location: 0, length: needleSize), &needleBuffer)
        CFDataGetBytes(haystackData, CFRange(location: 0, length: haystackSize), &haystackBuffer)
        
        // Define search boundaries
        let searchStartX = searchRegion != nil ? Int(searchRegion!.origin.x) : 0
        let searchStartY = searchRegion != nil ? Int(searchRegion!.origin.y) : 0
        let searchEndX = searchRegion != nil ? Int(searchRegion!.origin.x + searchRegion!.width - CGFloat(needleWidth)) : haystackWidth - needleWidth
        let searchEndY = searchRegion != nil ? Int(searchRegion!.origin.y + searchRegion!.height - CGFloat(needleHeight)) : haystackHeight - needleHeight
        
        // Multi-scale search for better performance
        let scales: [Int] = confidence != nil && confidence! < 0.9 ? [4, 2, 1] : [2, 1]
        
        for scale in scales {
            if let match = searchAtScale(
                needleBuffer: needleBuffer,
                haystackBuffer: haystackBuffer,
                needleWidth: needleWidth,
                needleHeight: needleHeight,
                haystackWidth: haystackWidth,
                haystackHeight: haystackHeight,
                searchStartX: searchStartX,
                searchStartY: searchStartY,
                searchEndX: searchEndX,
                searchEndY: searchEndY,
                scale: scale,
                confidence: confidence
            ) {
                print("SwiftAutoGUI: Found image at: \(match)")
                return match
            }
        }
        
        return nil
    }
    
    /// Search at a specific scale for multi-resolution matching
    private static func searchAtScale(
        needleBuffer: [UInt8],
        haystackBuffer: [UInt8],
        needleWidth: Int,
        needleHeight: Int,
        haystackWidth: Int,
        haystackHeight: Int,
        searchStartX: Int,
        searchStartY: Int,
        searchEndX: Int,
        searchEndY: Int,
        scale: Int,
        confidence: Double?
    ) -> CGRect? {
        let threshold = confidence ?? 0.95
        var bestMatch: (x: Int, y: Int, score: Double) = (0, 0, 0)
        
        // Coarse search with larger steps
        for y in stride(from: searchStartY, to: searchEndY, by: scale) {
            for x in stride(from: searchStartX, to: searchEndX, by: scale) {
                let score = quickCompare(
                    needleBuffer: needleBuffer,
                    haystackBuffer: haystackBuffer,
                    needleWidth: needleWidth,
                    needleHeight: needleHeight,
                    haystackWidth: haystackWidth,
                    x: x,
                    y: y,
                    sampleRate: scale
                )
                
                if score > bestMatch.score {
                    bestMatch = (x, y, score)
                }
                
                // Early exit if we found a very good match
                if score > 0.99 {
                    return CGRect(x: x, y: y, width: needleWidth, height: needleHeight)
                }
            }
        }
        
        // If we found a promising match, refine it
        if bestMatch.score > threshold * 0.9 && scale > 1 {
            // Fine search around the best match
            let fineSearchRange = scale * 2
            let fineStartX = max(searchStartX, bestMatch.x - fineSearchRange)
            let fineEndX = min(searchEndX, bestMatch.x + fineSearchRange)
            let fineStartY = max(searchStartY, bestMatch.y - fineSearchRange)
            let fineEndY = min(searchEndY, bestMatch.y + fineSearchRange)
            
            for y in fineStartY...fineEndY {
                for x in fineStartX...fineEndX {
                    let score = quickCompare(
                        needleBuffer: needleBuffer,
                        haystackBuffer: haystackBuffer,
                        needleWidth: needleWidth,
                        needleHeight: needleHeight,
                        haystackWidth: haystackWidth,
                        x: x,
                        y: y,
                        sampleRate: 1
                    )
                    
                    if score > bestMatch.score {
                        bestMatch = (x, y, score)
                    }
                }
            }
        }
        
        if bestMatch.score >= threshold {
            return CGRect(x: bestMatch.x, y: bestMatch.y, width: needleWidth, height: needleHeight)
        }
        
        return nil
    }
    
    /// Quick comparison using sampling for performance
    private static func quickCompare(
        needleBuffer: [UInt8],
        haystackBuffer: [UInt8],
        needleWidth: Int,
        needleHeight: Int,
        haystackWidth: Int,
        x: Int,
        y: Int,
        sampleRate: Int
    ) -> Double {
        var matchCount = 0
        var totalSamples = 0
        let tolerance: Int = 10  // Color tolerance
        
        // Sample pixels at regular intervals
        for sy in stride(from: 0, to: needleHeight, by: sampleRate) {
            for sx in stride(from: 0, to: needleWidth, by: sampleRate) {
                let needleIndex = (sy * needleWidth + sx) * 4
                let haystackIndex = ((y + sy) * haystackWidth + (x + sx)) * 4
                
                // Compare RGB values (ignore alpha)
                let rDiff = abs(Int(needleBuffer[needleIndex]) - Int(haystackBuffer[haystackIndex]))
                let gDiff = abs(Int(needleBuffer[needleIndex + 1]) - Int(haystackBuffer[haystackIndex + 1]))
                let bDiff = abs(Int(needleBuffer[needleIndex + 2]) - Int(haystackBuffer[haystackIndex + 2]))
                
                if rDiff <= tolerance && gDiff <= tolerance && bDiff <= tolerance {
                    matchCount += 1
                }
                totalSamples += 1
            }
        }
        
        return totalSamples > 0 ? Double(matchCount) / Double(totalSamples) : 0
    }
    
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
        
        // Use Vision framework for image recognition
        return findImageUsingVision(needle: needleCGImage, haystack: haystackCGImage, confidence: confidence, searchRegion: searchRegion)
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
        for y in searchStartY...min(searchEndY, haystackHeight - needleHeight) {
            for x in searchStartX...min(searchEndX, haystackWidth - needleWidth) {
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
                }
            }
        }
        
        // Check if match meets confidence threshold
        let threshold = confidence ?? 0.95  // Default to 95% match
        
        print("SwiftAutoGUI: Template matching - best score: \(bestMatch.score) at (\(bestMatch.x), \(bestMatch.y)), threshold: \(threshold)")
        
        if bestMatch.score >= threshold {
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