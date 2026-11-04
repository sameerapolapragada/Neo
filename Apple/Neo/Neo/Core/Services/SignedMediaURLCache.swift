import Foundation

actor SignedMediaURLCache: MediaURLResolving {
    private let signer: any MediaSigning
    private var cache: [String: Entry] = [:]

    init(signer: any MediaSigning) {
        self.signer = signer
    }

    func displayURL(for path: String?) async -> URL? {
        guard let path, MediaPath.isObjectPath(path) else { return nil }
        if let entry = cache[path], entry.expiresAt.timeIntervalSinceNow > TimeInterval(MediaPolicy.refreshLeewaySeconds) {
            return entry.url
        }
        do {
            let url = try await signer.signedURL(for: path, expiresIn: MediaPolicy.signedURLLifetimeSeconds)
            let expiresAt = Date().addingTimeInterval(TimeInterval(MediaPolicy.signedURLLifetimeSeconds))
            cache[path] = Entry(url: url, expiresAt: expiresAt)
            return url
        } catch {
            NeoLog.data.error("Signed URL failed: \(String(describing: error), privacy: .private)")
            return nil
        }
    }

    func clear() {
        cache = [:]
    }

    private struct Entry {
        var url: URL
        var expiresAt: Date
    }
}
