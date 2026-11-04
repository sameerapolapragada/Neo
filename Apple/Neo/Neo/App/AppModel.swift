import Foundation
import Observation
import Supabase

struct AppDependencies {
    var auth: any AuthServicing
    var pets: any PetRepository
    var moments: any MomentRepository
    var memories: any MemoryRepository
    var media: any MediaURLResolving
    var uploader: any MediaUploading
    var selection: any ActivePetStoring
    var accountDeletion: any AccountDeleting

    var editing: ProfileEditingDependencies {
        ProfileEditingDependencies(
            pets: pets,
            uploader: uploader,
            media: media,
            moments: moments,
            memories: memories
        )
    }
}

extension AppDependencies {
    @MainActor
    static func live(configuration: SupabaseConfiguration) -> AppDependencies {
        let client = SupabaseClientFactory.client(configuration)
        let store = SupabaseMediaStore(client: client)
        let endpoint = configuration.url.appending(path: "functions/v1/delete-account")
        return AppDependencies(
            auth: SupabaseAuthService(client: client),
            pets: SupabasePetRepository(client: client),
            moments: SupabaseMomentRepository(client: client),
            memories: SupabaseMemoryRepository(client: client),
            media: SignedMediaURLCache(signer: store),
            uploader: store,
            selection: UserDefaultsActivePetStore(),
            accountDeletion: SupabaseAccountDeletion(
                endpoint: endpoint,
                anonKey: configuration.anonKey,
                accessToken: {
                    let session = try await client.auth.session
                    return session.accessToken
                }
            )
        )
    }
}

enum SupabaseClientFactory {
    static func client(_ configuration: SupabaseConfiguration) -> SupabaseClient {
        SupabaseClient(supabaseURL: configuration.url, supabaseKey: configuration.anonKey)
    }
}

@MainActor
@Observable
final class AppModel {
    enum Gate: Equatable {
        case launching
        case needsConfiguration
        case rejectedServiceRole
        case signedOut
        case confirmEmail
        case ready
    }

    let dependencies: AppDependencies?
    private(set) var gate: Gate
    private(set) var ownerId: UUID?
    private(set) var library: PetLibrary?
    var authError: String?
    /// True only when the auth server accepted sign-out. Local cleanup does not set this.
    private(set) var remoteSessionRevoked = false

    init(dependencies: AppDependencies?, configurationState: SupabaseConfigurationState) {
        self.dependencies = dependencies
        switch configurationState {
        case .rejectedServiceRole:
            gate = .rejectedServiceRole
        case .missing:
            gate = dependencies == nil ? .needsConfiguration : .launching
        case .ready:
            gate = dependencies == nil ? .needsConfiguration : .launching
        }
    }

    convenience init() {
        let state = SupabaseConfigurationLoader.load()
        if case .ready(let configuration) = state {
            self.init(dependencies: AppDependencies.live(configuration: configuration), configurationState: state)
        } else {
            self.init(dependencies: nil, configurationState: state)
        }
    }

    func bootstrap() async {
        guard let dependencies, gate == .launching || gate == .ready else { return }
        if gate != .ready {
            gate = .launching
        }
        do {
            if let ownerId = try await dependencies.auth.restoreSession() {
                await enter(ownerId: ownerId)
            } else if gate != .ready {
                gate = .signedOut
            }
        } catch {
            authError = "We couldn't restore your session. Please sign in again."
            await finishLocalSession()
            remoteSessionRevoked = false
            gate = .signedOut
        }
    }

    func submitAuth(email: String, password: String, creatingAccount: Bool) async {
        guard let dependencies else { return }
        authError = nil
        do {
            if creatingAccount {
                let result = try await dependencies.auth.signUp(email: email, password: password)
                if result.needsEmailConfirmation {
                    gate = .confirmEmail
                } else if let ownerId = result.ownerId {
                    await enter(ownerId: ownerId)
                } else {
                    gate = .confirmEmail
                }
            } else {
                let ownerId = try await dependencies.auth.signIn(email: email, password: password)
                await enter(ownerId: ownerId)
            }
        } catch {
            authError = AuthErrorMessage.message(for: error, creatingAccount: creatingAccount)
        }
    }

    func signOut() async {
        var revoked = false
        var remoteFailure: String?
        if let auth = dependencies?.auth {
            do {
                try await auth.signOut()
                revoked = true
            } catch {
                remoteFailure = SessionCleanup.remoteSignOutFailed
            }
        }
        await finishLocalSession()
        remoteSessionRevoked = revoked
        authError = remoteFailure
        gate = dependencies == nil ? .needsConfiguration : .signedOut
    }

    func deleteAccount(password: String) async throws {
        guard let dependencies else { throw AccountDeletionError.unavailable }
        guard let email = await dependencies.auth.currentEmail(), !email.isEmpty else {
            throw AccountDeletionError.missingEmail
        }
        _ = try await dependencies.auth.signIn(email: email, password: password)
        try await dependencies.accountDeletion.deleteAuthenticatedAccount()
        await finishLocalSession()
        remoteSessionRevoked = false
        authError = SessionCleanup.accountDeleted
        gate = .signedOut
    }

    private func enter(ownerId: UUID) async {
        guard let dependencies else { return }
        if self.ownerId != ownerId {
            await clearPrivateCaches()
        }
        self.ownerId = ownerId
        remoteSessionRevoked = false
        let library = PetLibrary(ownerId: ownerId, repository: dependencies.pets, selection: dependencies.selection)
        self.library = library
        gate = .ready
        await library.refresh()
    }

    private func finishLocalSession() async {
        ownerId = nil
        library = nil
        await clearPrivateCaches()
    }

    private func clearPrivateCaches() async {
        if let cache = dependencies?.media as? SignedMediaURLCache {
            await cache.clear()
        }
        await TimelineThumbnailCache.shared.clear()
    }
}
