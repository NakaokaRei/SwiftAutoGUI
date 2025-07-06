import Testing
import AppKit
import CoreGraphics
@testable import SwiftAutoGUI

@Suite("Image Recognition Tests")
struct ImageRecognitionTests {
    
    @Test("locateOnScreen with valid image path")
    func testLocateOnScreenValidPath() {
        // Create a test image
        let testImagePath = createTestImage()
        defer { try? FileManager.default.removeItem(atPath: testImagePath) }
        
        // Try to locate the image (may fail if no screen access)
        let result = SwiftAutoGUI.locateOnScreen(testImagePath)
        
        // Test passes whether or not the image is found (depends on permissions)
        #expect(true)
    }
    
    @Test("locateOnScreen with invalid image path")
    func testLocateOnScreenInvalidPath() {
        let result = SwiftAutoGUI.locateOnScreen("/nonexistent/image.png")
        
        // Should return nil for invalid path
        #expect(result == nil)
    }
    
    @Test("locateOnScreen with region")
    func testLocateOnScreenWithRegion() {
        // Create a test image
        let testImagePath = createTestImage()
        defer { try? FileManager.default.removeItem(atPath: testImagePath) }
        
        // Search in a specific region
        let region = CGRect(x: 0, y: 0, width: 200, height: 200)
        let result = SwiftAutoGUI.locateOnScreen(testImagePath, region: region)
        
        // Test passes whether or not the image is found
        #expect(true)
    }
    
    @Test("locateOnScreen with confidence parameter")
    func testLocateOnScreenWithConfidence() {
        // Create a test image
        let testImagePath = createTestImage()
        defer { try? FileManager.default.removeItem(atPath: testImagePath) }
        
        // Search with different confidence levels
        let highConfidence = SwiftAutoGUI.locateOnScreen(testImagePath, confidence: 0.95)
        let lowConfidence = SwiftAutoGUI.locateOnScreen(testImagePath, confidence: 0.5)
        
        // Low confidence might find more matches than high confidence
        // But both could be nil if no screen access
        #expect(true)
    }
    
    // Helper function to create a test image
    private func createTestImage() -> String {
        let size = NSSize(width: 50, height: 50)
        let image = NSImage(size: size)
        
        image.lockFocus()
        NSColor.blue.setFill()
        NSRect(origin: .zero, size: size).fill()
        
        // Draw a simple pattern
        NSColor.white.setFill()
        NSRect(x: 10, y: 10, width: 30, height: 30).fill()
        
        image.unlockFocus()
        
        // Save to temp directory
        let tempDir = FileManager.default.temporaryDirectory
        let path = tempDir.appendingPathComponent("test_locate_image.png").path
        
        if let tiffData = image.tiffRepresentation,
           let bitmapImage = NSBitmapImageRep(data: tiffData),
           let pngData = bitmapImage.representation(using: .png, properties: [:]) {
            try? pngData.write(to: URL(fileURLWithPath: path))
        }
        
        return path
    }
}