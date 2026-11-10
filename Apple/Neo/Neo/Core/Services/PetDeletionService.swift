import Foundation

/// Local deletion used by tests and previews.
/// Storage objects go first. The pet row stays until that cleanup finishes,
/// so a retry still knows which photographs belong to this pet.
struct PetDeletionService: PetDeleting, Sendable {
    private let pets: any PetRepository
    private let moments: any MomentRepository
    private let uploader: any MediaUploading
    private let removePet: @Sendable (UUID, UUID) async throws -> Void

    init(
        pets: any PetRepository,
        moments: any MomentRepository,
        uploader: any MediaUploading,
        removePet: @escaping @Sendable (UUID, UUID) async throws -> Void
    ) {
        self.pets = pets
        self.moments = moments
        self.uploader = uploader
        self.removePet = removePet
    }

    func delete(petId: UUID, ownerId: UUID) async throws {
        let pet: Pet
        do {
            pet = try await pets.pet(id: petId, ownerId: ownerId)
        } catch RepositoryError.notFound {
            return
        }
        guard pet.ownerId == ownerId, pet.id == petId else {
            throw RepositoryError.notFound
        }
        let ownedMoments = try await moments.list(petId: petId, ownerId: ownerId)
        guard ownedMoments.allSatisfy({ $0.ownerId == ownerId && $0.petId == petId }) else {
            throw RepositoryError.notFound
        }
        var paths: [String] = []
        if let photoPath = pet.photoPath {
            paths.append(photoPath)
        }
        for moment in ownedMoments {
            paths.append(contentsOf: moment.media.map(\.storagePath))
        }
        try await OwnedObjectCleanup.remove(paths, ownerId: ownerId, uploader: uploader)
        for moment in ownedMoments {
            try await deleteMomentRow(moment.id, ownerId: ownerId)
        }
        try await deletePetRow(petId, ownerId: ownerId)
    }

    private func deleteMomentRow(_ id: UUID, ownerId: UUID) async throws {
        var lastError: Error?
        for _ in 0..<2 {
            do {
                try await moments.delete(id: id, ownerId: ownerId)
                return
            } catch RepositoryError.notFound {
                return
            } catch {
                lastError = error
            }
        }
        throw lastError ?? RepositoryError.remote
    }

    private func deletePetRow(_ id: UUID, ownerId: UUID) async throws {
        var lastError: Error?
        for _ in 0..<2 {
            do {
                try await removePet(id, ownerId)
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
