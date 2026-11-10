import Foundation
import Observation

enum ProfileScreenState: Equatable {
    case loading
    case empty
    case failed(String)
    case loaded
}

@MainActor
@Observable
final class PetProfileViewModel {
    private let library: PetLibrary
    private let moments: any MomentRepository
    private let media: any MediaURLResolving
    private let pets: any PetRepository
    private let board: MomentBoard
    private let petDeletion: (any PetDeleting)?

    private(set) var state: ProfileScreenState = .loading
    private(set) var photoURL: URL?
    private(set) var isDeleting = false
    private(set) var isConfirmingDelete = false
    var statsError: String?
    var deleteError: String?

    var momentCount: Int { board.momentCount }
    /// Moments on this pet whose category is Milestone.
    var milestoneCount: Int { board.milestoneCount }

    init(
        library: PetLibrary,
        moments: any MomentRepository,
        media: any MediaURLResolving,
        pets: any PetRepository,
        board: MomentBoard,
        petDeletion: (any PetDeleting)? = nil
    ) {
        self.library = library
        self.moments = moments
        self.media = media
        self.pets = pets
        self.board = board
        self.petDeletion = petDeletion
    }

    var selectedPet: Pet? { library.activePet }

    func load() async {
        if library.pets.isEmpty {
            state = .loading
        }
        await library.refresh()
        if library.pets.isEmpty {
            board.activate(petId: nil, ownerId: nil)
            photoURL = nil
            statsError = nil
            state = library.loadError.map(ProfileScreenState.failed) ?? .empty
            return
        }
        state = .loaded
        await loadDetails()
    }

    func retry() async {
        await load()
    }

    func select(_ pet: Pet) {
        library.select(pet)
    }

    func loadDetails() async {
        guard let pet = library.activePet else {
            board.activate(petId: nil, ownerId: nil)
            photoURL = nil
            return
        }
        let generation = board.beginLoad(petId: pet.id, ownerId: pet.ownerId)
        photoURL = await media.displayURL(for: pet.photoPath)
        do {
            let loadedMoments = try await moments.list(petId: pet.id, ownerId: pet.ownerId)
            guard library.activePet?.id == pet.id else { return }
            board.replaceFromServer(loadedMoments, petId: pet.id, ownerId: pet.ownerId, generation: generation)
            statsError = nil
        } catch {
            guard library.activePet?.id == pet.id else { return }
            statsError = error.localizedDescription
        }
    }

    func requestDelete() {
        guard library.activePet != nil, !isDeleting else { return }
        isConfirmingDelete = true
    }

    func cancelDelete() {
        isConfirmingDelete = false
    }

    func performDelete() async {
        guard let pet = library.activePet, !isDeleting else { return }
        isConfirmingDelete = false
        isDeleting = true
        defer { isDeleting = false }
        guard let petDeletion else {
            deleteError = CompanionDeletionError.unavailable.localizedDescription
            return
        }
        do {
            try await petDeletion.delete(petId: pet.id, ownerId: pet.ownerId)
            library.noteDeleted(pet.id)
            board.activate(petId: library.activePet?.id, ownerId: library.activePet?.ownerId)
            deleteError = nil
            if library.activePet == nil {
                photoURL = nil
                state = library.pets.isEmpty ? .empty : .loaded
            } else {
                await loadDetails()
            }
        } catch {
            deleteError = error.localizedDescription
        }
    }

    func toggleFavorite() async {
        guard var pet = library.activePet else { return }
        pet.isFavorite.toggle()
        pet.updatedAt = Date()
        do {
            let saved = try await pets.upsert(pet)
            library.noteSaved(saved)
            statsError = nil
        } catch {
            statsError = error.localizedDescription
        }
    }
}
