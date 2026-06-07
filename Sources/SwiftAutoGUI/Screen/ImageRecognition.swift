import AppKit
import CoreGraphics
import Foundation
import ImageRecognition

private let imageTemplateMatcher = Result { try TemplateMatcher() }

extension SwiftAutoGUI {

    // MARK: Image Recognition

    /// Locate an image on the screen and return its position.
    ///
    /// - Parameters:
    ///   - imagePath: Path to the image file to search for.
    ///   - grayscale: Skip color verification for faster matching.
    ///   - confidence: Matching confidence threshold from 0.0 to 1.0. Defaults to 0.95.
    ///   - region: Limit the search to a screen region in points.
    /// - Returns: The matching rectangle in screen points, or nil when no match is found.
    public static func locateOnScreen(
        _ imagePath: String,
        grayscale: Bool = false,
        confidence: Double? = nil,
        region: CGRect? = nil
    ) async throws -> CGRect? {
        return try await locateMatches(
            imagePath,
            grayscale: grayscale,
            confidence: confidence,
            region: region,
            findAll: false
        ).first
    }

    /// Locate an image on the screen and return its center point.
    public static func locateCenterOnScreen(
        _ imagePath: String,
        grayscale: Bool = false,
        confidence: Double? = nil,
        region: CGRect? = nil
    ) async throws -> CGPoint? {
        guard let rect = try await locateOnScreen(
            imagePath,
            grayscale: grayscale,
            confidence: confidence,
            region: region
        ) else {
            return nil
        }

        return CGPoint(x: rect.midX, y: rect.midY)
    }

    /// Locate all non-overlapping instances of an image on the screen.
    public static func locateAllOnScreen(
        _ imagePath: String,
        grayscale: Bool = false,
        confidence: Double? = nil,
        region: CGRect? = nil
    ) async throws -> [CGRect] {
        return try await locateMatches(
            imagePath,
            grayscale: grayscale,
            confidence: confidence,
            region: region,
            findAll: true
        )
    }

    private static func locateMatches(
        _ imagePath: String,
        grayscale: Bool,
        confidence: Double?,
        region: CGRect?,
        findAll: Bool
    ) async throws -> [CGRect] {
        guard let needleImage = NSImage(contentsOfFile: imagePath),
              let needleCGImage = needleImage.cgImage(
                forProposedRect: nil,
                context: nil,
                hints: nil
              ) else {
            return []
        }

        let screenshot = if let region {
            try await screenshot(region: region)
        } else {
            try await screenshot()
        }

        guard let screenshot,
              let haystackCGImage = screenshot.cgImage(
                forProposedRect: nil,
                context: nil,
                hints: nil
              ),
              screenshot.size.width > 0,
              screenshot.size.height > 0 else {
            return []
        }

        let matcher = try imageTemplateMatcher.get()
        let matches = try matcher.match(
            needle: needleCGImage,
            in: haystackCGImage,
            threshold: Float(confidence ?? 0.95),
            findAll: findAll,
            grayscale: grayscale
        )

        let scaleX = CGFloat(haystackCGImage.width) / screenshot.size.width
        let scaleY = CGFloat(haystackCGImage.height) / screenshot.size.height
        let origin = region?.origin ?? .zero

        return matches.map { match in
            CGRect(
                x: origin.x + CGFloat(match.x) / scaleX,
                y: origin.y + CGFloat(match.y) / scaleY,
                width: CGFloat(match.width) / scaleX,
                height: CGFloat(match.height) / scaleY
            )
        }
    }
}
