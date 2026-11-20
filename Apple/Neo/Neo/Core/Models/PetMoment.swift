import Foundation

enum MomentCategory: String, CaseIterable, Identifiable, Sendable {
    case daily = "Daily"
    case adventure = "Adventure"
    case milestone = "Milestone"

    var id: String { rawValue }

    static func fromStored(_ value: String) -> MomentCategory {
        MomentCategory(rawValue: value) ?? .daily
    }
}

enum MomentCategoryFilter: String, CaseIterable, Identifiable, Sendable {
    case all = "All"
    case daily = "Daily"
    case adventure = "Adventure"
    case milestone = "Milestone"

    var id: String { rawValue }

    var category: MomentCategory? {
        switch self {
        case .all: nil
        case .daily: .daily
        case .adventure: .adventure
        case .milestone: .milestone
        }
    }
}

struct MomentMedia: Identifiable, Equatable, Sendable {
    let id: UUID
    var momentId: UUID
    var ownerId: UUID
    var storagePath: String
    var sortOrder: Int
    var contentType: String
    var byteCount: Int?
    var width: Int?
    var height: Int?
}

struct PetMoment: Identifiable, Equatable, Sendable {
    let id: UUID
    var ownerId: UUID
    var petId: UUID
    var title: String
    var caption: String
    var category: MomentCategory
    var momentDate: Date
    var isFavorite: Bool
    var media: [MomentMedia]
    var tags: [MomentTag] = []
    var createdAt: Date
    var updatedAt: Date

    var coverPath: String? {
        media.inDisplayOrder().first?.storagePath
    }

    func dateLabel() -> String {
        momentDate.formatted(date: .abbreviated, time: .omitted)
    }
}

extension Array where Element == MomentMedia {
    func inDisplayOrder() -> [MomentMedia] {
        sorted { lhs, rhs in
            if lhs.sortOrder != rhs.sortOrder {
                return lhs.sortOrder < rhs.sortOrder
            }
            return lhs.id.uuidString < rhs.id.uuidString
        }
    }
}

struct MomentCursor: Equatable, Sendable {
    var momentDate: Date
    var createdAt: Date
    var id: UUID
}

struct MomentPage: Equatable, Sendable {
    var moments: [PetMoment]
    var nextCursor: MomentCursor?
}

enum MomentFeedSorting {
    static func ordered(_ moments: [PetMoment]) -> [PetMoment] {
        moments.sorted { comesBefore($0, $1) }
    }

    static func page(
        from moments: [PetMoment],
        category: MomentCategory?,
        cursor: MomentCursor?,
        limit: Int
    ) -> MomentPage {
        guard limit > 0 else { return MomentPage(moments: [], nextCursor: nil) }
        let filtered = ordered(moments).filter { moment in
            matches(moment, category: category, tag: nil)
        }
        let remaining: [PetMoment]
        if let cursor {
            remaining = filtered.filter { comesAfter($0, cursor: cursor) }
        } else {
            remaining = filtered
        }
        let slice = Array(remaining.prefix(limit))
        let next = slice.count == limit ? makeCursor(for: slice[slice.count - 1]) : nil
        return MomentPage(moments: slice, nextCursor: next)
    }

    static func matching(
        _ moments: [PetMoment],
        category: MomentCategory?,
        tag: MomentTag?
    ) -> [PetMoment] {
        ordered(moments).filter { matches($0, category: category, tag: tag) }
    }

    static func matches(_ moment: PetMoment, category: MomentCategory?, tag: MomentTag?) -> Bool {
        if let category, moment.category != category { return false }
        if let tag, !moment.tags.contains(tag) { return false }
        return true
    }

    static func makeCursor(for moment: PetMoment) -> MomentCursor {
        MomentCursor(momentDate: moment.momentDate, createdAt: moment.createdAt, id: moment.id)
    }

    private static func comesBefore(_ lhs: PetMoment, _ rhs: PetMoment) -> Bool {
        if lhs.momentDate != rhs.momentDate {
            return lhs.momentDate > rhs.momentDate
        }
        if lhs.createdAt != rhs.createdAt {
            return lhs.createdAt > rhs.createdAt
        }
        return lhs.id.uuidString > rhs.id.uuidString
    }

    private static func comesAfter(_ moment: PetMoment, cursor: MomentCursor) -> Bool {
        if moment.momentDate != cursor.momentDate {
            return moment.momentDate < cursor.momentDate
        }
        if moment.createdAt != cursor.createdAt {
            return moment.createdAt < cursor.createdAt
        }
        return moment.id.uuidString < cursor.id.uuidString
    }
}
