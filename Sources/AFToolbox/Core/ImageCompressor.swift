import Foundation
import ImageIO
import UniformTypeIdentifiers

struct CompressionResult: Identifiable {
    let id = UUID()
    let sourceName: String
    let outputURL: URL?
    let originalBytes: Int
    let newBytes: Int
    let errorText: String?

    var savedPercent: Int {
        guard originalBytes > 0, newBytes > 0 else { return 0 }
        return max(0, Int(((1 - Double(newBytes) / Double(originalBytes)) * 100).rounded()))
    }
}

enum ImageCompressor {
    static let imageExtensions: Set<String> = ["jpg", "jpeg", "png", "heic", "heif", "tiff", "tif", "bmp", "gif", "webp"]

    enum Mode {
        case maxEdge(Int)
        case scale(Double)
    }

    static func compress(url: URL, mode: Mode, quality: Double, suffix: String) -> CompressionResult {
        switch mode {
        case .maxEdge(let edge):
            return compress(url: url, maxEdge: edge, quality: quality, suffix: suffix)
        case .scale(let factor):
            guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
                  let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
                  let width = properties[kCGImagePropertyPixelWidth] as? Int,
                  let height = properties[kCGImagePropertyPixelHeight] as? Int else {
                return CompressionResult(sourceName: url.lastPathComponent, outputURL: nil,
                                         originalBytes: 0, newBytes: 0, errorText: "Bild konnte nicht gelesen werden")
            }
            let edge = max(1, Int((Double(max(width, height)) * factor).rounded()))
            return compress(url: url, maxEdge: edge, quality: quality, suffix: suffix)
        }
    }

    static func compress(url: URL, maxEdge: Int, quality: Double, suffix: String) -> CompressionResult {
        let name = url.lastPathComponent
        let originalBytes = fileSize(url)

        func failure(_ text: String) -> CompressionResult {
            CompressionResult(sourceName: name, outputURL: nil, originalBytes: originalBytes, newBytes: 0, errorText: text)
        }

        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            return failure("Bild konnte nicht gelesen werden")
        }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxEdge,
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return failure("Verkleinern fehlgeschlagen")
        }
        let base = url.deletingPathExtension().lastPathComponent
        let outputURL = url.deletingLastPathComponent().appendingPathComponent(base + suffix + ".jpg")
        guard let destination = CGImageDestinationCreateWithURL(outputURL as CFURL, UTType.jpeg.identifier as CFString, 1, nil) else {
            return failure("Ausgabedatei konnte nicht angelegt werden")
        }
        CGImageDestinationAddImage(destination, image, [kCGImageDestinationLossyCompressionQuality: quality] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else {
            return failure("Speichern fehlgeschlagen")
        }
        return CompressionResult(sourceName: name, outputURL: outputURL,
                                 originalBytes: originalBytes, newBytes: fileSize(outputURL), errorText: nil)
    }

    private static func fileSize(_ url: URL) -> Int {
        ((try? FileManager.default.attributesOfItem(atPath: url.path))?[.size] as? Int) ?? 0
    }
}
