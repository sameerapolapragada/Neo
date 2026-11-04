import Foundation

enum SupabaseTable {
    /// Kept distinct from the Expo app's `pets`, `memories`, and storage buckets.
    static let pets = "companion_pets"
    static let moments = "companion_moments"
    static let momentMedia = "companion_moment_media"
    static let memories = "companion_memories"
    static let mediaBucket = "companion-pet-media"
}

enum MediaPolicy {
    /// Short-lived access to the private bucket. Callers must not persist this URL.
    static let signedURLLifetimeSeconds = 600
    static let refreshLeewaySeconds = 60
}

enum MediaPath {
    static func isObjectPath(_ path: String) -> Bool {
        let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        if trimmed.contains("://") || trimmed.hasPrefix("/") || trimmed.contains("..") {
            return false
        }
        return true
    }
}

enum MediaObjectPath {
    static func jpeg(ownerId: UUID, petId: UUID, fileId: UUID = UUID()) -> String {
        let owner = ownerId.uuidString.lowercased()
        let pet = petId.uuidString.lowercased()
        let file = fileId.uuidString.lowercased()
        return "\(owner)/\(pet)/\(file).jpg"
    }

    /// Private object key for one photo on a moment. The first folder is the owner.
    static func momentJPEG(ownerId: UUID, petId: UUID, momentId: UUID, fileId: UUID = UUID()) -> String {
        let owner = ownerId.uuidString.lowercased()
        let pet = petId.uuidString.lowercased()
        let moment = momentId.uuidString.lowercased()
        let file = fileId.uuidString.lowercased()
        return "\(owner)/\(pet)/\(moment)/\(file).jpg"
    }

    static func belongsToOwner(_ path: String, ownerId: UUID) -> Bool {
        let owner = ownerId.uuidString.lowercased()
        return MediaPath.isObjectPath(path) && path.hasPrefix(owner + "/")
    }

    static func isMomentPhoto(_ path: String, ownerId: UUID, petId: UUID, momentId: UUID) -> Bool {
        let prefix = "\(ownerId.uuidString.lowercased())/\(petId.uuidString.lowercased())/\(momentId.uuidString.lowercased())/"
        guard belongsToOwner(path, ownerId: ownerId), path.hasPrefix(prefix), path.hasSuffix(".jpg") else {
            return false
        }
        let file = path.dropFirst(prefix.count)
        return !file.isEmpty && !file.contains("/")
    }
}

enum MediaPathGuard {
    static func validate(_ path: String?) throws {
        if let path, !MediaPath.isObjectPath(path) {
            throw RepositoryError.invalidPhoto
        }
    }
}
