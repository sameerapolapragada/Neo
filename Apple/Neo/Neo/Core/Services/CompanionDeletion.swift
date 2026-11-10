import Foundation

enum CompanionDeletionError: LocalizedError, Equatable {
    case unavailable
    case rejected
    case incomplete(stage: String)

    var errorDescription: String? {
        switch self {
        case .unavailable:
            "Deletion isn't available."
        case .rejected:
            "That record isn't on this account."
        case .incomplete(let stage):
            "Deletion stopped during \(stage). Try again to continue."
        }
    }
}

protocol MomentDeleting: Sendable {
    func delete(momentId: UUID, petId: UUID, ownerId: UUID) async throws
}

protocol PetDeleting: Sendable {
    func delete(petId: UUID, ownerId: UUID) async throws
}

protocol StorageCleaning: Sendable {
    func cleanupOwnedStorage(paths: [String]) async throws
}

struct MomentDeletionRequest: Encodable, Equatable, Sendable {
    var momentId: UUID
    var petId: UUID
}

struct PetDeletionRequest: Encodable, Equatable, Sendable {
    var petId: UUID
}

struct StorageCleanupRequest: Encodable, Equatable, Sendable {
    var paths: [String]
}

/// Calls the signed-in user's deletion functions.
/// The service-role key stays on the server. This client sends only the user session.
struct SupabaseCompanionDeletion: MomentDeleting, PetDeleting, StorageCleaning, Sendable {
    let functionsBase: URL
    let anonKey: String
    let accessToken: @Sendable () async throws -> String

    func delete(momentId: UUID, petId: UUID, ownerId: UUID) async throws {
        _ = ownerId
        try await post(
            function: "delete-moment",
            body: MomentDeletionRequest(momentId: momentId, petId: petId)
        )
    }

    func delete(petId: UUID, ownerId: UUID) async throws {
        _ = ownerId
        try await post(function: "delete-pet", body: PetDeletionRequest(petId: petId))
    }

    func cleanupOwnedStorage(paths: [String]) async throws {
        try await post(function: "cleanup-storage", body: StorageCleanupRequest(paths: paths))
    }

    private func post(function: String, body: some Encodable) async throws {
        let endpoint = functionsBase.appending(path: function)
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        let token = try await accessToken()
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder.companion.encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        let decoded = try? JSONDecoder().decode(AccountDeletionResponse.self, from: data)
        if (200..<300).contains(statusCode), decoded?.status == "deleted" {
            return
        }
        if let stage = decoded?.stage, !stage.isEmpty {
            throw CompanionDeletionError.incomplete(stage: stage)
        }
        if statusCode == 401 || statusCode == 403 || statusCode == 404 {
            throw CompanionDeletionError.rejected
        }
        throw CompanionDeletionError.rejected
    }
}

private extension JSONEncoder {
    static var companion: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }
}
