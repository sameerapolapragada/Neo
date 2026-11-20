import XCTest
@testable import Neo

@MainActor
final class LittleMomentPromptTests: XCTestCase {
    private var prompts: [LittleMomentPrompt] = []
    private var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        return calendar
    }()

    override func setUp() async throws {
        prompts = try loadPrompts()
    }

    func testCatalogHasExactlyThirtyUniquePrompts() {
        XCTAssertEqual(prompts.count, 30)
        XCTAssertEqual(Set(prompts.map(\.id)).count, 30)
        let expected = (1...30).map { String(format: "moment_%02d", $0) }
        XCTAssertEqual(prompts.map(\.id), expected)
        XCTAssertEqual(prompts.first { $0.id == "moment_08" }?.category, .adventure)
        XCTAssertEqual(prompts.first { $0.id == "moment_10" }?.category, .milestone)
        XCTAssertEqual(prompts.first { $0.id == "moment_17" }?.category, .adventure)
        XCTAssertEqual(prompts.first { $0.id == "moment_20" }?.category, .milestone)
        XCTAssertEqual(prompts.first { $0.id == "moment_25" }?.category, .adventure)
        XCTAssertEqual(prompts.first { $0.id == "moment_26" }?.category, .milestone)
        XCTAssertEqual(prompts.first { $0.id == "moment_30" }?.category, .milestone)
        XCTAssertEqual(prompts.filter { $0.category == .daily }.count, 23)
        let attention = prompts.first { $0.id == "moment_27" }
        XCTAssertEqual(attention?.description, "Every pet has a special way of saying, 'Notice me.'")
        XCTAssertTrue(prompts.allSatisfy { !$0.suggestedTitle.isEmpty && !$0.description.isEmpty })
    }

    func testFirstCycleUsesOnePromptPerTwoDayWindow() {
        let start = date(2026, 1, 1)
        let harness = makeHarness()
        harness.presenter.refresh(ownerId: harness.ownerId, petId: harness.petId, today: start)
        let nextDay = calendar.date(byAdding: .day, value: 1, to: start)!
        harness.presenter.refresh(ownerId: harness.ownerId, petId: harness.petId, today: nextDay)
        XCTAssertEqual(harness.presenter.prompt?.id, "moment_01")
        for slot in 0..<30 {
            let first = LittleMomentRotation.prompt(elapsedDays: slot * 2, prompts: prompts)
            let second = LittleMomentRotation.prompt(elapsedDays: slot * 2 + 1, prompts: prompts)
            XCTAssertEqual(first.id, second.id)
            XCTAssertEqual(first.id, String(format: "moment_%02d", slot + 1))
        }
    }

    func testDay60AndDay61Transition() {
        let start = date(2026, 1, 1)
        let harness = makeHarness()
        harness.presenter.refresh(ownerId: harness.ownerId, petId: harness.petId, today: start)
        let day60 = calendar.date(byAdding: .day, value: 59, to: start)!
        harness.presenter.refresh(ownerId: harness.ownerId, petId: harness.petId, today: day60)
        XCTAssertEqual(harness.presenter.prompt?.id, "moment_30")
        let day61 = calendar.date(byAdding: .day, value: 60, to: start)!
        harness.presenter.refresh(ownerId: harness.ownerId, petId: harness.petId, today: day61)
        XCTAssertNotEqual(harness.presenter.prompt?.id, "moment_30")
        let day62 = calendar.date(byAdding: .day, value: 61, to: start)!
        let on61 = harness.presenter.prompt?.id
        harness.presenter.refresh(ownerId: harness.ownerId, petId: harness.petId, today: day62)
        XCTAssertEqual(harness.presenter.prompt?.id, on61)
    }

    func testFeaturedPromptStaysStableAcrossRestart() {
        let start = date(2026, 4, 2)
        let harness = makeHarness()
        harness.presenter.refresh(ownerId: harness.ownerId, petId: harness.petId, today: start)
        let anchor = harness.store.record(ownerId: harness.ownerId, petId: harness.petId)?.anchorDay
        let shown = harness.presenter.prompt?.id
        let restarted = LittleMomentPresenter(store: harness.store, prompts: prompts, calendar: calendar)
        let nextDay = calendar.date(byAdding: .day, value: 1, to: start)!
        restarted.refresh(ownerId: harness.ownerId, petId: harness.petId, today: nextDay)
        XCTAssertEqual(restarted.prompt?.id, shown)
        XCTAssertEqual(harness.store.record(ownerId: harness.ownerId, petId: harness.petId)?.anchorDay, anchor)
        XCTAssertEqual(shown, "moment_01")
    }

    func testReshuffleIsDeterministicAndDoesNotRepeatTheBoundary() {
        let first = LittleMomentRotation.order(forCycle: 4)
        let second = LittleMomentRotation.order(forCycle: 4)
        XCTAssertEqual(first, second)
        XCTAssertEqual(Set(first).count, 30)
        for cycle in 1...24 {
            let previous = LittleMomentRotation.order(forCycle: cycle - 1)
            let current = LittleMomentRotation.order(forCycle: cycle)
            XCTAssertNotEqual(current[0], previous.last)
            XCTAssertEqual(Set(current), Set(0..<30))
        }
    }

    func testPetsAndAccountsKeepSeparateAnchors() {
        let harness = makeHarness()
        let otherOwner = UUID()
        let otherPet = UUID()
        let start = date(2026, 2, 1)
        harness.presenter.refresh(ownerId: harness.ownerId, petId: harness.petId, today: start)
        let later = calendar.date(byAdding: .day, value: 4, to: start)!
        harness.presenter.refresh(ownerId: harness.ownerId, petId: otherPet, today: later)
        XCTAssertEqual(harness.presenter.prompt?.id, "moment_01")
        harness.presenter.refresh(ownerId: harness.ownerId, petId: harness.petId, today: later)
        XCTAssertEqual(harness.presenter.prompt?.id, "moment_03")
        harness.presenter.refresh(ownerId: otherOwner, petId: harness.petId, today: later)
        XCTAssertEqual(harness.presenter.prompt?.id, "moment_01")
        XCTAssertNotEqual(
            harness.store.record(ownerId: harness.ownerId, petId: harness.petId)?.anchorDay,
            harness.store.record(ownerId: otherOwner, petId: harness.petId)?.anchorDay
        )
    }

    func testAnotherIdeaDoesNotChangeTheScheduledRotation() {
        let harness = makeHarness()
        let start = date(2026, 5, 3)
        harness.presenter.refresh(ownerId: harness.ownerId, petId: harness.petId, today: start)
        let scheduled = harness.presenter.prompt?.id
        harness.presenter.anotherIdea(today: start)
        XCTAssertTrue(harness.presenter.isAlternative)
        XCTAssertNotEqual(harness.presenter.prompt?.id, scheduled)
        let firstAlternative = harness.presenter.prompt?.id
        harness.presenter.anotherIdea(today: start)
        XCTAssertNotEqual(harness.presenter.prompt?.id, firstAlternative)
        XCTAssertNotEqual(harness.presenter.prompt?.id, scheduled)
        harness.presenter.returnToScheduled(today: start)
        XCTAssertFalse(harness.presenter.isAlternative)
        XCTAssertEqual(harness.presenter.prompt?.id, scheduled)
        XCTAssertEqual(
            harness.store.record(ownerId: harness.ownerId, petId: harness.petId)?.anchorDay,
            LittleMomentRotation.dayKey(start, calendar: calendar)
        )
    }

    func testMaybeLaterHidesTheCardUntilALaterDay() {
        let harness = makeHarness()
        let start = date(2026, 6, 4)
        harness.presenter.refresh(ownerId: harness.ownerId, petId: harness.petId, today: start)
        let anchor = harness.store.record(ownerId: harness.ownerId, petId: harness.petId)?.anchorDay
        harness.presenter.dismissForToday(today: start)
        XCTAssertNil(harness.presenter.prompt)
        harness.presenter.refresh(ownerId: harness.ownerId, petId: harness.petId, today: start)
        XCTAssertNil(harness.presenter.prompt)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: start)!
        harness.presenter.refresh(ownerId: harness.ownerId, petId: harness.petId, today: tomorrow)
        XCTAssertEqual(harness.presenter.prompt?.id, "moment_01")
        XCTAssertEqual(harness.store.record(ownerId: harness.ownerId, petId: harness.petId)?.anchorDay, anchor)
    }

    func testCreateMomentPrefillDoesNotSaveUntilTheOwnerSaves() async throws {
        let moments = InMemoryMomentRepository()
        let owner = UUID()
        let petId = UUID()
        let model = CreatePetMomentViewModel(
            ownerId: owner,
            petId: petId,
            pets: InMemoryPetRepository(),
            moments: moments,
            uploader: InMemoryMediaStore(),
            prefill: MomentDraftPrefill(title: "A Favorite Adventure", category: .adventure, promptId: "moment_08")
        )
        XCTAssertEqual(model.title, "A Favorite Adventure")
        XCTAssertEqual(model.category, .adventure)
        XCTAssertFalse(model.hasUnsavedChanges)
        XCTAssertFalse(model.didSave)
        let stored = try await moments.list(petId: petId, ownerId: owner)
        XCTAssertTrue(stored.isEmpty)
        model.title = "Our afternoon"
        XCTAssertTrue(model.hasUnsavedChanges)
        XCTAssertFalse(model.didSave)
    }

    func testWeeklyReminderSchedulesOneGenericNotification() async {
        let fake = FakeLittleMomentNotifications()
        let harness = makeHarness()
        let coordinator = LittleMomentReminderCoordinator(store: harness.store, scheduler: fake)
        let preferences = LittleMomentReminderPreferences(frequency: .weekly, weekdays: [2], hour: 9, minute: 30)
        let outcome = await coordinator.update(preferences, ownerId: harness.ownerId)
        XCTAssertEqual(outcome, .scheduled)
        XCTAssertEqual(fake.requests.count, 1)
        XCTAssertEqual(fake.requests[0].weekday, 2)
        XCTAssertEqual(fake.requests[0].hour, 9)
        XCTAssertEqual(fake.requests[0].minute, 30)
        XCTAssertEqual(fake.requests[0].title, LittleMomentNotificationCopy.title)
        XCTAssertEqual(fake.requests[0].body, LittleMomentNotificationCopy.body)
        XCTAssertFalse(fake.requests[0].body.contains("Mochi"))
        XCTAssertFalse(fake.requests[0].title.contains("Mochi"))
        XCTAssertEqual(fake.requests[0].body, "Neo has a new memory idea for you.")
    }

    func testTwiceWeeklyReminderSchedulesTwoDifferentDays() async {
        let fake = FakeLittleMomentNotifications()
        let harness = makeHarness()
        let coordinator = LittleMomentReminderCoordinator(store: harness.store, scheduler: fake)
        let preferences = LittleMomentReminderPreferences(frequency: .twiceWeekly, weekdays: [1, 4], hour: 18, minute: 0)
        let outcome = await coordinator.update(preferences, ownerId: harness.ownerId)
        XCTAssertEqual(outcome, .scheduled)
        XCTAssertEqual(fake.requests.map(\.weekday), [1, 4])
        XCTAssertEqual(Set(fake.requests.map(\.identifier)).count, 2)
        XCTAssertTrue(fake.requests.allSatisfy { $0.hour == 18 && $0.minute == 0 })
    }

    func testDeniedNotificationPermissionKeepsTheInAppPrompt() async {
        let fake = FakeLittleMomentNotifications()
        fake.grant = false
        let harness = makeHarness()
        let coordinator = LittleMomentReminderCoordinator(store: harness.store, scheduler: fake)
        let preferences = LittleMomentReminderPreferences(frequency: .weekly, weekdays: [1], hour: 10, minute: 0)
        let outcome = await coordinator.update(preferences, ownerId: harness.ownerId)
        XCTAssertEqual(outcome, .denied)
        XCTAssertTrue(fake.requests.isEmpty)
        XCTAssertEqual(fake.status, .denied)
        harness.presenter.refresh(ownerId: harness.ownerId, petId: harness.petId, today: date(2026, 7, 1))
        XCTAssertEqual(harness.presenter.prompt?.id, "moment_01")
    }

    func testCancellingRemindersRemovesScheduledRequests() async {
        let fake = FakeLittleMomentNotifications()
        let harness = makeHarness()
        let coordinator = LittleMomentReminderCoordinator(store: harness.store, scheduler: fake)
        _ = await coordinator.update(
            LittleMomentReminderPreferences(frequency: .weekly, weekdays: [6], hour: 8, minute: 15),
            ownerId: harness.ownerId
        )
        XCTAssertEqual(fake.requests.count, 1)
        await coordinator.cancelAll()
        XCTAssertTrue(fake.requests.isEmpty)
        let stored = harness.store.reminders(for: harness.ownerId)
        XCTAssertEqual(stored.frequency, .weekly)
    }

    func testSignOutCancelsRemindersWithoutMixingAccounts() async {
        let fake = FakeLittleMomentNotifications()
        let harness = makeHarness()
        let coordinator = LittleMomentReminderCoordinator(store: harness.store, scheduler: fake)
        _ = await coordinator.update(
            LittleMomentReminderPreferences(frequency: .weekly, weekdays: [3], hour: 11, minute: 0),
            ownerId: harness.ownerId
        )
        await coordinator.cancelAll()
        XCTAssertTrue(fake.requests.isEmpty)
        let otherOwner = UUID()
        _ = await coordinator.update(
            LittleMomentReminderPreferences(frequency: .twiceWeekly, weekdays: [2, 5], hour: 16, minute: 45),
            ownerId: otherOwner
        )
        XCTAssertEqual(fake.requests.map(\.weekday), [2, 5])
        XCTAssertTrue(fake.requests.allSatisfy { $0.identifier.contains(otherOwner.uuidString) })
        XCTAssertTrue(fake.requests.allSatisfy { !$0.identifier.contains(harness.ownerId.uuidString) })
        XCTAssertEqual(harness.store.reminders(for: harness.ownerId).frequency, .weekly)
        XCTAssertEqual(harness.store.reminders(for: otherOwner).frequency, .twiceWeekly)
        await coordinator.reconcile(ownerId: nil)
        XCTAssertTrue(fake.requests.isEmpty)
        XCTAssertEqual(harness.store.reminders(for: harness.ownerId).weekdays, [3])
    }

    func testCalendarDaysStayStableAcrossTimeZonesAndDaylightSaving() {
        var newYork = Calendar(identifier: .gregorian)
        newYork.timeZone = TimeZone(identifier: "America/New_York")!
        let springEvening = date(2026, 3, 8, 23, calendar: newYork)
        let twoCalendarDaysLater = date(2026, 3, 9, 0, 30, calendar: newYork)
        XCTAssertEqual(LittleMomentRotation.elapsedDays(from: "2026-03-07", to: springEvening, calendar: newYork), 1)
        XCTAssertEqual(LittleMomentRotation.elapsedDays(from: "2026-03-07", to: twoCalendarDaysLater, calendar: newYork), 2)
        XCTAssertEqual(
            LittleMomentRotation.prompt(elapsedDays: 0, prompts: prompts).id,
            LittleMomentRotation.prompt(elapsedDays: 1, prompts: prompts).id
        )
        XCTAssertEqual(LittleMomentRotation.prompt(elapsedDays: 2, prompts: prompts).id, "moment_02")
        let afterFallBack = date(2026, 11, 2, 0, 30, calendar: newYork)
        XCTAssertEqual(LittleMomentRotation.elapsedDays(from: "2026-11-01", to: afterFallBack, calendar: newYork), 1)
    }

    private func makeHarness() -> LittleMomentHarness {
        let suite = "neo.littleMoments.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        let store = LittleMomentStore(defaults: defaults)
        let presenter = LittleMomentPresenter(store: store, prompts: prompts, calendar: calendar)
        return LittleMomentHarness(store: store, presenter: presenter, ownerId: UUID(), petId: UUID())
    }

    private func loadPrompts() throws -> [LittleMomentPrompt] {
        if let url = Bundle.main.url(forResource: "LittleMomentPrompts", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let decoded = try? LittleMomentCatalog.load(from: data) {
            return decoded
        }
        let source = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Neo/Resources/LittleMomentPrompts.json")
        let data = try Data(contentsOf: source)
        return try LittleMomentCatalog.load(from: data)
    }

    private func date(
        _ year: Int,
        _ month: Int,
        _ day: Int,
        _ hour: Int = 12,
        _ minute: Int = 0,
        calendar chosen: Calendar? = nil
    ) -> Date {
        let calendar = chosen ?? self.calendar
        var parts = DateComponents()
        parts.calendar = calendar
        parts.timeZone = calendar.timeZone
        parts.year = year
        parts.month = month
        parts.day = day
        parts.hour = hour
        parts.minute = minute
        return calendar.date(from: parts)!
    }
}

private struct LittleMomentHarness {
    var store: LittleMomentStore
    var presenter: LittleMomentPresenter
    var ownerId: UUID
    var petId: UUID
}

private final class FakeLittleMomentNotifications: LittleMomentNotificationScheduling, @unchecked Sendable {
    var status: UNAuthorizationStatus = .notDetermined
    var grant = true
    var requests: [LittleMomentNotificationDraft] = []

    func authorizationStatus() async -> UNAuthorizationStatus { status }

    func requestAuthorization() async -> Bool {
        if grant {
            status = .authorized
            return true
        }
        status = .denied
        return false
    }

    func replace(_ drafts: [LittleMomentNotificationDraft]) async {
        requests = drafts
    }

    func cancelAll() async {
        requests = []
    }
}
