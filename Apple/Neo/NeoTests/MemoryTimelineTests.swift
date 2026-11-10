import UIKit
import XCTest
@testable import Neo

@MainActor
final class MemoryTimelineTests: XCTestCase {
    func testChronologicalOrdering() async throws {
        let owner = UUID()
        let pet = UUID()
        let repository = InMemoryMomentRepository()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar.locale = Locale(identifier: "en_US")
        let newerYear = calendar.date(from: DateComponents(year: 2026, month: 6, day: 2, hour: 15))!
        let olderYear = calendar.date(from: DateComponents(year: 2024, month: 11, day: 3, hour: 9))!
        let sameDayLater = calendar.date(from: DateComponents(year: 2026, month: 6, day: 2, hour: 18))!
        _ = try await repository.upsert(makeMoment(owner: owner, pet: pet, title: "Older year", date: olderYear, createdAt: olderYear))
        _ = try await repository.upsert(makeMoment(owner: owner, pet: pet, title: "Afternoon", date: newerYear, createdAt: newerYear))
        _ = try await repository.upsert(makeMoment(owner: owner, pet: pet, title: "Evening", date: sameDayLater, createdAt: sameDayLater))

        let model = makeModel(repository: repository, calendar: calendar)
        let selected = makePet(owner: owner, id: pet, birthday: calendar.date(from: DateComponents(year: 2020, month: 1, day: 1)))
        await model.load(pet: selected)

        XCTAssertEqual(model.moments.map(\.title), ["Evening", "Afternoon", "Older year"])
        XCTAssertEqual(model.years.map(\.title), ["2026", "2024"])
        XCTAssertEqual(model.years[0].moments.map(\.title), ["Evening", "Afternoon"])
        XCTAssertEqual(model.dateLabel(for: model.moments[0]), model.dateLabel(for: model.moments[1]))
        XCTAssertFalse(model.dateLabel(for: model.moments[0]).contains(":"))
        XCTAssertTrue(model.years.allSatisfy { year in year.moments.allSatisfy { $0.title != "Birthday" } })
    }

    func testYearGroupingAndDateOnlyTimeZones() {
        var losAngeles = Calendar(identifier: .gregorian)
        losAngeles.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        losAngeles.locale = Locale(identifier: "en_US")
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(secondsFromGMT: 0)!

        let stillPreviousYear = utc.date(from: DateComponents(year: 2026, month: 1, day: 1, hour: 7, minute: 30))!
        let localNewYear = utc.date(from: DateComponents(year: 2026, month: 1, day: 1, hour: 8, minute: 30))!
        let morning = utc.date(from: DateComponents(year: 2026, month: 3, day: 2, hour: 16))!
        let evening = utc.date(from: DateComponents(year: 2026, month: 3, day: 3, hour: 1))!

        let groups = TimelineGrouping.years(
            from: [
                makeMoment(title: "Before midnight", date: stillPreviousYear, createdAt: stillPreviousYear),
                makeMoment(title: "After midnight", date: localNewYear, createdAt: localNewYear),
                makeMoment(title: "Morning", date: morning, createdAt: morning),
                makeMoment(title: "Evening", date: evening, createdAt: evening),
            ],
            calendar: losAngeles
        )

        XCTAssertEqual(groups.map(\.year), [2026, 2025])
        XCTAssertEqual(groups[0].moments.map(\.title), ["Evening", "Morning", "After midnight"])
        XCTAssertEqual(groups[1].moments.map(\.title), ["Before midnight"])
        XCTAssertEqual(TimelineDateFormatting.fullDate(stillPreviousYear, calendar: losAngeles), "December 31, 2025")
        XCTAssertEqual(TimelineDateFormatting.fullDate(localNewYear, calendar: losAngeles), "January 1, 2026")
        XCTAssertEqual(
            TimelineDateFormatting.fullDate(morning, calendar: losAngeles),
            TimelineDateFormatting.fullDate(evening, calendar: losAngeles)
        )
        XCTAssertEqual(TimelineDateFormatting.fullDate(morning, calendar: losAngeles), "March 2, 2026")
        XCTAssertEqual(TimelineCaption.preview("   "), "")
        XCTAssertEqual(TimelineCaption.preview("Sun on the rug"), "Sun on the rug")
        let long = String(repeating: "a", count: 120)
        let preview = TimelineCaption.preview(long)
        XCTAssertTrue(preview.hasSuffix("…"))
        XCTAssertLessThan(preview.count, long.count)
    }

    func testMultipleMemoriesOnTheSameDate() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let day = calendar.date(from: DateComponents(year: 2026, month: 4, day: 8, hour: 12))!
        let earlierWrite = makeMoment(
            title: "Earlier write",
            date: day,
            createdAt: day,
            id: UUID(uuidString: "00000000-0000-0000-0000-0000000000AA")!
        )
        let laterWrite = makeMoment(
            title: "Later write",
            date: day,
            createdAt: day.addingTimeInterval(60),
            id: UUID(uuidString: "00000000-0000-0000-0000-0000000000BB")!
        )
        let tieLow = makeMoment(
            title: "Tie low",
            date: day,
            createdAt: day.addingTimeInterval(60),
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        )
        let tieHigh = makeMoment(
            title: "Tie high",
            date: day,
            createdAt: day.addingTimeInterval(60),
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        )
        let groups = TimelineGrouping.years(
            from: [tieLow, earlierWrite, laterWrite, tieHigh],
            calendar: calendar
        )
        XCTAssertEqual(groups.map(\.year), [2026])
        XCTAssertEqual(groups[0].moments.map(\.title), ["Later write", "Tie high", "Tie low", "Earlier write"])
        let labels = groups[0].moments.map { TimelineDateFormatting.fullDate($0.momentDate, calendar: calendar) }
        XCTAssertEqual(Set(labels).count, 1)
    }

    func testEmptyStates() async {
        let model = makeModel(repository: InMemoryMomentRepository())
        XCTAssertEqual(model.presentation(for: nil), .noPet)
        await model.load(pet: nil)
        XCTAssertTrue(model.years.isEmpty)
        XCTAssertEqual(model.presentation(for: nil), .noPet)

        let owner = UUID()
        let pet = makePet(owner: owner, id: UUID(), birthday: Date(timeIntervalSince1970: 1_600_000_000))
        await model.load(pet: pet)
        XCTAssertEqual(model.presentation(for: pet), .empty)
        XCTAssertTrue(model.moments.isEmpty)
        XCTAssertTrue(model.years.isEmpty)

        let failing = makeModel(repository: FailingMomentRepository())
        await failing.load(pet: pet)
        XCTAssertEqual(failing.presentation(for: pet), .failed)
        XCTAssertEqual(failing.loadError, RepositoryError.remote.localizedDescription)
        XCTAssertTrue(failing.years.isEmpty)
    }

    func testNavigationToDetailAndRefresh() async throws {
        let owner = UUID()
        let petId = UUID()
        let repository = InMemoryMomentRepository()
        var moment = makeMoment(owner: owner, pet: petId, title: "Porch light", date: Date(timeIntervalSince1970: 1_720_000_000), createdAt: Date(timeIntervalSince1970: 1_720_000_000))
        moment.caption = "He waited by the door."
        _ = try await repository.upsert(moment)
        let other = makeMoment(owner: UUID(), pet: UUID(), title: "Someone else", date: moment.momentDate, createdAt: moment.createdAt)
        _ = try await repository.upsert(other)

        let route = TimelineNavigation.detailRoute(for: moment)
        guard case .detail(let momentId, let routePet, let routeOwner) = route else {
            return XCTFail("Expected a memory detail route")
        }
        XCTAssertEqual(momentId, moment.id)
        XCTAssertEqual(routePet, petId)
        XCTAssertEqual(routeOwner, owner)

        let opened = try await repository.moment(id: momentId, petId: routePet, ownerId: routeOwner)
        XCTAssertEqual(opened.title, "Porch light")
        XCTAssertEqual(opened.caption, "He waited by the door.")
        do {
            _ = try await repository.moment(id: moment.id, petId: other.petId, ownerId: other.ownerId)
            XCTFail("Expected another pet's timeline to stay closed")
        } catch RepositoryError.notFound {
        }

        let model = makeModel(repository: repository)
        let pet = makePet(owner: owner, id: petId, birthday: nil)
        await model.load(pet: pet)
        XCTAssertEqual(model.presentation(for: pet), .loaded)

        var edited = opened
        edited.title = "Porch light, later"
        _ = try await repository.upsert(edited)
        await model.load(pet: pet)
        XCTAssertEqual(model.moments.map(\.title), ["Porch light, later"])

        try await repository.delete(id: moment.id, ownerId: owner)
        await model.load(pet: pet)
        XCTAssertTrue(model.moments.isEmpty)
        XCTAssertEqual(model.presentation(for: pet), .empty)
        do {
            _ = try await repository.moment(id: moment.id, petId: petId, ownerId: owner)
            XCTFail("Expected the deleted moment to stay gone")
        } catch RepositoryError.notFound {
        }
    }

    func testPaginationKeepsYearsTogether() async throws {
        let owner = UUID()
        let petId = UUID()
        let repository = InMemoryMomentRepository()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let coverId = UUID(uuidString: "00000000-0000-0000-0000-0000000000c1")!
        let extraId = UUID(uuidString: "00000000-0000-0000-0000-0000000000e1")!
        let dates = (0..<5).map { index in
            calendar.date(from: DateComponents(year: index < 3 ? 2026 : 2025, month: 5, day: 10 + index, hour: 12))!
        }
        for (index, date) in dates.enumerated() {
            let momentId = UUID()
            let cover = MediaObjectPath.momentJPEG(ownerId: owner, petId: petId, momentId: momentId, fileId: coverId)
            let extra = MediaObjectPath.momentJPEG(ownerId: owner, petId: petId, momentId: momentId, fileId: extraId)
            let media = [
                MomentMedia(id: UUID(), momentId: momentId, ownerId: owner, storagePath: extra, sortOrder: 1, contentType: "image/jpeg", byteCount: nil, width: nil, height: nil),
                MomentMedia(id: UUID(), momentId: momentId, ownerId: owner, storagePath: cover, sortOrder: 0, contentType: "image/jpeg", byteCount: nil, width: nil, height: nil)
            ]
            _ = try await repository.upsert(
                makeMoment(
                    owner: owner,
                    pet: petId,
                    title: "Day \(index)",
                    date: date,
                    createdAt: date,
                    id: momentId,
                    media: media
                )
            )
        }

        let resolver = RecordingTimelineResolver()
        let model = MemoryTimelineViewModel(repository: repository, media: resolver, pageSize: 2, calendar: calendar)
        let pet = makePet(owner: owner, id: petId, birthday: nil)
        await model.load(pet: pet)
        XCTAssertEqual(model.moments.map(\.title), ["Day 2", "Day 1"])
        XCTAssertTrue(model.canLoadMore)
        XCTAssertEqual(model.years.map(\.title), ["2026"])

        await model.loadMore()
        XCTAssertEqual(model.moments.map(\.title), ["Day 2", "Day 1", "Day 0", "Day 4"])
        XCTAssertEqual(model.years.map(\.title), ["2026", "2025"])
        XCTAssertEqual(model.years[0].moments.map(\.title), ["Day 2", "Day 1", "Day 0"])
        XCTAssertEqual(model.years[1].moments.map(\.title), ["Day 4"])

        await model.loadMore()
        XCTAssertEqual(model.moments.map(\.title), ["Day 2", "Day 1", "Day 0", "Day 4", "Day 3"])
        XCTAssertEqual(model.years[0].moments.count, 3)
        XCTAssertEqual(model.years[1].moments.map(\.title), ["Day 4", "Day 3"])
        XCTAssertFalse(model.canLoadMore)
        XCTAssertFalse(model.isLoadingMore)
        let requested = await resolver.requestedPaths()
        let coverSuffix = "\(coverId.uuidString.lowercased()).jpg"
        let extraSuffix = "\(extraId.uuidString.lowercased()).jpg"
        XCTAssertEqual(requested.count, 5)
        XCTAssertTrue(requested.allSatisfy { $0.hasSuffix(coverSuffix) })
        XCTAssertFalse(requested.contains { $0.hasSuffix(extraSuffix) })
    }

    func testThumbnailDoesNotKeepFullResolution() throws {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 640, height: 480))
        let image = renderer.image { context in
            UIColor.brown.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 640, height: 480))
        }
        let source = try XCTUnwrap(image.jpegData(compressionQuality: 0.9))
        let thumbnail = try XCTUnwrap(TimelineImageSizing.thumbnailJPEG(from: source, maxPixel: 96))
        let imageSource = try XCTUnwrap(CGImageSourceCreateWithData(thumbnail as CFData, nil))
        let decoded = try XCTUnwrap(CGImageSourceCreateImageAtIndex(imageSource, 0, nil))
        XCTAssertLessThanOrEqual(max(decoded.width, decoded.height), 96)
        XCTAssertGreaterThan(max(decoded.width, decoded.height), 0)
        XCTAssertLessThan(thumbnail.count, source.count)
    }

    private func makeModel(
        repository: any MomentRepository,
        calendar: Calendar = .current
    ) -> MemoryTimelineViewModel {
        MemoryTimelineViewModel(
            repository: repository,
            media: SignedMediaURLCache(signer: TimelineEmptySigner()),
            pageSize: 20,
            calendar: calendar
        )
    }

    private func makePet(owner: UUID, id: UUID, birthday: Date?) -> Pet {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        return Pet(
            id: id,
            ownerId: owner,
            name: "Milo",
            species: .dog,
            breed: "",
            birthday: birthday,
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

    private func makeMoment(
        owner: UUID = UUID(),
        pet: UUID = UUID(),
        title: String,
        date: Date,
        createdAt: Date,
        id: UUID = UUID(),
        media: [MomentMedia] = []
    ) -> PetMoment {
        PetMoment(
            id: id,
            ownerId: owner,
            petId: pet,
            title: title,
            caption: "\(title) caption",
            category: .daily,
            momentDate: date,
            isFavorite: false,
            media: media,
            createdAt: createdAt,
            updatedAt: createdAt
        )
    }
}

private actor FailingMomentRepository: MomentRepository {
    func list(petId: UUID, ownerId: UUID) async throws -> [PetMoment] {
        throw RepositoryError.remote
    }

    func moment(id: UUID, petId: UUID, ownerId: UUID) async throws -> PetMoment {
        throw RepositoryError.remote
    }

    func page(
        petId: UUID,
        ownerId: UUID,
        category: MomentCategory?,
        cursor: MomentCursor?,
        limit: Int
    ) async throws -> MomentPage {
        throw RepositoryError.remote
    }

    func upsert(_ moment: PetMoment) async throws -> PetMoment {
        throw RepositoryError.remote
    }

    func setFavorite(id: UUID, petId: UUID, ownerId: UUID, isFavorite: Bool) async throws -> PetMoment {
        throw RepositoryError.remote
    }

    func delete(id: UUID, ownerId: UUID) async throws {
        throw RepositoryError.remote
    }
}

private actor RecordingTimelineResolver: MediaURLResolving {
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

private actor TimelineEmptySigner: MediaSigning {
    func signedURL(for path: String, expiresIn: Int) async throws -> URL {
        throw RepositoryError.notFound
    }
}
