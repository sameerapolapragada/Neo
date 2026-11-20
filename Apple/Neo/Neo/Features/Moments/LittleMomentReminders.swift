import Foundation
import UserNotifications

enum LittleMomentNotificationCopy {
    static let title = "A little moment worth saving 🐾"
    static let body = "Neo has a new memory idea for you."
    static let route = "littleMoment"
    static let identifierPrefix = "neo.littleMoment."
}

struct LittleMomentNotificationDraft: Equatable, Sendable {
    var identifier: String
    var weekday: Int
    var hour: Int
    var minute: Int
    var title: String
    var body: String
}

enum LittleMomentReminderPlanner {
    static func requests(
        for preferences: LittleMomentReminderPreferences,
        ownerId: UUID
    ) -> [LittleMomentNotificationDraft] {
        let normalized = preferences.normalized()
        guard normalized.frequency != .off else { return [] }
        return normalized.weekdays.map { weekday in
            LittleMomentNotificationDraft(
                identifier: "\(LittleMomentNotificationCopy.identifierPrefix)\(ownerId.uuidString).weekday.\(weekday)",
                weekday: weekday,
                hour: normalized.hour,
                minute: normalized.minute,
                title: LittleMomentNotificationCopy.title,
                body: LittleMomentNotificationCopy.body
            )
        }
    }
}

enum LittleMomentReminderOutcome: Equatable, Sendable {
    case off
    case scheduled
    case denied
}

protocol LittleMomentNotificationScheduling: Sendable {
    func authorizationStatus() async -> UNAuthorizationStatus
    func requestAuthorization() async -> Bool
    func replace(_ drafts: [LittleMomentNotificationDraft]) async
    func cancelAll() async
}

final class LittleMomentReminderCoordinator: @unchecked Sendable {
    static let shared = LittleMomentReminderCoordinator(
        store: .shared,
        scheduler: SystemLittleMomentNotifications()
    )

    private let store: LittleMomentStore
    private let scheduler: any LittleMomentNotificationScheduling

    init(store: LittleMomentStore, scheduler: any LittleMomentNotificationScheduling) {
        self.store = store
        self.scheduler = scheduler
    }

    func update(_ preferences: LittleMomentReminderPreferences, ownerId: UUID) async -> LittleMomentReminderOutcome {
        let normalized = preferences.normalized()
        store.saveReminders(normalized, ownerId: ownerId)
        guard normalized.frequency != .off else {
            await scheduler.cancelAll()
            return .off
        }
        let allowed = await ensurePermission()
        guard allowed else {
            await scheduler.cancelAll()
            return .denied
        }
        await scheduler.replace(LittleMomentReminderPlanner.requests(for: normalized, ownerId: ownerId))
        return .scheduled
    }

    func reconcile(ownerId: UUID?) async {
        guard let ownerId else {
            await scheduler.cancelAll()
            return
        }
        let preferences = store.reminders(for: ownerId)
        guard preferences.frequency != .off else {
            await scheduler.cancelAll()
            return
        }
        let status = await scheduler.authorizationStatus()
        guard status == .authorized || status == .provisional || status == .ephemeral else {
            await scheduler.cancelAll()
            return
        }
        await scheduler.replace(LittleMomentReminderPlanner.requests(for: preferences, ownerId: ownerId))
    }

    func cancelAll() async {
        await scheduler.cancelAll()
    }

    private func ensurePermission() async -> Bool {
        let status = await scheduler.authorizationStatus()
        switch status {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            return await scheduler.requestAuthorization()
        case .denied:
            return false
        @unknown default:
            return false
        }
    }
}

final class SystemLittleMomentNotifications: LittleMomentNotificationScheduling, @unchecked Sendable {
    func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    func requestAuthorization() async -> Bool {
        let granted = (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])) ?? false
        return granted
    }

    func replace(_ drafts: [LittleMomentNotificationDraft]) async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let existing = pending.map(\.identifier).filter { $0.hasPrefix(LittleMomentNotificationCopy.identifierPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: existing)
        for draft in drafts {
            let content = UNMutableNotificationContent()
            content.title = draft.title
            content.body = draft.body
            content.sound = .default
            content.userInfo = ["neoRoute": LittleMomentNotificationCopy.route]
            var components = DateComponents()
            components.weekday = draft.weekday
            components.hour = draft.hour
            components.minute = draft.minute
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(identifier: draft.identifier, content: content, trigger: trigger)
            try? await center.add(request)
        }
    }

    func cancelAll() async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let existing = pending.map(\.identifier).filter { $0.hasPrefix(LittleMomentNotificationCopy.identifierPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: existing)
    }
}

final class LittleMomentNotificationRouter: NSObject, UNUserNotificationCenterDelegate, @unchecked Sendable {
    static let shared = LittleMomentNotificationRouter()

    var onOpen: (@MainActor () -> Void)?
    private var pending = false

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .list])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let route = response.notification.request.content.userInfo["neoRoute"] as? String
        if route == LittleMomentNotificationCopy.route {
            Task { @MainActor in
                if let onOpen = self.onOpen {
                    onOpen()
                } else {
                    self.pending = true
                }
            }
        }
        completionHandler()
    }

    @MainActor
    func consumeIfNeeded() {
        guard pending else { return }
        pending = false
        onOpen?()
    }
}
