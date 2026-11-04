import Foundation
import ImageIO
import UniformTypeIdentifiers

enum TimelineImageSizing {
    /// About three times a 72-point thumbnail, so the row does not decode a full 2048-pixel photo.
    static let thumbnailMaxPixel = 216

    static func thumbnailJPEG(from data: Data, maxPixel: Int = thumbnailMaxPixel) -> Data? {
        guard maxPixel > 0, let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let options = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: false,
            kCGImageSourceThumbnailMaxPixelSize: maxPixel
        ] as CFDictionary
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options) else { return nil }
        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(output, UTType.jpeg.identifier as CFString, 1, nil) else {
            return nil
        }
        let properties = [kCGImageDestinationLossyCompressionQuality: 0.82] as CFDictionary
        CGImageDestinationAddImage(destination, image, properties)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return output as Data
    }
}

actor TimelineThumbnailCache {
    static let shared = TimelineThumbnailCache()

    private var dataByPath: [String: Data] = [:]
    private var order: [String] = []
    private let limit = 80

    func data(for path: String) -> Data? {
        dataByPath[path]
    }

    func store(_ data: Data, for path: String) {
        if dataByPath[path] == nil {
            order.append(path)
        }
        dataByPath[path] = data
        while order.count > limit, let oldest = order.first {
            order.removeFirst()
            if oldest != path {
                dataByPath.removeValue(forKey: oldest)
            }
        }
    }

    func clear() {
        dataByPath = [:]
        order = []
    }

    func storedCount() -> Int {
        dataByPath.count
    }
}

enum FeedImageSizing {
    /// Feed cards are about a screen wide. This stays well under the 2048-pixel upload.
    static let coverMaxPixel = 960

    static func cacheKey(path: String, maxPixel: Int) -> String {
        "\(maxPixel)|\(path)"
    }
}

enum TimelineThumbnailLoader {
    private static let session: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.urlCache = nil
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: configuration)
    }()

    static func jpegThumbnail(from url: URL, maxPixel: Int = TimelineImageSizing.thumbnailMaxPixel) async -> Data? {
        do {
            let (data, response) = try await session.data(from: url)
            if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                return nil
            }
            return TimelineImageSizing.thumbnailJPEG(from: data, maxPixel: maxPixel)
        } catch {
            return nil
        }
    }
}
