import Foundation

enum RepositoryError: LocalizedError, Equatable {
    case notFound
    case invalidPhoto
    case remote

    var errorDescription: String? {
        switch self {
        case .notFound:
            "That record is no longer available."
        case .invalidPhoto:
            "Choose a photo from your library and try again."
        case .remote:
            "We couldn't reach your scrapbook. Check your connection and try again."
        }
    }
}

enum AuthErrorMessage {
    static func message(for error: Error, creatingAccount: Bool) -> String {
        let text = String(describing: error).lowercased()
        if text.contains("email not confirmed") || text.contains("not confirmed") {
            return "Confirm your email, then sign in."
        }
        if text.contains("already registered") || text.contains("already been registered") {
            return "An account with that email already exists. Sign in instead."
        }
        if text.contains("over_email_send_rate_limit") || text.contains("rate limit") || text.contains("too many requests") {
            return rateLimit
        }
        if creatingAccount {
            return "We couldn't create the account. Check the email and try again."
        }
        return "That email and password didn't match."
    }

    static func recoveryMessage(for error: Error) -> String {
        let text = String(describing: error).lowercased()
        if text.contains("over_email_send_rate_limit") || text.contains("rate limit") || text.contains("too many requests") {
            return rateLimit
        }
        if text.contains("user not found") || text.contains("email not found") {
            return neutralRecovery
        }
        return "We couldn't send the email. Check the address and try again."
    }

    static let rateLimit = "Too many emails were sent. Wait a few minutes, then try once more."
    static let neutralRecovery = "If an account exists for that email, we sent a link. Open it on this iPhone."
    static let expiredLink = "That link has expired or was already used. Request a new one."
}
