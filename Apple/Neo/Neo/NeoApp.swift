import SwiftUI

@main
struct NeoApp: App {
    @State private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView(app: appModel)
                .tint(NeoColor.espresso)
        }
    }
}
