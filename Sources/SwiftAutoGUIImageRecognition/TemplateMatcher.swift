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
    private let tiledPipeline: any MTLComputePipelineState

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
        guard let tiledFunction = library.makeFunction(
            name: "tiledNormalizedCrossCorrelation"
        ) else {
            throw TemplateMatcherError.shaderFunctionMissing
        }

        self.device = device
        self.commandQueue = commandQueue
        self.pipeline = try device.makeComputePipelineState(function: function)
        self.tiledPipeline = try device.makeComputePipelineState(function: tiledFunction)
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
            length: haystackPixels.pixels.count
        ), let needleBuffer = device.makeBuffer(
            bytes: needlePixels.pixels,
            length: needlePixels.pixels.count
        ), let scoreBuffer = device.makeBuffer(
            length: outputCount * MemoryLayout<Float>.stride,
            options: .storageModeShared
        ) else {
            throw TemplateMatcherError.bufferCreationFailed
        }

        var parameters = MatchParameters(
            imageWidth: UInt32(haystackPixels.width),
            imageHeight: UInt32(haystackPixels.height),
            templateWidth: UInt32(needlePixels.width),
            templateHeight: UInt32(needlePixels.height),
            outputWidth: UInt32(outputWidth),
            outputHeight: UInt32(outputHeight),
            templateMean: templateStatistics.mean,
            templateSumSquaredDeviations: templateStatistics.sumSquaredDeviations
        )

        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeComputeCommandEncoder() else {
            throw TemplateMatcherError.commandExecutionFailed("Could not create a command encoder.")
        }

        let threadgroupSize = MTLSize(width: 8, height: 8, depth: 1)
        let tileWidth = needlePixels.width + threadgroupSize.width - 1
        let tileHeight = needlePixels.height + threadgroupSize.height - 1
        let tileByteCount = tileWidth * tileHeight
        let canUseTiledPipeline =
            needlePixels.width * needlePixels.height <= 4_096 &&
            tileByteCount + tiledPipeline.staticThreadgroupMemoryLength
                <= device.maxThreadgroupMemoryLength

        encoder.setComputePipelineState(canUseTiledPipeline ? tiledPipeline : pipeline)
        encoder.setBuffer(haystackBuffer, offset: 0, index: 0)
        encoder.setBuffer(needleBuffer, offset: 0, index: 1)
        encoder.setBuffer(scoreBuffer, offset: 0, index: 2)
        encoder.setBytes(&parameters, length: MemoryLayout<MatchParameters>.stride, index: 3)

        if canUseTiledPipeline {
            encoder.setThreadgroupMemoryLength(tileByteCount, index: 0)
            encoder.dispatchThreadgroups(
                MTLSize(
                    width: (outputWidth + threadgroupSize.width - 1) / threadgroupSize.width,
                    height: (outputHeight + threadgroupSize.height - 1) / threadgroupSize.height,
                    depth: 1
                ),
                threadsPerThreadgroup: threadgroupSize
            )
        } else {
            encoder.dispatchThreads(
                MTLSize(width: outputWidth, height: outputHeight, depth: 1),
                threadsPerThreadgroup: threadgroupSize
            )
        }
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

        if !findAll {
            var bestIndex: Int?
            var bestScore = threshold

            for index in 0..<outputCount {
                let score = scores[index]
                if score.isFinite,
                   score >= threshold,
                   bestIndex == nil || score > bestScore {
                    bestIndex = index
                    bestScore = score
                }
            }

            return bestIndex.map {
                [
                    ImageMatch(
                        x: $0 % outputWidth,
                        y: $0 / outputWidth,
                        width: needlePixels.width,
                        height: needlePixels.height,
                        score: bestScore
                    )
                ]
            } ?? []
        }

        var matches: [ImageMatch] = []
        matches.reserveCapacity(min(outputCount, 64))
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

        return NonMaximumSuppression.apply(to: matches)
    }
}

private struct TemplateStatistics {
    let mean: Float
    let sumSquaredDeviations: Float

    init(pixels: [UInt8]) {
        let scale = 1 / Float(UInt8.max)
        let mean = pixels.reduce(into: Float.zero) {
            $0 += Float($1) * scale
        } / Float(pixels.count)
        self.mean = mean
        self.sumSquaredDeviations = pixels.reduce(into: 0) { result, value in
            let deviation = Float(value) * scale - mean
            result += deviation * deviation
        }
    }
}

private struct MatchParameters {
    let imageWidth: UInt32
    let imageHeight: UInt32
    let templateWidth: UInt32
    let templateHeight: UInt32
    let outputWidth: UInt32
    let outputHeight: UInt32
    let templateMean: Float
    let templateSumSquaredDeviations: Float
}
