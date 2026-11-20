#if DEBUG
import Foundation

actor InMemoryWellnessStore: PetWellnessRepository {
    private var checks: [UUID: PawCheck] = [:]
    private var weights: [UUID: WeightEntry] = [:]

    func pawChecks(petId: UUID, ownerId: UUID) async throws -> [PawCheck] {
        checks.values
            .filter { $0.petId == petId && $0.ownerId == ownerId }
            .sorted { $0.observationDate > $1.observationDate }
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
        var stored = check
        stored.observations = PawCheckRules.sanitized(check.observations)
        stored.note = check.note.flatMap { PawCheckRules.note(from: $0) }
        stored.source = PawCheck.sourceOwnerReported
        if let existing = checks.values.first(where: {
            $0.ownerId == check.ownerId
                && $0.petId == check.petId
                && Calendar.current.isDate($0.observationDate, inSameDayAs: check.observationDate)
        }) {
            stored.id = existing.id
            stored.createdAt = existing.createdAt
        }
        if let occupied = checks[stored.id], occupied.ownerId != stored.ownerId || occupied.petId != stored.petId {
            throw RepositoryError.notFound
        }
        checks[stored.id] = stored
        return stored
    }

    func weightEntries(petId: UUID, ownerId: UUID) async throws -> [WeightEntry] {
        WeightLog.history(weights.values.filter { $0.petId == petId && $0.ownerId == ownerId })
    }

    func save(_ entry: WeightEntry, pet: Pet) async throws -> WeightEntry {
        guard entry.weightValue > 0 else { throw RepositoryError.remote }
        guard CompanionAuthorization.writePetRecord(
            actor: entry.ownerId,
            recordOwner: entry.ownerId,
            recordPetId: entry.petId,
            pet: pet
        ) == .allowed else {
            throw RepositoryError.notFound
        }
        if let existing = weights[entry.id], existing.ownerId != entry.ownerId || existing.petId != entry.petId {
            throw RepositoryError.notFound
        }
        var stored = entry
        stored.source = WeightEntry.sourceOwnerReported
        weights[stored.id] = stored
        return stored
    }

    func deleteWeight(id: UUID, petId: UUID, ownerId: UUID) async throws {
        guard let entry = weights[id], entry.petId == petId, entry.ownerId == ownerId else {
            throw RepositoryError.notFound
        }
        weights.removeValue(forKey: id)
    }

    func deletePet(id: UUID, ownerId: UUID) async throws {
        checks = checks.filter { $0.value.petId != id || $0.value.ownerId != ownerId }
        weights = weights.filter { $0.value.petId != id || $0.value.ownerId != ownerId }
    }

    func deleteOwner(_ ownerId: UUID) async throws {
        checks = checks.filter { $0.value.ownerId != ownerId }
        weights = weights.filter { $0.value.ownerId != ownerId }
    }
}
#endif
