import Foundation

enum AccountDeletionError: LocalizedError, Equatable {
    case unavailable
    case missingEmail
    case incomplete(stage: String)
    case rejected

    var errorDescription: String? {
        switch self {
        case .unavailable:
            return "Account deletion isn't available."
        case .missingEmail:
            return "Sign in again before deleting this account."
        case .incomplete(let stage):
            return "Deletion stopped during \(stage). Your account is still here. Try again to continue."
        case .rejected:
            return "The server did not confirm that the account was deleted."
        }
    }
}

protocol AccountDeleting: Sendable {
    func deleteAuthenticatedAccount(password: String) async throws
}

struct AccountDeletionResponse: Decodable, Sendable {
    var status: String
    var stage: String?
}

struct AccountDeletionRequest: Encodable, Equatable, Sendable {
    var confirm = true
    var password: String
}

/// Calls the signed-in user's delete-account function.
/// The service-role key stays on the server. The password is checked by Auth
/// inside that function; this client does not keep a copy after the request.
struct SupabaseAccountDeletion: AccountDeleting, Sendable {
    let endpoint: URL
    let anonKey: String
    let accessToken: @Sendable () async throws -> String

    func deleteAuthenticatedAccount(password: String) async throws {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        let token = try await accessToken()
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(AccountDeletionRequest(password: password))

        let (data, response) = try await URLSession.shared.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        let body = try? JSONDecoder().decode(AccountDeletionResponse.self, from: data)
        if (200..<300).contains(statusCode), body?.status == "deleted" {
            return
        }
        if let stage = body?.stage, !stage.isEmpty {
            throw AccountDeletionError.incomplete(stage: stage)
        }
        throw AccountDeletionError.rejected
    }
}

enum SessionCleanup {
    /// Shown when this device is signed out but the server did not accept revocation.
    /// Previously issued access tokens and signed URLs can keep working until they expire.
    static let remoteSignOutFailed = "Signed out on this device. The server did not revoke the session, so it may stay valid until it expires. Links that were already created can keep working until they expire too."
    static let accountDeleted = "This account was deleted. This device is signed out. A session created before deletion can keep working until it expires."
}
