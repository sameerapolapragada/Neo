import Foundation
import UIKit

enum PhotoEncoding {
    static func jpegData(from data: Data, maxPixel: CGFloat = 2048) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let pixelWidth = image.size.width * image.scale
        let pixelHeight = image.size.height * image.scale
        let longest = max(pixelWidth, pixelHeight)
        let rendered: UIImage
        if longest > maxPixel, longest > 0 {
            let ratio = maxPixel / longest
            let target = CGSize(width: pixelWidth * ratio, height: pixelHeight * ratio)
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1
            let renderer = UIGraphicsImageRenderer(size: target, format: format)
            rendered = renderer.image { _ in
                image.draw(in: CGRect(origin: .zero, size: target))
            }
        } else {
            rendered = image
        }
        return rendered.jpegData(compressionQuality: 0.85)
    }
}
