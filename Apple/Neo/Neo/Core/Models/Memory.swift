import Foundation

enum MemoryCategory: String, CaseIterable, Identifiable, Sendable {
    case memory = "Memory"
    case adventure = "Adventure"
    case funnyMoment = "Funny Moment"
    case birthday = "Birthday"
    case favoriteThing = "Favorite Thing"

    var id: String { rawValue }

    static func fromStored(_ value: String) -> MemoryCategory {
        MemoryCategory(rawValue: value) ?? .memory
    }
}

enum MemorySentiment: String, CaseIterable, Identifiable, Sendable {
    case emotional = "Emotional"
    case joyful = "Joyful"
    case hilarious = "Hilarious"
    case loving = "Loving"
    case proud = "Proud"
    case bittersweet = "Bittersweet"

    var id: String { rawValue }

    static func fromStored(_ value: String) -> MemorySentiment? {
        MemorySentiment(rawValue: value)
    }
}

struct Memory: Identifiable, Equatable, Sendable {
    let id: UUID
    var ownerId: UUID
    var petId: UUID
    var title: String
    var notes: String
    var category: MemoryCategory
    var sentiment: MemorySentiment?
    var photoPath: String?
    var occurredAt: Date
    var createdAt: Date
    var updatedAt: Date

    func occurredLabel() -> String {
        occurredAt.formatted(date: .abbreviated, time: .omitted)
    }

    var shareText: String {
        "\(title)\n\n\(notes)"
    }
}
