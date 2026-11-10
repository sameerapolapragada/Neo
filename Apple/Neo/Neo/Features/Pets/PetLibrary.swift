import Foundation
import Observation

@MainActor
@Observable
final class PetLibrary {
    private let repository: any PetRepository
    private let selection: any ActivePetStoring
    let ownerId: UUID

    private(set) var pets: [Pet] = []
    private(set) var activePetId: UUID?
    private(set) var isLoading = false
    var loadError: String?

    init(ownerId: UUID, repository: any PetRepository, selection: any ActivePetStoring) {
        self.ownerId = ownerId
        self.repository = repository
        self.selection = selection
        self.activePetId = selection.activePetId(for: ownerId)
    }

    var activePet: Pet? {
        if let activePetId, let pet = pets.first(where: { $0.id == activePetId }) {
            return pet
        }
        return pets.first
    }

    func refresh() async {
        isLoading = pets.isEmpty
        defer { isLoading = false }
        do {
            pets = try await repository.list(ownerId: ownerId)
            restoreSelection()
            loadError = nil
        } catch {
            loadError = error.localizedDescription
        }
    }

    func select(_ pet: Pet) {
        guard pet.ownerId == ownerId else { return }
        activePetId = pet.id
        selection.setActivePetId(pet.id, for: ownerId)
    }

    func noteDeleted(_ id: UUID) {
        pets.removeAll { $0.id == id }
        if activePetId == id {
            restoreSelection()
        }
    }

    func noteSaved(_ pet: Pet) {
        guard pet.ownerId == ownerId else { return }
        if let index = pets.firstIndex(where: { $0.id == pet.id }) {
            pets[index] = pet
        } else {
            pets.insert(pet, at: 0)
        }
        select(pet)
    }

    private func restoreSelection() {
        if let activePetId, pets.contains(where: { $0.id == activePetId }) {
            return
        }
        if let first = pets.first {
            select(first)
        } else {
            activePetId = nil
            selection.setActivePetId(nil, for: ownerId)
        }
    }
}
