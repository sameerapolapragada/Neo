import Foundation

struct LittleMomentPrompt: Codable, Equatable, Identifiable, Sendable {
    var id: String
    var title: String
    var description: String
    var suggestedCategory: String
    var suggestedTitle: String

    var category: MomentCategory {
        MomentCategory.fromStored(suggestedCategory)
    }

    var draft: MomentDraftPrefill {
        MomentDraftPrefill(title: suggestedTitle, category: category, promptId: id)
    }
}

struct MomentDraftPrefill: Hashable, Sendable {
    var title: String
    var category: MomentCategory
    var promptId: String
}

enum LittleMomentCatalog {
    static let expectedCount = 30

    static func load(from data: Data) throws -> [LittleMomentPrompt] {
        let decoded = try JSONDecoder().decode([LittleMomentPrompt].self, from: data)
        let sorted = decoded.sorted { $0.id < $1.id }
        let ids = sorted.map(\.id)
        guard sorted.count == expectedCount, Set(ids).count == expectedCount else {
            throw Failure.invalidCatalog
        }
        let expected = (1...expectedCount).map { String(format: "moment_%02d", $0) }
        guard ids == expected else { throw Failure.invalidCatalog }
        guard sorted.allSatisfy({ MomentCategory(rawValue: $0.suggestedCategory) != nil }) else {
            throw Failure.invalidCatalog
        }
        guard sorted.allSatisfy({ !$0.title.isEmpty && !$0.description.isEmpty && !$0.suggestedTitle.isEmpty }) else {
            throw Failure.invalidCatalog
        }
        return sorted
    }

    static func bundled(bundle: Bundle = .main) -> [LittleMomentPrompt] {
        guard let url = bundle.url(forResource: "LittleMomentPrompts", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let prompts = try? load(from: data) else {
            return []
        }
        return prompts
    }

    enum Failure: Error {
        case invalidCatalog
    }
}
