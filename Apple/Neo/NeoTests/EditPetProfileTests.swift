import UIKit
import XCTest
@testable import Neo

@MainActor
final class EditPetProfileTests: XCTestCase {
    func testRequiredNameValidation() async throws {
        let owner = UUID()
        let pets = InMemoryPetRepository()
        let model = makeModel(owner: owner, pet: nil, pets: pets)

        model.species = .dog
        model.name = "   "
        await model.save()
        XCTAssertFalse(model.didSave)
        XCTAssertEqual(model.fieldErrors[.name], "Name is required")
        let blankRows = try await pets.list(ownerId: owner)
        XCTAssertTrue(blankRows.isEmpty)

        model.name = "M"
        await model.save()
        XCTAssertFalse(model.didSave)
        XCTAssertEqual(model.fieldErrors[.name], "Name must be at least 2 characters")
        let shortRows = try await pets.list(ownerId: owner)
        XCTAssertTrue(shortRows.isEmpty)

        model.name = " Milo "
        await model.save()
        XCTAssertTrue(model.didSave)
        let saved = try await pets.pet(id: model.petId, ownerId: owner)
        XCTAssertEqual(saved.name, "Milo")
        XCTAssertNil(saved.birthday)
        XCTAssertNil(saved.adoptionDate)
    }

    func testWeightValidation() async throws {
        let owner = UUID()
        let pets = InMemoryPetRepository()
        let model = makeModel(owner: owner, pet: nil, pets: pets)
        model.name = "Milo"
        model.species = .cat

        for invalid in ["0", "0.0", "-4", "heavy"] {
            model.weightText = invalid
            await model.save()
            XCTAssertFalse(model.didSave)
            XCTAssertNotNil(model.fieldErrors[.weight])
            let rejected = try await pets.list(ownerId: owner)
            XCTAssertTrue(rejected.isEmpty)
        }
        XCTAssertEqual(model.fieldErrors[.weight], "Enter a valid weight")

        model.weightText = "0"
        await model.save()
        XCTAssertEqual(model.fieldErrors[.weight], "Enter a weight greater than zero")

        model.weightText = "12,5"
        model.weightUnit = .kilograms
        await model.save()
        let saved = try await pets.pet(id: model.petId, ownerId: owner)
        XCTAssertEqual(saved.weightValue, 12.5)
        XCTAssertEqual(saved.weightUnit, .kilograms)
        let rows = try await pets.list(ownerId: owner)
        XCTAssertEqual(rows.count, 1)
    }

    func testPersonalityCharacterLimit() async throws {
        let owner = UUID()
        let pets = InMemoryPetRepository()
        let model = makeModel(owner: owner, pet: nil, pets: pets)
        model.name = "Milo"
        model.species = .other
        model.personality = String(repeating: "a", count: PetValidation.personalityLimit + 1)

        await model.save()
        XCTAssertFalse(model.didSave)
        XCTAssertEqual(
            model.fieldErrors[.personality],
            "Personality must be \(PetValidation.personalityLimit) characters or less"
        )
        let rejected = try await pets.list(ownerId: owner)
        XCTAssertTrue(rejected.isEmpty)

        model.personality = String(repeating: "b", count: PetValidation.personalityLimit)
        await model.save()
        let saved = try await pets.pet(id: model.petId, ownerId: owner)
        XCTAssertEqual(saved.bio.count, PetValidation.personalityLimit)
    }

    func testCancellationBehavior() async throws {
        let owner = UUID()
        let pets = InMemoryPetRepository()
        let original = makePet(owner: owner, name: "Milo")
        _ = try await pets.upsert(original)
        let model = makeModel(owner: owner, pet: original, pets: pets)

        XCTAssertFalse(model.hasUnsavedChanges)
        model.name = "Mila"
        model.personality = "Quiet"
        XCTAssertTrue(model.hasUnsavedChanges)

        model.name = original.name
        model.personality = original.bio
        XCTAssertFalse(model.hasUnsavedChanges)

        model.photoJPEG = Data([0x01])
        XCTAssertTrue(model.hasUnsavedChanges)
        model.photoJPEG = nil
        XCTAssertFalse(model.hasUnsavedChanges)

        model.breed = "Shepherd"
        XCTAssertTrue(model.hasUnsavedChanges)
        let stored = try await pets.pet(id: original.id, ownerId: owner)
        XCTAssertEqual(stored, original)
        XCTAssertFalse(model.didSave)
    }

    func testSavingAndErrorHandling() async throws {
        let owner = UUID()
        let pets = RecordingPetRepository()
        let created = Date(timeIntervalSince1970: 1_700_000_000)
        var stored = makePet(owner: owner, name: "Server name", createdAt: created)
        stored.breed = "Stored mix"
        stored.birthday = created
        stored.adoptionDate = created
        stored.weightValue = 14
        stored.favoriteToy = "Rope"
        stored.bio = "Gentle"
        stored.gender = .female
        stored.microchipId = "CHIP-1"
        stored.isFavorite = true
        stored.photoPath = objectPath(owner: owner, pet: stored.id)
        await pets.seed(stored)

        var stale = stored
        stale.name = "Stale"
        stale.bio = "Old"
        let uploader = CountingUploader()
        let model = makeModel(owner: owner, pet: stale, pets: pets, uploader: uploader)
        await model.load()
        XCTAssertEqual(model.name, "Server name")
        XCTAssertEqual(model.personality, "Gentle")
        XCTAssertEqual(model.breed, "Stored mix")
        XCTAssertTrue(model.hasBirthday)
        XCTAssertTrue(model.hasAdoptionDate)
        XCTAssertEqual(model.weightText, "14")
        XCTAssertEqual(model.favoriteToy, "Rope")
        XCTAssertFalse(model.hasUnsavedChanges)
        XCTAssertNil(model.serverError)

        model.breed = "  "
        model.hasBirthday = false
        model.hasAdoptionDate = false
        model.weightText = ""
        model.favoriteToy = " "
        model.personality = "  "
        model.species = .rabbit
        await model.save()

        let saved = try await pets.pet(id: stored.id, ownerId: owner)
        XCTAssertTrue(model.didSave)
        XCTAssertEqual(saved.id, model.petId)
        XCTAssertEqual(saved.breed, "")
        XCTAssertNil(saved.birthday)
        XCTAssertNil(saved.adoptionDate)
        XCTAssertNil(saved.weightValue)
        XCTAssertNil(saved.favoriteToy)
        XCTAssertEqual(saved.bio, "")
        XCTAssertEqual(saved.species, .rabbit)
        XCTAssertEqual(saved.gender, .female)
        XCTAssertEqual(saved.microchipId, "CHIP-1")
        XCTAssertTrue(saved.isFavorite)
        XCTAssertEqual(saved.createdAt, created)
        XCTAssertEqual(saved.photoPath, stored.photoPath)
        XCTAssertEqual(saved.ownerId, owner)
        let uploadsBeforeRetry = await uploader.calls
        XCTAssertEqual(uploadsBeforeRetry, 0)

        model.didSave = false
        model.name = "Server name updated"
        await model.save()
        let rows = try await pets.list(ownerId: owner)
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows.first?.id, stored.id)
        XCTAssertEqual(rows.first?.name, "Server name updated")
        XCTAssertEqual(rows.first?.createdAt, created)
        let updates = await pets.upsertCount
        XCTAssertEqual(updates, 2)

        let library = PetLibrary(ownerId: owner, repository: pets, selection: InMemoryActivePetStore())
        let failingSave = EditPetProfileViewModel(
            ownerId: owner,
            pet: rows[0],
            pets: pets,
            uploader: uploader,
            media: SignedMediaURLCache(signer: InMemoryMediaStore()),
            library: library
        )
        await pets.setUpsertError(RepositoryError.remote)
        failingSave.name = "Should not stick"
        failingSave.photoJPEG = Data([0xAB])
        await failingSave.save()
        XCTAssertFalse(failingSave.didSave)
        XCTAssertFalse(failingSave.isSaving)
        XCTAssertEqual(failingSave.serverError, RepositoryError.remote.localizedDescription)
        let unchanged = try await pets.pet(id: stored.id, ownerId: owner)
        XCTAssertEqual(unchanged.name, "Server name updated")
        XCTAssertEqual(unchanged.photoPath, stored.photoPath)
        let uploadsAfterFailure = await uploader.calls
        XCTAssertEqual(uploadsAfterFailure, 1)
    }

    func testDuplicateSaveSubmitsOneProfile() async throws {
        let owner = UUID()
        let pets = RecordingPetRepository()
        let gate = UploadGate()
        let model = makeModel(
            owner: owner,
            pet: nil,
            pets: pets,
            uploader: PausingUploader(gate: gate)
        )
        model.name = "Milo"
        model.species = .dog
        model.photoJPEG = Data([0x01])

        let first = Task { await model.save() }
        await gate.waitUntilPaused()
        XCTAssertTrue(model.isSaving)
        let second = Task { await model.save() }
        await second.value
        XCTAssertTrue(model.isSaving)
        XCTAssertFalse(model.didSave)

        gate.resume()
        await first.value
        XCTAssertTrue(model.didSave)
        XCTAssertFalse(model.isSaving)
        let rows = try await pets.list(ownerId: owner)
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows.first?.id, model.petId)
        let updates = await pets.upsertCount
        XCTAssertEqual(updates, 1)
        let path = try XCTUnwrap(rows.first?.photoPath)
        XCTAssertTrue(MediaObjectPath.isProfilePhoto(path, ownerId: owner, petId: model.petId))
    }

    func testPhotoReplacementFailure() async throws {
        let owner = UUID()
        let pets = RecordingPetRepository()
        let original = makePet(owner: owner, name: "Milo")
        let originalPath = objectPath(owner: owner, pet: original.id)
        var seeded = original
        seeded.photoPath = originalPath
        await pets.seed(seeded)

        let uploader = CountingUploader()
        let model = makeModel(owner: owner, pet: seeded, pets: pets, uploader: uploader)
        let keptPreview = Data([0x22])
        model.photoJPEG = keptPreview

        model.stagePhoto(Data([0x47, 0x49, 0x46, 0x38, 0x39, 0x61]))
        XCTAssertEqual(model.photoError, ProfilePhotoValidation.Issue.unsupportedType.message)
        XCTAssertEqual(model.photoJPEG, keptPreview)
        XCTAssertEqual(model.existingPhotoPath, originalPath)

        model.stagePhoto(Data(count: ProfilePhotoValidation.maxBytes + 1))
        XCTAssertEqual(model.photoError, ProfilePhotoValidation.Issue.tooLarge.message)
        XCTAssertEqual(model.photoJPEG, keptPreview)

        let png = try XCTUnwrap(samplePNG())
        model.stagePhoto(png)
        XCTAssertNil(model.photoError)
        XCTAssertNotNil(model.photoJPEG)
        XCTAssertNotEqual(model.photoJPEG, keptPreview)

        await uploader.setError(RepositoryError.remote)
        await model.save()
        XCTAssertFalse(model.didSave)
        XCTAssertEqual(model.serverError, RepositoryError.remote.localizedDescription)
        XCTAssertEqual(model.existingPhotoPath, originalPath)
        let updates = await pets.upsertCount
        XCTAssertEqual(updates, 0)
        let stored = try await pets.pet(id: original.id, ownerId: owner)
        XCTAssertEqual(stored.photoPath, originalPath)
        XCTAssertEqual(stored.name, "Milo")
        let uploads = await uploader.calls
        XCTAssertEqual(uploads, 1)
    }

    private func makeModel(
        owner: UUID,
        pet: Pet?,
        pets: any PetRepository,
        uploader: any MediaUploading = InMemoryMediaStore()
    ) -> EditPetProfileViewModel {
        let library = PetLibrary(ownerId: owner, repository: pets, selection: InMemoryActivePetStore())
        return EditPetProfileViewModel(
            ownerId: owner,
            pet: pet,
            pets: pets,
            uploader: uploader,
            media: SignedMediaURLCache(signer: InMemoryMediaStore()),
            library: library
        )
    }

    private func makePet(
        owner: UUID,
        name: String,
        createdAt: Date = Date(timeIntervalSince1970: 1_700_000_000)
    ) -> Pet {
        Pet(
            id: UUID(),
            ownerId: owner,
            name: name,
            species: .dog,
            breed: "Mix",
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
            createdAt: createdAt,
            updatedAt: createdAt
        )
    }

    private func objectPath(owner: UUID, pet: UUID) -> String {
        MediaObjectPath.jpeg(
            ownerId: owner,
            petId: pet,
            fileId: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        )
    }

    private func samplePNG() -> Data? {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 8, height: 8))
        let image = renderer.image { context in
            UIColor.brown.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
        }
        return image.pngData()
    }
}

private actor RecordingPetRepository: PetRepository {
    private var storage: [UUID: Pet] = [:]
    private var upsertError: Error?
    private(set) var upsertCount = 0

    func seed(_ pet: Pet) {
        storage[pet.id] = pet
    }

    func setUpsertError(_ error: Error?) {
        upsertError = error
    }

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
        upsertCount += 1
        if let upsertError {
            throw upsertError
        }
        try MediaPathGuard.validate(pet.photoPath)
        storage[pet.id] = pet
        return pet
    }
}

private actor CountingUploader: MediaUploading {
    private(set) var calls = 0
    private var error: Error?

    func setError(_ error: Error?) {
        self.error = error
    }

    func uploadJPEG(_ data: Data, ownerId: UUID, petId: UUID) async throws -> String {
        calls += 1
        if let error { throw error }
        return MediaObjectPath.jpeg(ownerId: ownerId, petId: petId)
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

private struct PausingUploader: MediaUploading {
    let gate: UploadGate

    func uploadJPEG(_ data: Data, ownerId: UUID, petId: UUID) async throws -> String {
        await gate.wait()
        return MediaObjectPath.jpeg(ownerId: ownerId, petId: petId)
    }
}
