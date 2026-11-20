import SwiftUI
import UserNotifications

@main
struct NeoApp: App {
    @State private var appModel = AppModel()

    init() {
        UNUserNotificationCenter.current().delegate = LittleMomentNotificationRouter.shared
    }

    var body: some Scene {
        WindowGroup {
            RootView(app: appModel)
                .tint(NeoColor.espresso)
                .onOpenURL { url in
                    Task { await appModel.handleAuthURL(url) }
                }
        }
    }
}
