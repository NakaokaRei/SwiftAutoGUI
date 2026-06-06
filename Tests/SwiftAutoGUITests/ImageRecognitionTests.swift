import Testing
@testable import SwiftAutoGUI

@Suite("Image Recognition API Tests")
struct ImageRecognitionTests {
    @Test("Image recognition actions default to color matching at 0.95 confidence")
    func actionDefaults() {
        let action = Action.locateOnScreen("/tmp/template.png")

        guard case .locateOnScreen(
            _,
            let grayscale,
            let confidence,
            _
        ) = action else {
            Issue.record("Expected a locateOnScreen action")
            return
        }

        #expect(grayscale == false)
        #expect(confidence == 0.95)
    }

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
