import SwiftUI

@MainActor
@Observable
final class LittleMomentPresenter {
    private let store: LittleMomentStore
    private let prompts: [LittleMomentPrompt]
    private let calendar: Calendar
    private var ownerId: UUID?
    private var petId: UUID?
    private var record: LittleMomentPetRecord?

    private(set) var prompt: LittleMomentPrompt?
    private(set) var isAlternative = false

    init(
        store: LittleMomentStore = .shared,
        prompts: [LittleMomentPrompt] = LittleMomentCatalog.bundled(),
        calendar: Calendar = .current
    ) {
        self.store = store
        self.prompts = prompts
        self.calendar = calendar
    }

    var draft: MomentDraftPrefill? {
        prompt?.draft
    }

    func refresh(ownerId: UUID, petId: UUID, today: Date = .now, forceFeatured: Bool = false) {
        guard !prompts.isEmpty else {
            clear()
            return
        }
        self.ownerId = ownerId
        self.petId = petId
        var stored = LittleMomentEngine.ensureRecord(
            existing: store.record(ownerId: ownerId, petId: petId),
            today: today,
            calendar: calendar
        )
        if forceFeatured {
            LittleMomentEngine.revealFeatured(&stored)
        }
        record = stored
        store.save(stored, ownerId: ownerId, petId: petId)
        applyVisible(today: today, forceFeatured: forceFeatured)
    }

    func anotherIdea(today: Date = .now) {
        guard var stored = record, let ownerId, let petId, !prompts.isEmpty else { return }
        _ = LittleMomentEngine.chooseAlternative(record: &stored, today: today, calendar: calendar, prompts: prompts)
        record = stored
        store.save(stored, ownerId: ownerId, petId: petId)
        applyVisible(today: today, forceFeatured: false)
    }

    func returnToScheduled(today: Date = .now) {
        guard var stored = record, let ownerId, let petId else { return }
        LittleMomentEngine.returnToScheduled(&stored)
        record = stored
        store.save(stored, ownerId: ownerId, petId: petId)
        applyVisible(today: today, forceFeatured: false)
    }

    func dismissForToday(today: Date = .now) {
        guard var stored = record, let ownerId, let petId else { return }
        LittleMomentEngine.dismissForToday(&stored, today: today, calendar: calendar)
        record = stored
        store.save(stored, ownerId: ownerId, petId: petId)
        prompt = nil
        isAlternative = false
    }

    func clear() {
        ownerId = nil
        petId = nil
        record = nil
        prompt = nil
        isAlternative = false
    }

    private func applyVisible(today: Date, forceFeatured: Bool) {
        guard let stored = record else {
            prompt = nil
            return
        }
        if let visible = LittleMomentEngine.visiblePrompt(
            record: stored,
            today: today,
            calendar: calendar,
            prompts: prompts,
            forceFeatured: forceFeatured
        ) {
            prompt = visible.prompt
            isAlternative = visible.isAlternative
        } else {
            prompt = nil
            isAlternative = false
        }
    }
}

struct LittleMomentCard: View {
    var prompt: LittleMomentPrompt
    var isAlternative: Bool
    var onCapture: () -> Void
    var onAnother: () -> Void
    var onDismiss: () -> Void
    var onReturn: () -> Void

    var body: some View {
        NeoCard {
            Text("A Little Moment to Save")
                .font(NeoFont.caption.weight(.semibold))
                .foregroundStyle(NeoColor.warmBrown)
            Text(prompt.title)
                .font(NeoFont.cardTitle)
                .foregroundStyle(NeoColor.espresso)
                .fixedSize(horizontal: false, vertical: true)
            Text(prompt.description)
                .font(NeoFont.body)
                .foregroundStyle(NeoColor.black)
                .fixedSize(horizontal: false, vertical: true)
            Button("Capture This Moment", action: onCapture)
                .buttonStyle(NeoPrimaryButtonStyle())
                .accessibilityIdentifier("captureLittleMoment")
            Button("Another Idea", action: onAnother)
                .buttonStyle(NeoQuietButtonStyle())
                .accessibilityIdentifier("anotherLittleMoment")
            Button("Maybe Later", action: onDismiss)
                .buttonStyle(NeoQuietButtonStyle())
                .accessibilityIdentifier("dismissLittleMoment")
            if isAlternative {
                Button("Today's suggestion", action: onReturn)
                    .buttonStyle(NeoQuietButtonStyle())
                    .accessibilityIdentifier("scheduledLittleMoment")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("littleMomentCard")
    }
}

struct LittleMomentReminderSettings: View {
    var ownerId: UUID
    @State private var preferences: LittleMomentReminderPreferences
    @State private var time: Date
    @State private var permissionNote: String?

    init(ownerId: UUID, store: LittleMomentStore = .shared) {
        self.ownerId = ownerId
        let stored = store.reminders(for: ownerId)
        _preferences = State(initialValue: stored)
        _time = State(initialValue: Self.date(hour: stored.hour, minute: stored.minute))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: NeoSpacing.sm) {
            Text("Little Moment Reminders")
                .font(NeoFont.sectionTitle)
                .foregroundStyle(NeoColor.espresso)
            Text("A gentle nudge to save one small memory. Suggestions stay in Moments even when reminders are off.")
                .font(NeoFont.body)
                .foregroundStyle(NeoColor.warmBrown)
                .fixedSize(horizontal: false, vertical: true)

            Picker("Reminder frequency", selection: $preferences.frequency) {
                ForEach(LittleMomentReminderFrequency.allCases) { frequency in
                    Text(frequency.label).tag(frequency)
                }
            }
            .pickerStyle(.inline)
            .labelsHidden()
            .accessibilityLabel("Little Moment reminder frequency")

            if preferences.frequency != .off {
                dayControls
                DatePicker("Reminder time", selection: $time, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .accessibilityLabel("Reminder time")
            }

            if let permissionNote {
                Text(permissionNote)
                    .font(NeoFont.callout)
                    .foregroundStyle(NeoColor.warmBrown)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .onChange(of: preferences.frequency) { _, _ in
            Task { await save() }
        }
        .onChange(of: preferences.weekdays) { _, _ in
            Task { await save() }
        }
        .onChange(of: time) { _, newValue in
            let parts = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            preferences.hour = parts.hour ?? preferences.hour
            preferences.minute = parts.minute ?? preferences.minute
            Task { await save() }
        }
    }

    @ViewBuilder
    private var dayControls: some View {
        if preferences.frequency == .weekly {
            weekdayPicker(title: "Reminder day", index: 0)
        } else if preferences.frequency == .twiceWeekly {
            weekdayPicker(title: "First day", index: 0)
            weekdayPicker(title: "Second day", index: 1)
        }
    }

    private func weekdayPicker(title: String, index: Int) -> some View {
        Picker(title, selection: weekdayBinding(index)) {
            ForEach(1...7, id: \.self) { weekday in
                Text(weekdayName(weekday)).tag(weekday)
            }
        }
        .accessibilityLabel(title)
    }

    private func weekdayBinding(_ index: Int) -> Binding<Int> {
        Binding {
            preferences.weekdays.indices.contains(index) ? preferences.weekdays[index] : 1
        } set: { newValue in
            var days = preferences.weekdays
            while days.count <= index { days.append(1) }
            days[index] = newValue
            preferences.weekdays = days
        }
    }

    private func save() async {
        let normalized = preferences.normalized()
        if normalized != preferences {
            preferences = normalized
            return
        }
        let outcome = await LittleMomentReminderCoordinator.shared.update(preferences, ownerId: ownerId)
        switch outcome {
        case .denied:
            permissionNote = "Reminders stay off until notifications are allowed for Neo in Settings. Suggestions in Moments still appear."
        case .scheduled, .off:
            permissionNote = nil
        }
    }

    private func weekdayName(_ weekday: Int) -> String {
        let symbols = Calendar.current.weekdaySymbols
        let index = weekday - 1
        guard symbols.indices.contains(index) else { return "Day \(weekday)" }
        return symbols[index]
    }

    private static func date(hour: Int, minute: Int) -> Date {
        var parts = Calendar.current.dateComponents([.year, .month, .day], from: .now)
        parts.hour = hour
        parts.minute = minute
        return Calendar.current.date(from: parts) ?? .now
    }
}
