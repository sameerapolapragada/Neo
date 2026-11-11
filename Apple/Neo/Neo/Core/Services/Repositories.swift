import Foundation

struct SignUpResult: Equatable, Sendable {
    var ownerId: UUID?
    var needsEmailConfirmation: Bool
}

protocol AuthServicing: Sendable {
    func restoreSession() async throws -> UUID?
    func signIn(email: String, password: String) async throws -> UUID
    func signUp(email: String, password: String) async throws -> SignUpResult
    func sendPasswordReset(email: String) async throws
    func completeAuthCallback(_ url: URL) async throws -> UUID
    func updatePassword(_ password: String) async throws -> UUID
    func signOut() async throws
    func currentEmail() async -> String?
}

extension AuthServicing {
    func currentEmail() async -> String? { nil }

    func sendPasswordReset(email: String) async throws {
        throw RepositoryError.remote
    }

    func completeAuthCallback(_ url: URL) async throws -> UUID {
        throw RepositoryError.remote
    }

    func updatePassword(_ password: String) async throws -> UUID {
        throw RepositoryError.remote
    }
}

protocol PetRepository: Sendable {
    func list(ownerId: UUID) async throws -> [Pet]
    func pet(id: UUID, ownerId: UUID) async throws -> Pet
    func upsert(_ pet: Pet) async throws -> Pet
}

protocol MomentRepository: Sendable {
    func list(petId: UUID, ownerId: UUID) async throws -> [PetMoment]
    func moment(id: UUID, petId: UUID, ownerId: UUID) async throws -> PetMoment
    func page(
        petId: UUID,
        ownerId: UUID,
        category: MomentCategory?,
        cursor: MomentCursor?,
        limit: Int
    ) async throws -> MomentPage
    func upsert(_ moment: PetMoment) async throws -> PetMoment
    func setFavorite(id: UUID, petId: UUID, ownerId: UUID, isFavorite: Bool) async throws -> PetMoment
    func delete(id: UUID, ownerId: UUID) async throws
}

protocol MemoryRepository: Sendable {
    func list(petId: UUID, ownerId: UUID) async throws -> [Memory]
    func upsert(_ memory: Memory) async throws -> Memory
    func delete(id: UUID, ownerId: UUID) async throws
}

protocol MediaUploading: Sendable {
    func uploadJPEG(_ data: Data, ownerId: UUID, petId: UUID) async throws -> String
    func uploadMomentJPEG(_ data: Data, ownerId: UUID, petId: UUID, momentId: UUID) async throws -> String
    func deleteUploadedObject(_ path: String, ownerId: UUID) async throws
}

extension MediaUploading {
    func uploadMomentJPEG(_ data: Data, ownerId: UUID, petId: UUID, momentId: UUID) async throws -> String {
        try await uploadJPEG(data, ownerId: ownerId, petId: petId)
    }

    func deleteUploadedObject(_ path: String, ownerId: UUID) async throws {
        guard MediaObjectPath.belongsToOwner(path, ownerId: ownerId) else {
            throw RepositoryError.invalidPhoto
        }
    }
}

protocol MediaSigning: Sendable {
    func signedURL(for path: String, expiresIn: Int) async throws -> URL
}

protocol MediaURLResolving: Sendable {
    func displayURL(for path: String?) async -> URL?
}

@MainActor
protocol ActivePetStoring: AnyObject {
    func activePetId(for ownerId: UUID) -> UUID?
    func setActivePetId(_ id: UUID?, for ownerId: UUID)
}
