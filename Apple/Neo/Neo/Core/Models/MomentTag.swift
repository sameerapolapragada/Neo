import Foundation

enum MomentTag: String, CaseIterable, Identifiable, Sendable {
    case playing
    case sleeping
    case eating
    case exploring
    case socializing
    case learning
    case cuddling
    case relaxing
    case outdoor
    case indoor
    case grooming
    case funnyMoment = "funny_moment"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .playing: "Playing"
        case .sleeping: "Sleeping"
        case .eating: "Eating"
        case .exploring: "Exploring"
        case .socializing: "Socializing"
        case .learning: "Learning"
        case .cuddling: "Cuddling"
        case .relaxing: "Relaxing"
        case .outdoor: "Outdoor"
        case .indoor: "Indoor"
        case .grooming: "Grooming"
        case .funnyMoment: "Funny Moment"
        }
    }

    static let maximumPerMoment = 5

    static func fromStored(_ value: String) -> MomentTag? {
        MomentTag(rawValue: value)
    }

    static func sanitized(_ tags: [MomentTag]) -> [MomentTag] {
        var kept: [MomentTag] = []
        for tag in tags where !kept.contains(tag) {
            kept.append(tag)
            if kept.count == maximumPerMoment { break }
        }
        return kept
    }

    static func toggle(_ tag: MomentTag, in tags: [MomentTag]) -> [MomentTag] {
        if let index = tags.firstIndex(of: tag) {
            var next = tags
            next.remove(at: index)
            return next
        }
        guard tags.count < maximumPerMoment else { return tags }
        return tags + [tag]
    }
}

enum MomentTagFilter: Identifiable, Equatable, Sendable {
    case all
    case tag(MomentTag)

    var id: String {
        switch self {
        case .all: "all"
        case .tag(let tag): tag.rawValue
        }
    }

    var tag: MomentTag? {
        switch self {
        case .all: nil
        case .tag(let tag): tag
        }
    }

    var title: String {
        switch self {
        case .all: "Any tag"
        case .tag(let tag): tag.title
        }
    }
}
