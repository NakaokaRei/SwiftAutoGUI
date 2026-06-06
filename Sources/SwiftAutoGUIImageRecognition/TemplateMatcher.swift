import CoreGraphics
import Foundation
import Metal

package struct ImageMatch: Sendable, Equatable {
    package let x: Int
    package let y: Int
    package let width: Int
    package let height: Int
    package let score: Float

    package init(x: Int, y: Int, width: Int, height: Int, score: Float) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.score = score
    }
}

package enum TemplateMatcherError: Error, LocalizedError {
    case metalUnavailable
    case commandQueueCreationFailed
    case shaderLibraryCreationFailed
    case shaderFunctionMissing
    case bufferCreationFailed
    case imageConversionFailed
    case commandExecutionFailed(String)

    package var errorDescription: String? {
        switch self {
        case .metalUnavailable:
            "Metal is not available on this device."
        case .commandQueueCreationFailed:
            "Could not create a Metal command queue."
        case .shaderLibraryCreationFailed:
            "Could not load the template-matching Metal library."
        case .shaderFunctionMissing:
            "The template-matching Metal function is missing."
        case .bufferCreationFailed:
            "Could not allocate a Metal buffer."
        case .imageConversionFailed:
            "Could not convert a CGImage to grayscale pixels."
        case .commandExecutionFailed(let detail):
            "Metal template matching failed: \(detail)"
        }
    }
}

package final class TemplateMatcher: @unchecked Sendable {
    private let device: any MTLDevice
    private let commandQueue: any MTLCommandQueue
    private let pipeline: any MTLComputePipelineState

    package init() throws {
        guard let device = MTLCreateSystemDefaultDevice() else {
            throw TemplateMatcherError.metalUnavailable
        }
        guard let commandQueue = device.makeCommandQueue() else {
            throw TemplateMatcherError.commandQueueCreationFailed
        }

        guard let libraryURL = Bundle.module.url(
            forResource: "TemplateMatching",
            withExtension: "metallib"
        ) else {
            throw TemplateMatcherError.shaderLibraryCreationFailed
        }
        let library = try device.makeLibrary(URL: libraryURL)

        guard let function = library.makeFunction(name: "normalizedCrossCorrelation") else {
            throw TemplateMatcherError.shaderFunctionMissing
        }

        self.device = device
        self.commandQueue = commandQueue
        self.pipeline = try device.makeComputePipelineState(function: function)
    }

    package func match(
        needle: CGImage,
        in haystack: CGImage,
        threshold: Float,
        findAll: Bool
    ) throws -> [ImageMatch] {
        let needlePixels = try GrayscaleImage(cgImage: needle)
        let haystackPixels = try GrayscaleImage(cgImage: haystack)

        guard needlePixels.width <= haystackPixels.width,
              needlePixels.height <= haystackPixels.height else {
            return []
        }

        let templateStatistics = TemplateStatistics(pixels: needlePixels.pixels)
        guard templateStatistics.sumSquaredDeviations > Float.ulpOfOne else {
            return []
        }

        let outputWidth = haystackPixels.width - needlePixels.width + 1
        let outputHeight = haystackPixels.height - needlePixels.height + 1
        let outputCount = outputWidth * outputHeight

        guard let haystackBuffer = device.makeBuffer(
            bytes: haystackPixels.pixels,
            length: haystackPixels.pixels.count * MemoryLayout<Float>.stride
        ), let needleBuffer = device.makeBuffer(
            bytes: needlePixels.pixels,
            length: needlePixels.pixels.count * MemoryLayout<Float>.stride
        ), let scoreBuffer = device.makeBuffer(
            length: outputCount * MemoryLayout<Float>.stride,
            options: .storageModeShared
        ) else {
            throw TemplateMatcherError.bufferCreationFailed
        }

        var parameters = MatchParameters(
            imageWidth: UInt32(haystackPixels.width),
            templateWidth: UInt32(needlePixels.width),
            templateHeight: UInt32(needlePixels.height),
            outputWidth: UInt32(outputWidth),
            templateMean: templateStatistics.mean,
            templateSumSquaredDeviations: templateStatistics.sumSquaredDeviations
        )

        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeComputeCommandEncoder() else {
            throw TemplateMatcherError.commandExecutionFailed("Could not create a command encoder.")
        }

        encoder.setComputePipelineState(pipeline)
        encoder.setBuffer(haystackBuffer, offset: 0, index: 0)
        encoder.setBuffer(needleBuffer, offset: 0, index: 1)
        encoder.setBuffer(scoreBuffer, offset: 0, index: 2)
        encoder.setBytes(&parameters, length: MemoryLayout<MatchParameters>.stride, index: 3)

        let threadgroupWidth = min(pipeline.maxTotalThreadsPerThreadgroup, outputCount)
        encoder.dispatchThreads(
            MTLSize(width: outputCount, height: 1, depth: 1),
            threadsPerThreadgroup: MTLSize(width: threadgroupWidth, height: 1, depth: 1)
        )
        encoder.endEncoding()

        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        guard commandBuffer.status == .completed else {
            throw TemplateMatcherError.commandExecutionFailed(
                commandBuffer.error?.localizedDescription ?? "Unknown command-buffer error."
            )
        }

        let scores = scoreBuffer.contents()
            .bindMemory(to: Float.self, capacity: outputCount)

        var matches: [ImageMatch] = []
        matches.reserveCapacity(findAll ? min(outputCount, 64) : 1)

        for index in 0..<outputCount {
            let score = scores[index]
            guard score.isFinite, score >= threshold else { continue }

            matches.append(
                ImageMatch(
                    x: index % outputWidth,
                    y: index / outputWidth,
                    width: needlePixels.width,
                    height: needlePixels.height,
                    score: score
                )
            )
        }

        matches.sort {
            if $0.score == $1.score {
                return ($0.y, $0.x) < ($1.y, $1.x)
            }
            return $0.score > $1.score
        }

        if findAll {
            return NonMaximumSuppression.apply(to: matches)
        }
        return matches.first.map { [$0] } ?? []
    }
}

private struct TemplateStatistics {
    let mean: Float
    let sumSquaredDeviations: Float

    init(pixels: [Float]) {
        let mean = pixels.reduce(0, +) / Float(pixels.count)
        self.mean = mean
        self.sumSquaredDeviations = pixels.reduce(into: 0) { result, value in
            let deviation = value - mean
            result += deviation * deviation
        }
    }
}

private struct MatchParameters {
    let imageWidth: UInt32
    let templateWidth: UInt32
    let templateHeight: UInt32
    let outputWidth: UInt32
    let templateMean: Float
    let templateSumSquaredDeviations: Float
}
