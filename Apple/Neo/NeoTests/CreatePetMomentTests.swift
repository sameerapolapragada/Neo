import XCTest
@testable import Neo

@MainActor
final class CreatePetMomentTests: XCTestCase {
    private let jpeg = Data([0xFF, 0xD8, 0xFF, 0xD9])

    func testTitleValidation() async throws {
        let harness = try await makeHarness()
        XCTAssertFalse(harness.model.hasUnsavedChanges)
        XCTAssertTrue(Calendar.current.isDateInToday(harness.model.momentDate))
        await harness.model.save()
        XCTAssertFalse(harness.model.didSave)
        XCTAssertEqual(harness.model.fieldErrors[.title], "Title is required")
        let untitled = try await harness.moments.list(petId: harness.petId, ownerId: harness.owner)
        XCTAssertTrue(untitled.isEmpty)

        harness.model.title = String(repeating: "a", count: MomentValidation.titleLimit + 1)
        XCTAssertNil(harness.model.addJPEG(jpeg))
        await harness.model.save()
        XCTAssertEqual(
            harness.model.fieldErrors[.title],
            "Title must be \(MomentValidation.titleLimit) characters or less"
        )
        XCTAssertFalse(harness.model.didSave)

        harness.model.title = String(repeating: "b", count: MomentValidation.titleLimit)
        harness.model.caption = String(repeating: "c", count: MomentValidation.captionLimit + 1)
        await harness.model.save()
        XCTAssertEqual(
            harness.model.fieldErrors[.caption],
            "Caption must be \(MomentValidation.captionLimit) characters or less"
        )
        XCTAssertEqual(harness.model.title.count, MomentValidation.titleLimit)
        XCTAssertEqual(harness.model.photos.count, 1)

        harness.model.caption = ""
        XCTAssertTrue(harness.model.hasUnsavedChanges)
        await harness.model.save()
        let saved = try await harness.moments.moment(
            id: harness.model.momentId,
            petId: harness.petId,
            ownerId: harness.owner
        )
        XCTAssertEqual(saved.title.count, MomentValidation.titleLimit)
        XCTAssertEqual(saved.caption, "")
    }

    func testPhotoCountRestrictions() async throws {
        let harness = try await makeHarness()
        harness.model.title = "Morning"
        await harness.model.save()
        XCTAssertEqual(harness.model.fieldErrors[.photos], "Add at least one photo")
        XCTAssertFalse(harness.model.didSave)

        for _ in 0..<MomentValidation.maximumPhotos {
            XCTAssertNil(harness.model.addJPEG(jpeg))
        }
        XCTAssertEqual(harness.model.photos.count, MomentValidation.maximumPhotos)
        XCTAssertNotNil(harness.model.addJPEG(jpeg))
        XCTAssertEqual(harness.model.photos.count, MomentValidation.maximumPhotos)
        XCTAssertFalse(harness.model.canAddPhoto)

        let first = harness.model.photos[0].id
        let second = harness.model.photos[1].id
        harness.model.movePhoto(from: 0, to: 1)
        XCTAssertEqual(harness.model.photos[0].id, second)
        XCTAssertEqual(harness.model.photos[1].id, first)

        harness.model.removePhoto(id: first)
        XCTAssertEqual(harness.model.photos.count, MomentValidation.maximumPhotos - 1)
        XCTAssertFalse(harness.model.photos.contains(where: { $0.id == first }))
    }

    func testFailedUploadRecovery() async throws {
        let owner = UUID()
        let petId = UUID()
        let pets = InMemoryPetRepository()
        let moments = InMemoryMomentRepository()
        _ = try await pets.upsert(makePet(owner: owner, id: petId))
        let uploader = FlakyMomentUploader()
        let model = CreatePetMomentViewModel(
            ownerId: owner,
            petId: petId,
            pets: pets,
            moments: moments,
            uploader: uploader
        )
        model.title = "Porch light"
        model.caption = "He waited by the door."
        XCTAssertNil(model.addJPEG(jpeg))
        XCTAssertNil(model.addJPEG(jpeg))
        await uploader.failOnCall(2)

        await model.save()
        XCTAssertFalse(model.didSave)
        XCTAssertFalse(model.isSaving)
        XCTAssertEqual(model.saveError, RepositoryError.remote.localizedDescription)
        XCTAssertEqual(model.title, "Porch light")
        XCTAssertEqual(model.caption, "He waited by the door.")
        XCTAssertEqual(model.photos.count, 2)
        let abandoned = try await moments.list(petId: petId, ownerId: owner)
        XCTAssertTrue(abandoned.isEmpty)
        let storedAfterFailure = await uploader.storedCount()
        XCTAssertEqual(storedAfterFailure, 0)

        await uploader.failOnCall(nil)
        await model.save()
        XCTAssertTrue(model.didSave)
        let saved = try await moments.moment(id: model.momentId, petId: petId, ownerId: owner)
        XCTAssertEqual(saved.media.count, 2)
        XCTAssertEqual(saved.media.map(\.sortOrder), [0, 1])

        let partialMoments = InMemoryMomentRepository()
        let partial = PartialMomentRepository(inner: partialMoments)
        let store = InMemoryMediaStore()
        let retry = CreatePetMomentViewModel(
            ownerId: owner,
            petId: petId,
            pets: pets,
            moments: partial,
            uploader: store
        )
        retry.title = "Should not remain"
        XCTAssertNil(retry.addJPEG(jpeg))
        await partial.failNextUpsert()
        await retry.save()
        XCTAssertFalse(retry.didSave)
        XCTAssertEqual(retry.title, "Should not remain")
        XCTAssertEqual(retry.photos.count, 1)
        let partialRows = try await partialMoments.list(petId: petId, ownerId: owner)
        XCTAssertTrue(partialRows.isEmpty)
        let leftoverFiles = await store.objectCount()
        XCTAssertEqual(leftoverFiles, 0)
    }

    func testDuplicateSavePrevention() async throws {
        let harness = try await makeHarness()
        let gate = UploadGate()
        let uploader = PausingMomentUploader(gate: gate)
        let model = CreatePetMomentViewModel(
            ownerId: harness.owner,
            petId: harness.petId,
            pets: harness.pets,
            moments: harness.moments,
            uploader: uploader
        )
        model.title = "One save"
        XCTAssertNil(model.addJPEG(jpeg))

        let first = Task { await model.save() }
        await gate.waitUntilPaused()
        XCTAssertTrue(model.isSaving)
        let second = Task { await model.save() }
        await second.value
        XCTAssertFalse(model.didSave)
        XCTAssertTrue(model.isSaving)

        gate.resume()
        await first.value
        XCTAssertTrue(model.didSave)
        XCTAssertFalse(model.isSaving)
        let rows = try await harness.moments.list(petId: harness.petId, ownerId: harness.owner)
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows.first?.id, model.momentId)
    }

    func testCorrectPetAssociation() async throws {
        let harness = try await makeHarness()
        harness.model.title = "Our walk"
        harness.model.category = .adventure
        XCTAssertNil(harness.model.addJPEG(jpeg))
        await harness.model.save()

        let saved = try await harness.moments.moment(
            id: harness.model.momentId,
            petId: harness.petId,
            ownerId: harness.owner
        )
        XCTAssertEqual(saved.ownerId, harness.owner)
        XCTAssertEqual(saved.petId, harness.petId)
        XCTAssertEqual(saved.category, .adventure)
        let path = try XCTUnwrap(saved.media.first?.storagePath)
        XCTAssertTrue(
            MediaObjectPath.isMomentPhoto(
                path,
                ownerId: harness.owner,
                petId: harness.petId,
                momentId: harness.model.momentId
            )
        )

        let stranger = CreatePetMomentViewModel(
            ownerId: UUID(),
            petId: harness.petId,
            pets: harness.pets,
            moments: harness.moments,
            uploader: InMemoryMediaStore()
        )
        stranger.title = "Not mine"
        XCTAssertNil(stranger.addJPEG(jpeg))
        await stranger.save()
        XCTAssertFalse(stranger.didSave)
        XCTAssertEqual(stranger.saveError, "That pet isn't on this account.")
        XCTAssertEqual(stranger.title, "Not mine")
        let rows = try await harness.moments.list(petId: harness.petId, ownerId: harness.owner)
        XCTAssertEqual(rows.map(\.title), ["Our walk"])

        var stolen = saved
        stolen.media[0].storagePath = "\(UUID().uuidString.lowercased())/\(harness.petId.uuidString.lowercased())/file.jpg"
        do {
            _ = try await harness.moments.upsert(stolen)
            XCTFail("Expected a cross-user storage path to be rejected")
        } catch RepositoryError.invalidPhoto {
        }
        let unchanged = try await harness.moments.moment(
            id: saved.id,
            petId: harness.petId,
            ownerId: harness.owner
        )
        XCTAssertEqual(unchanged.media.first?.storagePath, path)
    }

    func testPersistenceAndRefresh() async throws {
        let harness = try await makeHarness()
        harness.model.title = "First morning"
        harness.model.caption = "Sun on the rug."
        harness.model.category = .milestone
        XCTAssertNil(harness.model.addJPEG(jpeg))
        await harness.model.save()
        XCTAssertTrue(harness.model.didSave)

        let feed = PetMomentsViewModel(
            repository: harness.moments,
            media: SignedMediaURLCache(signer: InMemoryMediaStore())
        )
        await feed.load(pet: harness.pet)
        XCTAssertEqual(feed.moments.map(\.title), ["First morning"])
        XCTAssertEqual(feed.moments.first?.petId, harness.petId)
        XCTAssertEqual(feed.moments.first?.ownerId, harness.owner)
        XCTAssertEqual(feed.moments.first?.caption, "Sun on the rug.")
        XCTAssertEqual(feed.moments.first?.category, .milestone)
        XCTAssertEqual(feed.presentation(for: harness.pet), .loaded)
    }

    private func makeHarness() async throws -> Harness {
        let owner = UUID()
        let petId = UUID()
        let pets = InMemoryPetRepository()
        let moments = InMemoryMomentRepository()
        let pet = makePet(owner: owner, id: petId)
        _ = try await pets.upsert(pet)
        let model = CreatePetMomentViewModel(
            ownerId: owner,
            petId: petId,
            pets: pets,
            moments: moments,
            uploader: InMemoryMediaStore()
        )
        return Harness(owner: owner, petId: petId, pet: pet, pets: pets, moments: moments, model: model)
    }

    private func makePet(owner: UUID, id: UUID) -> Pet {
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
            photoPath: nil,
            bio: "",
            favoriteToy: nil,
            isFavorite: false,
            createdAt: now,
            updatedAt: now
        )
    }
}

private struct Harness {
    let owner: UUID
    let petId: UUID
    let pet: Pet
    let pets: InMemoryPetRepository
    let moments: InMemoryMomentRepository
    let model: CreatePetMomentViewModel
}

private actor FlakyMomentUploader: MediaUploading {
    private let store = InMemoryMediaStore()
    private var calls = 0
    private var failCall: Int?

    func failOnCall(_ call: Int?) {
        calls = 0
        failCall = call
    }

    func uploadJPEG(_ data: Data, ownerId: UUID, petId: UUID) async throws -> String {
        try await store.uploadJPEG(data, ownerId: ownerId, petId: petId)
    }

    func uploadMomentJPEG(_ data: Data, ownerId: UUID, petId: UUID, momentId: UUID) async throws -> String {
        calls += 1
        if calls == failCall {
            throw RepositoryError.remote
        }
        return try await store.uploadMomentJPEG(data, ownerId: ownerId, petId: petId, momentId: momentId)
    }

    func deleteUploadedObject(_ path: String, ownerId: UUID) async throws {
        try await store.deleteUploadedObject(path, ownerId: ownerId)
    }

    func storedCount() async -> Int {
        await store.objectCount()
    }
}

private actor PartialMomentRepository: MomentRepository {
    let inner: InMemoryMomentRepository
    private var failUpsert = false

    init(inner: InMemoryMomentRepository) {
        self.inner = inner
    }

    func failNextUpsert() {
        failUpsert = true
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
        let saved = try await inner.upsert(moment)
        if failUpsert {
            failUpsert = false
            throw RepositoryError.remote
        }
        return saved
    }

    func setFavorite(id: UUID, petId: UUID, ownerId: UUID, isFavorite: Bool) async throws -> PetMoment {
        try await inner.setFavorite(id: id, petId: petId, ownerId: ownerId, isFavorite: isFavorite)
    }

    func delete(id: UUID, ownerId: UUID) async throws {
        try await inner.delete(id: id, ownerId: ownerId)
    }
}

private actor PausingMomentUploader: MediaUploading {
    let gate: UploadGate
    private let store = InMemoryMediaStore()

    init(gate: UploadGate) {
        self.gate = gate
    }

    func uploadJPEG(_ data: Data, ownerId: UUID, petId: UUID) async throws -> String {
        try await store.uploadJPEG(data, ownerId: ownerId, petId: petId)
    }

    func uploadMomentJPEG(_ data: Data, ownerId: UUID, petId: UUID, momentId: UUID) async throws -> String {
        await gate.wait()
        return try await store.uploadMomentJPEG(data, ownerId: ownerId, petId: petId, momentId: momentId)
    }

    func deleteUploadedObject(_ path: String, ownerId: UUID) async throws {
        try await store.deleteUploadedObject(path, ownerId: ownerId)
    }
}

private final class UploadGate: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<Void, Never>?
    private var waiting: CheckedContinuation<Void, Never>?

    func wait() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            lock.lock()
            self.continuation = continuation
            let waiting = self.waiting
            self.waiting = nil
            lock.unlock()
            waiting?.resume()
        }
    }

    func waitUntilPaused() async {
        let alreadyPaused: Bool = {
            lock.lock()
            let paused = continuation != nil
            lock.unlock()
            return paused
        }()
        if alreadyPaused { return }
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            lock.lock()
            if self.continuation != nil {
                lock.unlock()
                continuation.resume()
            } else {
                self.waiting = continuation
                lock.unlock()
            }
        }
    }

    func resume() {
        lock.lock()
        let continuation = self.continuation
        self.continuation = nil
        lock.unlock()
        continuation?.resume()
    }
}
