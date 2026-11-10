import os
import XCTest
@testable import Neo

@MainActor
final class StabilizationTests: XCTestCase {
    private let jpeg = Data([0xFF, 0xD8, 0xFF, 0xD9])

    func testMilestoneCountFollowsMomentCategoryForTheSelectedPet() async throws {
        let owner = UUID()
        let pets = InMemoryPetRepository()
        let moments = InMemoryMomentRepository()
        let now = Date()
        let milo = makePet(owner: owner, name: "Milo", createdAt: now)
        let ada = makePet(owner: owner, name: "Ada", createdAt: now.addingTimeInterval(-10))
        _ = try await pets.upsert(milo)
        _ = try await pets.upsert(ada)
        _ = try await moments.upsert(makeMoment(owner: owner, pet: milo.id, title: "Nap", category: .daily))
        _ = try await moments.upsert(makeMoment(owner: owner, pet: milo.id, title: "First walk", category: .milestone))
        _ = try await moments.upsert(makeMoment(owner: owner, pet: ada.id, title: "Ada day", category: .milestone))

        let library = PetLibrary(ownerId: owner, repository: pets, selection: InMemoryActivePetStore())
        let board = MomentBoard()
        let profile = PetProfileViewModel(
            library: library,
            moments: moments,
            media: SignedMediaURLCache(signer: EmptySigner()),
            pets: pets,
            board: board
        )
        await profile.load()
        XCTAssertEqual(profile.selectedPet?.id, milo.id)
        XCTAssertEqual(profile.momentCount, 2)
        XCTAssertEqual(profile.milestoneCount, 1)

        let created = try await saveMoment(title: "Gotcha day", category: .milestone, owner: owner, pet: milo.id, pets: pets, moments: moments, board: board)
        XCTAssertEqual(profile.momentCount, 3)
        XCTAssertEqual(profile.milestoneCount, 2)

        var edited = created
        edited.title = "Gotcha morning"
        edited.category = .daily
        edited.updatedAt = Date().addingTimeInterval(5)
        let saved = try await moments.upsert(edited)
        board.noteSaved(saved)
        XCTAssertEqual(profile.momentCount, 3)
        XCTAssertEqual(profile.milestoneCount, 1)

        board.noteDeleted(id: saved.id, petId: milo.id, ownerId: owner)
        XCTAssertEqual(profile.momentCount, 2)
        XCTAssertEqual(profile.milestoneCount, 1)

        profile.select(ada)
        await profile.loadDetails()
        XCTAssertEqual(profile.momentCount, 1)
        XCTAssertEqual(profile.milestoneCount, 1)
        XCTAssertEqual(board.moment(id: saved.id), nil)
    }

    func testCreateEditDeleteAndFavoriteReachEverySurface() async throws {
        let owner = UUID()
        let pets = InMemoryPetRepository()
        let moments = InMemoryMomentRepository()
        let store = InMemoryMediaStore()
        let pet = makePet(owner: owner, name: "Milo", createdAt: Date())
        _ = try await pets.upsert(pet)
        _ = try await moments.upsert(makeMoment(owner: owner, pet: pet.id, title: "Existing", category: .daily))

        let library = PetLibrary(ownerId: owner, repository: pets, selection: InMemoryActivePetStore())
        let board = MomentBoard()
        let media = SignedMediaURLCache(signer: store)
        let profile = PetProfileViewModel(library: library, moments: moments, media: media, pets: pets, board: board)
        let feed = PetMomentsViewModel(repository: moments, media: media, board: board)
        let timeline = MemoryTimelineViewModel(repository: moments, media: media, board: board)
        await profile.load()
        await feed.load(pet: pet)
        await timeline.load(pet: pet)
        let existing = try XCTUnwrap(feed.moments.first)

        let detail = MemoryDetailViewModel(
            momentId: existing.id,
            pet: pet,
            pets: pets,
            moments: moments,
            media: media,
            uploader: store,
            board: board
        )
        await detail.load()

        let created = try await saveMoment(
            title: "Park day",
            category: .milestone,
            owner: owner,
            pet: pet.id,
            pets: pets,
            moments: moments,
            board: board,
            uploader: store
        )
        await feed.applyBoard()
        await timeline.applyBoard()
        detail.applyBoard()
        XCTAssertEqual(profile.milestoneCount, 1)
        XCTAssertEqual(profile.momentCount, 2)
        XCTAssertTrue(feed.moments.contains(where: { $0.id == created.id && $0.title == "Park day" }))
        XCTAssertTrue(timeline.moments.contains(where: { $0.id == created.id }))

        let editor = CreatePetMomentViewModel(
            ownerId: owner,
            petId: pet.id,
            moment: try await moments.moment(id: created.id, petId: pet.id, ownerId: owner),
            pets: pets,
            moments: moments,
            uploader: store,
            board: board
        )
        editor.title = "Park morning"
        await editor.save()
        await feed.applyBoard()
        await timeline.applyBoard()
        detail.applyBoard()
        XCTAssertEqual(feed.moments.first(where: { $0.id == created.id })?.title, "Park morning")
        XCTAssertEqual(timeline.moments.first(where: { $0.id == created.id })?.title, "Park morning")

        let favoriteTarget = try XCTUnwrap(feed.moments.first(where: { $0.id == created.id }))
        await feed.toggleFavorite(favoriteTarget)
        let favoriteDetail = MemoryDetailViewModel(
            momentId: created.id,
            pet: pet,
            pets: pets,
            moments: moments,
            media: media,
            uploader: store,
            board: board
        )
        await favoriteDetail.load()
        XCTAssertEqual(favoriteDetail.moment?.isFavorite, true)
        XCTAssertEqual(feed.moments.first(where: { $0.id == created.id })?.isFavorite, true)
        await favoriteDetail.toggleFavorite()
        await feed.applyBoard()
        await timeline.applyBoard()
        XCTAssertEqual(feed.moments.first(where: { $0.id == created.id })?.isFavorite, false)
        XCTAssertEqual(timeline.moments.first(where: { $0.id == created.id })?.isFavorite, false)

        favoriteDetail.requestDelete()
        await favoriteDetail.commitDelete()
        await feed.applyBoard()
        await timeline.applyBoard()
        XCTAssertTrue(favoriteDetail.didDelete)
        XCTAssertFalse(feed.moments.contains(where: { $0.id == created.id }))
        XCTAssertFalse(timeline.moments.contains(where: { $0.id == created.id }))
        XCTAssertEqual(profile.momentCount, 1)
        XCTAssertEqual(profile.milestoneCount, 0)
        XCTAssertEqual(detail.moment?.id, existing.id)
    }

    func testPetSwitchIgnoresAnInFlightList() async throws {
        let owner = UUID()
        let pets = InMemoryPetRepository()
        let store = InMemoryMomentRepository()
        let gated = GatedMomentRepository(inner: store)
        let now = Date()
        let milo = makePet(owner: owner, name: "Milo", createdAt: now)
        let ada = makePet(owner: owner, name: "Ada", createdAt: now.addingTimeInterval(-10))
        _ = try await pets.upsert(milo)
        _ = try await pets.upsert(ada)
        _ = try await store.upsert(makeMoment(owner: owner, pet: milo.id, title: "Milestone", category: .milestone))
        _ = try await store.upsert(makeMoment(owner: owner, pet: ada.id, title: "Ada", category: .daily))

        let library = PetLibrary(ownerId: owner, repository: pets, selection: InMemoryActivePetStore())
        let board = MomentBoard()
        let profile = PetProfileViewModel(
            library: library,
            moments: gated,
            media: SignedMediaURLCache(signer: EmptySigner()),
            pets: pets,
            board: board
        )
        await profile.load()
        gated.pauseNextList = true
        let stale = Task { await profile.loadDetails() }
        await gated.waitUntilPaused()
        profile.select(ada)
        await profile.loadDetails()
        gated.release()
        await stale.value
        XCTAssertEqual(profile.selectedPet?.id, ada.id)
        XCTAssertEqual(profile.momentCount, 1)
        XCTAssertEqual(profile.milestoneCount, 0)

        let feed = PetMomentsViewModel(repository: gated, media: SignedMediaURLCache(signer: EmptySigner()), board: board)
        gated.pauseNextPage = true
        let stalePage = Task { await feed.load(pet: milo) }
        await gated.waitUntilPaused()
        await feed.load(pet: ada)
        gated.release()
        await stalePage.value
        XCTAssertEqual(feed.moments.map(\.petId), [ada.id])
        XCTAssertEqual(feed.moments.map(\.title), ["Ada"])
    }

    func testSignOutFailureClearsLocalDataWithoutClaimingRevocation() async throws {
        let owner = UUID()
        let auth = SessionAuth(owner: owner, email: "ada@example.com")
        auth.signOutError = RepositoryError.remote
        let signer = CountingSigner()
        let cache = SignedMediaURLCache(signer: signer)
        let app = try makeApp(owner: owner, auth: auth, media: cache)
        await app.bootstrap()
        XCTAssertEqual(app.gate, .ready)
        XCTAssertEqual(app.ownerId, owner)

        let path = MediaObjectPath.jpeg(ownerId: owner, petId: UUID())
        let signed = await cache.displayURL(for: path)
        XCTAssertNotNil(signed)
        XCTAssertEqual(signer.calls, 1)
        await TimelineThumbnailCache.shared.store(Data([1, 2, 3]), for: FeedImageSizing.cacheKey(path: path, maxPixel: 960))

        await app.signOut()
        XCTAssertEqual(app.gate, .signedOut)
        XCTAssertFalse(app.remoteSessionRevoked)
        XCTAssertEqual(app.authError, SessionCleanup.remoteSignOutFailed)
        XCTAssertNil(app.ownerId)
        XCTAssertNil(app.library)
        let stored = await TimelineThumbnailCache.shared.storedCount()
        XCTAssertEqual(stored, 0)
        let afterSignOut = await cache.displayURL(for: path)
        XCTAssertNil(afterSignOut)
        XCTAssertEqual(signer.calls, 1)

        let restarted = try makeApp(owner: owner, auth: auth, media: cache)
        await restarted.bootstrap()
        XCTAssertEqual(restarted.gate, .ready)
        XCTAssertEqual(restarted.ownerId, owner)
        XCTAssertFalse(restarted.remoteSessionRevoked)
        let restored = await cache.displayURL(for: path)
        XCTAssertNotNil(restored)
        XCTAssertEqual(signer.calls, 2)
    }

    func testSuccessfulSignOutStaysSignedOutAfterRestart() async throws {
        let owner = UUID()
        let auth = SessionAuth(owner: owner, email: "ada@example.com")
        let app = try makeApp(owner: owner, auth: auth, media: SignedMediaURLCache(signer: EmptySigner()))
        await app.bootstrap()
        await app.signOut()
        XCTAssertTrue(app.remoteSessionRevoked)
        XCTAssertNil(app.authError)

        let restarted = try makeApp(owner: owner, auth: auth, media: SignedMediaURLCache(signer: EmptySigner()))
        await restarted.bootstrap()
        XCTAssertEqual(restarted.gate, .signedOut)
        XCTAssertNil(restarted.ownerId)
    }

    func testAccountDeletionRequiresConfirmationAndCanResume() async throws {
        let owner = UUID()
        let auth = SessionAuth(owner: owner, email: "ada@example.com")
        let deletion = ScriptedAccountDeletion()
        let app = try makeApp(
            owner: owner,
            auth: auth,
            media: SignedMediaURLCache(signer: EmptySigner()),
            deletion: deletion
        )
        await app.bootstrap()

        deletion.error = AccountDeletionError.incomplete(stage: "storage")
        do {
            try await app.deleteAccount(password: "secret")
            XCTFail("Deletion should stay incomplete")
        } catch let error as AccountDeletionError {
            XCTAssertEqual(error, .incomplete(stage: "storage"))
        }
        XCTAssertEqual(deletion.calls, 1)
        XCTAssertEqual(app.gate, .ready)
        XCTAssertEqual(app.ownerId, owner)

        deletion.error = nil
        try await app.deleteAccount(password: "secret")
        XCTAssertEqual(deletion.calls, 2)
        XCTAssertEqual(app.gate, .signedOut)
        XCTAssertNil(app.ownerId)
        XCTAssertNil(app.library)
        XCTAssertEqual(app.authError, SessionCleanup.accountDeleted)
        XCTAssertFalse(app.remoteSessionRevoked)

        let other = try makeApp(owner: owner, auth: auth, media: SignedMediaURLCache(signer: EmptySigner()), deletion: deletion)
        await other.bootstrap()
        let callsBefore = deletion.calls
        do {
            try await other.deleteAccount(password: "wrong")
            XCTFail("Wrong password should stop deletion")
        } catch {
            XCTAssertNotEqual(error as? AccountDeletionError, .rejected)
        }
        XCTAssertEqual(deletion.calls, callsBefore)
        XCTAssertEqual(other.gate, .ready)
    }

    func testFeedCoversUseASmallerImageThanTheUpload() {
        XCTAssertLessThan(FeedImageSizing.coverMaxPixel, 2048)
        XCTAssertGreaterThan(FeedImageSizing.coverMaxPixel, TimelineImageSizing.thumbnailMaxPixel)
        XCTAssertEqual(FeedImageSizing.cacheKey(path: "owner/pet/file.jpg", maxPixel: 960), "960|owner/pet/file.jpg")
        XCTAssertNotEqual(
            FeedImageSizing.cacheKey(path: "owner/pet/file.jpg", maxPixel: FeedImageSizing.coverMaxPixel),
            FeedImageSizing.cacheKey(path: "owner/pet/file.jpg", maxPixel: TimelineImageSizing.thumbnailMaxPixel)
        )

        let format = UIGraphicsImageRendererFormat()
        format.opaque = true
        format.scale = 1
        let sourceImage = UIGraphicsImageRenderer(size: CGSize(width: 800, height: 400), format: format).image { context in
            UIColor.brown.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 800, height: 400))
        }
        let source = sourceImage.jpegData(compressionQuality: 0.9)!
        let thumb = TimelineImageSizing.thumbnailJPEG(from: source, maxPixel: 64)!
        let decoded = UIImage(data: thumb)!
        XCTAssertLessThanOrEqual(max(decoded.size.width, decoded.size.height) * decoded.scale, 64)
        XCTAssertLessThan(thumb.count, source.count)

        let card = MomentShareRendering.render(
            petName: "Milo",
            title: "A day outside",
            dateText: "May 1, 2026",
            caption: "The park was quiet.",
            photo: nil
        )
        let alpha = card?.cgImage?.alphaInfo
        XCTAssertTrue(
            alpha == CGImageAlphaInfo.noneSkipLast || alpha == CGImageAlphaInfo.none,
            "Story card alpha was \(String(describing: alpha))"
        )
    }

    private func saveMoment(
        title: String,
        category: MomentCategory,
        owner: UUID,
        pet: UUID,
        pets: InMemoryPetRepository,
        moments: InMemoryMomentRepository,
        board: MomentBoard,
        uploader: any MediaUploading = InMemoryMediaStore()
    ) async throws -> PetMoment {
        let creator = CreatePetMomentViewModel(
            ownerId: owner,
            petId: pet,
            pets: pets,
            moments: moments,
            uploader: uploader,
            board: board
        )
        creator.title = title
        creator.category = category
        XCTAssertNil(creator.addJPEG(jpeg))
        await creator.save()
        XCTAssertTrue(creator.didSave)
        return try await moments.moment(id: creator.momentId, petId: pet, ownerId: owner)
    }

    private func makeApp(
        owner: UUID,
        auth: SessionAuth,
        media: SignedMediaURLCache,
        deletion: any AccountDeleting = ScriptedAccountDeletion()
    ) throws -> AppModel {
        let dependencies = AppDependencies(
            auth: auth,
            pets: InMemoryPetRepository(),
            moments: InMemoryMomentRepository(),
            memories: InMemoryMemoryRepository(),
            media: media,
            uploader: InMemoryMediaStore(),
            selection: InMemoryActivePetStore(),
            accountDeletion: deletion
        )
        return AppModel(dependencies: dependencies, configurationState: .missing)
    }

    private func makePet(owner: UUID, name: String, createdAt: Date) -> Pet {
        Pet(
            id: UUID(),
            ownerId: owner,
            name: name,
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
            createdAt: createdAt,
            updatedAt: createdAt
        )
    }

    private func makeMoment(owner: UUID, pet: UUID, title: String, category: MomentCategory) -> PetMoment {
        let now = Date()
        return PetMoment(
            id: UUID(),
            ownerId: owner,
            petId: pet,
            title: title,
            caption: title,
            category: category,
            momentDate: now,
            isFavorite: false,
            media: [],
            createdAt: now,
            updatedAt: now
        )
    }
}

private struct PauseState: Sendable {
    var waiters: [CheckedContinuation<Void, Never>] = []
    var starters: [CheckedContinuation<Void, Never>] = []
}

private final class PauseGate: @unchecked Sendable {
    private let state = OSAllocatedUnfairLock(initialState: PauseState())

    func pause() async {
        await withCheckedContinuation { continuation in
            let starters = state.withLock { value -> [CheckedContinuation<Void, Never>] in
                value.waiters.append(continuation)
                let ready = value.starters
                value.starters = []
                return ready
            }
            starters.forEach { $0.resume() }
        }
    }

    func waitUntilPaused() async {
        await withCheckedContinuation { continuation in
            let alreadyWaiting = state.withLock { value -> Bool in
                if value.waiters.isEmpty {
                    value.starters.append(continuation)
                    return false
                }
                return true
            }
            if alreadyWaiting {
                continuation.resume()
            }
        }
    }

    func release() {
        let pending = state.withLock { value -> [CheckedContinuation<Void, Never>] in
            let pending = value.waiters
            value.waiters = []
            return pending
        }
        pending.forEach { $0.resume() }
    }
}

private final class GatedMomentRepository: MomentRepository, @unchecked Sendable {
    let inner: InMemoryMomentRepository
    let gate = PauseGate()
    var pauseNextList = false
    var pauseNextPage = false

    init(inner: InMemoryMomentRepository) {
        self.inner = inner
    }

    func list(petId: UUID, ownerId: UUID) async throws -> [PetMoment] {
        if pauseNextList {
            pauseNextList = false
            await gate.pause()
        }
        return try await inner.list(petId: petId, ownerId: ownerId)
    }

    func moment(id: UUID, petId: UUID, ownerId: UUID) async throws -> PetMoment {
        try await inner.moment(id: id, petId: petId, ownerId: ownerId)
    }

    func page(petId: UUID, ownerId: UUID, category: MomentCategory?, cursor: MomentCursor?, limit: Int) async throws -> MomentPage {
        if pauseNextPage {
            pauseNextPage = false
            await gate.pause()
        }
        return try await inner.page(petId: petId, ownerId: ownerId, category: category, cursor: cursor, limit: limit)
    }

    func upsert(_ moment: PetMoment) async throws -> PetMoment {
        try await inner.upsert(moment)
    }

    func setFavorite(id: UUID, petId: UUID, ownerId: UUID, isFavorite: Bool) async throws -> PetMoment {
        try await inner.setFavorite(id: id, petId: petId, ownerId: ownerId, isFavorite: isFavorite)
    }

    func delete(id: UUID, ownerId: UUID) async throws {
        try await inner.delete(id: id, ownerId: ownerId)
    }

    func waitUntilPaused() async {
        await gate.waitUntilPaused()
    }

    func release() {
        gate.release()
    }
}

private final class SessionAuth: AuthServicing, @unchecked Sendable {
    var owner: UUID?
    var email: String?
    var password = "secret"
    var signOutError: Error?

    init(owner: UUID?, email: String?) {
        self.owner = owner
        self.email = email
    }

    func restoreSession() async throws -> UUID? { owner }

    func signIn(email: String, password: String) async throws -> UUID {
        guard password == self.password, let owner else { throw RepositoryError.remote }
        return owner
    }

    func signUp(email: String, password: String) async throws -> SignUpResult {
        SignUpResult(ownerId: owner, needsEmailConfirmation: false)
    }

    func signOut() async throws {
        if let signOutError { throw signOutError }
        owner = nil
    }

    func currentEmail() async -> String? { email }
}

private final class ScriptedAccountDeletion: AccountDeleting, @unchecked Sendable {
    var error: Error?
    private(set) var calls = 0

    func deleteAuthenticatedAccount(password: String) async throws {
        calls += 1
        if let error { throw error }
        _ = password
    }
}

private struct EmptySigner: MediaSigning {
    func signedURL(for path: String, expiresIn: Int) async throws -> URL {
        throw RepositoryError.notFound
    }
}

private final class CountingSigner: MediaSigning, @unchecked Sendable {
    private(set) var calls = 0

    func signedURL(for path: String, expiresIn: Int) async throws -> URL {
        calls += 1
        return URL(string: "https://example.test/\(calls)")!
    }
}
