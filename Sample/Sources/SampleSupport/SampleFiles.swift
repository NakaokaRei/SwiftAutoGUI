import AppKit
import ComposableArchitecture
import IssueReporting
import SwiftAutoGUI

public struct SampleFiles: Sendable {
    public struct ImageResult: Equatable, Sendable {
        public var path: String
        public var message: String
    }
    public var createImage: @MainActor @Sendable (Bool) -> ImageResult
    public var saveScreenshot: @MainActor @Sendable (CGRect?) async -> Void
}
extension SampleFiles: DependencyKey {
    public static let liveValue = Self(
        createImage: { tiled in
            var renderer = TestImageRenderer()
            if tiled {
                renderer.createTiledTestImageForRecognition()
            } else {
                renderer.createTestImageForRecognition()
            }
            return ImageResult(
                path: renderer.testImagePath, message: renderer.imageRecognitionResult)
        },
        saveScreenshot: { region in
            guard
                let documents = FileManager.default.urls(
                    for: .documentDirectory, in: .userDomainMask
                ).first
            else { return }
            let path = documents.appendingPathComponent(
                region == nil ? "swiftautogui_screenshot.png" : "swiftautogui_region.png"
            ).path
            let saved =
                await AutomationAction.screenshotToFile(filename: path, region: region).execute()
                as? Bool
            if saved == true {
                NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: documents.path)
            }
        }
    )
    public static let testValue = Self(
        createImage: { _ in
            reportIssue("Unimplemented SampleFiles.createImage")
            return ImageResult(path: "", message: "")
        },
        saveScreenshot: { _ in reportIssue("Unimplemented SampleFiles.saveScreenshot") }
    )
}
extension DependencyValues {
    public var sampleFiles: SampleFiles {
        get { self[SampleFiles.self] }
        set { self[SampleFiles.self] = newValue }
    }
}

@MainActor
private struct TestImageRenderer {
    var testImagePath = ""
    var imageRecognitionResult = ""
    mutating func createTiledTestImageForRecognition() {
        guard
            let bitmapImage = NSBitmapImageRep(
                bitmapDataPlanes: nil,
                pixelsWide: 64,
                pixelsHigh: 64,
                bitsPerSample: 8,
                samplesPerPixel: 4,
                hasAlpha: true,
                isPlanar: false,
                colorSpaceName: .deviceRGB,
                bytesPerRow: 0,
                bitsPerPixel: 0
            ), let context = NSGraphicsContext(bitmapImageRep: bitmapImage)
        else {
            imageRecognitionResult = "Failed to create 64x64 test image bitmap"
            return
        }

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = context

        NSColor.systemBlue.setFill()
        NSRect(x: 0, y: 0, width: 64, height: 64).fill()

        NSColor.white.setFill()
        NSRect(x: 12, y: 12, width: 40, height: 40).fill()

        NSColor.systemRed.setFill()
        NSRect(x: 19, y: 19, width: 26, height: 26).fill()

        NSColor.systemYellow.setFill()
        NSBezierPath(ovalIn: NSRect(x: 26, y: 26, width: 12, height: 12)).fill()

        context.flushGraphics()
        NSGraphicsContext.restoreGraphicsState()

        // Preserve the 64x64 pixel template while displaying it at 32 points.
        // On a 2x Retina display, Preview then renders it as 64x64 screen pixels,
        // matching the pixel dimensions used by template matching.
        bitmapImage.size = NSSize(width: 32, height: 32)

        let documents = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first!
        let path = documents.appendingPathComponent(
            "tiled_test_recognition_image.png"
        ).path

        if let pngData = bitmapImage.representation(using: .png, properties: [:]) {
            do {
                try pngData.write(to: URL(fileURLWithPath: path))
                testImagePath = path
                imageRecognitionResult = """
                    Tiled matcher test image created at: \(path)
                    Pixel size: \(bitmapImage.pixelsWide)x\(bitmapImage.pixelsHigh)
                    Display size: \(Int(bitmapImage.size.width))x\(Int(bitmapImage.size.height)) points
                    Open this image in a separate Preview window, then try to locate it.
                    """
            } catch {
                imageRecognitionResult = "Failed to create tiled test image: \(error)"
            }
        }
    }

    mutating func createTestImageForRecognition() {
        let size = NSSize(width: 100, height: 100)
        let image = NSImage(size: size)

        image.lockFocus()

        NSColor.systemBlue.setFill()
        NSRect(origin: .zero, size: size).fill()

        NSColor.white.setFill()
        NSRect(x: 20, y: 20, width: 60, height: 60).fill()

        NSColor.systemRed.setFill()
        NSRect(x: 30, y: 30, width: 40, height: 40).fill()

        NSColor.systemYellow.setFill()
        NSBezierPath(ovalIn: NSRect(x: 40, y: 40, width: 20, height: 20)).fill()

        image.unlockFocus()

        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            .first!
        let path = documents.appendingPathComponent("test_recognition_image.png").path

        if let tiffData = image.tiffRepresentation,
            let bitmapImage = NSBitmapImageRep(data: tiffData),
            let pngData = bitmapImage.representation(using: .png, properties: [:])
        {
            do {
                try pngData.write(to: URL(fileURLWithPath: path))
                testImagePath = path
                imageRecognitionResult =
                    "Test image created at: \(path)\nPlease open this image in Preview or another app, then try to locate it."
            } catch {
                imageRecognitionResult = "Failed to create test image: \(error)"
            }
        }
    }

}
