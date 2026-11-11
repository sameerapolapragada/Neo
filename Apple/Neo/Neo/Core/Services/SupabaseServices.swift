import Foundation
import Supabase

struct SupabaseAuthService: AuthServicing {
    let client: SupabaseClient

    func restoreSession() async throws -> UUID? {
        guard client.auth.currentSession != nil else { return nil }
        let session = try await client.auth.session
        return session.user.id
    }

    func signIn(email: String, password: String) async throws -> UUID {
        let session = try await client.auth.signIn(
            email: email.trimmingCharacters(in: .whitespacesAndNewlines),
            password: password
        )
        return session.user.id
    }

    func signUp(email: String, password: String) async throws -> SignUpResult {
        let response = try await client.auth.signUp(
            email: email.trimmingCharacters(in: .whitespacesAndNewlines),
            password: password,
            redirectTo: AuthCallback.url
        )
        switch response {
        case .session(let session):
            return SignUpResult(ownerId: session.user.id, needsEmailConfirmation: false)
        case .user:
            return SignUpResult(ownerId: nil, needsEmailConfirmation: true)
        }
    }

    func sendPasswordReset(email: String) async throws {
        try await client.auth.resetPasswordForEmail(
            email.trimmingCharacters(in: .whitespacesAndNewlines),
            redirectTo: AuthCallback.url
        )
    }

    func completeAuthCallback(_ url: URL) async throws -> UUID {
        let session = try await client.auth.session(from: url)
        return session.user.id
    }

    func updatePassword(_ password: String) async throws -> UUID {
        let user = try await client.auth.update(user: UserAttributes(password: password))
        return user.id
    }

    func signOut() async throws {
        do {
            try await client.auth.signOut()
        } catch {
            // The global call did not revoke the server session. Clear the local
            // SDK session so the next launch does not restore it, then report the failure.
            // Tokens and signed URLs already issued can still work until they expire.
            try? await client.auth.signOut(scope: .local)
            throw error
        }
    }

    func currentEmail() async -> String? {
        if let email = client.auth.currentSession?.user.email, !email.isEmpty {
            return email
        }
        return try? await client.auth.session.user.email
    }
}

struct SupabasePetRepository: PetRepository {
    let client: SupabaseClient

    func list(ownerId: UUID) async throws -> [Pet] {
        do {
            let rows: [PetRow] = try await client
                .from(SupabaseTable.pets)
                .select()
                .eq("owner_id", value: ownerId.uuidString.lowercased())
                .order("created_at", ascending: false)
                .execute()
                .value
            return rows.map { $0.pet() }
        } catch {
            throw RepositoryErrorMapping.wrap(error)
        }
    }

    func pet(id: UUID, ownerId: UUID) async throws -> Pet {
        do {
            let row: PetRow = try await client
                .from(SupabaseTable.pets)
                .select()
                .eq("id", value: id.uuidString.lowercased())
                .eq("owner_id", value: ownerId.uuidString.lowercased())
                .single()
                .execute()
                .value
            return row.pet()
        } catch {
            throw RepositoryErrorMapping.wrap(error)
        }
    }

    func upsert(_ pet: Pet) async throws -> Pet {
        do {
            try MediaPathGuard.validate(pet.photoPath)
            if let photoPath = pet.photoPath,
               !MediaObjectPath.isProfilePhoto(photoPath, ownerId: pet.ownerId, petId: pet.id) {
                throw RepositoryError.invalidPhoto
            }
            let row = PetRow(pet)
            let saved: PetRow = try await client
                .from(SupabaseTable.pets)
                .upsert(row, onConflict: "id")
                .select()
                .single()
                .execute()
                .value
            return saved.pet()
        } catch {
            throw RepositoryErrorMapping.wrap(error)
        }
    }
}

struct SupabaseMomentRepository: MomentRepository {
    let client: SupabaseClient

    func list(petId: UUID, ownerId: UUID) async throws -> [PetMoment] {
        do {
            let rows = try await momentRows(petId: petId, ownerId: ownerId, category: nil, cursor: nil, limit: nil)
            return try await attachingMedia(to: rows, ownerId: ownerId)
        } catch {
            throw RepositoryErrorMapping.wrap(error)
        }
    }

    func moment(id: UUID, petId: UUID, ownerId: UUID) async throws -> PetMoment {
        do {
            let rows: [MomentRow] = try await client
                .from(SupabaseTable.moments)
                .select()
                .eq("id", value: id.uuidString.lowercased())
                .eq("owner_id", value: ownerId.uuidString.lowercased())
                .eq("pet_id", value: petId.uuidString.lowercased())
                .limit(1)
                .execute()
                .value
            guard let row = rows.first else { throw RepositoryError.notFound }
            let moments = try await attachingMedia(to: [row], ownerId: ownerId)
            guard let moment = moments.first else { throw RepositoryError.notFound }
            return moment
        } catch {
            throw RepositoryErrorMapping.wrap(error)
        }
    }

    func page(
        petId: UUID,
        ownerId: UUID,
        category: MomentCategory?,
        cursor: MomentCursor?,
        limit: Int
    ) async throws -> MomentPage {
        do {
            let rows = try await momentRows(
                petId: petId,
                ownerId: ownerId,
                category: category,
                cursor: cursor,
                limit: limit
            )
            let moments = try await attachingMedia(to: rows, ownerId: ownerId)
            let next = moments.count == limit ? moments.last.map { MomentFeedSorting.makeCursor(for: $0) } : nil
            return MomentPage(moments: moments, nextCursor: next)
        } catch {
            throw RepositoryErrorMapping.wrap(error)
        }
    }

    func upsert(_ moment: PetMoment) async throws -> PetMoment {
        do {
            for item in moment.media {
                guard item.momentId == moment.id, item.ownerId == moment.ownerId else {
                    throw RepositoryError.invalidPhoto
                }
                try MediaPathGuard.validate(item.storagePath)
                guard MediaObjectPath.isMomentPhoto(
                    item.storagePath,
                    ownerId: moment.ownerId,
                    petId: moment.petId,
                    momentId: moment.id
                ) else {
                    throw RepositoryError.invalidPhoto
                }
            }
            let saved: MomentRow = try await client
                .from(SupabaseTable.moments)
                .upsert(MomentRow(moment), onConflict: "id")
                .select()
                .single()
                .execute()
                .value
            do {
                try await replaceMedia(moment.media, momentId: moment.id, ownerId: moment.ownerId)
            } catch {
                try? await abandonEmptyMoment(id: moment.id)
                throw error
            }
            return saved.moment(media: moment.media.inDisplayOrder())
        } catch {
            throw RepositoryErrorMapping.wrap(error)
        }
    }

    func setFavorite(id: UUID, petId: UUID, ownerId: UUID, isFavorite: Bool) async throws -> PetMoment {
        do {
            let rows: [MomentRow] = try await client
                .from(SupabaseTable.moments)
                .update(MomentFavoriteUpdate(isFavorite: isFavorite))
                .eq("id", value: id.uuidString.lowercased())
                .eq("owner_id", value: ownerId.uuidString.lowercased())
                .eq("pet_id", value: petId.uuidString.lowercased())
                .select()
                .execute()
                .value
            guard let row = rows.first else { throw RepositoryError.notFound }
            let moments = try await attachingMedia(to: [row], ownerId: ownerId)
            guard let moment = moments.first else { throw RepositoryError.notFound }
            return moment
        } catch {
            throw RepositoryErrorMapping.wrap(error)
        }
    }

    func delete(id: UUID, ownerId: UUID) async throws {
        _ = ownerId
        do {
            try await abandonEmptyMoment(id: id)
        } catch {
            throw RepositoryErrorMapping.wrap(error)
        }
    }

    private func momentRows(
        petId: UUID,
        ownerId: UUID,
        category: MomentCategory?,
        cursor: MomentCursor?,
        limit: Int?
    ) async throws -> [MomentRow] {
        let owner = ownerId.uuidString.lowercased()
        let pet = petId.uuidString.lowercased()
        var filter = client
            .from(SupabaseTable.moments)
            .select()
            .eq("owner_id", value: owner)
            .eq("pet_id", value: pet)
        if let category {
            filter = filter.eq("category", value: category.rawValue)
        }
        if let cursor {
            filter = filter.or(Self.olderThan(cursor))
        }
        var query = filter
            .order("moment_date", ascending: false)
            .order("created_at", ascending: false)
            .order("id", ascending: false)
        if let limit {
            query = query.limit(limit)
        }
        return try await query.execute().value
    }

    private func attachingMedia(to rows: [MomentRow], ownerId: UUID) async throws -> [PetMoment] {
        let ids = rows.map { $0.id.uuidString.lowercased() }
        let mediaRows: [MomentMediaRow]
        if ids.isEmpty {
            mediaRows = []
        } else {
            mediaRows = try await client
                .from(SupabaseTable.momentMedia)
                .select()
                .eq("owner_id", value: ownerId.uuidString.lowercased())
                .in("moment_id", values: ids)
                .order("sort_order", ascending: true)
                .execute()
                .value
        }
        let grouped = Dictionary(grouping: mediaRows, by: \.momentId)
        return rows.map { row in
            let media = (grouped[row.id] ?? []).map { $0.media() }
            return row.moment(media: media)
        }
    }

    private func replaceMedia(_ media: [MomentMedia], momentId: UUID, ownerId: UUID) async throws {
        for item in media where item.ownerId != ownerId || item.momentId != momentId {
            throw RepositoryError.invalidPhoto
        }
        let params = ReplaceMomentMediaParams(momentId: momentId, media: media.map(MomentMediaRow.init))
        let _: ReplaceMomentMediaResult = try await client
            .rpc("companion_replace_moment_media", params: params)
            .execute()
            .value
    }

    private func abandonEmptyMoment(id: UUID) async throws {
        try await client
            .rpc("companion_abandon_empty_moment", params: AbandonEmptyMomentParams(momentId: id))
            .execute()
    }

    private static func olderThan(_ cursor: MomentCursor) -> String {
        let momentDate = quoted(SupabaseDates.calendarDay(cursor.momentDate))
        let createdAt = quoted(SupabaseDates.timestamp(cursor.createdAt))
        let id = cursor.id.uuidString.lowercased()
        return [
            "moment_date.lt.\(momentDate)",
            "and(moment_date.eq.\(momentDate),created_at.lt.\(createdAt))",
            "and(moment_date.eq.\(momentDate),created_at.eq.\(createdAt),id.lt.\(id))"
        ].joined(separator: ",")
    }

    private static func quoted(_ value: String) -> String {
        "\"\(value)\""
    }
}

struct SupabaseMemoryRepository: MemoryRepository {
    let client: SupabaseClient

    func list(petId: UUID, ownerId: UUID) async throws -> [Memory] {
        do {
            let rows: [MemoryRow] = try await client
                .from(SupabaseTable.memories)
                .select()
                .eq("owner_id", value: ownerId.uuidString.lowercased())
                .eq("pet_id", value: petId.uuidString.lowercased())
                .order("occurred_at", ascending: false)
                .execute()
                .value
            return rows.map { $0.memory() }
        } catch {
            throw RepositoryErrorMapping.wrap(error)
        }
    }

    func upsert(_ memory: Memory) async throws -> Memory {
        do {
            try MediaPathGuard.validate(memory.photoPath)
            let saved: MemoryRow = try await client
                .from(SupabaseTable.memories)
                .upsert(MemoryRow(memory))
                .select()
                .single()
                .execute()
                .value
            return saved.memory()
        } catch {
            throw RepositoryErrorMapping.wrap(error)
        }
    }

    func delete(id: UUID, ownerId: UUID) async throws {
        do {
            try await client
                .from(SupabaseTable.memories)
                .delete()
                .eq("id", value: id.uuidString.lowercased())
                .eq("owner_id", value: ownerId.uuidString.lowercased())
                .execute()
        } catch {
            throw RepositoryErrorMapping.wrap(error)
        }
    }
}

struct SupabaseMediaStore: MediaUploading, MediaSigning {
    let client: SupabaseClient

    func uploadJPEG(_ data: Data, ownerId: UUID, petId: UUID) async throws -> String {
        try MomentUploadRules.validateJPEG(data)
        let path = MediaObjectPath.jpeg(ownerId: ownerId, petId: petId)
        try await upload(data, path: path)
        return path
    }

    func uploadMomentJPEG(_ data: Data, ownerId: UUID, petId: UUID, momentId: UUID) async throws -> String {
        try MomentUploadRules.validateJPEG(data)
        let path = MediaObjectPath.momentJPEG(ownerId: ownerId, petId: petId, momentId: momentId)
        try await upload(data, path: path)
        return path
    }

    func deleteUploadedObject(_ path: String, ownerId: UUID) async throws {
        guard MediaObjectPath.belongsToOwner(path, ownerId: ownerId) else {
            throw RepositoryError.invalidPhoto
        }
        do {
            _ = try await client.storage
                .from(SupabaseTable.mediaBucket)
                .remove(paths: [path])
        } catch {
            throw RepositoryErrorMapping.wrap(error)
        }
    }

    private func upload(_ data: Data, path: String) async throws {
        do {
            _ = try await client.storage
                .from(SupabaseTable.mediaBucket)
                .upload(
                    path,
                    data: data,
                    options: FileOptions(contentType: "image/jpeg")
                )
        } catch {
            throw RepositoryErrorMapping.wrap(error)
        }
    }

    func signedURL(for path: String, expiresIn: Int) async throws -> URL {
        guard MediaObjectPath.isCanonical(path), !MediaObjectPath.isPublicObjectURL(path) else {
            throw RepositoryError.invalidPhoto
        }
        do {
            let url = try await client.storage
                .from(SupabaseTable.mediaBucket)
                .createSignedURL(path: path, expiresIn: expiresIn)
            guard !MediaObjectPath.isPublicObjectURL(url.absoluteString) else {
                throw RepositoryError.invalidPhoto
            }
            return url
        } catch let error as RepositoryError {
            throw error
        } catch {
            throw RepositoryErrorMapping.wrap(error)
        }
    }
}
