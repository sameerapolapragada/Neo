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
        if creatingAccount {
            return "We couldn't create the account. Check the email and try again."
        }
        return "That email and password didn't match."
    }
}
