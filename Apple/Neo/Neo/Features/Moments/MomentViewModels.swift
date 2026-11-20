import Foundation
import Observation
import UIKit

enum MomentsPresentation: Equatable {
    case noPet
    case loading
    case empty
    case filteredEmpty
    case failed
    case loaded
}

@MainActor
@Observable
final class PetMomentsViewModel {
    static let defaultPageSize = 20

    private let repository: any MomentRepository
    private let media: any MediaURLResolving
    private let pageSize: Int
    private let board: MomentBoard?

    private(set) var moments: [PetMoment] = []
    private(set) var coverURLs: [UUID: URL] = [:]
    private(set) var filter: MomentCategoryFilter = .all
    private(set) var isLoading = false
    private(set) var isLoadingMore = false
    private(set) var canLoadMore = false
    private(set) var didLoad = false
    var loadError: String?
    var favoriteError: String?

    private var nextCursor: MomentCursor?
    private var loadGeneration = 0
    private var favoriteIDs: Set<UUID> = []
    private var loadedPetID: UUID?
    private var loadedOwnerID: UUID?
    private var appliedDeltaID = 0

    init(
        repository: any MomentRepository,
        media: any MediaURLResolving,
        pageSize: Int = PetMomentsViewModel.defaultPageSize,
        board: MomentBoard? = nil
    ) {
        self.repository = repository
        self.media = media
        self.pageSize = pageSize
        self.board = board
    }

    func coverURL(for id: UUID) -> URL? {
        coverURLs[id]
    }

    func presentation(for pet: Pet?) -> MomentsPresentation {
        guard pet != nil else { return .noPet }
        if isLoading && moments.isEmpty { return .loading }
        if !didLoad && moments.isEmpty && loadError == nil { return .loading }
        if loadError != nil && moments.isEmpty { return .failed }
        if moments.isEmpty && filter == .all { return .empty }
        if moments.isEmpty { return .filteredEmpty }
        return .loaded
    }

    func load(pet: Pet?) async {
        loadGeneration += 1
        let generation = loadGeneration
        guard let pet else {
            clear()
            return
        }
        if loadedPetID != pet.id {
            moments = []
            coverURLs = [:]
            nextCursor = nil
            canLoadMore = false
        }
        loadedPetID = pet.id
        loadedOwnerID = pet.ownerId
        board?.activate(petId: pet.id, ownerId: pet.ownerId)
        isLoading = moments.isEmpty
        let deltaFloor = board?.latestDeltaID ?? appliedDeltaID
        defer {
            if generation == loadGeneration {
                isLoading = false
            }
        }
        do {
            let page = try await repository.page(
                petId: pet.id,
                ownerId: pet.ownerId,
                category: filter.category,
                cursor: nil,
                limit: pageSize
            )
            guard generation == loadGeneration else { return }
            moments = page.moments
            nextCursor = page.nextCursor
            canLoadMore = page.nextCursor != nil
            coverURLs = [:]
            appliedDeltaID = deltaFloor
            let additions = mergeBoard(after: deltaFloor)
            await resolveCovers(for: page.moments + additions)
            loadError = nil
            didLoad = true
        } catch {
            guard generation == loadGeneration else { return }
            loadError = error.localizedDescription
            didLoad = true
        }
    }

    func apply(_ filter: MomentCategoryFilter, pet: Pet?) async {
        guard filter != self.filter else { return }
        self.filter = filter
        moments = []
        coverURLs = [:]
        nextCursor = nil
        canLoadMore = false
        didLoad = false
        loadError = nil
        await load(pet: pet)
    }

    func loadMore() async {
        guard
            canLoadMore,
            !isLoading,
            !isLoadingMore,
            let cursor = nextCursor,
            let petId = loadedPetID,
            let ownerId = loadedOwnerID
        else { return }
        let generation = loadGeneration
        isLoadingMore = true
        defer {
            if generation == loadGeneration {
                isLoadingMore = false
            }
        }
        do {
            let page = try await repository.page(
                petId: petId,
                ownerId: ownerId,
                category: filter.category,
                cursor: cursor,
                limit: pageSize
            )
            guard generation == loadGeneration else { return }
            let existing = Set(moments.map(\.id))
            let fresh = page.moments.filter { !existing.contains($0.id) }
            moments.append(contentsOf: fresh)
            nextCursor = page.nextCursor
            canLoadMore = page.nextCursor != nil
            await resolveCovers(for: fresh)
            loadError = nil
        } catch {
            guard generation == loadGeneration else { return }
            loadError = error.localizedDescription
        }
    }

    func toggleFavorite(_ moment: PetMoment) async {
        guard !favoriteIDs.contains(moment.id) else { return }
        guard loadedPetID == moment.petId, loadedOwnerID == moment.ownerId else { return }
        favoriteIDs.insert(moment.id)
        defer { favoriteIDs.remove(moment.id) }
        do {
            let saved = try await repository.setFavorite(
                id: moment.id,
                petId: moment.petId,
                ownerId: moment.ownerId,
                isFavorite: !moment.isFavorite
            )
            board?.noteSaved(saved)
            if let index = moments.firstIndex(where: { $0.id == saved.id }) {
                moments[index].isFavorite = saved.isFavorite
            }
            favoriteError = nil
        } catch {
            favoriteError = error.localizedDescription
        }
    }

    func applyBoard() async {
        guard let board else { return }
        if board.petId != loadedPetID || board.ownerId != loadedOwnerID {
            moments = []
            coverURLs = [:]
            nextCursor = nil
            canLoadMore = false
            return
        }
        let additions = mergeBoard(after: appliedDeltaID)
        if !additions.isEmpty {
            await resolveCovers(for: additions)
        }
    }

    private func matches(_ moment: PetMoment) -> Bool {
        guard let category = filter.category else { return true }
        return moment.category == category
    }

    @discardableResult
    private func mergeBoard(after floor: Int) -> [PetMoment] {
        guard let board else { return [] }
        var cursor = nextCursor
        let additions = MomentListSync.apply(
            moments: &moments,
            canLoadMore: canLoadMore,
            nextCursor: &cursor,
            matches: matches,
            deltas: board.deltas(after: floor)
        )
        nextCursor = cursor
        if let last = board.deltas(after: floor).last?.id {
            appliedDeltaID = last
        }
        return additions
    }

    private func clear() {
        moments = []
        coverURLs = [:]
        nextCursor = nil
        canLoadMore = false
        loadedPetID = nil
        loadedOwnerID = nil
        loadError = nil
        favoriteError = nil
        didLoad = false
        isLoading = false
    }

    private func resolveCovers(for moments: [PetMoment]) async {
        await withTaskGroup(of: (UUID, URL?).self) { group in
            for moment in moments {
                guard let path = moment.coverPath else { continue }
                group.addTask { [media] in
                    (moment.id, await media.displayURL(for: path))
                }
            }
            for await (id, url) in group {
                if let url {
                    coverURLs[id] = url
                }
            }
        }
    }
}

struct MomentPhotoDraft: Identifiable, Equatable, Sendable {
    let id: UUID
    var jpeg: Data?
    var existingPath: String?
    var existingMediaId: UUID?
    var previewURL: URL?
    var byteCount: Int?
    var width: Int?
    var height: Int?
}

@MainActor
@Observable
final class CreatePetMomentViewModel {
    let ownerId: UUID
    let petId: UUID
    let momentId: UUID
    let isEditing: Bool
    private let pets: any PetRepository
    private let moments: any MomentRepository
    private let uploader: any MediaUploading
    private let storageCleanup: (any StorageCleaning)?
    private let board: MomentBoard?
    private var pendingPhotoRemoval: [String] = []
    private let baselineDate: Date
    private let baselineTitle: String
    private let baselineCaption: String
    private let baselineCategory: MomentCategory
    private let baselinePhotoIDs: [UUID]
    private let preservedFavorite: Bool
    private let preservedCreatedAt: Date?
    private let originalPaths: [String]

    var title = ""
    var caption = ""
    var momentDate = Date()
    var category: MomentCategory = .daily
    private(set) var photos: [MomentPhotoDraft] = []
    var fieldErrors: [MomentField: String] = [:]
    var photoError: String?
    var saveError: String?
    private(set) var isSaving = false
    private(set) var didSave = false
    private(set) var uploadedCount = 0
    private(set) var uploadTotal = 0

    var canAddPhoto: Bool { photos.count < MomentValidation.maximumPhotos }

    var progressLabel: String? {
        guard isSaving, uploadTotal > 0 else { return nil }
        return "Uploading \(min(uploadedCount, uploadTotal)) of \(uploadTotal)"
    }

    var hasUnsavedChanges: Bool {
        if isEditing {
            return title != baselineTitle
                || caption != baselineCaption
                || category != baselineCategory
                || !Calendar.current.isDate(momentDate, inSameDayAs: baselineDate)
                || photos.map(\.id) != baselinePhotoIDs
                || photos.contains { $0.jpeg != nil }
        }
        return !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !photos.isEmpty
            || category != .daily
            || !Calendar.current.isDate(momentDate, inSameDayAs: baselineDate)
    }

    init(
        ownerId: UUID,
        petId: UUID,
        pets: any PetRepository,
        moments: any MomentRepository,
        uploader: any MediaUploading,
        storageCleanup: (any StorageCleaning)? = nil,
        board: MomentBoard? = nil,
        prefill: MomentDraftPrefill? = nil,
        now: Date = .now
    ) {
        self.ownerId = ownerId
        self.petId = petId
        self.momentId = UUID()
        self.isEditing = false
        self.pets = pets
        self.moments = moments
        self.uploader = uploader
        self.storageCleanup = storageCleanup
        self.board = board
        let suggestedTitle = prefill?.title ?? ""
        let suggestedCategory = prefill?.category ?? .daily
        self.baselineDate = now
        self.baselineTitle = suggestedTitle
        self.baselineCaption = ""
        self.baselineCategory = suggestedCategory
        self.baselinePhotoIDs = []
        self.preservedFavorite = false
        self.preservedCreatedAt = nil
        self.originalPaths = []
        self.title = suggestedTitle
        self.category = suggestedCategory
        self.momentDate = now
    }

    init(
        ownerId: UUID,
        petId: UUID,
        moment: PetMoment,
        photoURLs: [UUID: URL] = [:],
        pets: any PetRepository,
        moments: any MomentRepository,
        uploader: any MediaUploading,
        storageCleanup: (any StorageCleaning)? = nil,
        board: MomentBoard? = nil
    ) {
        self.ownerId = ownerId
        self.petId = petId
        self.momentId = moment.id
        self.isEditing = true
        self.pets = pets
        self.moments = moments
        self.uploader = uploader
        self.storageCleanup = storageCleanup
        self.board = board
        self.baselineDate = moment.momentDate
        self.baselineTitle = moment.title
        self.baselineCaption = moment.caption
        self.baselineCategory = moment.category
        self.preservedFavorite = moment.isFavorite
        self.preservedCreatedAt = moment.createdAt
        let ordered = moment.media.inDisplayOrder()
        self.originalPaths = ordered.map(\.storagePath)
        self.baselinePhotoIDs = ordered.map(\.id)
        self.title = moment.title
        self.caption = moment.caption
        self.momentDate = moment.momentDate
        self.category = moment.category
        self.photos = ordered.map { item in
            MomentPhotoDraft(
                id: item.id,
                jpeg: nil,
                existingPath: item.storagePath,
                existingMediaId: item.id,
                previewURL: photoURLs[item.id],
                byteCount: item.byteCount,
                width: item.width,
                height: item.height
            )
        }
    }

    func preparePhotos(_ batches: [Data]) {
        for data in batches {
            guard photos.count < MomentValidation.maximumPhotos else {
                photoError = "You can add up to \(MomentValidation.maximumPhotos) photos."
                return
            }
            switch ProfilePhotoValidation.jpeg(from: data) {
            case .success(let jpeg):
                photoError = addJPEG(jpeg)
            case .failure(let issue):
                photoError = issue.message
            }
        }
    }

    @discardableResult
    func addJPEG(_ data: Data) -> String? {
        guard photos.count < MomentValidation.maximumPhotos else {
            let message = "You can add up to \(MomentValidation.maximumPhotos) photos."
            photoError = message
            return message
        }
        do {
            try MomentUploadRules.validateJPEG(data)
        } catch {
            let message = RepositoryError.invalidPhoto.localizedDescription
            photoError = message
            return message
        }
        photos.append(MomentPhotoDraft(id: UUID(), jpeg: data))
        photoError = nil
        fieldErrors[.photos] = nil
        return nil
    }

    func removePhoto(id: UUID) {
        photos.removeAll { $0.id == id }
    }

    func movePhoto(from index: Int, to destination: Int) {
        guard photos.indices.contains(index), photos.indices.contains(destination), index != destination else { return }
        let photo = photos.remove(at: index)
        photos.insert(photo, at: destination)
    }

    func save() async {
        guard !isSaving, !didSave else { return }
        let errors = MomentValidation.errors(
            title: title,
            caption: caption,
            photoCount: photos.count
        )
        fieldErrors = errors
        guard errors.isEmpty else { return }

        isSaving = true
        uploadedCount = 0
        uploadTotal = photos.filter { $0.jpeg != nil }.count
        defer {
            isSaving = false
            uploadedCount = 0
            uploadTotal = 0
        }

        do {
            _ = try await pets.pet(id: petId, ownerId: ownerId)
        } catch {
            saveError = "That pet isn't on this account."
            return
        }

        var uploaded: [String] = []
        do {
            let resolved = try await resolvedPaths(recordingNewUploads: &uploaded)
            let saved = try await moments.upsert(makeMoment(paths: resolved))
            board?.activate(petId: petId, ownerId: ownerId)
            board?.noteSaved(saved)
            adopt(resolved)
            let kept = Set(resolved)
            pendingPhotoRemoval.append(contentsOf: originalPaths.filter { !kept.contains($0) })
            let failed = await finishPhotoCleanup(protected: kept)
            if failed.isEmpty {
                saveError = nil
                didSave = true
            } else {
                saveError = "This memory is saved. A previous photo could not be removed. Save again to retry."
                didSave = false
            }
        } catch {
            await recover(uploaded: uploaded)
            saveError = error.localizedDescription
        }
    }

    private func adopt(_ paths: [String]) {
        for index in photos.indices where index < paths.count {
            photos[index].existingPath = paths[index]
            photos[index].jpeg = nil
        }
    }

    private func finishPhotoCleanup(protected: Set<String>) async -> [String] {
        let unique = Array(Set(pendingPhotoRemoval)).filter { !protected.contains($0) }
        let failed = await OwnedObjectCleanup.removeReportingFailures(unique, ownerId: ownerId, uploader: uploader)
        pendingPhotoRemoval = failed
        if let storageCleanup, !unique.isEmpty {
            try? await storageCleanup.cleanupOwnedStorage(paths: failed.isEmpty ? unique : failed)
        }
        return failed
    }

    private func resolvedPaths(recordingNewUploads uploaded: inout [String]) async throws -> [String] {
        var resolved: [String] = []
        for photo in photos {
            if let jpeg = photo.jpeg {
                uploadedCount += 1
                let path = try await uploader.uploadMomentJPEG(
                    jpeg,
                    ownerId: ownerId,
                    petId: petId,
                    momentId: momentId
                )
                guard MediaObjectPath.isMomentPhoto(path, ownerId: ownerId, petId: petId, momentId: momentId) else {
                    if MediaObjectPath.belongsToOwner(path, ownerId: ownerId) {
                        uploaded.append(path)
                    }
                    throw RepositoryError.invalidPhoto
                }
                uploaded.append(path)
                resolved.append(path)
            } else if let path = photo.existingPath,
                      MediaObjectPath.isMomentPhoto(path, ownerId: ownerId, petId: petId, momentId: momentId) {
                resolved.append(path)
            } else {
                throw RepositoryError.invalidPhoto
            }
        }
        return resolved
    }

    private func makeMoment(paths: [String]) -> PetMoment {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCaption = caption.trimmingCharacters(in: .whitespacesAndNewlines)
        let now = Date()
        let media = paths.enumerated().map { index, path in
            let photo = photos[index]
            let image = photo.jpeg.flatMap { UIImage(data: $0) }
            return MomentMedia(
                id: photo.existingMediaId ?? UUID(),
                momentId: momentId,
                ownerId: ownerId,
                storagePath: path,
                sortOrder: index,
                contentType: "image/jpeg",
                byteCount: photo.jpeg?.count ?? photo.byteCount,
                width: image.map { Int(($0.size.width * $0.scale).rounded()) } ?? photo.width,
                height: image.map { Int(($0.size.height * $0.scale).rounded()) } ?? photo.height
            )
        }
        return PetMoment(
            id: momentId,
            ownerId: ownerId,
            petId: petId,
            title: trimmedTitle,
            caption: trimmedCaption,
            category: category,
            momentDate: momentDate,
            isFavorite: preservedFavorite,
            media: media,
            createdAt: preservedCreatedAt ?? now,
            updatedAt: now
        )
    }

    private func recover(uploaded paths: [String]) async {
        let failed = await OwnedObjectCleanup.removeReportingFailures(paths, ownerId: ownerId, uploader: uploader)
        if !failed.isEmpty {
            pendingPhotoRemoval = failed
            if let storageCleanup {
                try? await storageCleanup.cleanupOwnedStorage(paths: failed)
            }
        }
        if !isEditing {
            try? await moments.delete(id: momentId, ownerId: ownerId)
        }
    }
}
