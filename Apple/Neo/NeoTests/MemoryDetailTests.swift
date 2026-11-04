import UIKit
import XCTest
@testable import Neo

@MainActor
final class MemoryDetailTests: XCTestCase {
    func testPhotoOrdering() async throws {
        let owner = UUID()
        let petId = UUID()
        let momentId = UUID()
        let repository = InMemoryMomentRepository()
        let media = [
            media(owner: owner, moment: momentId, path: path(owner, petId, "c.jpg"), order: 2),
            media(owner: owner, moment: momentId, path: path(owner, petId, "a.jpg"), order: 0),
            media(owner: owner, moment: momentId, path: path(owner, petId, "b.jpg"), order: 1)
        ]
        _ = try await repository.upsert(moment(owner: owner, pet: petId, id: momentId, title: "Walk", media: media))
        let pets = try await ownedPets(owner: owner, pet: petId)
        let model = makeModel(momentId: momentId, owner: owner, pet: petId, pets: pets, moments: repository)
        await model.load()

        XCTAssertEqual(model.presentation, .loaded)
        XCTAssertEqual(model.photos.map(\.sortOrder), [0, 1, 2])
        XCTAssertEqual(model.photos.map(\.storagePath), [
            path(owner, petId, "a.jpg"),
            path(owner, petId, "b.jpg"),
            path(owner, petId, "c.jpg")
        ])
        XCTAssertEqual(model.positionLabel, "1 / 3")
        model.selectPhoto(2)
        XCTAssertEqual(model.positionLabel, "3 / 3")
        model.selectPhoto(9)
        XCTAssertEqual(model.photoIndex, 2)
        XCTAssertTrue(model.tags.isEmpty)
    }

    func testFavoritePersistence() async throws {
        let owner = UUID()
        let petId = UUID()
        let momentId = UUID()
        let repository = InMemoryMomentRepository()
        _ = try await repository.upsert(moment(owner: owner, pet: petId, id: momentId, title: "Nap", media: [onePhoto(owner, petId, momentId)]))
        let pets = try await ownedPets(owner: owner, pet: petId)
        let model = makeModel(momentId: momentId, owner: owner, pet: petId, pets: pets, moments: repository)
        await model.load()
        XCTAssertEqual(model.moment?.isFavorite, false)

        await model.toggleFavorite()
        XCTAssertEqual(model.moment?.isFavorite, true)
        let stored = try await repository.moment(id: momentId, petId: petId, ownerId: owner)
        XCTAssertTrue(stored.isFavorite)

        await model.toggleFavorite()
        let cleared = try await repository.moment(id: momentId, petId: petId, ownerId: owner)
        XCTAssertFalse(cleared.isFavorite)
        XCTAssertEqual(model.moment?.isFavorite, false)
    }

    func testEditAndRefresh() async throws {
        let owner = UUID()
        let petId = UUID()
        let momentId = UUID()
        let repository = InMemoryMomentRepository()
        let existing = path(owner, petId, "cover.jpg")
        let original = moment(
            owner: owner,
            pet: petId,
            id: momentId,
            title: "Porch light",
            caption: "He waited.",
            category: .daily,
            favorite: true,
            media: [media(owner: owner, moment: momentId, path: existing, order: 0)]
        )
        _ = try await repository.upsert(original)
        let pets = try await ownedPets(owner: owner, pet: petId)
        let uploader = UploadCounter()
        let editor = CreatePetMomentViewModel(
            ownerId: owner,
            petId: petId,
            moment: original,
            pets: pets,
            moments: repository,
            uploader: uploader
        )
        XCTAssertEqual(editor.title, "Porch light")
        XCTAssertEqual(editor.caption, "He waited.")
        XCTAssertEqual(editor.category, .daily)
        XCTAssertEqual(editor.photos.count, 1)
        XCTAssertFalse(editor.hasUnsavedChanges)

        editor.title = "Porch light, later"
        editor.caption = "He waited by the door."
        editor.category = .milestone
        await editor.save()
        XCTAssertTrue(editor.didSave)
        let uploads = await uploader.uploads
        XCTAssertEqual(uploads, 0)

        let model = makeModel(momentId: momentId, owner: owner, pet: petId, pets: pets, moments: repository)
        await model.load()
        XCTAssertEqual(model.moment?.id, momentId)
        XCTAssertEqual(model.moment?.title, "Porch light, later")
        XCTAssertEqual(model.moment?.caption, "He waited by the door.")
        XCTAssertEqual(model.moment?.category, .milestone)
        XCTAssertEqual(model.moment?.isFavorite, true)
        XCTAssertEqual(model.photos.map(\.storagePath), [existing])
    }

    func testShareRenderingExcludesPrivateData() async throws {
        let owner = UUID()
        let petId = UUID()
        let momentId = UUID()
        let secretPath = path(owner, petId, "file.jpg")
        let repository = InMemoryMomentRepository()
        _ = try await repository.upsert(
            moment(owner: owner, pet: petId, id: momentId, title: "Our walk", caption: "Sun on the rug.", media: [
                media(owner: owner, moment: momentId, path: secretPath, order: 0)
            ])
        )
        let pets = try await ownedPets(owner: owner, pet: petId)
        let model = makeModel(momentId: momentId, owner: owner, pet: petId, pets: pets, moments: repository)
        await model.load()
        XCTAssertNil(model.shareImage)

        let photo = UIGraphicsImageRenderer(size: CGSize(width: 40, height: 40)).image { context in
            UIColor.brown.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 40, height: 40))
        }
        model.makeShareImage(photo: photo)
        let image = try XCTUnwrap(model.shareImage)
        let ratio = image.size.width / image.size.height
        XCTAssertEqual(ratio, 9.0 / 16.0, accuracy: 0.02)
        let jpeg = try XCTUnwrap(image.jpegData(compressionQuality: 0.9))
        XCTAssertTrue(jpeg.starts(with: [0xFF, 0xD8, 0xFF]))

        let text = model.shareDescription
        XCTAssertTrue(text.contains("Milo"))
        XCTAssertTrue(text.contains("Our walk"))
        XCTAssertFalse(text.lowercased().contains("http"))
        XCTAssertFalse(text.contains(secretPath))
        XCTAssertFalse(text.lowercased().contains("token"))
        XCTAssertFalse(text.contains("sb_secret"))
        XCTAssertFalse(text.contains(owner.uuidString))
    }

    func testDeletionConfirmationAndRecovery() async throws {
        let owner = UUID()
        let petId = UUID()
        let momentId = UUID()
        let store = InMemoryMediaStore()
        let kept = try await store.uploadMomentJPEG(Data([0xFF, 0xD8, 0xFF, 0xD9]), ownerId: owner, petId: petId, momentId: momentId)
        let repository = InMemoryMomentRepository()
        _ = try await repository.upsert(
            moment(owner: owner, pet: petId, id: momentId, title: "Gone", media: [
                media(owner: owner, moment: momentId, path: kept, order: 0)
            ])
        )
        let pets = try await ownedPets(owner: owner, pet: petId)
        let model = makeModel(momentId: momentId, owner: owner, pet: petId, pets: pets, moments: repository, uploader: store)
        await model.load()

        await model.commitDelete()
        XCTAssertFalse(model.didDelete)
        let untouched = try await repository.moment(id: momentId, petId: petId, ownerId: owner)
        XCTAssertEqual(untouched.title, "Gone")

        model.requestDelete()
        model.cancelDelete()
        await model.commitDelete()
        XCTAssertFalse(model.didDelete)

        model.requestDelete()
        await model.commitDelete()
        XCTAssertTrue(model.didDelete)
        let storedFiles = await store.objectCount()
        XCTAssertEqual(storedFiles, 0)
        do {
            _ = try await repository.moment(id: momentId, petId: petId, ownerId: owner)
            XCTFail("Expected the moment to be deleted")
        } catch RepositoryError.notFound {
        }

        let retryOwner = UUID()
        let retryPet = UUID()
        let retryMoment = UUID()
        let flakyStore = ScriptedDeleteUploader(failuresBeforeSuccess: 1)
        let object = MediaObjectPath.momentJPEG(ownerId: retryOwner, petId: retryPet, momentId: retryMoment)
        let retryMoments = InMemoryMomentRepository()
        _ = try await retryMoments.upsert(
            moment(owner: retryOwner, pet: retryPet, id: retryMoment, title: "Retry", media: [
                media(owner: retryOwner, moment: retryMoment, path: object, order: 0)
            ])
        )
        let retryPets = try await ownedPets(owner: retryOwner, pet: retryPet)
        let service = MomentDeletionService(pets: retryPets, moments: retryMoments, uploader: flakyStore)
        try await service.delete(momentId: retryMoment, petId: retryPet, ownerId: retryOwner)
        let attempts = await flakyStore.deletedPaths
        XCTAssertEqual(attempts, [object, object])
        do {
            _ = try await retryMoments.moment(id: retryMoment, petId: retryPet, ownerId: retryOwner)
            XCTFail("Expected retry to finish deletion")
        } catch RepositoryError.notFound {
        }

        let stuckOwner = UUID()
        let stuckPet = UUID()
        let stuckMoment = UUID()
        let stuckPath = MediaObjectPath.momentJPEG(ownerId: stuckOwner, petId: stuckPet, momentId: stuckMoment)
        let stuckMoments = InMemoryMomentRepository()
        _ = try await stuckMoments.upsert(
            moment(owner: stuckOwner, pet: stuckPet, id: stuckMoment, title: "Stuck", media: [
                media(owner: stuckOwner, moment: stuckMoment, path: stuckPath, order: 0)
            ])
        )
        let stuck = MomentDeletionService(
            pets: try await ownedPets(owner: stuckOwner, pet: stuckPet),
            moments: stuckMoments,
            uploader: ScriptedDeleteUploader(failuresBeforeSuccess: 5)
        )
        do {
            try await stuck.delete(momentId: stuckMoment, petId: stuckPet, ownerId: stuckOwner)
            XCTFail("Expected storage failure to keep the moment")
        } catch RepositoryError.remote {
        }
        let remaining = try await stuckMoments.moment(id: stuckMoment, petId: stuckPet, ownerId: stuckOwner)
        XCTAssertEqual(remaining.title, "Stuck")
    }

    func testUnauthorizedAndMissingMoment() async throws {
        let owner = UUID()
        let stranger = UUID()
        let petId = UUID()
        let momentId = UUID()
        let repository = InMemoryMomentRepository()
        _ = try await repository.upsert(moment(owner: owner, pet: petId, id: momentId, title: "Mine", media: [onePhoto(owner, petId, momentId)]))
        let pets = try await ownedPets(owner: owner, pet: petId)

        let outsider = makeModel(momentId: momentId, owner: stranger, pet: petId, pets: pets, moments: repository)
        await outsider.load()
        XCTAssertEqual(outsider.presentation, .unauthorized)
        XCTAssertNil(outsider.moment)
        XCTAssertEqual(outsider.loadError, "That memory isn't on this account.")
        let stillThere = try await repository.moment(id: momentId, petId: petId, ownerId: owner)
        XCTAssertEqual(stillThere.title, "Mine")

        let missing = makeModel(momentId: UUID(), owner: owner, pet: petId, pets: pets, moments: repository)
        await missing.load()
        XCTAssertEqual(missing.presentation, .missing)
        XCTAssertNil(missing.moment)
        XCTAssertEqual(missing.loadError, RepositoryError.notFound.localizedDescription)
    }

    private func makeModel(
        momentId: UUID,
        owner: UUID,
        pet petId: UUID,
        pets: InMemoryPetRepository,
        moments: any MomentRepository,
        uploader: any MediaUploading = InMemoryMediaStore()
    ) -> MemoryDetailViewModel {
        MemoryDetailViewModel(
            momentId: momentId,
            pet: makePet(owner: owner, id: petId),
            pets: pets,
            moments: moments,
            media: SignedMediaURLCache(signer: DetailEmptySigner()),
            uploader: uploader
        )
    }

    private func ownedPets(owner: UUID, pet petId: UUID) async throws -> InMemoryPetRepository {
        let pets = InMemoryPetRepository()
        _ = try await pets.upsert(makePet(owner: owner, id: petId))
        return pets
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

    private func moment(
        owner: UUID,
        pet: UUID,
        id: UUID,
        title: String,
        caption: String = "A kept day.",
        category: MomentCategory = .daily,
        favorite: Bool = false,
        media: [MomentMedia]
    ) -> PetMoment {
        let day = Date(timeIntervalSince1970: 1_720_000_000)
        return PetMoment(
            id: id,
            ownerId: owner,
            petId: pet,
            title: title,
            caption: caption,
            category: category,
            momentDate: day,
            isFavorite: favorite,
            media: media,
            createdAt: day,
            updatedAt: day
        )
    }

    private func onePhoto(_ owner: UUID, _ pet: UUID, _ moment: UUID) -> MomentMedia {
        media(owner: owner, moment: moment, path: path(owner, pet, "photo.jpg"), order: 0)
    }

    private func media(owner: UUID, moment: UUID, path: String, order: Int) -> MomentMedia {
        MomentMedia(
            id: UUID(),
            momentId: moment,
            ownerId: owner,
            storagePath: path,
            sortOrder: order,
            contentType: "image/jpeg",
            byteCount: 4,
            width: nil,
            height: nil
        )
    }

    private func path(_ owner: UUID, _ pet: UUID, _ file: String) -> String {
        "\(owner.uuidString.lowercased())/\(pet.uuidString.lowercased())/\(file)"
    }
}

private actor UploadCounter: MediaUploading {
    private(set) var uploads = 0

    func uploadJPEG(_ data: Data, ownerId: UUID, petId: UUID) async throws -> String {
        uploads += 1
        throw RepositoryError.invalidPhoto
    }

    func uploadMomentJPEG(_ data: Data, ownerId: UUID, petId: UUID, momentId: UUID) async throws -> String {
        uploads += 1
        throw RepositoryError.invalidPhoto
    }

    func deleteUploadedObject(_ path: String, ownerId: UUID) async throws {}
}

private actor ScriptedDeleteUploader: MediaUploading {
    private var failuresRemaining: Int
    private(set) var deletedPaths: [String] = []

    init(failuresBeforeSuccess: Int) {
        failuresRemaining = failuresBeforeSuccess
    }

    func uploadJPEG(_ data: Data, ownerId: UUID, petId: UUID) async throws -> String {
        throw RepositoryError.invalidPhoto
    }

    func uploadMomentJPEG(_ data: Data, ownerId: UUID, petId: UUID, momentId: UUID) async throws -> String {
        throw RepositoryError.invalidPhoto
    }

    func deleteUploadedObject(_ path: String, ownerId: UUID) async throws {
        deletedPaths.append(path)
        if failuresRemaining > 0 {
            failuresRemaining -= 1
            throw RepositoryError.remote
        }
    }
}

private actor DetailEmptySigner: MediaSigning {
    func signedURL(for path: String, expiresIn: Int) async throws -> URL {
        throw RepositoryError.notFound
    }
}
