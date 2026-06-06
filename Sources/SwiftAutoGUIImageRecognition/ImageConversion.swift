import CoreGraphics
import Foundation

struct GrayscaleImage {
    let width: Int
    let height: Int
    let pixels: [UInt8]

    init(cgImage: CGImage) throws {
        let imageWidth = cgImage.width
        let imageHeight = cgImage.height
        width = imageWidth
        height = imageHeight

        var bytes = [UInt8](repeating: 0, count: imageWidth * imageHeight)
        let rendered = bytes.withUnsafeMutableBytes { rawBuffer -> Bool in
            guard let baseAddress = rawBuffer.baseAddress,
                  let context = CGContext(
                    data: baseAddress,
                    width: imageWidth,
                    height: imageHeight,
                    bitsPerComponent: 8,
                    bytesPerRow: imageWidth,
                    space: CGColorSpaceCreateDeviceGray(),
                    bitmapInfo: CGImageAlphaInfo.none.rawValue
                  ) else {
                return false
            }

            context.interpolationQuality = .none
            context.draw(
                cgImage,
                in: CGRect(x: 0, y: 0, width: imageWidth, height: imageHeight)
            )
            return true
        }

        guard rendered else {
            throw TemplateMatcherError.imageConversionFailed
        }

        pixels = bytes
    }
}

struct ColorImage {
    let width: Int
    let height: Int
    let pixels: [UInt8]

    init(cgImage: CGImage) throws {
        let imageWidth = cgImage.width
        let imageHeight = cgImage.height
        width = imageWidth
        height = imageHeight

        var bytes = [UInt8](repeating: 0, count: imageWidth * imageHeight * 4)
        let rendered = bytes.withUnsafeMutableBytes { rawBuffer -> Bool in
            guard let baseAddress = rawBuffer.baseAddress,
                  let context = CGContext(
                    data: baseAddress,
                    width: imageWidth,
                    height: imageHeight,
                    bitsPerComponent: 8,
                    bytesPerRow: imageWidth * 4,
                    space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                  ) else {
                return false
            }

            context.interpolationQuality = .none
            context.draw(
                cgImage,
                in: CGRect(x: 0, y: 0, width: imageWidth, height: imageHeight)
            )
            return true
        }

        guard rendered else {
            throw TemplateMatcherError.imageConversionFailed
        }

        pixels = bytes
    }
}
