import SwiftUI

struct RootView: View {
    var app: AppModel
    @State private var signIn = SignInViewModel()

    var body: some View {
        Group {
            switch app.gate {
            case .launching:
                ProgressView("Opening your scrapbook")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .needsConfiguration:
                NoticeView(
                    title: "Connect Supabase",
                    message: "Add your project URL and anon key in Apple/Neo/Config/Secrets.xcconfig, then rebuild. Use the anon or publishable key. Never put the service-role key in the app."
                )
            case .rejectedServiceRole:
                NoticeView(
                    title: "This key cannot be used",
                    message: "That value is a service-role key. It bypasses row security, so Neo will not start with it. Replace it with the anon or publishable key."
                )
            case .signedOut, .confirmEmail:
                SignInView(viewModel: signIn, app: app)
            case .chooseNewPassword:
                ResetPasswordView(app: app)
            case .ready:
                if let library = app.library, let dependencies = app.dependencies {
                    MainTabView(app: app, library: library, dependencies: dependencies)
                } else {
                    ProgressView("Opening your scrapbook")
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(NeoColor.cream.ignoresSafeArea())
        .task {
            await app.bootstrap()
        }
    }
}

private struct NoticeView: View {
    var title: String
    var message: String

    var body: some View {
        ScreenScaffold {
            Text(title)
                .font(NeoFont.sectionTitle)
                .foregroundStyle(NeoColor.espresso)
            Text(message)
                .font(NeoFont.body)
                .foregroundStyle(NeoColor.black)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct MainTabView: View {
    var app: AppModel
    var library: PetLibrary
    var dependencies: AppDependencies
    @State private var profileModel: PetProfileViewModel
    @State private var momentsModel: PetMomentsViewModel
    @State private var timelineModel: MemoryTimelineViewModel
    @State private var board: MomentBoard

    init(app: AppModel, library: PetLibrary, dependencies: AppDependencies) {
        self.app = app
        self.library = library
        self.dependencies = dependencies
        let board = MomentBoard()
        _board = State(initialValue: board)
        _profileModel = State(
            initialValue: PetProfileViewModel(
                library: library,
                moments: dependencies.moments,
                media: dependencies.media,
                pets: dependencies.pets,
                board: board,
                petDeletion: dependencies.petDeletion
            )
        )
        _momentsModel = State(
            initialValue: PetMomentsViewModel(
                repository: dependencies.moments,
                media: dependencies.media,
                board: board
            )
        )
        _timelineModel = State(
            initialValue: MemoryTimelineViewModel(
                repository: dependencies.moments,
                media: dependencies.media,
                board: board
            )
        )
    }

    var body: some View {
        TabView {
            NavigationStack {
                PetProfileView(
                    library: library,
                    viewModel: profileModel,
                    editing: dependencies.editing,
                    app: app,
                    onSignOut: { Task { await app.signOut() } }
                )
            }
            .tabItem { Label("Profile", systemImage: "pawprint") }

            PetMomentsView(library: library, viewModel: momentsModel, editing: dependencies.editing, board: board)
                .tabItem { Label("Moments", systemImage: "photo.on.rectangle.angled") }

            MemoryTimelineView(library: library, viewModel: timelineModel, editing: dependencies.editing, board: board)
                .tabItem { Label("Timeline", systemImage: "book.closed") }
        }
        .tint(NeoColor.espresso)
        .toolbarBackground(NeoColor.cream, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}
