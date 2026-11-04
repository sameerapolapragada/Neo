import Foundation

struct MomentDeletionService: Sendable {
    private let pets: any PetRepository
    private let moments: any MomentRepository
    private let uploader: any MediaUploading

    init(pets: any PetRepository, moments: any MomentRepository, uploader: any MediaUploading) {
        self.pets = pets
        self.moments = moments
        self.uploader = uploader
    }

    /// Removes owned storage objects, then the moment row. A failed object delete is retried once.
    /// The row stays until every owned object is gone, so a later attempt can finish the cleanup.
    func delete(momentId: UUID, petId: UUID, ownerId: UUID) async throws {
        _ = try await pets.pet(id: petId, ownerId: ownerId)
        let moment = try await moments.moment(id: momentId, petId: petId, ownerId: ownerId)
        guard moment.ownerId == ownerId, moment.petId == petId else {
            throw RepositoryError.notFound
        }
        try await removeOwnedObjects(moment.media.map(\.storagePath), ownerId: ownerId)
        try await moments.delete(id: moment.id, ownerId: ownerId)
    }

    private func removeOwnedObjects(_ paths: [String], ownerId: UUID) async throws {
        var pending = paths.filter { MediaObjectPath.belongsToOwner($0, ownerId: ownerId) }
        var lastError: Error?
        for _ in 0..<2 where !pending.isEmpty {
            var failed: [String] = []
            for path in pending {
                do {
                    try await uploader.deleteUploadedObject(path, ownerId: ownerId)
                } catch RepositoryError.notFound {
                } catch {
                    lastError = error
                    failed.append(path)
                }
            }
            pending = failed
        }
        if !pending.isEmpty {
            throw lastError ?? RepositoryError.remote
        }
    }
}
