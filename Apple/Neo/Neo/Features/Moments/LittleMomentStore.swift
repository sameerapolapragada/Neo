import Foundation

struct LittleMomentPetRecord: Codable, Equatable, Sendable {
    var anchorDay: String
    var alternativeId: String?
    var alternativeForPromptId: String?
    var recentAlternativeIds: [String]
    var dismissedDay: String?

    static func starting(on day: String) -> LittleMomentPetRecord {
        LittleMomentPetRecord(
            anchorDay: day,
            alternativeId: nil,
            alternativeForPromptId: nil,
            recentAlternativeIds: [],
            dismissedDay: nil
        )
    }
}

enum LittleMomentReminderFrequency: String, Codable, CaseIterable, Identifiable, Sendable {
    case off
    case weekly
    case twiceWeekly

    var id: String { rawValue }

    var label: String {
        switch self {
        case .off: "Off"
        case .weekly: "Once a week (recommended)"
        case .twiceWeekly: "Twice a week"
        }
    }
}

struct LittleMomentReminderPreferences: Codable, Equatable, Sendable {
    var frequency: LittleMomentReminderFrequency
    var weekdays: [Int]
    var hour: Int
    var minute: Int

    static let off = LittleMomentReminderPreferences(frequency: .off, weekdays: [1], hour: 10, minute: 0)

    func normalized() -> LittleMomentReminderPreferences {
        var copy = self
        copy.hour = min(23, max(0, hour))
        copy.minute = min(59, max(0, minute))
        var cleaned: [Int] = []
        for day in weekdays where (1...7).contains(day) && !cleaned.contains(day) {
            cleaned.append(day)
        }
        switch frequency {
        case .off:
            copy.weekdays = cleaned.isEmpty ? [1] : [cleaned[0]]
        case .weekly:
            copy.weekdays = [cleaned.first ?? 1]
        case .twiceWeekly:
            if cleaned.isEmpty { cleaned = [1] }
            if cleaned.count == 1 {
                cleaned.append(cleaned[0] == 1 ? 4 : 1)
            }
            copy.weekdays = Array(cleaned.prefix(2))
        }
        return copy
    }
}

final class LittleMomentStore: @unchecked Sendable {
    static let shared = LittleMomentStore()

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    convenience init() {
        self.init(defaults: .standard)
    }

    func record(ownerId: UUID, petId: UUID) -> LittleMomentPetRecord? {
        guard let data = defaults.data(forKey: petKey(ownerId: ownerId, petId: petId)),
              let record = try? decoder.decode(LittleMomentPetRecord.self, from: data) else {
            return nil
        }
        return record
    }

    func save(_ record: LittleMomentPetRecord, ownerId: UUID, petId: UUID) {
        guard let data = try? encoder.encode(record) else { return }
        defaults.set(data, forKey: petKey(ownerId: ownerId, petId: petId))
    }

    func reminders(for ownerId: UUID) -> LittleMomentReminderPreferences {
        guard let data = defaults.data(forKey: reminderKey(ownerId)),
              let stored = try? decoder.decode(LittleMomentReminderPreferences.self, from: data) else {
            return .off
        }
        return stored.normalized()
    }

    func saveReminders(_ preferences: LittleMomentReminderPreferences, ownerId: UUID) {
        guard let data = try? encoder.encode(preferences.normalized()) else { return }
        defaults.set(data, forKey: reminderKey(ownerId))
    }

    private func petKey(ownerId: UUID, petId: UUID) -> String {
        "neo.littleMoments.v1.pet.\(ownerId.uuidString).\(petId.uuidString)"
    }

    private func reminderKey(_ ownerId: UUID) -> String {
        "neo.littleMoments.v1.reminders.\(ownerId.uuidString)"
    }
}

enum LittleMomentEngine {
    static func ensureRecord(
        existing: LittleMomentPetRecord?,
        today: Date,
        calendar: Calendar
    ) -> LittleMomentPetRecord {
        existing ?? .starting(on: LittleMomentRotation.dayKey(today, calendar: calendar))
    }

    static func scheduledPrompt(
        record: LittleMomentPetRecord,
        today: Date,
        calendar: Calendar,
        prompts: [LittleMomentPrompt]
    ) -> LittleMomentPrompt {
        let elapsed = LittleMomentRotation.elapsedDays(from: record.anchorDay, to: today, calendar: calendar)
        return LittleMomentRotation.prompt(elapsedDays: elapsed, prompts: prompts)
    }

    static func visiblePrompt(
        record: LittleMomentPetRecord,
        today: Date,
        calendar: Calendar,
        prompts: [LittleMomentPrompt],
        forceFeatured: Bool
    ) -> (prompt: LittleMomentPrompt, isAlternative: Bool)? {
        let todayKey = LittleMomentRotation.dayKey(today, calendar: calendar)
        if !forceFeatured, record.dismissedDay == todayKey {
            return nil
        }
        let scheduled = scheduledPrompt(record: record, today: today, calendar: calendar, prompts: prompts)
        if !forceFeatured,
           let alternativeId = record.alternativeId,
           record.alternativeForPromptId == scheduled.id,
           let alternative = prompts.first(where: { $0.id == alternativeId }) {
            return (alternative, true)
        }
        return (scheduled, false)
    }

    static func chooseAlternative(
        record: inout LittleMomentPetRecord,
        today: Date,
        calendar: Calendar,
        prompts: [LittleMomentPrompt]
    ) -> LittleMomentPrompt {
        let scheduled = scheduledPrompt(record: record, today: today, calendar: calendar, prompts: prompts)
        var recent = record.recentAlternativeIds
        let chosen = nextAlternative(scheduledId: scheduled.id, recent: &recent, prompts: prompts)
        record.alternativeId = chosen.id
        record.alternativeForPromptId = scheduled.id
        record.recentAlternativeIds = recent
        record.dismissedDay = nil
        return chosen
    }

    static func returnToScheduled(_ record: inout LittleMomentPetRecord) {
        record.alternativeId = nil
        record.alternativeForPromptId = nil
    }

    static func dismissForToday(_ record: inout LittleMomentPetRecord, today: Date, calendar: Calendar) {
        record.dismissedDay = LittleMomentRotation.dayKey(today, calendar: calendar)
    }

    static func revealFeatured(_ record: inout LittleMomentPetRecord) {
        record.dismissedDay = nil
        record.alternativeId = nil
        record.alternativeForPromptId = nil
    }

    static func nextAlternative(
        scheduledId: String,
        recent: inout [String],
        prompts: [LittleMomentPrompt]
    ) -> LittleMomentPrompt {
        func available() -> LittleMomentPrompt? {
            prompts.first { $0.id != scheduledId && !recent.contains($0.id) }
        }
        while available() == nil, !recent.isEmpty {
            recent.removeFirst()
        }
        let chosen = available() ?? prompts.first { $0.id != scheduledId } ?? prompts[0]
        recent.removeAll { $0 == chosen.id }
        recent.append(chosen.id)
        if recent.count > 10 {
            recent.removeFirst(recent.count - 10)
        }
        return chosen
    }
}
