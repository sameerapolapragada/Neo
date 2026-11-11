import Foundation

enum AuthCallback {
    static let scheme = "com.neo.petcompanion"
    static let url = URL(string: "com.neo.petcompanion://auth/callback")!
    static let pendingRecoveryKey = "neo.pendingPasswordRecovery"

    static func matches(_ url: URL) -> Bool {
        url.scheme?.caseInsensitiveCompare(scheme) == .orderedSame
    }

    static func isRecovery(_ url: URL) -> Bool {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        if components?.queryItems?.contains(where: { $0.name == "type" && $0.value == "recovery" }) == true {
            return true
        }
        guard let fragment = components?.fragment else { return false }
        return fragment.split(separator: "&").contains { item in
            let parts = item.split(separator: "=", maxSplits: 1)
            return parts.count == 2 && parts[0] == "type" && parts[1] == "recovery"
        }
    }
}
