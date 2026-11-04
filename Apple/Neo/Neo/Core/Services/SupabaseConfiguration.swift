import Foundation

enum SupabaseKeyGuard {
    enum Failure: Error, Equatable {
        case empty
        case serviceRole
    }

    /// The app may use the anon or publishable key only. A service-role key bypasses RLS.
    static func validate(_ key: String) throws {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            throw Failure.empty
        }
        if trimmed.hasPrefix("sb_secret") || role(from: trimmed) == "service_role" {
            throw Failure.serviceRole
        }
    }

    static func role(from jwt: String) -> String? {
        let parts = jwt.split(separator: ".")
        guard parts.count >= 2 else { return nil }
        guard let data = base64URLDecode(String(parts[1])) else { return nil }
        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let role = json["role"] as? String
        else {
            return nil
        }
        return role
    }

    private static func base64URLDecode(_ value: String) -> Data? {
        var text = value.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        let remainder = text.count % 4
        if remainder > 0 {
            text += String(repeating: "=", count: 4 - remainder)
        }
        return Data(base64Encoded: text)
    }
}

struct SupabaseConfiguration: Equatable, Sendable {
    var url: URL
    var anonKey: String
}

enum SupabaseConfigurationState: Equatable, Sendable {
    case ready(SupabaseConfiguration)
    case missing
    case rejectedServiceRole
}

enum SupabaseConfigurationLoader {
    static func load(bundle: Bundle = .main) -> SupabaseConfigurationState {
        let urlString = bundle.object(forInfoDictionaryKey: "SUPABASE_URL") as? String ?? ""
        let anonKey = bundle.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String ?? ""
        return resolve(urlString: urlString, anonKey: anonKey)
    }

    static func resolve(urlString: String, anonKey: String) -> SupabaseConfigurationState {
        let urlString = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        let anonKey = anonKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if urlString.isEmpty || urlString.contains("$(") || anonKey.isEmpty || anonKey.contains("$(") {
            return .missing
        }
        guard let url = URL(string: urlString), url.scheme == "https", url.host != nil else {
            return .missing
        }
        do {
            try SupabaseKeyGuard.validate(anonKey)
        } catch SupabaseKeyGuard.Failure.serviceRole {
            return .rejectedServiceRole
        } catch {
            return .missing
        }
        return .ready(SupabaseConfiguration(url: url, anonKey: anonKey))
    }
}
