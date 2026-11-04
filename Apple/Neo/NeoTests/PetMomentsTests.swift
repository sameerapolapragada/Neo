import XCTest
@testable import Neo

@MainActor
final class PetMomentsTests: XCTestCase {
    private let base = Date(timeIntervalSince1970: 1_700_000_000)

    func testCategoryFiltering() async throws {
        let owner = UUID()
        let pet = UUID()
        let repository = InMemoryMomentRepository()
        let daily = makeMoment(owner: owner, pet: pet, title: "Morning", category: .daily, day: 3)
        let adventure = makeMoment(owner: owner, pet: pet, title: "Trail", category: .adventure, day: 2)
        let milestone = makeMoment(owner: owner, pet: pet, title: "First day", category: .milestone, day: 1)
        _ = try await repository.upsert(daily)
        _ = try await repository.upsert(adventure)
        _ = try await repository.upsert(milestone)

        let model = makeModel(repository: repository)
        let selected = makePet(owner: owner, id: pet)
        await model.load(pet: selected)
        XCTAssertEqual(model.moments.map(\.title), ["Morning", "Trail", "First day"])

        await model.apply(.daily, pet: selected)
        XCTAssertEqual(model.moments.map(\.title), ["Morning"])
        await model.apply(.adventure, pet: selected)
        XCTAssertEqual(model.moments.map(\.title), ["Trail"])
        await model.apply(.milestone, pet: selected)
        XCTAssertEqual(model.moments.map(\.title), ["First day"])
        await model.apply(.all, pet: selected)
        XCTAssertEqual(model.moments.map(\.category), [.daily, .adventure, .milestone])
    }

    func testSortingByMemoryDate() async throws {
        let owner = UUID()
        let pet = UUID()
        let repository = InMemoryMomentRepository()
        let sameDayOlder = makeMoment(
            owner: owner,
            pet: pet,
            title: "Earlier write",
            day: 4,
            createdAt: base.addingTimeInterval(10),
            id: UUID(uuidString: "00000000-0000-0000-0000-0000000000AA")!
        )
        let sameDayNewer = makeMoment(
            owner: owner,
            pet: pet,
            title: "Later write",
            day: 4,
            createdAt: base.addingTimeInterval(40),
            id: UUID(uuidString: "00000000-0000-0000-0000-0000000000BB")!
        )
        let olderDay = makeMoment(owner: owner, pet: pet, title: "Last week", day: 1)
        let tieLow = makeMoment(
            owner: owner,
            pet: pet,
            title: "Tie low",
            day: 4,
            createdAt: base.addingTimeInterval(40),
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        )
        let tieHigh = makeMoment(
            owner: owner,
            pet: pet,
            title: "Tie high",
            day: 4,
            createdAt: base.addingTimeInterval(40),
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        )
        for moment in [olderDay, sameDayOlder, tieLow, tieHigh, sameDayNewer] {
            _ = try await repository.upsert(moment)
        }

        let model = makeModel(repository: repository, pageSize: 10)
        await model.load(pet: makePet(owner: owner, id: pet))
        XCTAssertEqual(
            model.moments.map(\.title),
            ["Later write", "Tie high", "Tie low", "Earlier write", "Last week"]
        )
    }

    func testEmptyState() async throws {
        let owner = UUID()
        let pet = makePet(owner: owner, id: UUID())
        let model = makeModel(repository: InMemoryMomentRepository())
        XCTAssertEqual(model.presentation(for: nil), .noPet)
        XCTAssertEqual(model.presentation(for: pet), .loading)
        await model.load(pet: pet)
        XCTAssertTrue(model.moments.isEmpty)
        XCTAssertEqual(model.presentation(for: pet), .empty)
        XCTAssertNil(model.loadError)
    }

    func testFavoriteToggling() async throws {
        let owner = UUID()
        let pet = UUID()
        let repository = InMemoryMomentRepository()
        let moment = makeMoment(owner: owner, pet: pet, title: "Nap", day: 2)
        _ = try await repository.upsert(moment)
        let model = makeModel(repository: repository)
        let selected = makePet(owner: owner, id: pet)
        await model.load(pet: selected)

        await model.toggleFavorite(moment)
        let favored = try await repository.moment(id: moment.id, petId: pet, ownerId: owner)
        XCTAssertTrue(favored.isFavorite)
        XCTAssertEqual(model.moments.first?.isFavorite, true)
        XCTAssertNil(model.favoriteError)

        await model.toggleFavorite(model.moments[0])
        let cleared = try await repository.moment(id: moment.id, petId: pet, ownerId: owner)
        XCTAssertFalse(cleared.isFavorite)
        XCTAssertEqual(model.moments.first?.isFavorite, false)

        let failing = RejectingFavoriteRepository(stored: [cleared])
        let failingModel = makeModel(repository: failing)
        await failingModel.load(pet: selected)
        await failingModel.toggleFavorite(failingModel.moments[0])
        XCTAssertEqual(failingModel.moments.first?.isFavorite, false)
        XCTAssertEqual(failingModel.favoriteError, RepositoryError.remote.localizedDescription)
        let unchanged = try await failing.moment(id: moment.id, petId: pet, ownerId: owner)
        XCTAssertFalse(unchanged.isFavorite)
    }

    func testCrossPetAndCrossUserAccessIsolation() async throws {
        let owner = UUID()
        let otherOwner = UUID()
        let pet = UUID()
        let otherPet = UUID()
        let repository = InMemoryMomentRepository()
        let kept = makeMoment(owner: owner, pet: pet, title: "Home", day: 5, favorite: true)
        let otherPetMoment = makeMoment(owner: owner, pet: otherPet, title: "Other pet", day: 6)
        let otherOwnerMoment = makeMoment(owner: otherOwner, pet: pet, title: "Other person", day: 7)
        _ = try await repository.upsert(kept)
        _ = try await repository.upsert(otherPetMoment)
        _ = try await repository.upsert(otherOwnerMoment)

        let model = makeModel(repository: repository)
        await model.load(pet: makePet(owner: owner, id: pet))
        XCTAssertEqual(model.moments.map(\.title), ["Home"])

        let otherPetPage = try await repository.page(
            petId: otherPet,
            ownerId: owner,
            category: nil,
            cursor: nil,
            limit: 20
        )
        XCTAssertEqual(otherPetPage.moments.map(\.title), ["Other pet"])

        let foreignPage = try await repository.page(
            petId: pet,
            ownerId: otherOwner,
            category: nil,
            cursor: nil,
            limit: 20
        )
        XCTAssertEqual(foreignPage.moments.map(\.title), ["Other person"])
        let crossed = try await repository.page(
            petId: otherPet,
            ownerId: otherOwner,
            category: nil,
            cursor: nil,
            limit: 20
        )
        XCTAssertTrue(crossed.moments.isEmpty)

        do {
            _ = try await repository.setFavorite(id: kept.id, petId: otherPet, ownerId: owner, isFavorite: false)
            XCTFail("Expected a favorite change for another pet to be rejected")
        } catch RepositoryError.notFound {
        }
        do {
            _ = try await repository.setFavorite(id: kept.id, petId: pet, ownerId: otherOwner, isFavorite: false)
            XCTFail("Expected a favorite change for another owner to be rejected")
        } catch RepositoryError.notFound {
        }
        let stored = try await repository.moment(id: kept.id, petId: pet, ownerId: owner)
        XCTAssertTrue(stored.isFavorite)
        XCTAssertEqual(stored.title, "Home")
    }

    func testPaginationHandling() async throws {
        let owner = UUID()
        let pet = UUID()
        let repository = InMemoryMomentRepository()
        let titles = ["Newest", "Second", "Third", "Fourth", "Oldest"]
        for (index, title) in titles.enumerated() {
            _ = try await repository.upsert(
                makeMoment(owner: owner, pet: pet, title: title, day: 10 - index)
            )
        }
        let model = makeModel(repository: repository, pageSize: 2)
        let selected = makePet(owner: owner, id: pet)
        await model.load(pet: selected)
        XCTAssertEqual(model.moments.map(\.title), ["Newest", "Second"])
        XCTAssertTrue(model.canLoadMore)

        await model.loadMore()
        XCTAssertEqual(model.moments.map(\.title), ["Newest", "Second", "Third", "Fourth"])
        XCTAssertTrue(model.canLoadMore)

        await model.loadMore()
        XCTAssertEqual(model.moments.map(\.title), titles)
        XCTAssertFalse(model.canLoadMore)

        await model.apply(.daily, pet: selected)
        XCTAssertEqual(model.moments.map(\.title), ["Newest", "Second"])
        XCTAssertTrue(model.canLoadMore)
    }

    func testFeedUsesTheCoverImageOnly() async throws {
        let owner = UUID()
        let pet = UUID()
        let momentId = UUID()
        let cover = "\(owner.uuidString.lowercased())/\(pet.uuidString.lowercased())/cover.jpg"
        let extra = "\(owner.uuidString.lowercased())/\(pet.uuidString.lowercased())/extra.jpg"
        let moment = makeMoment(
            owner: owner,
            pet: pet,
            title: "Two photos",
            day: 2,
            id: momentId,
            media: [
                MomentMedia(
                    id: UUID(),
                    momentId: momentId,
                    ownerId: owner,
                    storagePath: extra,
                    sortOrder: 1,
                    contentType: "image/jpeg",
                    byteCount: 20,
                    width: 8,
                    height: 8
                ),
                MomentMedia(
                    id: UUID(),
                    momentId: momentId,
                    ownerId: owner,
                    storagePath: cover,
                    sortOrder: 0,
                    contentType: "image/jpeg",
                    byteCount: 20,
                    width: 8,
                    height: 8
                )
            ]
        )
        let repository = InMemoryMomentRepository()
        _ = try await repository.upsert(moment)
        let resolver = RecordingResolver()
        let model = PetMomentsViewModel(repository: repository, media: resolver, pageSize: 10)
        await model.load(pet: makePet(owner: owner, id: pet))
        let requested = await resolver.requestedPaths()
        XCTAssertEqual(requested, [cover])
        XCTAssertEqual(model.coverURL(for: momentId)?.absoluteString, "https://signed.test/\(cover)")
    }

    private func makeModel(
        repository: any MomentRepository,
        pageSize: Int = 20
    ) -> PetMomentsViewModel {
        PetMomentsViewModel(
            repository: repository,
            media: SignedMediaURLCache(signer: MomentEmptySigner()),
            pageSize: pageSize
        )
    }

    private func makePet(owner: UUID, id: UUID) -> Pet {
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
            createdAt: base,
            updatedAt: base
        )
    }

    private func makeMoment(
        owner: UUID,
        pet: UUID,
        title: String,
        category: MomentCategory = .daily,
        day: Int,
        createdAt: Date? = nil,
        id: UUID = UUID(),
        favorite: Bool = false,
        media: [MomentMedia] = []
    ) -> PetMoment {
        let momentDate = base.addingTimeInterval(Double(day) * 86_400)
        let written = createdAt ?? momentDate
        return PetMoment(
            id: id,
            ownerId: owner,
            petId: pet,
            title: title,
            caption: "\(title) caption",
            category: category,
            momentDate: momentDate,
            isFavorite: favorite,
            media: media,
            createdAt: written,
            updatedAt: written
        )
    }
}

private actor RejectingFavoriteRepository: MomentRepository {
    private var storage: [UUID: PetMoment]

    init(stored: [PetMoment]) {
        storage = Dictionary(uniqueKeysWithValues: stored.map { ($0.id, $0) })
    }

    func list(petId: UUID, ownerId: UUID) async throws -> [PetMoment] {
        MomentFeedSorting.ordered(storage.values.filter { $0.petId == petId && $0.ownerId == ownerId })
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
            from: storage.values.filter { $0.petId == petId && $0.ownerId == ownerId },
            category: category,
            cursor: cursor,
            limit: limit
        )
    }

    func upsert(_ moment: PetMoment) async throws -> PetMoment {
        storage[moment.id] = moment
        return moment
    }

    func setFavorite(id: UUID, petId: UUID, ownerId: UUID, isFavorite: Bool) async throws -> PetMoment {
        throw RepositoryError.remote
    }

    func delete(id: UUID, ownerId: UUID) async throws {
        throw RepositoryError.notFound
    }
}

private actor RecordingResolver: MediaURLResolving {
    private var paths: [String] = []

    func displayURL(for path: String?) async -> URL? {
        guard let path else { return nil }
        paths.append(path)
        return URL(string: "https://signed.test/\(path)")
    }

    func requestedPaths() -> [String] {
        paths
    }
}

private actor MomentEmptySigner: MediaSigning {
    func signedURL(for path: String, expiresIn: Int) async throws -> URL {
        throw RepositoryError.notFound
    }
}
