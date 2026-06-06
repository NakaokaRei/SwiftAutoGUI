import Testing
@testable import SwiftAutoGUI

@Suite("Image Recognition API Tests")
struct ImageRecognitionTests {
    @Test("locateOnScreen returns nil for an invalid image path")
    func locateInvalidImage() async throws {
        let match = try await SwiftAutoGUI.locateOnScreen("/nonexistent/image.png")
        #expect(match == nil)
    }

    @Test("locateCenterOnScreen returns nil for an invalid image path")
    func locateCenterInvalidImage() async throws {
        let match = try await SwiftAutoGUI.locateCenterOnScreen("/nonexistent/image.png")
        #expect(match == nil)
    }

    @Test("locateAllOnScreen returns no matches for an invalid image path")
    func locateAllInvalidImage() async throws {
        let matches = try await SwiftAutoGUI.locateAllOnScreen("/nonexistent/image.png")
        #expect(matches.isEmpty)
    }
}
