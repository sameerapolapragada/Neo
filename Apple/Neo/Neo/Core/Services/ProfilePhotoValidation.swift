import Foundation
import UIKit

enum MomentUploadRules {
    static func validateJPEG(_ data: Data) throws {
        guard data.count <= ProfilePhotoValidation.maxBytes, data.starts(with: [0xFF, 0xD8, 0xFF]) else {
            throw RepositoryError.invalidPhoto
        }
    }
}

enum ProfilePhotoValidation {
    /// Matches the private bucket limit in the local schema proposal.
    static let maxBytes = 10 * 1024 * 1024

    enum Issue: Equatable, Error {
        case unsupportedType
        case tooLarge

        var message: String {
            switch self {
            case .unsupportedType:
                "Use a JPEG, PNG, or HEIC photo."
            case .tooLarge:
                "Choose a photo smaller than 10 MB."
            }
        }
    }

    static func jpeg(from data: Data) -> Result<Data, Issue> {
        guard !data.isEmpty else { return .failure(.unsupportedType) }
        guard data.count <= maxBytes else { return .failure(.tooLarge) }
        guard isSupportedImage(data) else { return .failure(.unsupportedType) }
        guard let jpeg = PhotoEncoding.jpegData(from: data), !jpeg.isEmpty else {
            return .failure(.unsupportedType)
        }
        guard jpeg.count <= maxBytes else { return .failure(.tooLarge) }
        return .success(jpeg)
    }

    private static func isSupportedImage(_ data: Data) -> Bool {
        if data.starts(with: [0xFF, 0xD8, 0xFF]) { return true }
        if data.starts(with: [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]) { return true }
        return isHEIF(data)
    }

    private static func isHEIF(_ data: Data) -> Bool {
        guard data.count >= 12 else { return false }
        guard String(data: data.subdata(in: 4..<8), encoding: .ascii) == "ftyp" else { return false }
        let brand = String(data: data.subdata(in: 8..<12), encoding: .ascii) ?? ""
        return ["heic", "heix", "heif", "mif1", "msf1", "hevc"].contains(brand)
    }
}
