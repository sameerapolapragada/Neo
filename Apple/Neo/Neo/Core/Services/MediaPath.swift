import Foundation

enum SupabaseTable {
    /// Kept distinct from the Expo app's `pets`, `memories`, and storage buckets.
    static let pets = "companion_pets"
    static let moments = "companion_moments"
    static let momentMedia = "companion_moment_media"
    static let momentTags = "companion_moment_tags"
    static let pawChecks = "companion_paw_checks"
    static let weightEntries = "companion_weight_entries"
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
    /// `{owner}/pets/{pet}/profile/{file}.jpg`
    static func jpeg(ownerId: UUID, petId: UUID, fileId: UUID = UUID()) -> String {
        "\(text(ownerId))/pets/\(text(petId))/profile/\(text(fileId)).jpg"
    }

    /// `{owner}/moments/{moment}/{file}.jpg`. The key does not include the pet id.
    /// `petId` stays in the signature so callers still name the parent pet they checked.
    static func momentJPEG(ownerId: UUID, petId: UUID, momentId: UUID, fileId: UUID = UUID()) -> String {
        _ = petId
        return "\(text(ownerId))/moments/\(text(momentId))/\(text(fileId)).jpg"
    }

    static func isProfilePhoto(_ path: String, ownerId: UUID, petId: UUID) -> Bool {
        guard let parts = parts(in: path), parts.count == 5 else { return false }
        return parts[0] == text(ownerId)
            && parts[1] == "pets"
            && parts[2] == text(petId)
            && parts[3] == "profile"
            && isJPEGFile(parts[4])
    }

    static func isMomentPhoto(_ path: String, ownerId: UUID, petId: UUID, momentId: UUID) -> Bool {
        _ = petId
        guard let parts = parts(in: path), parts.count == 4 else { return false }
        return parts[0] == text(ownerId)
            && parts[1] == "moments"
            && parts[2] == text(momentId)
            && isJPEGFile(parts[3])
    }

    /// True only for a canonical profile or moment key owned by this account.
    static func belongsToOwner(_ path: String, ownerId: UUID) -> Bool {
        guard let parts = parts(in: path), parts[0] == text(ownerId) else { return false }
        switch parts.count {
        case 5:
            return parts[1] == "pets" && isUUID(parts[2]) && parts[3] == "profile" && isJPEGFile(parts[4])
        case 4:
            return parts[1] == "moments" && isUUID(parts[2]) && isJPEGFile(parts[3])
        default:
            return false
        }
    }

    static func isCanonical(_ path: String) -> Bool {
        guard let owner = ownerId(in: path) else { return false }
        return belongsToOwner(path, ownerId: owner)
    }

    static func ownerId(in path: String) -> UUID? {
        guard let first = parts(in: path)?.first else { return nil }
        return UUID(uuidString: first)
    }

    /// A Storage public-object URL. Signed URLs use `/object/sign/` and are not matched.
    static func isPublicObjectURL(_ value: String) -> Bool {
        value.contains("/object/public/")
    }

    private static func parts(in path: String) -> [String]? {
        guard MediaPath.isObjectPath(path) else { return nil }
        let parts = path.split(separator: "/", omittingEmptySubsequences: false).map(String.init)
        guard !parts.contains(where: \.isEmpty) else { return nil }
        return parts
    }

    private static func isJPEGFile(_ value: String) -> Bool {
        guard value.hasSuffix(".jpg") else { return false }
        return isUUID(String(value.dropLast(4)))
    }

    private static func isUUID(_ value: String) -> Bool {
        guard let parsed = UUID(uuidString: value) else { return false }
        return parsed.uuidString.lowercased() == value
    }

    private static func text(_ id: UUID) -> String {
        id.uuidString.lowercased()
    }
}

enum MediaPathGuard {
    static func validate(_ path: String?) throws {
        if let path, !MediaPath.isObjectPath(path) {
            throw RepositoryError.invalidPhoto
        }
    }
}
