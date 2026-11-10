import UIKit
import XCTest
@testable import Neo

final class FoundationTests: XCTestCase {
    func testServiceRoleKeyIsRejected() throws {
        let key = jwt(role: "service_role")
        XCTAssertThrowsError(try SupabaseKeyGuard.validate(key)) { error in
            XCTAssertEqual(error as? SupabaseKeyGuard.Failure, .serviceRole)
        }
        let state = SupabaseConfigurationLoader.resolve(
            urlString: "https://example.supabase.co",
            anonKey: key
        )
        XCTAssertEqual(state, .rejectedServiceRole)
    }

    func testAnonAndPublishableKeysAreAllowed() throws {
        XCTAssertNoThrow(try SupabaseKeyGuard.validate(jwt(role: "anon")))
        XCTAssertNoThrow(try SupabaseKeyGuard.validate("sb_publishable_example"))
        XCTAssertThrowsError(try SupabaseKeyGuard.validate("sb_secret_example")) { error in
            XCTAssertEqual(error as? SupabaseKeyGuard.Failure, .serviceRole)
        }
        let state = SupabaseConfigurationLoader.resolve(
            urlString: "https://example.supabase.co",
            anonKey: jwt(role: "anon")
        )
        guard case .ready(let configuration) = state else {
            return XCTFail("Expected a ready configuration")
        }
        XCTAssertEqual(configuration.url.host, "example.supabase.co")
    }

    func testMissingAndInsecureConfiguration() {
        XCTAssertEqual(
            SupabaseConfigurationLoader.resolve(urlString: "", anonKey: ""),
            .missing
        )
        XCTAssertEqual(
            SupabaseConfigurationLoader.resolve(urlString: "http://example.supabase.co", anonKey: jwt(role: "anon")),
            .missing
        )
        XCTAssertEqual(
            SupabaseConfigurationLoader.resolve(urlString: "$(SUPABASE_URL)", anonKey: "abc"),
            .missing
        )
    }

    func testTablesStaySeparateFromExpo() {
        XCTAssertEqual(SupabaseTable.pets, "companion_pets")
        XCTAssertEqual(SupabaseTable.moments, "companion_moments")
        XCTAssertEqual(SupabaseTable.momentMedia, "companion_moment_media")
        XCTAssertEqual(SupabaseTable.memories, "companion_memories")
        XCTAssertNotEqual(SupabaseTable.moments, "moments")
        XCTAssertEqual(SupabaseTable.mediaBucket, "companion-pet-media")
        XCTAssertNotEqual(SupabaseTable.pets, "pets")
        XCTAssertNotEqual(SupabaseTable.memories, "memories")
    }

    func testPhase1RowsUseTheDatabaseColumnNames() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let momentDay = calendar.date(from: DateComponents(year: 2026, month: 5, day: 2, hour: 15))!
        let owner = UUID()
        let petId = UUID()
        let momentId = UUID()
        let pet = Pet(
            id: petId,
            ownerId: owner,
            name: "Milo",
            species: .dog,
            breed: "",
            birthday: nil,
            gender: .unknown,
            adoptionDate: nil,
            weightValue: 12.5,
            weightUnit: .pounds,
            microchipId: nil,
            photoPath: MediaObjectPath.jpeg(
                ownerId: owner,
                petId: petId,
                fileId: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
            ),
            bio: "Calm",
            favoriteToy: nil,
            isFavorite: false,
            createdAt: momentDay,
            updatedAt: momentDay
        )
        let petJSON = try jsonObject(PetRow(pet))
        XCTAssertEqual(petJSON["weight"] as? Double, 12.5)
        XCTAssertEqual(petJSON["personality"] as? String, "Calm")
        XCTAssertEqual(petJSON["profile_photo_path"] as? String, pet.photoPath)
        XCTAssertNil(petJSON["bio"])
        XCTAssertNil(petJSON["photo_path"])
        XCTAssertNil(petJSON["weight_value"])

        let moment = PetMoment(
            id: momentId,
            ownerId: owner,
            petId: petId,
            title: "Park",
            caption: "",
            category: .milestone,
            momentDate: momentDay,
            isFavorite: false,
            media: [],
            createdAt: momentDay,
            updatedAt: momentDay
        )
        let momentJSON = try jsonObject(MomentRow(moment))
        XCTAssertEqual(momentJSON["moment_date"] as? String, SupabaseDates.calendarDay(momentDay))
        XCTAssertEqual((momentJSON["moment_date"] as? String)?.count, 10)
        XCTAssertEqual(momentJSON["category"] as? String, "Milestone")

        let media = MomentMedia(
            id: UUID(),
            momentId: momentId,
            ownerId: owner,
            storagePath: MediaObjectPath.momentJPEG(
                ownerId: owner,
                petId: petId,
                momentId: momentId,
                fileId: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
            ),
            sortOrder: 0,
            contentType: "image/jpeg",
            byteCount: 1200,
            width: 800,
            height: 600
        )
        let mediaJSON = try jsonObject(MomentMediaRow(media))
        XCTAssertEqual(mediaJSON["mime_type"] as? String, "image/jpeg")
        XCTAssertEqual(mediaJSON["file_size"] as? Int, 1200)
        XCTAssertNil(mediaJSON["content_type"])
        XCTAssertNil(mediaJSON["byte_count"])
    }

    private func jsonObject<T: Encodable>(_ value: T) throws -> [String: Any] {
        let data = try JSONEncoder().encode(value)
        let object = try JSONSerialization.jsonObject(with: data)
        return try XCTUnwrap(object as? [String: Any])
    }

    func testMediaPathsArePrivateObjectKeys() {
        let owner = UUID()
        let pet = UUID()
        let path = MediaObjectPath.jpeg(ownerId: owner, petId: pet)
        XCTAssertTrue(MediaPath.isObjectPath(path))
        XCTAssertTrue(path.contains("/pets/"))
        XCTAssertTrue(path.contains("/profile/"))
        XCTAssertTrue(MediaObjectPath.isProfilePhoto(path, ownerId: owner, petId: pet))
        XCTAssertFalse(path.contains("://"))
        XCTAssertFalse(MediaPath.isObjectPath("https://cdn.example/pet.jpg"))
        XCTAssertFalse(MediaPath.isObjectPath("/tmp/pet.jpg"))
        XCTAssertFalse(MediaPath.isObjectPath("../secret.jpg"))
        XCTAssertEqual(MediaPolicy.signedURLLifetimeSeconds, 600)
    }

    func testPetValidationMatchesProfileRules() {
        let missing = PetValidation.errors(
            name: "A",
            species: nil,
            weightText: "heavy",
            personality: ""
        )
        XCTAssertEqual(missing[.name], "Name must be at least 2 characters")
        XCTAssertEqual(missing[.species], "Species is required")
        XCTAssertEqual(missing[.weight], "Enter a valid weight")

        let blankName = PetValidation.errors(
            name: "  ",
            species: .dog,
            weightText: "",
            personality: ""
        )
        XCTAssertEqual(blankName[.name], "Name is required")

        let zero = PetValidation.errors(
            name: "Milo",
            species: .dog,
            weightText: "0",
            personality: ""
        )
        XCTAssertEqual(zero[.weight], "Enter a weight greater than zero")

        let longPersonality = String(repeating: "a", count: PetValidation.personalityLimit + 1)
        let personality = PetValidation.errors(
            name: "Milo",
            species: .cat,
            weightText: "",
            personality: longPersonality
        )
        XCTAssertEqual(
            personality[.personality],
            "Personality must be \(PetValidation.personalityLimit) characters or less"
        )

        let valid = PetValidation.errors(
            name: "  Milo ",
            species: .dog,
            weightText: "12.5",
            personality: "Soft ears."
        )
        XCTAssertTrue(valid.isEmpty)
        XCTAssertNil(valid[.personality])
        XCTAssertEqual(WeightParser.value(from: " 12.5 "), 12.5)
    }

    func testMomentAndMemoryValidation() {
        XCTAssertEqual(
            MomentValidation.errors(title: " ", caption: "", photoCount: 1)[.title],
            "Title is required"
        )
        XCTAssertTrue(MomentValidation.errors(title: "Nap", caption: "", photoCount: 1).isEmpty)
        XCTAssertNotNil(
            MomentValidation.errors(
                title: "Nap",
                caption: String(repeating: "a", count: 301),
                photoCount: 1
            )[.caption]
        )
        XCTAssertNotNil(MemoryValidation.errors(title: "A", notes: "Hi")[.title])
        XCTAssertNotNil(MemoryValidation.errors(title: "First rain", notes: "Hi")[.notes])
        XCTAssertTrue(MemoryValidation.errors(title: "First rain", notes: "He watched the window.").isEmpty)
    }

    func testAuthFormValidation() {
        XCTAssertNotNil(AuthFormValidation.error(email: "not-an-email", password: "longenough"))
        XCTAssertNotNil(AuthFormValidation.error(email: "a@b.com", password: "short"))
        XCTAssertNil(AuthFormValidation.error(email: "sam@example.com", password: "longenough"))
    }

    func testPetAge() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let birthday = calendar.date(from: DateComponents(year: 2024, month: 1, day: 1, hour: 12))!
        let now = calendar.date(from: DateComponents(year: 2026, month: 3, day: 1, hour: 12))!
        XCTAssertEqual(PetAge.description(from: birthday, now: now, calendar: calendar), "2 yr 2 mo")
        XCTAssertEqual(PetAge.description(from: now, now: now, calendar: calendar), "Newborn")
        let future = calendar.date(from: DateComponents(year: 2027, month: 1, day: 1))!
        XCTAssertEqual(PetAge.description(from: future, now: now, calendar: calendar), "Not yet")
    }

    func testTimelineGroupsNewestFirst() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let owner = UUID()
        let pet = UUID()
        func moment(day: Date, title: String) -> PetMoment {
            PetMoment(
                id: UUID(),
                ownerId: owner,
                petId: pet,
                title: title,
                caption: "",
                category: .daily,
                momentDate: day,
                isFavorite: false,
                media: [],
                createdAt: day,
                updatedAt: day
            )
        }
        let january = calendar.date(from: DateComponents(year: 2025, month: 1, day: 2, hour: 12))!
        let marchEarly = calendar.date(from: DateComponents(year: 2026, month: 3, day: 2, hour: 12))!
        let marchLate = calendar.date(from: DateComponents(year: 2026, month: 3, day: 20, hour: 12))!
        let groups = TimelineGrouping.years(
            from: [
                moment(day: january, title: "January"),
                moment(day: marchEarly, title: "Early"),
                moment(day: marchLate, title: "Late"),
            ],
            calendar: calendar
        )
        XCTAssertEqual(groups.map(\.title), ["2026", "2025"])
        XCTAssertEqual(groups[0].moments.map(\.title), ["Late", "Early"])
    }

    func testSignedURLCacheReusesShortLivedURL() async {
        let signer = CountingSigner()
        let cache = SignedMediaURLCache(signer: signer)
        let owner = UUID()
        let path = MediaObjectPath.jpeg(ownerId: owner, petId: UUID(), fileId: UUID())
        await cache.bind(ownerId: owner)
        let first = await cache.displayURL(for: path)
        let second = await cache.displayURL(for: path)
        let calls = await signer.calls
        let expiry = await signer.lastExpiry
        let blocked = await cache.displayURL(for: "https://public.example/object/public/file.jpg")
        let missing = await cache.displayURL(for: nil)
        XCTAssertEqual(first, second)
        XCTAssertEqual(calls, 1)
        XCTAssertEqual(expiry, 600)
        XCTAssertNil(blocked)
        XCTAssertNil(missing)
    }

    func testJPEGEncoding() {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 8, height: 8))
        let image = renderer.image { context in
            UIColor.brown.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
        }
        guard let png = image.pngData() else {
            return XCTFail("Expected PNG data")
        }
        XCTAssertNotNil(PhotoEncoding.jpegData(from: png))
    }

    private func jwt(role: String) -> String {
        func encode(_ text: String) -> String {
            Data(text.utf8)
                .base64EncodedString()
                .replacingOccurrences(of: "+", with: "-")
                .replacingOccurrences(of: "/", with: "_")
                .replacingOccurrences(of: "=", with: "")
        }
        return "\(encode(#"{"alg":"none"}"#)).\(encode(#"{"role":"\#(role)"}"#)).sig"
    }
}

private actor CountingSigner: MediaSigning {
    private(set) var calls = 0
    private(set) var lastExpiry = 0

    func signedURL(for path: String, expiresIn: Int) async throws -> URL {
        calls += 1
        lastExpiry = expiresIn
        return URL(string: "https://signed.test/\(path)")!
    }
}
