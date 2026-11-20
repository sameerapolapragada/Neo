import Foundation

struct PetRow: Codable, Sendable {
    var id: UUID
    var ownerId: UUID
    var name: String
    var species: String
    var breed: String
    var birthday: String?
    var gender: String
    var adoptionDate: String?
    var weightValue: Double?
    var weightUnit: String
    var microchipId: String?
    var photoPath: String?
    var bio: String
    var favoriteToy: String?
    var isFavorite: Bool
    var sex: String
    var reproductiveStatus: String
    var ageStatus: String
    var approximateAge: String?
    var sizeCategory: String
    var breedIdentity: String
    var createdAt: String
    var updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case ownerId = "owner_id"
        case name
        case species
        case breed
        case birthday
        case gender
        case adoptionDate = "adoption_date"
        case weightValue = "weight"
        case weightUnit = "weight_unit"
        case microchipId = "microchip_id"
        case photoPath = "profile_photo_path"
        case bio = "personality"
        case favoriteToy = "favorite_toy"
        case isFavorite = "is_favorite"
        case sex
        case reproductiveStatus = "reproductive_status"
        case ageStatus = "age_status"
        case approximateAge = "approximate_age"
        case sizeCategory = "size_category"
        case breedIdentity = "breed_identity"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(_ pet: Pet) {
        id = pet.id
        ownerId = pet.ownerId
        name = pet.name
        species = pet.species.rawValue
        breed = pet.breed
        birthday = SupabaseDates.dayString(pet.birthday)
        gender = pet.gender.rawValue
        adoptionDate = SupabaseDates.dayString(pet.adoptionDate)
        weightValue = pet.weightValue
        weightUnit = pet.weightUnit.rawValue
        microchipId = pet.microchipId
        photoPath = pet.photoPath
        bio = pet.bio
        favoriteToy = pet.favoriteToy
        isFavorite = pet.isFavorite
        sex = pet.sex.rawValue
        reproductiveStatus = pet.reproductiveStatus.rawValue
        ageStatus = pet.ageStatus.rawValue
        approximateAge = PetProfileDetails.approximateAge(from: pet.approximateAge ?? "")
        sizeCategory = pet.sizeCategory.rawValue
        breedIdentity = pet.breedIdentity.rawValue
        createdAt = SupabaseDates.timestamp(pet.createdAt)
        updatedAt = SupabaseDates.timestamp(pet.updatedAt)
    }

    func pet() -> Pet {
        Pet(
            id: id,
            ownerId: ownerId,
            name: name,
            species: Species.fromStored(species),
            breed: breed,
            birthday: SupabaseDates.parseDay(birthday),
            gender: PetGender.fromStored(gender),
            adoptionDate: SupabaseDates.parseDay(adoptionDate),
            weightValue: weightValue,
            weightUnit: WeightUnit.fromStored(weightUnit),
            microchipId: microchipId,
            photoPath: photoPath,
            bio: bio,
            favoriteToy: favoriteToy,
            isFavorite: isFavorite,
            sex: PetSex.fromStored(sex),
            reproductiveStatus: ReproductiveStatus.fromStored(reproductiveStatus),
            ageStatus: AgeStatus.fromStored(ageStatus),
            approximateAge: approximateAge,
            sizeCategory: PetSize.fromStored(sizeCategory),
            breedIdentity: BreedIdentity.fromStored(breedIdentity),
            createdAt: SupabaseDates.parseTimestamp(createdAt) ?? .now,
            updatedAt: SupabaseDates.parseTimestamp(updatedAt) ?? .now
        )
    }
}

struct MomentRow: Codable, Sendable {
    var id: UUID
    var ownerId: UUID
    var petId: UUID
    var title: String
    var caption: String
    var category: String
    var momentDate: String
    var isFavorite: Bool
    var createdAt: String
    var updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case ownerId = "owner_id"
        case petId = "pet_id"
        case title
        case caption
        case category
        case momentDate = "moment_date"
        case isFavorite = "is_favorite"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(_ moment: PetMoment) {
        id = moment.id
        ownerId = moment.ownerId
        petId = moment.petId
        title = moment.title
        caption = moment.caption
        category = moment.category.rawValue
        momentDate = SupabaseDates.calendarDay(moment.momentDate)
        isFavorite = moment.isFavorite
        createdAt = SupabaseDates.timestamp(moment.createdAt)
        updatedAt = SupabaseDates.timestamp(moment.updatedAt)
    }

    func moment(media: [MomentMedia] = []) -> PetMoment {
        PetMoment(
            id: id,
            ownerId: ownerId,
            petId: petId,
            title: title,
            caption: caption,
            category: MomentCategory.fromStored(category),
            momentDate: SupabaseDates.parseDay(momentDate, calendar: .current)
                ?? SupabaseDates.parseTimestamp(momentDate)
                ?? .now,
            isFavorite: isFavorite,
            media: media.inDisplayOrder(),
            createdAt: SupabaseDates.parseTimestamp(createdAt) ?? .now,
            updatedAt: SupabaseDates.parseTimestamp(updatedAt) ?? .now
        )
    }
}

struct MomentMediaRow: Codable, Sendable {
    var id: UUID
    var momentId: UUID
    var ownerId: UUID
    var storagePath: String
    var sortOrder: Int
    var contentType: String
    var byteCount: Int?
    var width: Int?
    var height: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case momentId = "moment_id"
        case ownerId = "owner_id"
        case storagePath = "storage_path"
        case sortOrder = "sort_order"
        case contentType = "mime_type"
        case byteCount = "file_size"
        case width
        case height
    }

    init(_ media: MomentMedia) {
        id = media.id
        momentId = media.momentId
        ownerId = media.ownerId
        storagePath = media.storagePath
        sortOrder = media.sortOrder
        contentType = media.contentType
        byteCount = media.byteCount
        width = media.width
        height = media.height
    }

    func media() -> MomentMedia {
        MomentMedia(
            id: id,
            momentId: momentId,
            ownerId: ownerId,
            storagePath: storagePath,
            sortOrder: sortOrder,
            contentType: contentType,
            byteCount: byteCount,
            width: width,
            height: height
        )
    }
}

struct ReplaceMomentMediaParams: Encodable, Sendable {
    var momentId: UUID
    var media: [MomentMediaRow]

    enum CodingKeys: String, CodingKey {
        case momentId = "p_moment_id"
        case media = "p_media"
    }
}

struct ReplaceMomentMediaResult: Decodable, Sendable {
    var removed: [String]
}

struct AbandonEmptyMomentParams: Encodable, Sendable {
    var momentId: UUID

    enum CodingKeys: String, CodingKey {
        case momentId = "p_moment_id"
    }
}

struct MomentFavoriteUpdate: Encodable {
    var isFavorite: Bool

    enum CodingKeys: String, CodingKey {
        case isFavorite = "is_favorite"
    }
}

struct MemoryRow: Codable, Sendable {
    var id: UUID
    var ownerId: UUID
    var petId: UUID
    var title: String
    var notes: String
    var category: String
    var sentiment: String?
    var photoPath: String?
    var occurredAt: String
    var createdAt: String
    var updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case ownerId = "owner_id"
        case petId = "pet_id"
        case title
        case notes
        case category
        case sentiment
        case photoPath = "photo_path"
        case occurredAt = "occurred_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(_ memory: Memory) {
        id = memory.id
        ownerId = memory.ownerId
        petId = memory.petId
        title = memory.title
        notes = memory.notes
        category = memory.category.rawValue
        sentiment = memory.sentiment?.rawValue
        photoPath = memory.photoPath
        occurredAt = SupabaseDates.timestamp(memory.occurredAt)
        createdAt = SupabaseDates.timestamp(memory.createdAt)
        updatedAt = SupabaseDates.timestamp(memory.updatedAt)
    }

    func memory() -> Memory {
        Memory(
            id: id,
            ownerId: ownerId,
            petId: petId,
            title: title,
            notes: notes,
            category: MemoryCategory.fromStored(category),
            sentiment: sentiment.flatMap(MemorySentiment.fromStored),
            photoPath: photoPath,
            occurredAt: SupabaseDates.parseTimestamp(occurredAt) ?? .now,
            createdAt: SupabaseDates.parseTimestamp(createdAt) ?? .now,
            updatedAt: SupabaseDates.parseTimestamp(updatedAt) ?? .now
        )
    }
}
