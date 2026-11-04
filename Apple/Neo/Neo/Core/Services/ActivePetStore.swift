import Foundation

@MainActor
final class UserDefaultsActivePetStore: ActivePetStoring {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func activePetId(for ownerId: UUID) -> UUID? {
        guard let raw = defaults.string(forKey: key(ownerId)) else { return nil }
        return UUID(uuidString: raw)
    }

    func setActivePetId(_ id: UUID?, for ownerId: UUID) {
        let storageKey = key(ownerId)
        if let id {
            defaults.set(id.uuidString, forKey: storageKey)
        } else {
            defaults.removeObject(forKey: storageKey)
        }
    }

    private func key(_ ownerId: UUID) -> String {
        "neo.activePet.\(ownerId.uuidString)"
    }
}

#if DEBUG
@MainActor
final class InMemoryActivePetStore: ActivePetStoring {
    private var values: [UUID: UUID] = [:]

    func activePetId(for ownerId: UUID) -> UUID? {
        values[ownerId]
    }

    func setActivePetId(_ id: UUID?, for ownerId: UUID) {
        values[ownerId] = id
    }
}
#endif
