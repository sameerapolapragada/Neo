import XCTest
@testable import Neo

@MainActor
final class PetProfileTests: XCTestCase {
    func testAgeUsesBirthdayAndDoesNotInventAMissingOne() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let birthday = calendar.date(from: DateComponents(year: 2024, month: 1, day: 1, hour: 12))!
        let now = calendar.date(from: DateComponents(year: 2026, month: 3, day: 1, hour: 12))!
        var pet = samplePet(birthday: birthday, adoption: nil, weight: nil, toy: nil)
        XCTAssertEqual(PetProfileDisplay.age(for: pet, now: now, calendar: calendar), "2 yr 2 mo")
        XCTAssertNotEqual(PetProfileDisplay.age(for: pet, now: now, calendar: calendar), PetProfileDisplay.missing)

        pet.birthday = nil
        XCTAssertEqual(PetProfileDisplay.age(for: pet, now: now, calendar: calendar), "Not added")
        XCTAssertNotEqual(PetProfileDisplay.age(for: pet, now: now, calendar: calendar), "Newborn")
        XCTAssertEqual(PetProfileDisplay.birthday(for: pet), "Not added")
    }

    func testDaysTogetherUsesAdoptionDateOnly() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let adoption = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1, hour: 8))!
        let now = calendar.date(from: DateComponents(year: 2026, month: 1, day: 11, hour: 22))!
        XCTAssertEqual(PetCompanionship.daysTogether(from: adoption, now: now, calendar: calendar), 10)
        XCTAssertEqual(PetCompanionship.daysTogether(from: now, now: now, calendar: calendar), 0)
        XCTAssertNil(PetCompanionship.daysTogether(from: nil, now: now, calendar: calendar))
        let future = calendar.date(from: DateComponents(year: 2026, month: 2, day: 1, hour: 12))!
        XCTAssertNil(PetCompanionship.daysTogether(from: future, now: now, calendar: calendar))

        let pet = samplePet(birthday: nil, adoption: nil, weight: nil, toy: nil)
        XCTAssertEqual(PetProfileDisplay.daysTogether(for: pet, now: now, calendar: calendar), "Not added")
    }

    func testEmptyOptionalFieldsStayEmpty() {
        let empty = samplePet(birthday: nil, adoption: nil, weight: nil, toy: "  ")
        XCTAssertEqual(PetProfileDisplay.weight(for: empty), "Not added")
        XCTAssertEqual(PetProfileDisplay.favoriteToy(for: empty), "Not added")
        XCTAssertEqual(PetProfileDisplay.birthday(for: empty), "Not added")

        var known = empty
        known.weightValue = 12.5
        known.weightUnit = .pounds
        known.favoriteToy = "Rope"
        XCTAssertEqual(PetProfileDisplay.weight(for: known), known.weightLabel())
        XCTAssertNotEqual(PetProfileDisplay.weight(for: known), PetProfileDisplay.missing)
        XCTAssertEqual(PetProfileDisplay.favoriteToy(for: known), "Rope")
    }

    func testProfileRepositoryFailureRetryAndEmpty() async {
        let owner = UUID()
        let repository = ScriptedPetRepository()
        repository.listResult = .failure(RepositoryError.remote)
        let library = PetLibrary(ownerId: owner, repository: repository, selection: InMemoryActivePetStore())
        let model = makeModel(owner: owner, library: library, pets: repository, moments: InMemoryMomentRepository())

        await model.load()
        XCTAssertEqual(model.state, .failed(RepositoryError.remote.localizedDescription))
        XCTAssertNil(model.selectedPet)

        repository.listResult = .success([])
        await model.retry()
        XCTAssertEqual(model.state, .empty)
        XCTAssertNil(model.selectedPet)
    }

    func testSwitchingPetsUsesThatPetsRecords() async throws {
        let owner = UUID()
        let pets = InMemoryPetRepository()
        let moments = InMemoryMomentRepository()
        let now = Date()
        let milo = samplePet(owner: owner, name: "Milo", birthday: now, adoption: now, weight: 10, toy: "Ball", createdAt: now)
        let ada = samplePet(
            owner: owner,
            name: "Ada",
            birthday: nil,
            adoption: nil,
            weight: nil,
            toy: nil,
            createdAt: now.addingTimeInterval(-500)
        )
        _ = try await pets.upsert(milo)
        _ = try await pets.upsert(ada)
        _ = try await moments.upsert(sampleMoment(owner: owner, pet: milo.id, caption: "One"))
        _ = try await moments.upsert(sampleMoment(owner: owner, pet: milo.id, caption: "Two"))
        _ = try await moments.upsert(sampleMoment(owner: owner, pet: milo.id, caption: "First walk", category: .milestone))
        _ = try await moments.upsert(sampleMoment(owner: owner, pet: ada.id, caption: "Only"))

        let library = PetLibrary(ownerId: owner, repository: pets, selection: InMemoryActivePetStore())
        let model = makeModel(owner: owner, library: library, pets: pets, moments: moments)
        await model.load()

        XCTAssertEqual(model.state, .loaded)
        XCTAssertEqual(model.selectedPet?.name, "Milo")
        XCTAssertEqual(model.momentCount, 3)
        XCTAssertEqual(model.milestoneCount, 1)

        model.select(ada)
        await model.loadDetails()
        XCTAssertEqual(model.selectedPet?.id, ada.id)
        XCTAssertEqual(model.momentCount, 1)
        XCTAssertEqual(model.milestoneCount, 0)
        XCTAssertEqual(PetProfileDisplay.age(for: ada), "Not added")
        XCTAssertEqual(PetProfileDisplay.daysTogether(for: ada), "Not added")
    }

    private func makeModel(
        owner: UUID,
        library: PetLibrary,
        pets: any PetRepository,
        moments: any MomentRepository,
        board: MomentBoard = MomentBoard()
    ) -> PetProfileViewModel {
        PetProfileViewModel(
            library: library,
            moments: moments,
            media: SignedMediaURLCache(signer: ProfileEmptySigner()),
            pets: pets,
            board: board
        )
    }

    private func samplePet(
        owner: UUID = UUID(),
        name: String = "Milo",
        birthday: Date?,
        adoption: Date?,
        weight: Double?,
        toy: String?,
        createdAt: Date = Date()
    ) -> Pet {
        Pet(
            id: UUID(),
            ownerId: owner,
            name: name,
            species: .dog,
            breed: "Mix",
            birthday: birthday,
            gender: .male,
            adoptionDate: adoption,
            weightValue: weight,
            weightUnit: .pounds,
            microchipId: nil,
            photoPath: nil,
            bio: "",
            favoriteToy: toy,
            isFavorite: false,
            createdAt: createdAt,
            updatedAt: createdAt
        )
    }

    private func sampleMoment(owner: UUID, pet: UUID, caption: String, category: MomentCategory = .daily) -> PetMoment {
        let now = Date()
        return PetMoment(
            id: UUID(),
            ownerId: owner,
            petId: pet,
            title: caption,
            caption: caption,
            category: category,
            momentDate: now,
            isFavorite: false,
            media: [],
            createdAt: now,
            updatedAt: now
        )
    }

}

private final class ScriptedPetRepository: PetRepository, @unchecked Sendable {
    var listResult: Result<[Pet], Error> = .success([])

    func list(ownerId: UUID) async throws -> [Pet] {
        try listResult.get().filter { $0.ownerId == ownerId }
    }

    func pet(id: UUID, ownerId: UUID) async throws -> Pet {
        let pets = try await list(ownerId: ownerId)
        guard let pet = pets.first(where: { $0.id == id }) else {
            throw RepositoryError.notFound
        }
        return pet
    }

    func upsert(_ pet: Pet) async throws -> Pet {
        pet
    }
}

private actor ProfileEmptySigner: MediaSigning {
    func signedURL(for path: String, expiresIn: Int) async throws -> URL {
        throw RepositoryError.notFound
    }
}
