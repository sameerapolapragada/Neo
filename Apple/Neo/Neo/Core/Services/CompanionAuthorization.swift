import Foundation

/// Why a private read or write was refused.
/// These cases are authorization results. They are not network failures,
/// and `missingRecord` is a setup problem rather than a successful block.
enum CompanionDenial: Equatable, Sendable {
    case anonymous
    case notOwner
    case ownerChange
    case forgedRelationship
    case outsideAccount
    case publicObjectURL
    case missingRecord
}

enum CompanionAccess: Equatable, Sendable {
    case allowed
    case denied(CompanionDenial)
}

/// The same ownership rules as the Phase 1 RLS policies.
/// `actor` is `auth.uid()`. `nil` is an anonymous request.
enum CompanionAuthorization {
    static func readPet(actor: UUID?, pet: Pet?) -> CompanionAccess {
        guard let pet else { return .denied(.missingRecord) }
        guard let actor else { return .denied(.anonymous) }
        guard pet.ownerId == actor else { return .denied(.notOwner) }
        return .allowed
    }

    static func insertPet(actor: UUID?, requestedOwner: UUID) -> CompanionAccess {
        guard let actor else { return .denied(.anonymous) }
        guard requestedOwner == actor else { return .denied(.notOwner) }
        return .allowed
    }

    static func updatePet(actor: UUID?, existing: Pet?, requestedOwner: UUID) -> CompanionAccess {
        guard let existing else { return .denied(.missingRecord) }
        guard let actor else { return .denied(.anonymous) }
        guard existing.ownerId == actor else { return .denied(.notOwner) }
        guard requestedOwner == actor else { return .denied(.ownerChange) }
        return .allowed
    }

    static func deletePet(actor: UUID?, pet: Pet?) -> CompanionAccess {
        readPet(actor: actor, pet: pet)
    }

    /// A moment is visible only when the caller owns both the moment and its pet.
    static func readMoment(actor: UUID?, moment: PetMoment?, pet: Pet?) -> CompanionAccess {
        guard let moment, let pet else { return .denied(.missingRecord) }
        guard let actor else { return .denied(.anonymous) }
        guard moment.ownerId == actor, pet.ownerId == actor else { return .denied(.notOwner) }
        guard moment.petId == pet.id else { return .denied(.forgedRelationship) }
        return .allowed
    }

    /// Inserting a moment for the caller's id onto another account's pet is rejected.
    static func insertMoment(actor: UUID?, momentOwner: UUID, pet: Pet?) -> CompanionAccess {
        guard let pet else { return .denied(.missingRecord) }
        guard let actor else { return .denied(.anonymous) }
        guard momentOwner == actor else { return .denied(.notOwner) }
        guard pet.ownerId == actor else { return .denied(.forgedRelationship) }
        return .allowed
    }

    static func updateMoment(
        actor: UUID?,
        existing: PetMoment?,
        requestedOwner: UUID,
        requestedPet: Pet?
    ) -> CompanionAccess {
        guard let existing, let requestedPet else { return .denied(.missingRecord) }
        guard let actor else { return .denied(.anonymous) }
        guard existing.ownerId == actor else { return .denied(.notOwner) }
        guard requestedOwner == actor else { return .denied(.ownerChange) }
        guard requestedPet.ownerId == actor else { return .denied(.forgedRelationship) }
        return .allowed
    }

    static func writeMedia(
        actor: UUID?,
        existingOwner: UUID?,
        requestedOwner: UUID,
        moment: PetMoment?,
        pet: Pet?
    ) -> CompanionAccess {
        guard let existingOwner, let moment, let pet else { return .denied(.missingRecord) }
        guard let actor else { return .denied(.anonymous) }
        guard existingOwner == actor else { return .denied(.notOwner) }
        guard requestedOwner == actor else { return .denied(.ownerChange) }
        guard moment.ownerId == actor, pet.ownerId == actor, moment.petId == pet.id else {
            return .denied(.forgedRelationship)
        }
        return .allowed
    }

    /// Storage SELECT, INSERT, UPDATE, and DELETE, including the SELECT that
    /// `createSignedURL` requires. The object key and `storage.objects.owner`
    /// both have to name the signed-in account.
    static func storageAccess(actor: UUID?, path: String, objectOwner: UUID?) -> CompanionAccess {
        if MediaObjectPath.isPublicObjectURL(path) || path.contains("://") {
            return .denied(.publicObjectURL)
        }
        guard let actor else { return .denied(.anonymous) }
        guard MediaObjectPath.belongsToOwner(path, ownerId: actor) else {
            return .denied(.outsideAccount)
        }
        guard let objectOwner else { return .denied(.missingRecord) }
        guard objectOwner == actor else { return .denied(.notOwner) }
        return .allowed
    }
}
