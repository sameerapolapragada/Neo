import Foundation

struct MomentDeletionService: MomentDeleting, Sendable {
    private let pets: any PetRepository
    private let moments: any MomentRepository
    private let uploader: any MediaUploading

    init(pets: any PetRepository, moments: any MomentRepository, uploader: any MediaUploading) {
        self.pets = pets
        self.moments = moments
        self.uploader = uploader
    }

    /// Removes owned storage objects, then the moment row.
    /// A missing moment is already deleted and can be requested again safely.
    /// The row stays when storage cleanup fails, so the paths are still available.
    func delete(momentId: UUID, petId: UUID, ownerId: UUID) async throws {
        do {
            _ = try await pets.pet(id: petId, ownerId: ownerId)
        } catch RepositoryError.notFound {
            throw RepositoryError.notFound
        }
        let moment: PetMoment
        do {
            moment = try await moments.moment(id: momentId, petId: petId, ownerId: ownerId)
        } catch RepositoryError.notFound {
            return
        }
        guard moment.ownerId == ownerId, moment.petId == petId, moment.id == momentId else {
            throw RepositoryError.notFound
        }
        try await OwnedObjectCleanup.remove(moment.media.map(\.storagePath), ownerId: ownerId, uploader: uploader)
        var lastError: Error?
        for _ in 0..<2 {
            do {
                try await moments.delete(id: moment.id, ownerId: ownerId)
                return
            } catch RepositoryError.notFound {
                return
            } catch {
                lastError = error
            }
        }
        throw lastError ?? RepositoryError.remote
    }
}
