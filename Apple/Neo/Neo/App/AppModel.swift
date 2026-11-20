import Foundation
import Observation
import Supabase

struct AppDependencies {
    var auth: any AuthServicing
    var pets: any PetRepository
    var moments: any MomentRepository
    var memories: any MemoryRepository
    var wellness: (any PetWellnessRepository)? = nil
    var media: any MediaURLResolving
    var uploader: any MediaUploading
    var selection: any ActivePetStoring
    var accountDeletion: any AccountDeleting
    var momentDeletion: (any MomentDeleting)? = nil
    var petDeletion: (any PetDeleting)? = nil
    var storageCleanup: (any StorageCleaning)? = nil

    var editing: ProfileEditingDependencies {
        ProfileEditingDependencies(
            pets: pets,
            uploader: uploader,
            media: media,
            moments: moments,
            memories: memories,
            wellness: wellness,
            momentDeletion: momentDeletion,
            petDeletion: petDeletion,
            storageCleanup: storageCleanup
        )
    }
}

extension AppDependencies {
    @MainActor
    static func live(configuration: SupabaseConfiguration) -> AppDependencies {
        let client = SupabaseClientFactory.client(configuration)
        let store = SupabaseMediaStore(client: client)
        let token: @Sendable () async throws -> String = {
            let session = try await client.auth.session
            return session.accessToken
        }
        let deletion = SupabaseCompanionDeletion(
            functionsBase: configuration.url.appending(path: "functions/v1"),
            anonKey: configuration.anonKey,
            accessToken: token
        )
        return AppDependencies(
            auth: SupabaseAuthService(client: client),
            pets: SupabasePetRepository(client: client),
            moments: SupabaseMomentRepository(client: client),
            memories: SupabaseMemoryRepository(client: client),
            wellness: SupabaseWellnessRepository(client: client),
            media: SignedMediaURLCache(signer: store),
            uploader: store,
            selection: UserDefaultsActivePetStore(),
            accountDeletion: SupabaseAccountDeletion(
                endpoint: configuration.url.appending(path: "functions/v1/delete-account"),
                anonKey: configuration.anonKey,
                accessToken: token
            ),
            momentDeletion: deletion,
            petDeletion: deletion,
            storageCleanup: deletion
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
        case chooseNewPassword
        case ready
    }

    let dependencies: AppDependencies?
    private(set) var gate: Gate
    private(set) var ownerId: UUID?
    private(set) var library: PetLibrary?
    var authError: String?
    var littleMomentReveal = 0
    private var pendingLittleMoment = false
    private var handledAuthURLs: Set<String> = []
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
                if UserDefaults.standard.bool(forKey: AuthCallback.pendingRecoveryKey) {
                    self.ownerId = ownerId
                    gate = .chooseNewPassword
                } else {
                    await enter(ownerId: ownerId)
                }
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
                    UserDefaults.standard.set(false, forKey: AuthCallback.pendingRecoveryKey)
                    await enter(ownerId: ownerId)
                } else {
                    gate = .confirmEmail
                }
            } else {
                let ownerId = try await dependencies.auth.signIn(email: email, password: password)
                UserDefaults.standard.set(false, forKey: AuthCallback.pendingRecoveryKey)
                await enter(ownerId: ownerId)
            }
        } catch {
            authError = AuthErrorMessage.message(for: error, creatingAccount: creatingAccount)
        }
    }

    func sendPasswordReset(email: String) async -> Bool {
        guard let dependencies else { return false }
        authError = nil
        do {
            try await dependencies.auth.sendPasswordReset(email: email)
            UserDefaults.standard.set(true, forKey: AuthCallback.pendingRecoveryKey)
            return true
        } catch {
            authError = AuthErrorMessage.recoveryMessage(for: error)
            return false
        }
    }

    func handleAuthURL(_ url: URL) async {
        guard let dependencies else { return }
        guard AuthCallback.matches(url) else { return }
        guard handledAuthURLs.insert(url.absoluteString).inserted else { return }
        let recovery = AuthCallback.isRecovery(url)
            || UserDefaults.standard.bool(forKey: AuthCallback.pendingRecoveryKey)
        if recovery {
            UserDefaults.standard.set(true, forKey: AuthCallback.pendingRecoveryKey)
        }
        do {
            let ownerId = try await dependencies.auth.completeAuthCallback(url)
            authError = nil
            if recovery {
                self.ownerId = ownerId
                gate = .chooseNewPassword
            } else {
                await enter(ownerId: ownerId)
            }
        } catch {
            handledAuthURLs.remove(url.absoluteString)
            authError = AuthErrorMessage.expiredLink
            if gate != .ready {
                gate = .signedOut
            }
        }
    }

    func saveNewPassword(_ password: String) async -> Bool {
        guard let dependencies else { return false }
        authError = nil
        do {
            let ownerId = try await dependencies.auth.updatePassword(password)
            UserDefaults.standard.set(false, forKey: AuthCallback.pendingRecoveryKey)
            await enter(ownerId: ownerId)
            return true
        } catch {
            authError = "We couldn't save that password. Request a new reset link and try again."
            return false
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
        await LittleMomentReminderCoordinator.shared.cancelAll()
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
        try await dependencies.accountDeletion.deleteAuthenticatedAccount(password: password)
        await LittleMomentReminderCoordinator.shared.cancelAll()
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
        if let cache = dependencies.media as? SignedMediaURLCache {
            await cache.bind(ownerId: ownerId)
        }
        self.ownerId = ownerId
        remoteSessionRevoked = false
        let library = PetLibrary(ownerId: ownerId, repository: dependencies.pets, selection: dependencies.selection)
        self.library = library
        gate = .ready
        await library.refresh()
        await LittleMomentReminderCoordinator.shared.reconcile(ownerId: ownerId)
        if pendingLittleMoment {
            pendingLittleMoment = false
            littleMomentReveal += 1
        }
    }

    func reconcileLittleMomentReminders() async {
        let signedIn = gate == .ready ? ownerId : nil
        await LittleMomentReminderCoordinator.shared.reconcile(ownerId: signedIn)
    }

    func openMomentsFromReminder() {
        guard gate == .ready else {
            pendingLittleMoment = true
            return
        }
        littleMomentReveal += 1
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
