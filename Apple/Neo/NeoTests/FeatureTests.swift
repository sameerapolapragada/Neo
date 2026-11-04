import XCTest
@testable import Neo

@MainActor
final class FeatureTests: XCTestCase {
    func testSavingPetUpdatesLibraryAndRejectsRemotePhotoURL() async throws {
        let owner = UUID()
        let pets = InMemoryPetRepository()
        let library = PetLibrary(ownerId: owner, repository: pets, selection: InMemoryActivePetStore())
        let model = EditPetProfileViewModel(
            ownerId: owner,
            pet: nil,
            pets: pets,
            uploader: InMemoryMediaStore(),
            media: SignedMediaURLCache(signer: InMemoryMediaStore()),
            library: library
        )
        model.name = "M"
        await model.save()
        XCTAssertFalse(model.didSave)
        XCTAssertEqual(model.fieldErrors[.name], "Name must be at least 2 characters")

        model.name = "Milo"
        model.species = .dog
        model.breed = "Mix"
        model.weightText = "14"
        await model.save()
        XCTAssertTrue(model.didSave)
        XCTAssertEqual(library.activePet?.name, "Milo")
        XCTAssertEqual(library.activePet?.ownerId, owner)

        var stolen = try XCTUnwrap(library.activePet)
        stolen.photoPath = "https://cdn.example/milo.jpg"
        do {
            _ = try await pets.upsert(stolen)
            XCTFail("Expected a remote photo URL to be rejected")
        } catch RepositoryError.invalidPhoto {
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }

    func testMomentFeedKeepsNewestFirstAndDeletes() async throws {
        let owner = UUID()
        let petId = UUID()
        let repository = InMemoryMomentRepository()
        let model = PetMomentsViewModel(
            repository: repository,
            media: SignedMediaURLCache(signer: EmptySigner())
        )
        let pet = samplePet(owner: owner, id: petId)
        let older = sampleMoment(owner: owner, pet: petId, caption: "Older", dayOffset: -2)
        let newer = sampleMoment(owner: owner, pet: petId, caption: "Newer", dayOffset: -1)
        _ = try await repository.upsert(older)
        _ = try await repository.upsert(newer)
        await model.load(pet: pet)
        XCTAssertEqual(model.moments.map(\.caption), ["Newer", "Older"])
        try await repository.delete(id: newer.id, ownerId: owner)
        await model.load(pet: pet)
        XCTAssertEqual(model.moments.map(\.caption), ["Older"])
    }

    func testCreateMomentRequiresCaption() async throws {
        let owner = UUID()
        let petId = UUID()
        let pets = InMemoryPetRepository()
        let moments = InMemoryMomentRepository()
        _ = try await pets.upsert(samplePet(owner: owner, id: petId))
        let model = CreatePetMomentViewModel(
            ownerId: owner,
            petId: petId,
            pets: pets,
            moments: moments,
            uploader: InMemoryMediaStore()
        )
        await model.save()
        XCTAssertFalse(model.didSave)
        XCTAssertEqual(model.fieldErrors[.title], "Title is required")
        model.title = "Sun on the rug"
        XCTAssertNil(model.addJPEG(Data([0xFF, 0xD8, 0xFF, 0xD9])))
        await model.save()
        XCTAssertTrue(model.didSave)
        let saved = try await moments.moment(id: model.momentId, petId: petId, ownerId: owner)
        XCTAssertEqual(saved.petId, petId)
        XCTAssertEqual(saved.ownerId, owner)
    }

    func testMemoryDetailMovesAndDeletes() async throws {
        let owner = UUID()
        let petId = UUID()
        let repository = InMemoryMemoryRepository()
        let first = sampleMemory(owner: owner, pet: petId, title: "First", dayOffset: -3)
        let second = sampleMemory(owner: owner, pet: petId, title: "Second", dayOffset: -1)
        _ = try await repository.upsert(first)
        _ = try await repository.upsert(second)
        let model = ScrapbookMemoryDetailViewModel(
            memoryId: first.id,
            petId: petId,
            ownerId: owner,
            repository: repository,
            media: SignedMediaURLCache(signer: EmptySigner())
        )
        await model.load()
        XCTAssertEqual(model.memory?.title, "First")
        XCTAssertEqual(model.positionLabel, "1 of 2")
        XCTAssertFalse(model.hasPrevious)
        XCTAssertTrue(model.hasNext)
        model.showNext()
        XCTAssertEqual(model.memory?.title, "Second")
        await model.delete()
        XCTAssertTrue(model.didDelete)
        let remaining = try await repository.list(petId: petId, ownerId: owner)
        XCTAssertEqual(remaining.map(\.title), ["First"])
    }

    func testCreateMemoryValidation() async {
        let model = CreateMemoryViewModel(
            ownerId: UUID(),
            petId: UUID(),
            repository: InMemoryMemoryRepository(),
            uploader: InMemoryMediaStore()
        )
        model.title = "Rain"
        model.notes = "No"
        await model.save()
        XCTAssertFalse(model.didSave)
        model.notes = "He sat by the door and listened."
        await model.save()
        XCTAssertTrue(model.didSave)
    }

    private func samplePet(owner: UUID, id: UUID) -> Pet {
        let now = Date()
        return Pet(
            id: id,
            ownerId: owner,
            name: "Milo",
            species: .dog,
            breed: "Mix",
            birthday: now,
            gender: .male,
            adoptionDate: now,
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

    private func sampleMoment(owner: UUID, pet: UUID, caption: String, dayOffset: Int) -> PetMoment {
        let day = Date().addingTimeInterval(Double(dayOffset) * 86_400)
        return PetMoment(
            id: UUID(),
            ownerId: owner,
            petId: pet,
            title: caption,
            caption: caption,
            category: .daily,
            momentDate: day,
            isFavorite: false,
            media: [],
            createdAt: day,
            updatedAt: day
        )
    }

    private func sampleMemory(owner: UUID, pet: UUID, title: String, dayOffset: Int) -> Memory {
        let day = Date().addingTimeInterval(Double(dayOffset) * 86_400)
        return Memory(
            id: UUID(),
            ownerId: owner,
            petId: pet,
            title: title,
            notes: "A kept day together.",
            category: .memory,
            sentiment: .loving,
            photoPath: nil,
            occurredAt: day,
            createdAt: day,
            updatedAt: day
        )
    }
}

private actor EmptySigner: MediaSigning {
    func signedURL(for path: String, expiresIn: Int) async throws -> URL {
        throw RepositoryError.notFound
    }
}
