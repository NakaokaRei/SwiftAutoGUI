import CoreGraphics
import Foundation
import Testing
@testable import SwiftAutoGUIImageRecognition

@Suite("Metal Template Matcher Tests")
struct TemplateMatcherTests {
    @Test("Finds an exact match at a known offset")
    func exactMatch() throws {
        let template = [
            UInt8(10), 80, 30,
            200, 40, 150,
        ]
        var haystack = [UInt8](repeating: 5, count: 8 * 7)
        insert(template, width: 3, height: 2, into: &haystack, haystackWidth: 8, x: 4, y: 3)

        let needleImage = makeImage(width: 3, height: 2, pixels: template)
        let haystackImage = makeImage(width: 8, height: 7, pixels: haystack)

        let matches = try makeMatcher().match(
            needle: needleImage,
            in: haystackImage,
            threshold: 0.999,
            findAll: false
        )

        #expect(matches.count == 1)
        #expect(matches.first?.x == 4)
        #expect(matches.first?.y == 3)
        #expect(matches.first?.score ?? 0 > 0.999)
    }

    @Test("Finds matches at both image edges")
    func edgeMatches() throws {
        let template = [
            UInt8(0), 40,
            180, 255,
        ]
        var haystack = [UInt8](repeating: 90, count: 7 * 6)
        insert(template, width: 2, height: 2, into: &haystack, haystackWidth: 7, x: 0, y: 0)
        insert(template, width: 2, height: 2, into: &haystack, haystackWidth: 7, x: 5, y: 4)

        let matches = try makeMatcher().match(
            needle: makeImage(width: 2, height: 2, pixels: template),
            in: makeImage(width: 7, height: 6, pixels: haystack),
            threshold: 0.999,
            findAll: true
        )

        #expect(matches.contains { $0.x == 0 && $0.y == 0 })
        #expect(matches.contains { $0.x == 5 && $0.y == 4 })
    }

    @Test("Rejects images below the threshold")
    func noMatch() throws {
        let template = [
            UInt8(0), 30,
            200, 255,
        ]
        let haystack = [UInt8](repeating: 127, count: 6 * 5)

        let matches = try makeMatcher().match(
            needle: makeImage(width: 2, height: 2, pixels: template),
            in: makeImage(width: 6, height: 5, pixels: haystack),
            threshold: 0.9,
            findAll: true
        )

        #expect(matches.isEmpty)
    }

    @Test("Rejects a constant template")
    func constantTemplate() throws {
        let template = [UInt8](repeating: 80, count: 4)
        let haystack = [UInt8](repeating: 80, count: 25)

        let matches = try makeMatcher().match(
            needle: makeImage(width: 2, height: 2, pixels: template),
            in: makeImage(width: 5, height: 5, pixels: haystack),
            threshold: 0,
            findAll: true
        )

        #expect(matches.isEmpty)
    }

    @Test("Returns no match when the template is larger than the image")
    func templateLargerThanImage() throws {
        let matches = try makeMatcher().match(
            needle: makeImage(width: 4, height: 4, pixels: Array(0..<16)),
            in: makeImage(width: 3, height: 3, pixels: Array(0..<9)),
            threshold: 0,
            findAll: true
        )

        #expect(matches.isEmpty)
    }

    @Test("Non-maximum suppression removes overlapping responses")
    func nonMaximumSuppression() {
        let matches = [
            ImageMatch(x: 2, y: 2, width: 4, height: 4, score: 1),
            ImageMatch(x: 3, y: 2, width: 4, height: 4, score: 0.99),
            ImageMatch(x: 10, y: 10, width: 4, height: 4, score: 0.98),
        ]

        let selected = NonMaximumSuppression.apply(to: matches)

        #expect(selected.count == 2)
        #expect(selected.contains { $0.x == 2 && $0.y == 2 })
        #expect(selected.contains { $0.x == 10 && $0.y == 10 })
    }

    @Test("Metal score matches a CPU NCC reference")
    func matchesCPUReference() throws {
        let template = [
            UInt8(10), 80, 30,
            200, 40, 150,
        ]
        let image = [
            UInt8(12), 76, 35,
            190, 48, 145,
        ]
        let expectedScore = referenceNCC(template: template, image: image)

        let matches = try makeMatcher().match(
            needle: makeImage(width: 3, height: 2, pixels: template),
            in: makeImage(width: 3, height: 2, pixels: image),
            threshold: -1,
            findAll: false
        )

        let score = try #require(matches.first?.score)
        #expect(abs(Double(score) - expectedScore) < 0.0001)
    }

    @Test("Converts color images to grayscale consistently")
    func colorConversion() throws {
        let rgba: [UInt8] = [
            255, 0, 0, 255,
            0, 255, 0, 255,
            0, 0, 255, 255,
            255, 255, 255, 255,
        ]
        let colorImage = makeRGBAImage(width: 2, height: 2, pixels: rgba)
        let grayscale = try GrayscaleImage(cgImage: colorImage)

        #expect(grayscale.width == 2)
        #expect(grayscale.height == 2)
        #expect(grayscale.pixels.count == 4)
        #expect(grayscale.pixels[1] > grayscale.pixels[0])
        #expect(grayscale.pixels[0] > grayscale.pixels[2])
        #expect(grayscale.pixels[3] > grayscale.pixels[1])
    }

    private func makeMatcher() throws -> TemplateMatcher {
        try TemplateMatcher()
    }

    private func makeImage(width: Int, height: Int, pixels: [UInt8]) -> CGImage {
        let provider = CGDataProvider(data: Data(pixels) as CFData)!
        return CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 8,
            bytesPerRow: width,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )!
    }

    private func makeRGBAImage(width: Int, height: Int, pixels: [UInt8]) -> CGImage {
        let provider = CGDataProvider(data: Data(pixels) as CFData)!
        return CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(
                rawValue: CGImageAlphaInfo.last.rawValue
            ),
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )!
    }

    private func referenceNCC(template: [UInt8], image: [UInt8]) -> Double {
        let templateValues = template.map(Double.init)
        let imageValues = image.map(Double.init)
        let templateMean = templateValues.reduce(0, +) / Double(templateValues.count)
        let imageMean = imageValues.reduce(0, +) / Double(imageValues.count)

        var numerator = 0.0
        var templateVariance = 0.0
        var imageVariance = 0.0

        for index in templateValues.indices {
            let templateDeviation = templateValues[index] - templateMean
            let imageDeviation = imageValues[index] - imageMean
            numerator += templateDeviation * imageDeviation
            templateVariance += templateDeviation * templateDeviation
            imageVariance += imageDeviation * imageDeviation
        }

        return numerator / sqrt(templateVariance * imageVariance)
    }

    private func insert(
        _ template: [UInt8],
        width: Int,
        height: Int,
        into haystack: inout [UInt8],
        haystackWidth: Int,
        x: Int,
        y: Int
    ) {
        for row in 0..<height {
            let sourceStart = row * width
            let destinationStart = (y + row) * haystackWidth + x
            haystack.replaceSubrange(
                destinationStart..<(destinationStart + width),
                with: template[sourceStart..<(sourceStart + width)]
            )
        }
    }
}
