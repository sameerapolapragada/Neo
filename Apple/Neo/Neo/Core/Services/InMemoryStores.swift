#if DEBUG
import Foundation

actor InMemoryPetRepository: PetRepository {
    private var storage: [UUID: Pet] = [:]

    func list(ownerId: UUID) async throws -> [Pet] {
        storage.values
            .filter { $0.ownerId == ownerId }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func pet(id: UUID, ownerId: UUID) async throws -> Pet {
        guard let pet = storage[id], pet.ownerId == ownerId else {
            throw RepositoryError.notFound
        }
        return pet
    }

    func upsert(_ pet: Pet) async throws -> Pet {
        if let existing = storage[pet.id], existing.ownerId != pet.ownerId {
            throw RepositoryError.notFound
        }
        try MediaPathGuard.validate(pet.photoPath)
        if let photoPath = pet.photoPath, !MediaObjectPath.isProfilePhoto(photoPath, ownerId: pet.ownerId, petId: pet.id) {
            throw RepositoryError.invalidPhoto
        }
        storage[pet.id] = pet
        return pet
    }

    func deleteOwned(id: UUID, ownerId: UUID) async throws {
        guard let pet = storage[id], pet.ownerId == ownerId else {
            throw RepositoryError.notFound
        }
        storage.removeValue(forKey: id)
    }
}

actor InMemoryMomentRepository: MomentRepository {
    private var storage: [UUID: PetMoment] = [:]

    func list(petId: UUID, ownerId: UUID) async throws -> [PetMoment] {
        MomentFeedSorting.ordered(owned(petId: petId, ownerId: ownerId))
    }

    func moment(id: UUID, petId: UUID, ownerId: UUID) async throws -> PetMoment {
        guard let moment = storage[id], moment.petId == petId, moment.ownerId == ownerId else {
            throw RepositoryError.notFound
        }
        return moment
    }

    func page(
        petId: UUID,
        ownerId: UUID,
        category: MomentCategory?,
        cursor: MomentCursor?,
        limit: Int
    ) async throws -> MomentPage {
        MomentFeedSorting.page(
            from: owned(petId: petId, ownerId: ownerId),
            category: category,
            cursor: cursor,
            limit: limit
        )
    }

    func upsert(_ moment: PetMoment) async throws -> PetMoment {
        if let existing = storage[moment.id], existing.ownerId != moment.ownerId {
            throw RepositoryError.notFound
        }
        for item in moment.media {
            guard item.momentId == moment.id, item.ownerId == moment.ownerId else {
                throw RepositoryError.invalidPhoto
            }
            try MediaPathGuard.validate(item.storagePath)
            guard MediaObjectPath.isMomentPhoto(
                item.storagePath,
                ownerId: moment.ownerId,
                petId: moment.petId,
                momentId: moment.id
            ) else {
                throw RepositoryError.invalidPhoto
            }
        }
        var stored = moment
        stored.media = moment.media.inDisplayOrder()
        storage[moment.id] = stored
        return stored
    }

    func setFavorite(id: UUID, petId: UUID, ownerId: UUID, isFavorite: Bool) async throws -> PetMoment {
        guard var moment = storage[id], moment.petId == petId, moment.ownerId == ownerId else {
            throw RepositoryError.notFound
        }
        moment.isFavorite = isFavorite
        moment.updatedAt = Date()
        storage[id] = moment
        return moment
    }

    func delete(id: UUID, ownerId: UUID) async throws {
        guard let moment = storage[id], moment.ownerId == ownerId else {
            throw RepositoryError.notFound
        }
        storage.removeValue(forKey: id)
    }

    private func owned(petId: UUID, ownerId: UUID) -> [PetMoment] {
        storage.values.filter { $0.petId == petId && $0.ownerId == ownerId }
    }
}

actor InMemoryMemoryRepository: MemoryRepository {
    private var storage: [UUID: Memory] = [:]

    func list(petId: UUID, ownerId: UUID) async throws -> [Memory] {
        storage.values
            .filter { $0.petId == petId && $0.ownerId == ownerId }
            .sorted { $0.occurredAt > $1.occurredAt }
    }

    func upsert(_ memory: Memory) async throws -> Memory {
        try MediaPathGuard.validate(memory.photoPath)
        storage[memory.id] = memory
        return memory
    }

    func delete(id: UUID, ownerId: UUID) async throws {
        guard let memory = storage[id], memory.ownerId == ownerId else {
            throw RepositoryError.notFound
        }
        storage.removeValue(forKey: id)
    }
}

actor InMemoryMediaStore: MediaUploading, MediaSigning {
    private var files: [String: Data] = [:]

    func uploadJPEG(_ data: Data, ownerId: UUID, petId: UUID) async throws -> String {
        try MomentUploadRules.validateJPEG(data)
        let path = MediaObjectPath.jpeg(ownerId: ownerId, petId: petId)
        files[path] = data
        return path
    }

    func uploadMomentJPEG(_ data: Data, ownerId: UUID, petId: UUID, momentId: UUID) async throws -> String {
        try MomentUploadRules.validateJPEG(data)
        let path = MediaObjectPath.momentJPEG(ownerId: ownerId, petId: petId, momentId: momentId)
        files[path] = data
        return path
    }

    func deleteUploadedObject(_ path: String, ownerId: UUID) async throws {
        guard MediaObjectPath.belongsToOwner(path, ownerId: ownerId) else {
            throw RepositoryError.invalidPhoto
        }
        files.removeValue(forKey: path)
    }

    func contains(_ path: String) -> Bool {
        files[path] != nil
    }

    func objectCount() -> Int {
        files.count
    }

    func signedURL(for path: String, expiresIn: Int) async throws -> URL {
        guard MediaObjectPath.isCanonical(path), !MediaObjectPath.isPublicObjectURL(path) else {
            throw RepositoryError.invalidPhoto
        }
        guard files[path] != nil else {
            throw RepositoryError.notFound
        }
        guard let url = URL(string: "https://signed.test/\(expiresIn)/\(path)"),
              !MediaObjectPath.isPublicObjectURL(url.absoluteString) else {
            throw RepositoryError.invalidPhoto
        }
        return url
    }
}
#endif
