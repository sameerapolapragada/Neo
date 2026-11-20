import Foundation
import Supabase

struct PawCheckRow: Codable, Sendable {
    var id: UUID
    var ownerId: UUID
    var petId: UUID
    var observationDate: String
    var appetite: String?
    var energy: String?
    var mood: String?
    var observations: [String]
    var note: String?
    var source: String
    var createdAt: String
    var updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case ownerId = "owner_id"
        case petId = "pet_id"
        case observationDate = "observation_date"
        case appetite
        case energy
        case mood
        case observations
        case note
        case source
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(_ check: PawCheck) {
        id = check.id
        ownerId = check.ownerId
        petId = check.petId
        observationDate = SupabaseDates.calendarDay(check.observationDate)
        appetite = check.appetite?.rawValue
        energy = check.energy?.rawValue
        mood = check.mood?.rawValue
        observations = PawCheckRules.sanitized(check.observations).map(\.rawValue)
        note = check.note.flatMap { PawCheckRules.note(from: $0) }
        source = PawCheck.sourceOwnerReported
        createdAt = SupabaseDates.timestamp(check.createdAt)
        updatedAt = SupabaseDates.timestamp(check.updatedAt)
    }

    func check() -> PawCheck {
        PawCheck(
            id: id,
            ownerId: ownerId,
            petId: petId,
            observationDate: SupabaseDates.parseDay(observationDate, calendar: .current) ?? .now,
            appetite: PawAppetite.fromStored(appetite),
            energy: PawEnergy.fromStored(energy),
            mood: PawMood.fromStored(mood),
            observations: observations.compactMap(PawObservation.fromStored),
            note: note,
            source: source,
            createdAt: SupabaseDates.parseTimestamp(createdAt) ?? .now,
            updatedAt: SupabaseDates.parseTimestamp(updatedAt) ?? .now
        )
    }
}

struct WeightEntryRow: Codable, Sendable {
    var id: UUID
    var ownerId: UUID
    var petId: UUID
    var measuredOn: String
    var weightValue: Double
    var weightUnit: String
    var source: String
    var createdAt: String
    var updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case ownerId = "owner_id"
        case petId = "pet_id"
        case measuredOn = "measured_on"
        case weightValue = "weight_value"
        case weightUnit = "weight_unit"
        case source
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(_ entry: WeightEntry) {
        id = entry.id
        ownerId = entry.ownerId
        petId = entry.petId
        measuredOn = SupabaseDates.calendarDay(entry.measuredOn)
        weightValue = entry.weightValue
        weightUnit = entry.weightUnit.rawValue
        source = WeightEntry.sourceOwnerReported
        createdAt = SupabaseDates.timestamp(entry.createdAt)
        updatedAt = SupabaseDates.timestamp(entry.updatedAt)
    }

    func entry() -> WeightEntry {
        WeightEntry(
            id: id,
            ownerId: ownerId,
            petId: petId,
            measuredOn: SupabaseDates.parseDay(measuredOn, calendar: .current) ?? .now,
            weightValue: weightValue,
            weightUnit: WeightUnit.fromStored(weightUnit),
            source: source,
            createdAt: SupabaseDates.parseTimestamp(createdAt) ?? .now,
            updatedAt: SupabaseDates.parseTimestamp(updatedAt) ?? .now
        )
    }
}

struct MomentTagRow: Decodable, Sendable {
    var momentId: UUID
    var tagKey: String

    enum CodingKeys: String, CodingKey {
        case momentId = "moment_id"
        case tagKey = "tag_key"
    }
}

struct ReplaceMomentTagsParams: Encodable, Sendable {
    var momentId: UUID
    var tags: [String]

    enum CodingKeys: String, CodingKey {
        case momentId = "p_moment_id"
        case tags = "p_tags"
    }
}

struct SupabaseWellnessRepository: PetWellnessRepository {
    let client: SupabaseClient

    func pawChecks(petId: UUID, ownerId: UUID) async throws -> [PawCheck] {
        do {
            let rows: [PawCheckRow] = try await client
                .from(SupabaseTable.pawChecks)
                .select()
                .eq("owner_id", value: ownerId.uuidString.lowercased())
                .eq("pet_id", value: petId.uuidString.lowercased())
                .order("observation_date", ascending: false)
                .execute()
                .value
            return rows.map { $0.check() }
        } catch {
            throw RepositoryErrorMapping.wrap(error)
        }
    }

    func save(_ check: PawCheck, pet: Pet) async throws -> PawCheck {
        guard CompanionAuthorization.writePetRecord(
            actor: check.ownerId,
            recordOwner: check.ownerId,
            recordPetId: check.petId,
            pet: pet
        ) == .allowed else {
            throw RepositoryError.notFound
        }
        do {
            let saved: PawCheckRow = try await client
                .from(SupabaseTable.pawChecks)
                .upsert(PawCheckRow(check), onConflict: "owner_id,pet_id,observation_date")
                .select()
                .single()
                .execute()
                .value
            return saved.check()
        } catch {
            throw RepositoryErrorMapping.wrap(error)
        }
    }

    func weightEntries(petId: UUID, ownerId: UUID) async throws -> [WeightEntry] {
        do {
            let rows: [WeightEntryRow] = try await client
                .from(SupabaseTable.weightEntries)
                .select()
                .eq("owner_id", value: ownerId.uuidString.lowercased())
                .eq("pet_id", value: petId.uuidString.lowercased())
                .order("measured_on", ascending: false)
                .order("created_at", ascending: false)
                .execute()
                .value
            return rows.map { $0.entry() }
        } catch {
            throw RepositoryErrorMapping.wrap(error)
        }
    }

    func save(_ entry: WeightEntry, pet: Pet) async throws -> WeightEntry {
        guard WeightValidation.value(from: String(entry.weightValue)) != nil else {
            throw RepositoryError.remote
        }
        guard CompanionAuthorization.writePetRecord(
            actor: entry.ownerId,
            recordOwner: entry.ownerId,
            recordPetId: entry.petId,
            pet: pet
        ) == .allowed else {
            throw RepositoryError.notFound
        }
        do {
            let saved: WeightEntryRow = try await client
                .from(SupabaseTable.weightEntries)
                .upsert(WeightEntryRow(entry), onConflict: "id")
                .select()
                .single()
                .execute()
                .value
            return saved.entry()
        } catch {
            throw RepositoryErrorMapping.wrap(error)
        }
    }

    func deleteWeight(id: UUID, petId: UUID, ownerId: UUID) async throws {
        do {
            try await client
                .from(SupabaseTable.weightEntries)
                .delete()
                .eq("id", value: id.uuidString.lowercased())
                .eq("pet_id", value: petId.uuidString.lowercased())
                .eq("owner_id", value: ownerId.uuidString.lowercased())
                .execute()
        } catch {
            throw RepositoryErrorMapping.wrap(error)
        }
    }

    func deletePet(id: UUID, ownerId: UUID) async throws {
        do {
            try await client
                .from(SupabaseTable.pawChecks)
                .delete()
                .eq("pet_id", value: id.uuidString.lowercased())
                .eq("owner_id", value: ownerId.uuidString.lowercased())
                .execute()
            try await client
                .from(SupabaseTable.weightEntries)
                .delete()
                .eq("pet_id", value: id.uuidString.lowercased())
                .eq("owner_id", value: ownerId.uuidString.lowercased())
                .execute()
        } catch {
            throw RepositoryErrorMapping.wrap(error)
        }
    }

    func deleteOwner(_ ownerId: UUID) async throws {
        do {
            try await client
                .from(SupabaseTable.pawChecks)
                .delete()
                .eq("owner_id", value: ownerId.uuidString.lowercased())
                .execute()
            try await client
                .from(SupabaseTable.weightEntries)
                .delete()
                .eq("owner_id", value: ownerId.uuidString.lowercased())
                .execute()
            try await client
                .from(SupabaseTable.momentTags)
                .delete()
                .eq("owner_id", value: ownerId.uuidString.lowercased())
                .execute()
        } catch {
            throw RepositoryErrorMapping.wrap(error)
        }
    }
}
