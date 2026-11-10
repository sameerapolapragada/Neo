import Foundation

protocol MediaClock: Sendable {
    func now() -> Date
}

struct SystemMediaClock: MediaClock {
    func now() -> Date { Date() }
}

actor SignedMediaURLCache: MediaURLResolving {
    private let signer: any MediaSigning
    private let clock: any MediaClock
    private var accountId: UUID?
    private var cache: [String: Entry] = [:]

    init(signer: any MediaSigning, clock: any MediaClock = SystemMediaClock()) {
        self.signer = signer
        self.clock = clock
    }

    /// Binds this cache to the signed-in account. A different account drops the previous URLs.
    func bind(ownerId: UUID) {
        guard accountId != ownerId else { return }
        cache = [:]
        accountId = ownerId
    }

    /// Drops this device's cached URLs. A URL already issued remains valid until it expires.
    func clear() {
        cache = [:]
        accountId = nil
    }

    func displayURL(for path: String?) async -> URL? {
        guard let accountId, let path else { return nil }
        guard !MediaObjectPath.isPublicObjectURL(path) else { return nil }
        guard MediaObjectPath.belongsToOwner(path, ownerId: accountId) else { return nil }
        let key = "\(accountId.uuidString.lowercased())|\(path)"
        if let entry = cache[key], entry.expiresAt.timeIntervalSince(clock.now()) > TimeInterval(MediaPolicy.refreshLeewaySeconds) {
            return entry.url
        }
        do {
            let url = try await signer.signedURL(for: path, expiresIn: MediaPolicy.signedURLLifetimeSeconds)
            guard !MediaObjectPath.isPublicObjectURL(url.absoluteString) else { return nil }
            let expiresAt = clock.now().addingTimeInterval(TimeInterval(MediaPolicy.signedURLLifetimeSeconds))
            cache[key] = Entry(url: url, expiresAt: expiresAt)
            return url
        } catch {
            NeoLog.data.error("Signed URL failed: \(String(describing: error), privacy: .private)")
            return nil
        }
    }

    private struct Entry {
        var url: URL
        var expiresAt: Date
    }
}
