import Foundation
import Observation

enum TimelinePresentation: Equatable {
    case noPet
    case loading
    case empty
    case failed
    case loaded
}

@MainActor
@Observable
final class MemoryTimelineViewModel {
    static let defaultPageSize = 20

    private let repository: any MomentRepository
    private let media: any MediaURLResolving
    private let pageSize: Int
    private let calendar: Calendar
    private let board: MomentBoard?

    private(set) var years: [TimelineYear] = []
    private(set) var moments: [PetMoment] = []
    private(set) var coverURLs: [UUID: URL] = [:]
    private(set) var isLoading = false
    private(set) var isLoadingMore = false
    private(set) var canLoadMore = false
    private(set) var didLoad = false
    var loadError: String?

    private var nextCursor: MomentCursor?
    private var loadGeneration = 0
    private var loadedPetID: UUID?
    private var loadedOwnerID: UUID?
    private var appliedDeltaID = 0

    init(
        repository: any MomentRepository,
        media: any MediaURLResolving,
        pageSize: Int = MemoryTimelineViewModel.defaultPageSize,
        calendar: Calendar = .current,
        board: MomentBoard? = nil
    ) {
        self.repository = repository
        self.media = media
        self.pageSize = pageSize
        self.calendar = calendar
        self.board = board
    }

    func presentation(for pet: Pet?) -> TimelinePresentation {
        guard pet != nil else { return .noPet }
        if isLoading && moments.isEmpty { return .loading }
        if !didLoad && moments.isEmpty && loadError == nil { return .loading }
        if loadError != nil && moments.isEmpty { return .failed }
        if moments.isEmpty { return .empty }
        return .loaded
    }

    func coverURL(for id: UUID) -> URL? {
        coverURLs[id]
    }

    func applyBoard() async {
        guard let board else { return }
        if board.petId != loadedPetID || board.ownerId != loadedOwnerID {
            moments = []
            years = []
            coverURLs = [:]
            nextCursor = nil
            canLoadMore = false
            return
        }
        let additions = mergeBoard(after: appliedDeltaID)
        years = TimelineGrouping.years(from: moments, calendar: calendar)
        if !additions.isEmpty {
            await resolveCovers(for: additions, replacing: false)
        }
    }

    @discardableResult
    private func mergeBoard(after floor: Int) -> [PetMoment] {
        guard let board else { return [] }
        var cursor = nextCursor
        let additions = MomentListSync.apply(
            moments: &moments,
            canLoadMore: canLoadMore,
            nextCursor: &cursor,
            matches: { _ in true },
            deltas: board.deltas(after: floor)
        )
        nextCursor = cursor
        if let last = board.deltas(after: floor).last?.id {
            appliedDeltaID = last
        }
        return additions
    }

    func dateLabel(for moment: PetMoment) -> String {
        TimelineDateFormatting.fullDate(moment.momentDate, calendar: calendar)
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
            years = []
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
                category: nil,
                cursor: nil,
                limit: pageSize
            )
            guard generation == loadGeneration else { return }
            moments = page.moments
            nextCursor = page.nextCursor
            canLoadMore = page.nextCursor != nil
            appliedDeltaID = deltaFloor
            let additions = mergeBoard(after: deltaFloor)
            years = TimelineGrouping.years(from: moments, calendar: calendar)
            await resolveCovers(for: page.moments + additions, replacing: true)
            loadError = nil
            didLoad = true
        } catch {
            guard generation == loadGeneration else { return }
            if moments.isEmpty {
                years = []
            }
            loadError = error.localizedDescription
            didLoad = true
        }
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
                category: nil,
                cursor: cursor,
                limit: pageSize
            )
            guard generation == loadGeneration else { return }
            let existing = Set(moments.map(\.id))
            let fresh = page.moments.filter { !existing.contains($0.id) }
            moments.append(contentsOf: fresh)
            nextCursor = page.nextCursor
            canLoadMore = page.nextCursor != nil
            years = TimelineGrouping.years(from: moments, calendar: calendar)
            await resolveCovers(for: fresh, replacing: false)
            loadError = nil
        } catch {
            guard generation == loadGeneration else { return }
            loadError = error.localizedDescription
        }
    }

    private func clear() {
        moments = []
        years = []
        coverURLs = [:]
        nextCursor = nil
        canLoadMore = false
        loadedPetID = nil
        loadedOwnerID = nil
        loadError = nil
        didLoad = false
        isLoading = false
        isLoadingMore = false
    }

    private func resolveCovers(for moments: [PetMoment], replacing: Bool) async {
        if replacing {
            coverURLs = [:]
        }
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

@MainActor
@Observable
final class ScrapbookMemoryDetailViewModel {
    private let repository: any MemoryRepository
    private let media: any MediaURLResolving
    let petId: UUID
    let ownerId: UUID

    private(set) var chronological: [Memory] = []
    private(set) var memory: Memory?
    private(set) var photoURL: URL?
    var loadError: String?
    var didDelete = false

    init(memoryId: UUID, petId: UUID, ownerId: UUID, repository: any MemoryRepository, media: any MediaURLResolving) {
        self.petId = petId
        self.ownerId = ownerId
        self.repository = repository
        self.media = media
        self.focusedId = memoryId
    }

    private var focusedId: UUID

    var positionLabel: String? {
        guard let index = chronological.firstIndex(where: { $0.id == focusedId }) else { return nil }
        return "\(index + 1) of \(chronological.count)"
    }

    var hasPrevious: Bool {
        guard let index = chronological.firstIndex(where: { $0.id == focusedId }) else { return false }
        return index > 0
    }

    var hasNext: Bool {
        guard let index = chronological.firstIndex(where: { $0.id == focusedId }) else { return false }
        return index < chronological.count - 1
    }

    func load() async {
        do {
            let loaded = try await repository.list(petId: petId, ownerId: ownerId)
            chronological = loaded.sorted { $0.occurredAt < $1.occurredAt }
            memory = chronological.first { $0.id == focusedId }
            photoURL = await media.displayURL(for: memory?.photoPath)
            loadError = memory == nil ? RepositoryError.notFound.localizedDescription : nil
        } catch {
            loadError = error.localizedDescription
        }
    }

    func showPrevious() {
        guard let index = chronological.firstIndex(where: { $0.id == focusedId }), index > 0 else { return }
        focus(chronological[index - 1])
    }

    func showNext() {
        guard let index = chronological.firstIndex(where: { $0.id == focusedId }), index < chronological.count - 1 else { return }
        focus(chronological[index + 1])
    }

    func delete() async {
        guard let memory else { return }
        do {
            try await repository.delete(id: memory.id, ownerId: ownerId)
            didDelete = true
        } catch {
            loadError = error.localizedDescription
        }
    }

    private func focus(_ memory: Memory) {
        focusedId = memory.id
        self.memory = memory
        Task { photoURL = await media.displayURL(for: memory.photoPath) }
    }
}

@MainActor
@Observable
final class CreateMemoryViewModel {
    let ownerId: UUID
    let petId: UUID
    private let repository: any MemoryRepository
    private let uploader: any MediaUploading
    private let memoryId: UUID
    private let existingCreatedAt: Date?

    var title = ""
    var notes = ""
    var category: MemoryCategory = .memory
    var sentiment: MemorySentiment?
    var occurredAt = Date()
    var photoJPEG: Data?
    var existingPhotoPath: String?
    var fieldErrors: [MemoryField: String] = [:]
    var saveError: String?
    var isSaving = false
    var didSave = false

    var isEditing: Bool { existingCreatedAt != nil }

    init(
        ownerId: UUID,
        petId: UUID,
        memory: Memory? = nil,
        repository: any MemoryRepository,
        uploader: any MediaUploading
    ) {
        self.ownerId = ownerId
        self.petId = petId
        self.repository = repository
        self.uploader = uploader
        self.memoryId = memory?.id ?? UUID()
        self.existingCreatedAt = memory?.createdAt
        if let memory {
            title = memory.title
            notes = memory.notes
            category = memory.category
            sentiment = memory.sentiment
            occurredAt = memory.occurredAt
            existingPhotoPath = memory.photoPath
        }
    }

    func save() async {
        let errors = MemoryValidation.errors(title: title, notes: notes)
        fieldErrors = errors
        guard errors.isEmpty else { return }
        isSaving = true
        defer { isSaving = false }
        do {
            var path = existingPhotoPath
            if let photoJPEG {
                path = try await uploader.uploadJPEG(photoJPEG, ownerId: ownerId, petId: petId)
            }
            let now = Date()
            let memory = Memory(
                id: memoryId,
                ownerId: ownerId,
                petId: petId,
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
                category: category,
                sentiment: sentiment,
                photoPath: path,
                occurredAt: occurredAt,
                createdAt: existingCreatedAt ?? now,
                updatedAt: now
            )
            _ = try await repository.upsert(memory)
            saveError = nil
            didSave = true
        } catch {
            saveError = error.localizedDescription
        }
    }
}
