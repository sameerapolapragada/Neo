import XCTest
@testable import Neo

@MainActor
final class StructuredPetDataTests: XCTestCase {
    func testOptionalProfileFieldsStayUnknownUntilTheOwnerChooses() {
        let pet = makePet(species: .cat)
        XCTAssertEqual(pet.sex, .unknown)
        XCTAssertEqual(pet.reproductiveStatus, .unknown)
        XCTAssertEqual(pet.sizeCategory, .unknown)
        XCTAssertEqual(pet.breedIdentity, .unknown)
        XCTAssertEqual(pet.ageStatus, .unknown)
        XCTAssertNil(pet.approximateAge)
        XCTAssertEqual(PetProfileDetails.breedLine(for: pet), "Not sure")
        XCTAssertEqual(PetProfileDisplay.age(for: pet), "Not added")
    }

    func testSpeciesOtherDoesNotForceSexOrBreed() {
        var pet = makePet(species: .other)
        pet.sex = .unknown
        pet.breedIdentity = .mixed
        XCTAssertEqual(pet.species, .other)
        XCTAssertEqual(PetProfileDetails.breedLine(for: pet), "Mixed breed")
        pet.breed = "Shepherd mix"
        XCTAssertEqual(PetProfileDetails.breedLine(for: pet), "Mixed · Shepherd mix")
    }

    func testLegacyGenderDoesNotInventSexFromSpayedOrNeutered() {
        XCTAssertEqual(
            PetLegacyGender.stored(sex: .unknown, reproductiveStatus: .yes, previous: .neutered),
            .neutered
        )
        XCTAssertEqual(
            PetLegacyGender.stored(sex: .unknown, reproductiveStatus: .yes, previous: .spayed),
            .spayed
        )
        XCTAssertEqual(
            PetLegacyGender.stored(sex: .male, reproductiveStatus: .no, previous: .unknown),
            .male
        )
        XCTAssertEqual(
            PetLegacyGender.stored(sex: .female, reproductiveStatus: .yes, previous: .unknown),
            .spayed
        )
    }

    func testExactBirthdayAndApproximateAgeStaySeparate() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let birthday = calendar.date(from: DateComponents(year: 2024, month: 1, day: 1))!
        let now = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        var pet = makePet(species: .dog)
        pet.birthday = birthday
        pet.ageStatus = .known
        XCTAssertEqual(PetProfileDetails.ageLine(for: pet, now: now, calendar: calendar), "2 years")

        pet.birthday = nil
        pet.ageStatus = .approximate
        pet.approximateAge = " About 3 years "
        XCTAssertEqual(PetProfileDetails.ageLine(for: pet, now: now, calendar: calendar), "About 3 years")
        XCTAssertNil(pet.birthday)
    }

    func testPawCheckEditsTheSameDayAndKeepsHistory() async throws {
        let owner = UUID()
        let pet = makePet(owner: owner, species: .dog)
        let store = InMemoryWellnessStore()
        var first = makeCheck(pet: pet, dayOffset: 0)
        first.appetite = .less
        let saved = try await store.save(first, pet: pet)
        var edited = saved
        edited.appetite = .normal
        edited.note = " Ate breakfast "
        edited.observations = [.nothingNoticed, .vomiting]
        let updated = try await store.save(edited, pet: pet)
        XCTAssertEqual(updated.id, saved.id)
        XCTAssertEqual(updated.appetite, .normal)
        XCTAssertEqual(updated.note, "Ate breakfast")
        XCTAssertEqual(updated.observations, [.nothingNoticed])

        var yesterday = makeCheck(pet: pet, dayOffset: -1)
        yesterday.mood = .quiet
        _ = try await store.save(yesterday, pet: pet)
        let history = try await store.pawChecks(petId: pet.id, ownerId: owner)
        XCTAssertEqual(history.count, 2)
        XCTAssertEqual(history.first?.mood, nil)
        XCTAssertEqual(history.last?.mood, .quiet)
    }

    func testNothingNoticedDoesNotCombineWithAnotherObservation() {
        let selected = PawCheckRules.observations(selecting: .vomiting, in: [.nothingNoticed])
        XCTAssertEqual(selected, [.vomiting])
        XCTAssertEqual(PawCheckRules.observations(selecting: .nothingNoticed, in: selected), [.nothingNoticed])
        XCTAssertFalse(selected.contains(.nothingNoticed))
    }

    func testSeriousObservationUsesACalmVeterinarianPrompt() {
        var check = makeCheck(pet: makePet(species: .cat), dayOffset: 0)
        check.observations = [.limping]
        XCTAssertTrue(check.mentionsSeriousConcern)
        XCTAssertFalse(PawCheck.veterinarianPrompt.localizedCaseInsensitiveContains("healthy"))
        XCTAssertFalse(PawCheck.veterinarianPrompt.localizedCaseInsensitiveContains("diagnosis"))
        check.observations = []
        XCTAssertFalse(check.mentionsSeriousConcern)
    }

    func testWeightValidationUnitsChartOrderAndUndatedProfileWeight() {
        XCTAssertNil(WeightValidation.value(from: "0"))
        XCTAssertNil(WeightValidation.value(from: "-2"))
        XCTAssertEqual(WeightValidation.value(from: "4.5"), 4.5)
        let kilograms = WeightConversion.convert(10, from: .pounds, to: .kilograms)
        let back = WeightConversion.convert(kilograms, from: .kilograms, to: .pounds)
        XCTAssertEqual(back, 10, accuracy: 0.0001)

        let pet = makePet(species: .dog)
        let older = makeWeight(pet: pet, daysAgo: 10, value: 20, unit: .pounds)
        let newer = makeWeight(pet: pet, daysAgo: 1, value: 8, unit: .kilograms)
        let future = makeWeight(pet: pet, daysAgo: -3, value: 30, unit: .pounds)
        let current = WeightLog.current([future, older, newer], on: Date())
        XCTAssertEqual(current?.id, newer.id)
        XCTAssertNotEqual(current?.weightValue, pet.weightValue)

        let chart = WeightLog.chart([newer, older], displayUnit: .pounds)
        XCTAssertEqual(chart.map(\.id), [older.id, newer.id])
        XCTAssertEqual(chart[0].value, 20, accuracy: 0.0001)
        XCTAssertGreaterThan(chart[1].value, 16)
        XCTAssertEqual(chart[0].unit, .pounds)
        XCTAssertEqual(newer.weightUnit, .kilograms)
    }

    func testMomentTagsRejectDuplicatesAndKeepTheCategoryFilter() {
        var tags = MomentTag.toggle(.playing, in: [])
        tags = MomentTag.toggle(.playing, in: tags)
        XCTAssertEqual(tags, [])
        tags = MomentTag.sanitized([.sleeping, .sleeping, .eating, .outdoor, .indoor, .grooming, .funnyMoment])
        XCTAssertEqual(tags.count, 5)
        XCTAssertFalse(tags.contains(.funnyMoment))

        var moment = makeMoment(tags: [.cuddling])
        moment.category = .milestone
        let daily = MomentFeedSorting.matching([moment], category: .daily, tag: .cuddling)
        let milestone = MomentFeedSorting.matching([moment], category: .milestone, tag: .cuddling)
        let otherTag = MomentFeedSorting.matching([moment], category: .milestone, tag: .playing)
        XCTAssertTrue(daily.isEmpty)
        XCTAssertEqual(milestone.map(\.id), [moment.id])
        XCTAssertTrue(otherTag.isEmpty)
    }

    func testAnotherAccountCannotUseThisPetsRecords() async throws {
        let owner = UUID()
        let stranger = UUID()
        let pet = makePet(owner: owner, species: .rabbit)
        let store = InMemoryWellnessStore()
        var stolen = makeCheck(pet: pet, dayOffset: 0)
        stolen.ownerId = stranger
        do {
            _ = try await store.save(stolen, pet: pet)
            XCTFail("Expected the other account to be refused")
        } catch RepositoryError.notFound {
        }
        var foreignPet = pet
        foreignPet.id = UUID()
        var moved = makeWeight(pet: pet, daysAgo: 0, value: 3, unit: .kilograms)
        moved.petId = foreignPet.id
        XCTAssertEqual(
            CompanionAuthorization.writePetRecord(
                actor: owner,
                recordOwner: owner,
                recordPetId: moved.petId,
                pet: pet
            ),
            .denied(.forgedRelationship)
        )
        do {
            _ = try await store.save(moved, pet: pet)
            XCTFail("Expected a different pet to be refused")
        } catch RepositoryError.notFound {
        }
        XCTAssertTrue(try await store.pawChecks(petId: pet.id, ownerId: stranger).isEmpty)
    }

    func testDeletingAPetOrAccountRemovesOnlyThatOwnersCareData() async throws {
        let owner = UUID()
        let otherOwner = UUID()
        let pet = makePet(owner: owner, species: .bird)
        let other = makePet(owner: otherOwner, species: .cat)
        let store = InMemoryWellnessStore()
        _ = try await store.save(makeCheck(pet: pet, dayOffset: 0), pet: pet)
        _ = try await store.save(makeWeight(pet: pet, daysAgo: 0, value: 1, unit: .kilograms), pet: pet)
        _ = try await store.save(makeCheck(pet: other, dayOffset: 0), pet: other)
        try await store.deletePet(id: pet.id, ownerId: owner)
        XCTAssertTrue(try await store.pawChecks(petId: pet.id, ownerId: owner).isEmpty)
        XCTAssertTrue(try await store.weightEntries(petId: pet.id, ownerId: owner).isEmpty)
        XCTAssertEqual(try await store.pawChecks(petId: other.id, ownerId: otherOwner).count, 1)

        try await store.deleteOwner(otherOwner)
        XCTAssertTrue(try await store.pawChecks(petId: other.id, ownerId: otherOwner).isEmpty)
    }

    func testDeletingAMomentRemovesItsTagsWithoutTouchingMedia() async throws {
        let owner = UUID()
        let pet = makePet(owner: owner, species: .dog)
        let moments = InMemoryMomentRepository()
        var moment = makeMoment(tags: [.playing, .playing, .outdoor])
        moment.ownerId = owner
        moment.petId = pet.id
        let saved = try await moments.upsert(moment)
        XCTAssertEqual(saved.tags, [.playing, .outdoor])
        try await moments.delete(id: saved.id, ownerId: owner)
        let remaining = try await moments.list(petId: pet.id, ownerId: owner)
        XCTAssertTrue(remaining.isEmpty)
        XCTAssertEqual(saved.media.count, 0)
    }

    func testMigrationDeclaresOwnershipCleanupAndDoesNotInventWeightDates() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let migration = try String(contentsOf: root.appending(path: "Supabase/migrations/20261120020000_companion_profile_wellness.sql"), encoding: .utf8)
        let deletion = try String(contentsOf: root.appending(path: "Supabase/functions/delete-account/index.ts"), encoding: .utf8)
        for table in ["companion_paw_checks", "companion_weight_entries", "companion_moment_tags"] {
            XCTAssertTrue(migration.contains("create table public.\(table)"))
            XCTAssertTrue(migration.contains("alter table public.\(table) enable row level security"))
            XCTAssertTrue(migration.contains("on delete cascade"))
            XCTAssertTrue(deletion.contains("\"\(table)\""))
        }
        XCTAssertTrue(migration.contains("owner_id = auth.uid()"))
        XCTAssertTrue(migration.contains("revoke all on table public.companion_paw_checks from public, anon, authenticated"))
        XCTAssertTrue(migration.contains("a moment can have at most five tags"))
        XCTAssertTrue(migration.contains("unique (owner_id, pet_id, observation_date)"))
        XCTAssertFalse(migration.contains("insert into public.companion_weight_entries"))
        XCTAssertTrue(migration.contains("The undated companion_pets.weight value is not migrated"))
        XCTAssertTrue(migration.contains("else 'unknown'"))
    }

    private func makePet(owner: UUID = UUID(), species: Species) -> Pet {
        Pet(
            id: UUID(),
            ownerId: owner,
            name: "Milo",
            species: species,
            breed: "",
            birthday: nil,
            gender: .unknown,
            adoptionDate: nil,
            weightValue: 12,
            weightUnit: .pounds,
            microchipId: nil,
            photoPath: nil,
            bio: "",
            favoriteToy: nil,
            isFavorite: false,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    private func makeCheck(pet: Pet, dayOffset: Int) -> PawCheck {
        PawCheck(
            id: UUID(),
            ownerId: pet.ownerId,
            petId: pet.id,
            observationDate: Date().addingTimeInterval(Double(dayOffset) * 86_400),
            appetite: nil,
            energy: nil,
            mood: nil,
            observations: [],
            note: nil,
            source: PawCheck.sourceOwnerReported,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    private func makeWeight(pet: Pet, daysAgo: Int, value: Double, unit: WeightUnit) -> WeightEntry {
        let created = Date().addingTimeInterval(Double(-daysAgo) * 86_400)
        return WeightEntry(
            id: UUID(),
            ownerId: pet.ownerId,
            petId: pet.id,
            measuredOn: created,
            weightValue: value,
            weightUnit: unit,
            source: WeightEntry.sourceOwnerReported,
            createdAt: created,
            updatedAt: created
        )
    }

    private func makeMoment(tags: [MomentTag]) -> PetMoment {
        PetMoment(
            id: UUID(),
            ownerId: UUID(),
            petId: UUID(),
            title: "Quiet afternoon",
            caption: "",
            category: .daily,
            momentDate: Date(),
            isFavorite: false,
            media: [],
            tags: tags,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}
