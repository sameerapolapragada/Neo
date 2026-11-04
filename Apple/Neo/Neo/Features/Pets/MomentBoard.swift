import Foundation
import Observation

struct MomentDelta: Identifiable {
    enum Kind {
        case saved(PetMoment)
        case deleted(UUID)
    }

    let id: Int
    let kind: Kind
}

/// Shared moments for the signed-in owner. Screens read the same pet, the same
/// counts, and the same edits. A load that finishes after the pet changes is ignored.
@MainActor
@Observable
final class MomentBoard {
    private(set) var petId: UUID?
    private(set) var ownerId: UUID?
    private(set) var generation = 0
    private(set) var changeToken = 0
    private(set) var listIsComplete = false

    private var records: [UUID: PetMoment] = [:]
    private var tombstones: Set<UUID> = []
    private var deltas: [MomentDelta] = []
    private var nextDeltaID = 0

    var latestDeltaID: Int { deltas.last?.id ?? 0 }

    var momentCount: Int {
        listIsComplete ? records.count : 0
    }

    var milestoneCount: Int {
        guard listIsComplete else { return 0 }
        return records.values.filter { $0.category == .milestone }.count
    }

    func activate(petId: UUID?, ownerId: UUID?) {
        guard petId != self.petId || ownerId != self.ownerId else { return }
        generation += 1
        self.petId = petId
        self.ownerId = ownerId
        records = [:]
        tombstones = []
        deltas = []
        listIsComplete = false
        changeToken += 1
    }

    func beginLoad(petId: UUID, ownerId: UUID) -> Int {
        activate(petId: petId, ownerId: ownerId)
        return generation
    }

    func replaceFromServer(_ moments: [PetMoment], petId: UUID, ownerId: UUID, generation: Int) {
        guard generation == self.generation, petId == self.petId, ownerId == self.ownerId else { return }
        var next: [UUID: PetMoment] = [:]
        for moment in moments where moment.petId == petId && moment.ownerId == ownerId && !tombstones.contains(moment.id) {
            if let local = records[moment.id], local.updatedAt > moment.updatedAt {
                next[moment.id] = local
            } else {
                next[moment.id] = moment
            }
        }
        for (id, local) in records where next[id] == nil && !tombstones.contains(id) && local.petId == petId && local.ownerId == ownerId {
            next[id] = local
        }
        records = next
        listIsComplete = true
        changeToken += 1
    }

    func noteSaved(_ moment: PetMoment) {
        guard moment.petId == petId, moment.ownerId == ownerId else { return }
        tombstones.remove(moment.id)
        records[moment.id] = moment
        append(.saved(moment))
    }

    func noteDeleted(id: UUID, petId: UUID, ownerId: UUID) {
        guard petId == self.petId, ownerId == self.ownerId else { return }
        records.removeValue(forKey: id)
        tombstones.insert(id)
        append(.deleted(id))
    }

    func isDeleted(_ id: UUID) -> Bool {
        tombstones.contains(id)
    }

    func moment(id: UUID) -> PetMoment? {
        records[id]
    }

    func deltas(after id: Int) -> [MomentDelta] {
        deltas.filter { $0.id > id }
    }

    private func append(_ kind: MomentDelta.Kind) {
        nextDeltaID += 1
        deltas.append(MomentDelta(id: nextDeltaID, kind: kind))
        if deltas.count > 40 {
            deltas.removeFirst(deltas.count - 40)
        }
        changeToken += 1
    }
}

enum MomentListSync {
    /// Applies creates, edits, and deletes onto an already loaded page.
    /// Newer moments are inserted. Older ones stay behind the cursor until the next page.
    @discardableResult
    static func apply(
        moments: inout [PetMoment],
        canLoadMore: Bool,
        nextCursor: inout MomentCursor?,
        matches: (PetMoment) -> Bool,
        deltas: [MomentDelta]
    ) -> [PetMoment] {
        var additions: [PetMoment] = []
        for delta in deltas {
            switch delta.kind {
            case .deleted(let id):
                moments.removeAll { $0.id == id }
            case .saved(let moment):
                if let index = moments.firstIndex(where: { $0.id == moment.id }) {
                    if matches(moment) {
                        moments[index] = moment
                    } else {
                        moments.remove(at: index)
                    }
                } else if matches(moment), belongs(moment, in: moments, canLoadMore: canLoadMore) {
                    additions.append(moment)
                }
            }
        }
        if !additions.isEmpty {
            moments = MomentFeedSorting.ordered(moments + additions)
        }
        if canLoadMore, let last = moments.last {
            nextCursor = MomentFeedSorting.makeCursor(for: last)
        }
        return additions
    }

    private static func belongs(_ moment: PetMoment, in loaded: [PetMoment], canLoadMore: Bool) -> Bool {
        guard canLoadMore, let oldest = loaded.last else { return true }
        return MomentFeedSorting.ordered([moment, oldest]).first?.id == moment.id
    }
}
