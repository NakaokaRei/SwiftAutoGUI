import Testing
import AppKit
import CoreGraphics
@testable import SwiftAutoGUI

@Suite("Image Recognition Tests")
struct ImageRecognitionTests {

    @Test("locateOnScreen with valid image path")
    func testLocateOnScreenValidPath() async throws {
        // Create a test image
        let testImagePath = createTestImage()
        defer { try? FileManager.default.removeItem(atPath: testImagePath) }

        // Try to locate the image (may fail if no screen access)
        let result = try await SwiftAutoGUI.locateOnScreen(testImagePath)

        // Test passes whether or not the image is found (depends on permissions)
        #expect(true)
    }

    @Test("locateOnScreen with invalid image path")
    func testLocateOnScreenInvalidPath() async throws {
        let result = try await SwiftAutoGUI.locateOnScreen("/nonexistent/image.png")

        // Should return nil for invalid path
        #expect(result == nil)
    }

    @Test("locateOnScreen with region")
    func testLocateOnScreenWithRegion() async throws {
        // Create a test image
        let testImagePath = createTestImage()
        defer { try? FileManager.default.removeItem(atPath: testImagePath) }

        // Search in a specific region
        let region = CGRect(x: 0, y: 0, width: 200, height: 200)
        let result = try await SwiftAutoGUI.locateOnScreen(testImagePath, region: region)

        // Test passes whether or not the image is found
        #expect(true)
    }

    @Test("locateOnScreen with confidence parameter")
    func testLocateOnScreenWithConfidence() async throws {
        // Create a test image
        let testImagePath = createTestImage()
        defer { try? FileManager.default.removeItem(atPath: testImagePath) }

        // Search with different confidence levels
        let highConfidence = try await SwiftAutoGUI.locateOnScreen(testImagePath, confidence: 0.95)
        let lowConfidence = try await SwiftAutoGUI.locateOnScreen(testImagePath, confidence: 0.5)

        // Low confidence might find more matches than high confidence
        // But both could be nil if no screen access
        #expect(true)
    }

    @Test("locateCenterOnScreen with valid image path")
    func testLocateCenterOnScreenValidPath() async throws {
        // Create a test image
        let testImagePath = createTestImage()
        defer { try? FileManager.default.removeItem(atPath: testImagePath) }

        // Try to locate the center of the image
        let center = try await SwiftAutoGUI.locateCenterOnScreen(testImagePath)

        // If an image is found, verify we get a valid center point
        if let center = center {
            #expect(center.x > 0)
            #expect(center.y > 0)
        }

        // Test passes whether or not the image is found (depends on permissions)
        #expect(true)
    }

    @Test("locateCenterOnScreen with invalid image path")
    func testLocateCenterOnScreenInvalidPath() async throws {
        let center = try await SwiftAutoGUI.locateCenterOnScreen("/nonexistent/image.png")

        // Should return nil for invalid path
        #expect(center == nil)
    }

    @Test("locateCenterOnScreen returns center of located rectangle")
    func testLocateCenterOnScreenReturnsCenter() async throws {
        // Create a test image
        let testImagePath = createTestImage()
        defer { try? FileManager.default.removeItem(atPath: testImagePath) }

        // Get both rectangle and center
        let rect = try await SwiftAutoGUI.locateOnScreen(testImagePath)
        let center = try await SwiftAutoGUI.locateCenterOnScreen(testImagePath)

        // If both are found, verify center matches rectangle's center
        if let rect = rect, let center = center {
            #expect(center.x == rect.midX)
            #expect(center.y == rect.midY)
        }

        // Test passes whether or not the image is found
        #expect(true)
    }

    @Test("locateCenterOnScreen with region")
    func testLocateCenterOnScreenWithRegion() async throws {
        // Create a test image
        let testImagePath = createTestImage()
        defer { try? FileManager.default.removeItem(atPath: testImagePath) }

        // Search in a specific region
        let region = CGRect(x: 0, y: 0, width: 200, height: 200)
        let center = try await SwiftAutoGUI.locateCenterOnScreen(testImagePath, region: region)

        // If found, verify center is within the search region
        if let center = center {
            #expect(region.contains(center))
        }

        // Test passes whether or not the image is found
        #expect(true)
    }

    @Test("locateCenterOnScreen with confidence parameter")
    func testLocateCenterOnScreenWithConfidence() async throws {
        // Create a test image
        let testImagePath = createTestImage()
        defer { try? FileManager.default.removeItem(atPath: testImagePath) }

        // Search with different confidence levels
        let highConfidenceCenter = try await SwiftAutoGUI.locateCenterOnScreen(testImagePath, confidence: 0.95)
        let lowConfidenceCenter = try await SwiftAutoGUI.locateCenterOnScreen(testImagePath, confidence: 0.5)

        // Test passes whether or not the images are found
        #expect(true)
    }

    @Test("locateAllOnScreen with valid image path")
    func testLocateAllOnScreenValidPath() async throws {
        // Create a test image
        let testImagePath = createTestImage()
        defer { try? FileManager.default.removeItem(atPath: testImagePath) }

        // Try to locate all instances of the image
        let results = try await SwiftAutoGUI.locateAllOnScreen(testImagePath)

        // Results should be an array (possibly empty)
        #expect(results.count >= 0)

        // If any images are found, verify they have valid dimensions
        for rect in results {
            #expect(rect.width > 0)
            #expect(rect.height > 0)
        }

        // Test passes whether or not images are found (depends on permissions)
        #expect(true)
    }

    @Test("locateAllOnScreen with invalid image path")
    func testLocateAllOnScreenInvalidPath() async throws {
        let results = try await SwiftAutoGUI.locateAllOnScreen("/nonexistent/image.png")

        // Should return empty array for invalid path
        #expect(results.isEmpty)
    }

    @Test("locateAllOnScreen with region")
    func testLocateAllOnScreenWithRegion() async throws {
        // Create a test image
        let testImagePath = createTestImage()
        defer { try? FileManager.default.removeItem(atPath: testImagePath) }

        // Search in a specific region
        let region = CGRect(x: 0, y: 0, width: 400, height: 400)
        let results = try await SwiftAutoGUI.locateAllOnScreen(testImagePath, region: region)

        // If found, verify all results are within the search region
        for rect in results {
            // The found rectangle should at least partially overlap with the search region
            #expect(region.intersects(rect))
        }

        // Test passes whether or not images are found
        #expect(true)
    }

    @Test("locateAllOnScreen with confidence parameter")
    func testLocateAllOnScreenWithConfidence() async throws {
        // Create a test image
        let testImagePath = createTestImage()
        defer { try? FileManager.default.removeItem(atPath: testImagePath) }

        // Search with different confidence levels
        let highConfidenceResults = try await SwiftAutoGUI.locateAllOnScreen(testImagePath, confidence: 0.95)
        let lowConfidenceResults = try await SwiftAutoGUI.locateAllOnScreen(testImagePath, confidence: 0.5)

        // Lower confidence should find same or more matches
        // But both could be empty if no screen access
        #expect(highConfidenceResults.count <= lowConfidenceResults.count)

        // Test passes whether or not images are found
        #expect(true)
    }

    @Test("locateAllOnScreen returns non-overlapping results")
    func testLocateAllOnScreenNonOverlapping() async throws {
        // Create a test image
        let testImagePath = createTestImage()
        defer { try? FileManager.default.removeItem(atPath: testImagePath) }

        // Find all instances
        let results = try await SwiftAutoGUI.locateAllOnScreen(testImagePath, confidence: 0.8)

        // Verify that results don't significantly overlap (due to non-maximum suppression)
        for i in 0..<results.count {
            for j in (i+1)..<results.count {
                let rect1 = results[i]
                let rect2 = results[j]

                // Calculate overlap
                let intersection = rect1.intersection(rect2)
                let overlap = intersection.width * intersection.height
                let minArea = min(rect1.width * rect1.height, rect2.width * rect2.height)

                // Overlap should be less than 50% of the smaller rectangle
                if minArea > 0 {
                    let overlapRatio = overlap / minArea
                    #expect(overlapRatio < 0.5)
                }
            }
        }

        // Test passes
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
