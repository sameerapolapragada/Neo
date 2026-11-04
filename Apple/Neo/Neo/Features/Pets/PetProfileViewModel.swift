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

    private(set) var state: ProfileScreenState = .loading
    private(set) var photoURL: URL?
    var statsError: String?

    var momentCount: Int { board.momentCount }
    /// Moments on this pet whose category is Milestone.
    var milestoneCount: Int { board.milestoneCount }

    init(
        library: PetLibrary,
        moments: any MomentRepository,
        media: any MediaURLResolving,
        pets: any PetRepository,
        board: MomentBoard
    ) {
        self.library = library
        self.moments = moments
        self.media = media
        self.pets = pets
        self.board = board
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
