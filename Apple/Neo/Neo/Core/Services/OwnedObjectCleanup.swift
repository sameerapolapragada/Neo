import Foundation

enum OwnedObjectCleanup {
    /// Deletes owned objects. A missing object is already cleaned up.
    /// Two attempts keep a storage timeout from reporting success.
    static func remove(_ paths: [String], ownerId: UUID, uploader: any MediaUploading) async throws {
        let failed = await removeReportingFailures(paths, ownerId: ownerId, uploader: uploader)
        if failed.contains(where: { !MediaObjectPath.belongsToOwner($0, ownerId: ownerId) }) {
            throw RepositoryError.invalidPhoto
        }
        if !failed.isEmpty {
            throw RepositoryError.remote
        }
    }

    /// Paths that still need another attempt. An unowned path is returned unchanged.
    static func removeReportingFailures(
        _ paths: [String],
        ownerId: UUID,
        uploader: any MediaUploading
    ) async -> [String] {
        var pending = Array(Set(paths))
        for _ in 0..<2 where !pending.isEmpty {
            var failed: [String] = []
            for path in pending {
                guard MediaObjectPath.belongsToOwner(path, ownerId: ownerId) else {
                    failed.append(path)
                    continue
                }
                do {
                    try await uploader.deleteUploadedObject(path, ownerId: ownerId)
                } catch RepositoryError.notFound {
                } catch {
                    failed.append(path)
                }
            }
            pending = failed
        }
        return pending
    }
}
