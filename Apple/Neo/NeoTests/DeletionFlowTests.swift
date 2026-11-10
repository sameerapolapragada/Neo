import UIKit
import XCTest
@testable import Neo

final class DeletionFlowTests: XCTestCase {
    func testDeletionRequestsDoNotNameAnOwner() throws {
        let moment = MomentDeletionRequest(momentId: UUID(), petId: UUID())
        let pet = PetDeletionRequest(petId: UUID())
        let cleanup = StorageCleanupRequest(paths: ["owned/pets/pet/profile/file.jpg"])
        for value in [encode(moment), encode(pet), encode(cleanup)] {
            let json = try XCTUnwrap(value)
            XCTAssertFalse(json.contains("ownerId"))
            XCTAssertFalse(json.contains("owner_id"))
        }
        let momentJSON = try XCTUnwrap(encode(moment))
        XCTAssertTrue(momentJSON.contains("momentId"))
        XCTAssertTrue(momentJSON.contains("petId"))
    }

    func testOwnerDeletesMomentAndFivePhotos() async throws {
        let owner = UUID()
        let petId = UUID()
        let momentId = UUID()
        let store = InMemoryMediaStore()
        var media: [MomentMedia] = []
        for order in 0..<5 {
            let path = try await store.uploadMomentJPEG(jpeg, ownerId: owner, petId: petId, momentId: momentId)
            media.append(photo(owner: owner, moment: momentId, path: path, order: order))
        }
        let moments = InMemoryMomentRepository()
        _ = try await moments.upsert(moment(owner: owner, pet: petId, id: momentId, media: media))
        let pets = try await seedPet(owner: owner, id: petId, photoPath: nil, store: store)
        let service = MomentDeletionService(pets: pets, moments: moments, uploader: store)
        try await service.delete(momentId: momentId, petId: petId, ownerId: owner)
        try await service.delete(momentId: momentId, petId: petId, ownerId: owner)
        let remainingObjects = await store.objectCount()
        XCTAssertEqual(remainingObjects, 0)
        await assertMissing(moments, id: momentId, petId: petId, owner: owner)
    }

    func testMissingStorageObjectStillDeletesTheMoment() async throws {
        let owner = UUID()
        let petId = UUID()
        let momentId = UUID()
        let path = MediaObjectPath.momentJPEG(ownerId: owner, petId: petId, momentId: momentId)
        let moments = InMemoryMomentRepository()
        _ = try await moments.upsert(moment(owner: owner, pet: petId, id: momentId, media: [
            photo(owner: owner, moment: momentId, path: path, order: 0)
        ]))
        let store = InMemoryMediaStore()
        let service = MomentDeletionService(
            pets: try await seedPet(owner: owner, id: petId, photoPath: nil, store: store),
            moments: moments,
            uploader: store
        )
        try await service.delete(momentId: momentId, petId: petId, ownerId: owner)
        await assertMissing(moments, id: momentId, petId: petId, owner: owner)
    }

    func testStorageFailureKeepsTheMomentForRetry() async throws {
        let owner = UUID()
        let petId = UUID()
        let momentId = UUID()
        let store = FlakyMediaStore(failures: 3)
        let path = try await store.uploadMomentJPEG(jpeg, ownerId: owner, petId: petId, momentId: momentId)
        let moments = InMemoryMomentRepository()
        _ = try await moments.upsert(moment(owner: owner, pet: petId, id: momentId, media: [
            photo(owner: owner, moment: momentId, path: path, order: 0)
        ]))
        let pets = try await seedPet(owner: owner, id: petId, photoPath: nil, store: store)
        let service = MomentDeletionService(pets: pets, moments: moments, uploader: store)
        do {
            try await service.delete(momentId: momentId, petId: petId, ownerId: owner)
            XCTFail("Expected the first cleanup to stop")
        } catch RepositoryError.remote {
        }
        let kept = try await moments.moment(id: momentId, petId: petId, ownerId: owner)
        XCTAssertEqual(kept.media.first?.storagePath, path)
        let keptObject = await store.contains(path)
        XCTAssertTrue(keptObject)
        try await service.delete(momentId: momentId, petId: petId, ownerId: owner)
        let removedObject = await store.contains(path)
        XCTAssertFalse(removedObject)
        await assertMissing(moments, id: momentId, petId: petId, owner: owner)
    }

    func testDatabaseFailureKeepsPathsAndRetryFinishes() async throws {
        let owner = UUID()
        let petId = UUID()
        let momentId = UUID()
        let store = InMemoryMediaStore()
        let path = try await store.uploadMomentJPEG(jpeg, ownerId: owner, petId: petId, momentId: momentId)
        let inner = InMemoryMomentRepository()
        _ = try await inner.upsert(moment(owner: owner, pet: petId, id: momentId, media: [
            photo(owner: owner, moment: momentId, path: path, order: 0)
        ]))
        let moments = FlakyMomentRepository(inner: inner, deleteFailures: 3)
        let service = MomentDeletionService(
            pets: try await seedPet(owner: owner, id: petId, photoPath: nil, store: store),
            moments: moments,
            uploader: store
        )
        do {
            try await service.delete(momentId: momentId, petId: petId, ownerId: owner)
            XCTFail("Expected the row delete to stop")
        } catch RepositoryError.remote {
        }
        let removedBeforeRetry = await store.contains(path)
        XCTAssertFalse(removedBeforeRetry)
        let stillThere = try await inner.moment(id: momentId, petId: petId, ownerId: owner)
        XCTAssertEqual(stillThere.media.first?.storagePath, path)
        try await service.delete(momentId: momentId, petId: petId, ownerId: owner)
        await assertMissing(inner, id: momentId, petId: petId, owner: owner)
    }

    func testPetDeletionRemovesOnlyThatPetsPhotos() async throws {
        let owner = UUID()
        let petId = UUID()
        let otherPetId = UUID()
        let momentId = UUID()
        let store = InMemoryMediaStore()
        let profile = try await store.uploadJPEG(jpeg, ownerId: owner, petId: petId)
        let otherProfile = try await store.uploadJPEG(jpeg, ownerId: owner, petId: otherPetId)
        let momentPath = try await store.uploadMomentJPEG(jpeg, ownerId: owner, petId: petId, momentId: momentId)
        let pets = InMemoryPetRepository()
        _ = try await pets.upsert(makePet(owner: owner, id: petId, photoPath: profile))
        _ = try await pets.upsert(makePet(owner: owner, id: otherPetId, photoPath: otherProfile))
        let moments = InMemoryMomentRepository()
        _ = try await moments.upsert(moment(owner: owner, pet: petId, id: momentId, media: [
            photo(owner: owner, moment: momentId, path: momentPath, order: 0)
        ]))
        let service = PetDeletionService(pets: pets, moments: moments, uploader: store) { id, ownerId in
            try await pets.deleteOwned(id: id, ownerId: ownerId)
        }
        try await service.delete(petId: petId, ownerId: owner)
        try await service.delete(petId: petId, ownerId: owner)
        let profileGone = await store.contains(profile)
        let momentGone = await store.contains(momentPath)
        let otherKept = await store.contains(otherProfile)
        XCTAssertFalse(profileGone)
        XCTAssertFalse(momentGone)
        XCTAssertTrue(otherKept)
        let remaining = try await pets.list(ownerId: owner)
        XCTAssertEqual(remaining.map(\.id), [otherPetId])
        await assertMissing(moments, id: momentId, petId: petId, owner: owner)
    }

    func testAnotherOwnerCannotDeletePetMomentOrImage() async throws {
        let owner = UUID()
        let stranger = UUID()
        let petId = UUID()
        let momentId = UUID()
        let store = InMemoryMediaStore()
        let profile = try await store.uploadJPEG(jpeg, ownerId: owner, petId: petId)
        let momentPath = try await store.uploadMomentJPEG(jpeg, ownerId: owner, petId: petId, momentId: momentId)
        let pets = InMemoryPetRepository()
        _ = try await pets.upsert(makePet(owner: owner, id: petId, photoPath: profile))
        let moments = InMemoryMomentRepository()
        _ = try await moments.upsert(moment(owner: owner, pet: petId, id: momentId, media: [
            photo(owner: owner, moment: momentId, path: momentPath, order: 0)
        ]))
        let momentService = MomentDeletionService(pets: pets, moments: moments, uploader: store)
        do {
            try await momentService.delete(momentId: momentId, petId: petId, ownerId: stranger)
            XCTFail("Expected the other account to be refused")
        } catch RepositoryError.notFound {
        }
        let petService = PetDeletionService(pets: pets, moments: moments, uploader: store) { id, ownerId in
            try await pets.deleteOwned(id: id, ownerId: ownerId)
        }
        try await petService.delete(petId: petId, ownerId: stranger)
        let profileKept = await store.contains(profile)
        let momentKept = await store.contains(momentPath)
        XCTAssertTrue(profileKept)
        XCTAssertTrue(momentKept)
        let kept = try await moments.moment(id: momentId, petId: petId, ownerId: owner)
        XCTAssertEqual(kept.media.first?.storagePath, momentPath)
        let keptPet = try await pets.pet(id: petId, ownerId: owner)
        XCTAssertEqual(keptPet.photoPath, profile)
    }

    func testUnownedPathDoesNotDeleteTheRecord() async throws {
        let owner = UUID()
        let petId = UUID()
        let momentId = UUID()
        let foreign = MediaObjectPath.momentJPEG(ownerId: UUID(), petId: petId, momentId: momentId)
        let moments = StubMomentRepository(stored: moment(owner: owner, pet: petId, id: momentId, media: [
            photo(owner: owner, moment: momentId, path: foreign, order: 0)
        ]))
        let service = MomentDeletionService(
            pets: try await seedPet(owner: owner, id: petId, photoPath: nil, store: InMemoryMediaStore()),
            moments: moments,
            uploader: InMemoryMediaStore()
        )
        do {
            try await service.delete(momentId: momentId, petId: petId, ownerId: owner)
            XCTFail("Expected an unowned path to stop deletion")
        } catch RepositoryError.invalidPhoto {
        }
        let calls = await moments.deleteCalls
        XCTAssertEqual(calls, 0)
    }

    func testConcurrentMomentDeletesLeaveNoRecord() async throws {
        let owner = UUID()
        let petId = UUID()
        let momentId = UUID()
        let store = InMemoryMediaStore()
        let path = try await store.uploadMomentJPEG(jpeg, ownerId: owner, petId: petId, momentId: momentId)
        let moments = InMemoryMomentRepository()
        _ = try await moments.upsert(moment(owner: owner, pet: petId, id: momentId, media: [
            photo(owner: owner, moment: momentId, path: path, order: 0)
        ]))
        let service = MomentDeletionService(
            pets: try await seedPet(owner: owner, id: petId, photoPath: nil, store: store),
            moments: moments,
            uploader: store
        )
        await withTaskGroup(of: Void.self) { group in
            group.addTask { try? await service.delete(momentId: momentId, petId: petId, ownerId: owner) }
            group.addTask { try? await service.delete(momentId: momentId, petId: petId, ownerId: owner) }
        }
        let raceRemoved = await store.contains(path)
        XCTAssertFalse(raceRemoved)
        await assertMissing(moments, id: momentId, petId: petId, owner: owner)
    }

    func testReplacedProfilePhotoIsRemovedOnlyAfterTheNewOneIsSaved() async throws {
        let owner = UUID()
        let petId = UUID()
        let store = InMemoryMediaStore()
        let original = try await store.uploadJPEG(jpeg, ownerId: owner, petId: petId)
        let pets = InMemoryPetRepository()
        let pet = makePet(owner: owner, id: petId, photoPath: original)
        _ = try await pets.upsert(pet)
        let photo = png
        let library = await MainActor.run {
            PetLibrary(ownerId: owner, repository: pets, selection: InMemoryActivePetStore())
        }
        await library.refresh()
        let model = await MainActor.run {
            EditPetProfileViewModel(
                ownerId: owner,
                pet: pet,
                pets: pets,
                uploader: store,
                media: SignedMediaURLCache(signer: store),
                library: library
            )
        }
        await MainActor.run { model.stagePhoto(photo) }
        await model.save()
        let didSave = await MainActor.run { model.didSave }
        XCTAssertTrue(didSave)
        let saved = try await pets.pet(id: petId, ownerId: owner)
        let replacement = try XCTUnwrap(saved.photoPath)
        XCTAssertNotEqual(replacement, original)
        let replacementKept = await store.contains(replacement)
        let originalRemoved = await store.contains(original)
        XCTAssertTrue(replacementKept)
        XCTAssertFalse(originalRemoved)
    }

    private func encode(_ value: some Encodable) -> String? {
        guard let data = try? JSONEncoder().encode(value) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func assertMissing(
        _ moments: InMemoryMomentRepository,
        id: UUID,
        petId: UUID,
        owner: UUID
    ) async {
        do {
            _ = try await moments.moment(id: id, petId: petId, ownerId: owner)
            XCTFail("Expected the moment to be gone")
        } catch RepositoryError.notFound {
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }

    private func seedPet(
        owner: UUID,
        id: UUID,
        photoPath: String?,
        store: any MediaUploading
    ) async throws -> InMemoryPetRepository {
        _ = store
        let pets = InMemoryPetRepository()
        _ = try await pets.upsert(makePet(owner: owner, id: id, photoPath: photoPath))
        return pets
    }

    private func makePet(owner: UUID, id: UUID, photoPath: String?) -> Pet {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        return Pet(
            id: id,
            ownerId: owner,
            name: "Milo",
            species: .dog,
            breed: "",
            birthday: nil,
            gender: .unknown,
            adoptionDate: nil,
            weightValue: nil,
            weightUnit: .pounds,
            microchipId: nil,
            photoPath: photoPath,
            bio: "",
            favoriteToy: nil,
            isFavorite: false,
            createdAt: now,
            updatedAt: now
        )
    }

    private func moment(owner: UUID, pet: UUID, id: UUID, media: [MomentMedia]) -> PetMoment {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        return PetMoment(
            id: id,
            ownerId: owner,
            petId: pet,
            title: "Memory",
            caption: "",
            category: .daily,
            momentDate: now,
            isFavorite: false,
            media: media,
            createdAt: now,
            updatedAt: now
        )
    }

    private func photo(owner: UUID, moment: UUID, path: String, order: Int) -> MomentMedia {
        MomentMedia(
            id: UUID(),
            momentId: moment,
            ownerId: owner,
            storagePath: path,
            sortOrder: order,
            contentType: "image/jpeg",
            byteCount: jpeg.count,
            width: nil,
            height: nil
        )
    }

    private var jpeg: Data { Data([0xFF, 0xD8, 0xFF, 0xD9]) }

    private var png: Data {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 8, height: 8))
        let image = renderer.image { context in
            UIColor.brown.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
        }
        return image.pngData() ?? Data()
    }
}

private actor FlakyMediaStore: MediaUploading {
    private let inner = InMemoryMediaStore()
    private var failures: Int

    init(failures: Int) {
        self.failures = failures
    }

    func uploadJPEG(_ data: Data, ownerId: UUID, petId: UUID) async throws -> String {
        try await inner.uploadJPEG(data, ownerId: ownerId, petId: petId)
    }

    func uploadMomentJPEG(_ data: Data, ownerId: UUID, petId: UUID, momentId: UUID) async throws -> String {
        try await inner.uploadMomentJPEG(data, ownerId: ownerId, petId: petId, momentId: momentId)
    }

    func deleteUploadedObject(_ path: String, ownerId: UUID) async throws {
        if failures > 0 {
            failures -= 1
            throw RepositoryError.remote
        }
        try await inner.deleteUploadedObject(path, ownerId: ownerId)
    }

    func contains(_ path: String) async -> Bool {
        await inner.contains(path)
    }
}

private actor StubMomentRepository: MomentRepository {
    private let stored: PetMoment
    private(set) var deleteCalls = 0

    init(stored: PetMoment) {
        self.stored = stored
    }

    func list(petId: UUID, ownerId: UUID) async throws -> [PetMoment] { [] }

    func moment(id: UUID, petId: UUID, ownerId: UUID) async throws -> PetMoment {
        guard stored.id == id, stored.petId == petId, stored.ownerId == ownerId else {
            throw RepositoryError.notFound
        }
        return stored
    }

    func page(
        petId: UUID,
        ownerId: UUID,
        category: MomentCategory?,
        cursor: MomentCursor?,
        limit: Int
    ) async throws -> MomentPage {
        MomentPage(moments: [], nextCursor: nil)
    }

    func upsert(_ moment: PetMoment) async throws -> PetMoment { moment }

    func setFavorite(id: UUID, petId: UUID, ownerId: UUID, isFavorite: Bool) async throws -> PetMoment {
        stored
    }

    func delete(id: UUID, ownerId: UUID) async throws {
        deleteCalls += 1
    }
}

private actor FlakyMomentRepository: MomentRepository {
    private let inner: InMemoryMomentRepository
    private var deleteFailures: Int

    init(inner: InMemoryMomentRepository, deleteFailures: Int) {
        self.inner = inner
        self.deleteFailures = deleteFailures
    }

    func list(petId: UUID, ownerId: UUID) async throws -> [PetMoment] {
        try await inner.list(petId: petId, ownerId: ownerId)
    }

    func moment(id: UUID, petId: UUID, ownerId: UUID) async throws -> PetMoment {
        try await inner.moment(id: id, petId: petId, ownerId: ownerId)
    }

    func page(
        petId: UUID,
        ownerId: UUID,
        category: MomentCategory?,
        cursor: MomentCursor?,
        limit: Int
    ) async throws -> MomentPage {
        try await inner.page(petId: petId, ownerId: ownerId, category: category, cursor: cursor, limit: limit)
    }

    func upsert(_ moment: PetMoment) async throws -> PetMoment {
        try await inner.upsert(moment)
    }

    func setFavorite(id: UUID, petId: UUID, ownerId: UUID, isFavorite: Bool) async throws -> PetMoment {
        try await inner.setFavorite(id: id, petId: petId, ownerId: ownerId, isFavorite: isFavorite)
    }

    func delete(id: UUID, ownerId: UUID) async throws {
        if deleteFailures > 0 {
            deleteFailures -= 1
            throw RepositoryError.remote
        }
        try await inner.delete(id: id, ownerId: ownerId)
    }
}
