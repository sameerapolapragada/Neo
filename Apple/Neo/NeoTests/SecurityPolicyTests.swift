import XCTest
@testable import Neo

/// Authorization results are compared as `CompanionDenial` or `RepositoryError.notFound` /
/// `invalidPhoto`. A thrown `RepositoryError.remote`, or a `.missingRecord` result, fails the test.
@MainActor
final class SecurityPolicyTests: XCTestCase {
    func testUserACannotReadUserBPet() async throws {
        let world = SecurityWorld()
        let pets = InMemoryPetRepository()
        try await pets.upsert(world.petA)
        let visible = try await pets.pet(id: world.petA.id, ownerId: world.ownerA)
        XCTAssertEqual(visible.id, world.petA.id)

        XCTAssertEqual(
            CompanionAuthorization.readPet(actor: world.ownerA, pet: world.petB),
            .denied(.notOwner)
        )
        await assertAuthorizationFailure {
            _ = try await pets.pet(id: world.petB.id, ownerId: world.ownerA)
        }
    }

    func testUserACannotUpdateUserBPet() async throws {
        let world = SecurityWorld()
        let pets = InMemoryPetRepository()
        try await pets.upsert(world.petB)
        var forged = world.petB
        forged.name = "Taken"
        forged.ownerId = world.ownerA

        XCTAssertEqual(
            CompanionAuthorization.updatePet(actor: world.ownerA, existing: world.petB, requestedOwner: world.ownerA),
            .denied(.notOwner)
        )
        await assertAuthorizationFailure {
            _ = try await pets.upsert(forged)
        }
        let unchanged = try await pets.pet(id: world.petB.id, ownerId: world.ownerB)
        XCTAssertEqual(unchanged.name, world.petB.name)
    }

    func testUserACannotDeleteUserBPet() async {
        let world = SecurityWorld()
        XCTAssertEqual(
            CompanionAuthorization.deletePet(actor: world.ownerA, pet: world.petB),
            .denied(.notOwner)
        )
        XCTAssertNotEqual(
            CompanionAuthorization.deletePet(actor: world.ownerA, pet: world.petB),
            .denied(.missingRecord)
        )
    }

    func testUserACannotAttachAMomentToUserBPet() async throws {
        let world = SecurityWorld()
        XCTAssertEqual(
            CompanionAuthorization.insertMoment(actor: world.ownerA, momentOwner: world.ownerA, pet: world.petB),
            .denied(.forgedRelationship)
        )

        let moments = InMemoryMomentRepository()
        let foreignPath = MediaObjectPath.momentJPEG(
            ownerId: world.ownerB,
            petId: world.petB.id,
            momentId: world.momentB.id,
            fileId: world.fileId
        )
        var forged = world.momentA
        forged.petId = world.petB.id
        forged.media = [media(world.ownerA, moment: world.momentA.id, path: foreignPath)]
        await assertAuthorizationFailure {
            _ = try await moments.upsert(forged)
        }
    }

    func testUserACannotReadUserBMoments() async throws {
        let world = SecurityWorld()
        let moments = InMemoryMomentRepository()
        try await moments.upsert(world.momentB)
        let stored = try await moments.moment(id: world.momentB.id, petId: world.petB.id, ownerId: world.ownerB)
        XCTAssertEqual(stored.id, world.momentB.id)

        XCTAssertEqual(
            CompanionAuthorization.readMoment(actor: world.ownerA, moment: world.momentB, pet: world.petB),
            .denied(.notOwner)
        )
        await assertAuthorizationFailure {
            _ = try await moments.moment(id: world.momentB.id, petId: world.petB.id, ownerId: world.ownerA)
        }
        let hidden = try await moments.list(petId: world.petB.id, ownerId: world.ownerA)
        XCTAssertTrue(hidden.isEmpty)
    }

    func testUserACannotChangeUserBMedia() async throws {
        let world = SecurityWorld()
        XCTAssertEqual(
            CompanionAuthorization.writeMedia(
                actor: world.ownerA,
                existingOwner: world.ownerB,
                requestedOwner: world.ownerA,
                moment: world.momentB,
                pet: world.petB
            ),
            .denied(.notOwner)
        )

        let moments = InMemoryMomentRepository()
        try await moments.upsert(world.momentB)
        var stolen = world.momentB
        stolen.ownerId = world.ownerA
        stolen.media[0].ownerId = world.ownerA
        await assertAuthorizationFailure {
            _ = try await moments.upsert(stolen)
        }
    }

    func testUserACannotSignUserBPhoto() async {
        let world = SecurityWorld()
        let signer = SecuritySigner()
        let cache = SignedMediaURLCache(signer: signer)
        await cache.bind(ownerId: world.ownerA)
        let path = MediaObjectPath.jpeg(ownerId: world.ownerB, petId: world.petB.id, fileId: world.fileId)

        let url = await cache.displayURL(for: path)
        let calls = await signer.calls
        XCTAssertNil(url)
        XCTAssertEqual(calls, 0)
        XCTAssertEqual(
            CompanionAuthorization.storageAccess(actor: world.ownerA, path: path, objectOwner: world.ownerB),
            .denied(.outsideAccount)
        )
    }

    func testUserACannotUploadIntoUserBFolder() async throws {
        let world = SecurityWorld()
        let store = InMemoryMediaStore()
        let jpeg = Data([0xFF, 0xD8, 0xFF, 0x00])
        let stored = try await store.uploadJPEG(jpeg, ownerId: world.ownerA, petId: world.petA.id)
        XCTAssertTrue(MediaObjectPath.isProfilePhoto(stored, ownerId: world.ownerA, petId: world.petA.id))

        let foreign = MediaObjectPath.momentJPEG(
            ownerId: world.ownerB,
            petId: world.petB.id,
            momentId: world.momentB.id,
            fileId: world.fileId
        )
        XCTAssertEqual(
            CompanionAuthorization.storageAccess(actor: world.ownerA, path: foreign, objectOwner: world.ownerA),
            .denied(.outsideAccount)
        )
        await assertAuthorizationFailure {
            try await store.deleteUploadedObject(foreign, ownerId: world.ownerA)
        }
        await assertAuthorizationFailure {
            _ = try await store.signedURL(for: "https://example.supabase.co/storage/v1/object/public/\(foreign)", expiresIn: 60)
        }
    }

    func testAnonymousRequestsCannotAccessPrivateData() async {
        let world = SecurityWorld()
        let path = MediaObjectPath.jpeg(ownerId: world.ownerA, petId: world.petA.id, fileId: world.fileId)
        XCTAssertEqual(CompanionAuthorization.readPet(actor: nil, pet: world.petA), .denied(.anonymous))
        XCTAssertEqual(
            CompanionAuthorization.readMoment(actor: nil, moment: world.momentA, pet: world.petA),
            .denied(.anonymous)
        )
        XCTAssertEqual(
            CompanionAuthorization.storageAccess(actor: nil, path: path, objectOwner: world.ownerA),
            .denied(.anonymous)
        )

        let signer = SecuritySigner()
        let cache = SignedMediaURLCache(signer: signer)
        let url = await cache.displayURL(for: path)
        let calls = await signer.calls
        XCTAssertNil(url)
        XCTAssertEqual(calls, 0)
    }

    func testOwnerCanAccessLegitimateRecords() async throws {
        let world = SecurityWorld()
        let pets = InMemoryPetRepository()
        let moments = InMemoryMomentRepository()
        try await pets.upsert(world.petA)
        try await moments.upsert(world.momentA)
        let pet = try await pets.pet(id: world.petA.id, ownerId: world.ownerA)
        let moment = try await moments.moment(id: world.momentA.id, petId: world.petA.id, ownerId: world.ownerA)
        XCTAssertEqual(pet.ownerId, world.ownerA)
        XCTAssertEqual(moment.media.first?.storagePath, world.momentA.media.first?.storagePath)

        XCTAssertEqual(CompanionAuthorization.readPet(actor: world.ownerA, pet: world.petA), .allowed)
        XCTAssertEqual(
            CompanionAuthorization.updatePet(actor: world.ownerA, existing: world.petA, requestedOwner: world.ownerA),
            .allowed
        )
        XCTAssertEqual(CompanionAuthorization.deletePet(actor: world.ownerA, pet: world.petA), .allowed)
        XCTAssertEqual(
            CompanionAuthorization.readMoment(actor: world.ownerA, moment: world.momentA, pet: world.petA),
            .allowed
        )
        let path = try XCTUnwrap(world.momentA.media.first?.storagePath)
        XCTAssertEqual(
            CompanionAuthorization.storageAccess(actor: world.ownerA, path: path, objectOwner: world.ownerA),
            .allowed
        )

        let signer = SecuritySigner()
        let cache = SignedMediaURLCache(signer: signer)
        await cache.bind(ownerId: world.ownerA)
        let url = await cache.displayURL(for: path)
        let calls = await signer.calls
        XCTAssertNotNil(url)
        XCTAssertEqual(calls, 1)
        XCTAssertFalse(url?.absoluteString.contains("/object/public/") ?? true)
    }

    func testForgedUUIDRelationshipsAreRejected() async throws {
        let world = SecurityWorld()
        XCTAssertEqual(
            CompanionAuthorization.updateMoment(
                actor: world.ownerA,
                existing: world.momentA,
                requestedOwner: world.ownerA,
                requestedPet: world.petB
            ),
            .denied(.forgedRelationship)
        )
        XCTAssertEqual(
            CompanionAuthorization.updatePet(actor: world.ownerA, existing: world.petA, requestedOwner: world.ownerB),
            .denied(.ownerChange)
        )

        let otherMoment = UUID()
        let mismatched = MediaObjectPath.momentJPEG(
            ownerId: world.ownerA,
            petId: world.petA.id,
            momentId: otherMoment,
            fileId: world.fileId
        )
        var forged = world.momentA
        forged.media = [media(world.ownerA, moment: world.momentA.id, path: mismatched)]
        let moments = InMemoryMomentRepository()
        await assertAuthorizationFailure {
            _ = try await moments.upsert(forged)
        }
    }

    func testSignedURLCacheIsIsolatedAndRefreshesWhenExpired() async {
        let world = SecurityWorld()
        let signer = SecuritySigner()
        let clock = ManualClock(Date(timeIntervalSince1970: 1_700_000_000))
        let cache = SignedMediaURLCache(signer: signer, clock: clock)
        let pathA = MediaObjectPath.jpeg(ownerId: world.ownerA, petId: world.petA.id, fileId: world.fileId)
        let pathB = MediaObjectPath.jpeg(ownerId: world.ownerB, petId: world.petB.id, fileId: world.fileId)

        await cache.bind(ownerId: world.ownerA)
        _ = await cache.displayURL(for: pathA)
        clock.current = clock.current.addingTimeInterval(
            TimeInterval(MediaPolicy.signedURLLifetimeSeconds - MediaPolicy.refreshLeewaySeconds)
        )
        _ = await cache.displayURL(for: pathA)
        var calls = await signer.calls
        XCTAssertEqual(calls, 2)

        await cache.bind(ownerId: world.ownerB)
        let leaked = await cache.displayURL(for: pathA)
        calls = await signer.calls
        XCTAssertNil(leaked)
        XCTAssertEqual(calls, 2)
        let own = await cache.displayURL(for: pathB)
        calls = await signer.calls
        XCTAssertNotNil(own)
        XCTAssertEqual(calls, 3)

        await cache.clear()
        let afterClear = await cache.displayURL(for: pathB)
        calls = await signer.calls
        XCTAssertNil(afterClear)
        XCTAssertEqual(calls, 3)
    }

    private func assertAuthorizationFailure(
        _ body: () async throws -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        do {
            try await body()
            XCTFail("expected an authorization failure", file: file, line: line)
        } catch let error as RepositoryError {
            XCTAssertNotEqual(error, .remote, "a transport failure is not an authorization result", file: file, line: line)
            XCTAssertTrue(
                error == .notFound || error == .invalidPhoto,
                "unexpected authorization error \(error)",
                file: file,
                line: line
            )
        } catch {
            XCTFail("expected RepositoryError, got \(error)", file: file, line: line)
        }
    }

    private func media(_ owner: UUID, moment: UUID, path: String) -> MomentMedia {
        MomentMedia(
            id: UUID(),
            momentId: moment,
            ownerId: owner,
            storagePath: path,
            sortOrder: 0,
            contentType: "image/jpeg",
            byteCount: 4,
            width: nil,
            height: nil
        )
    }
}

private struct SecurityWorld {
    let ownerA = UUID()
    let ownerB = UUID()
    let fileId = UUID(uuidString: "00000000-0000-0000-0000-0000000000aa")!
    let petA: Pet
    let petB: Pet
    let momentA: PetMoment
    let momentB: PetMoment

    init() {
        let petAId = UUID()
        let petBId = UUID()
        let momentAId = UUID()
        let momentBId = UUID()
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        petA = SecurityWorld.pet(id: petAId, owner: ownerA, now: now)
        petB = SecurityWorld.pet(id: petBId, owner: ownerB, now: now)
        momentA = SecurityWorld.moment(
            id: momentAId,
            owner: ownerA,
            pet: petAId,
            path: MediaObjectPath.momentJPEG(ownerId: ownerA, petId: petAId, momentId: momentAId, fileId: fileId),
            now: now
        )
        momentB = SecurityWorld.moment(
            id: momentBId,
            owner: ownerB,
            pet: petBId,
            path: MediaObjectPath.momentJPEG(ownerId: ownerB, petId: petBId, momentId: momentBId, fileId: fileId),
            now: now
        )
    }

    private static func pet(id: UUID, owner: UUID, now: Date) -> Pet {
        Pet(
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

    private static func moment(id: UUID, owner: UUID, pet: UUID, path: String, now: Date) -> PetMoment {
        PetMoment(
            id: id,
            ownerId: owner,
            petId: pet,
            title: "Walk",
            caption: "",
            category: .daily,
            momentDate: now,
            isFavorite: false,
            media: [
                MomentMedia(
                    id: UUID(),
                    momentId: id,
                    ownerId: owner,
                    storagePath: path,
                    sortOrder: 0,
                    contentType: "image/jpeg",
                    byteCount: 4,
                    width: nil,
                    height: nil
                )
            ],
            createdAt: now,
            updatedAt: now
        )
    }
}

private final class ManualClock: MediaClock, @unchecked Sendable {
    var current: Date

    init(_ current: Date) {
        self.current = current
    }

    func now() -> Date { current }
}

private actor SecuritySigner: MediaSigning {
    private(set) var calls = 0

    func signedURL(for path: String, expiresIn: Int) async throws -> URL {
        calls += 1
        return URL(string: "https://signed.test/object/sign/\(path)")!
    }
}
