import Foundation

enum PawAppetite: String, CaseIterable, Identifiable, Sendable {
    case normal
    case less
    case more
    case unsure

    var id: String { rawValue }

    var title: String {
        switch self {
        case .normal: "Normal"
        case .less: "Less than usual"
        case .more: "More than usual"
        case .unsure: "Not sure"
        }
    }

    static func fromStored(_ value: String?) -> PawAppetite? {
        guard let value else { return nil }
        return PawAppetite(rawValue: value)
    }
}

enum PawEnergy: String, CaseIterable, Identifiable, Sendable {
    case normal
    case lower
    case higher
    case unsure

    var id: String { rawValue }

    var title: String {
        switch self {
        case .normal: "Normal"
        case .lower: "Lower than usual"
        case .higher: "Higher than usual"
        case .unsure: "Not sure"
        }
    }

    static func fromStored(_ value: String?) -> PawEnergy? {
        guard let value else { return nil }
        return PawEnergy(rawValue: value)
    }
}

enum PawMood: String, CaseIterable, Identifiable, Sendable {
    case playful
    case relaxed
    case quiet
    case unsettled
    case unsure

    var id: String { rawValue }

    var title: String {
        switch self {
        case .playful: "Playful"
        case .relaxed: "Relaxed"
        case .quiet: "Quiet"
        case .unsettled: "Unsettled"
        case .unsure: "Not sure"
        }
    }

    static func fromStored(_ value: String?) -> PawMood? {
        guard let value else { return nil }
        return PawMood(rawValue: value)
    }
}

enum PawObservation: String, CaseIterable, Identifiable, Sendable {
    case drinkingMore = "drinking_more"
    case drinkingLess = "drinking_less"
    case vomiting
    case looseStool = "loose_stool"
    case scratching
    case limping
    case other
    case nothingNoticed = "nothing_noticed"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .drinkingMore: "Drinking more"
        case .drinkingLess: "Drinking less"
        case .vomiting: "Vomiting"
        case .looseStool: "Loose stool"
        case .scratching: "Scratching"
        case .limping: "Limping"
        case .other: "Other"
        case .nothingNoticed: "Nothing noticed"
        }
    }

    var isSerious: Bool {
        switch self {
        case .vomiting, .looseStool, .limping:
            true
        default:
            false
        }
    }

    static func fromStored(_ value: String) -> PawObservation? {
        PawObservation(rawValue: value)
    }
}

struct PawCheck: Identifiable, Equatable, Sendable {
    var id: UUID
    var ownerId: UUID
    var petId: UUID
    var observationDate: Date
    var appetite: PawAppetite?
    var energy: PawEnergy?
    var mood: PawMood?
    var observations: [PawObservation]
    var note: String?
    var source: String
    var createdAt: Date
    var updatedAt: Date

    static let noteLimit = 280
    static let sourceOwnerReported = "owner_reported"
    static let veterinarianPrompt = "If this worries you, or it keeps happening, a veterinarian can help. This check-in only saves what you noticed."

    var mentionsSeriousConcern: Bool {
        observations.contains { $0.isSerious }
    }
}

enum PawCheckRules {
    static func note(from text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return String(trimmed.prefix(PawCheck.noteLimit))
    }

    /// Nothing noticed stands alone. Other choices remove it, and it removes them.
    static func observations(selecting choice: PawObservation, in current: [PawObservation]) -> [PawObservation] {
        if choice == .nothingNoticed {
            return current.contains(.nothingNoticed) ? [] : [.nothingNoticed]
        }
        var next = current.filter { $0 != .nothingNoticed }
        if let index = next.firstIndex(of: choice) {
            next.remove(at: index)
        } else {
            next.append(choice)
        }
        return next
    }

    static func sanitized(_ observations: [PawObservation]) -> [PawObservation] {
        var kept: [PawObservation] = []
        for observation in observations where !kept.contains(observation) {
            if observation == .nothingNoticed {
                return [.nothingNoticed]
            }
            kept.append(observation)
        }
        return kept
    }

    static func sameDay(_ checks: [PawCheck], petId: UUID, ownerId: UUID, day: Date, calendar: Calendar = .current) -> PawCheck? {
        checks.first { check in
            check.petId == petId
                && check.ownerId == ownerId
                && calendar.isDate(check.observationDate, inSameDayAs: day)
        }
    }
}
