import SwiftUI

struct PetProfileView: View {
    var library: PetLibrary
    @Bindable var viewModel: PetProfileViewModel
    var editing: ProfileEditingDependencies
    var app: AppModel
    var onSignOut: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                ProgressView("Loading profile")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .failed(let message):
                failed(message)
            case .empty:
                empty
            case .loaded:
                if let pet = library.activePet {
                    loaded(pet)
                } else {
                    empty
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(NeoColor.cream.ignoresSafeArea())
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(NeoColor.cream, for: .navigationBar)
        .toolbar {
            if library.pets.count > 1 {
                ToolbarItem(placement: .topBarLeading) {
                    petSwitcher
                }
            }
            ToolbarItemGroup(placement: .topBarTrailing) {
                NavigationLink {
                    AccountSettingsView(app: app)
                } label: {
                    Image(systemName: "person.crop.circle")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(NeoColor.espresso)
                        .frame(width: NeoSpacing.minTapTarget, height: NeoSpacing.minTapTarget)
                }
                .accessibilityLabel("Account settings")
                Button("Log Out", action: onSignOut)
                    .font(NeoFont.caption.weight(.semibold))
                    .foregroundStyle(NeoColor.warmBrown)
                    .accessibilityLabel("Log out")
            }
        }
        .task {
            await viewModel.load()
        }
        .onChange(of: library.activePet?.id) { _, _ in
            Task { await viewModel.loadDetails() }
        }
        .onChange(of: library.activePet?.updatedAt) { _, _ in
            Task { await viewModel.loadDetails() }
        }
    }

    private func loaded(_ pet: Pet) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: NeoSpacing.lg) {
                hero(pet)
                PetIdentityCard(pet: pet) {
                    Task { await viewModel.toggleFavorite() }
                }
                .padding(.horizontal, NeoSpacing.screenMargin)
                .padding(.top, -56)

                NeoCard {
                    PetInfoRow(systemImage: "hourglass", title: "Age", value: PetProfileDisplay.age(for: pet))
                    PetInfoRow(systemImage: "gift", title: "Birthday", value: PetProfileDisplay.birthday(for: pet))
                    PetInfoRow(systemImage: "person", title: "Sex", value: pet.sex.title, isQuiet: pet.sex == .unknown)
                    PetInfoRow(systemImage: "heart", title: "Spayed or neutered", value: pet.reproductiveStatus.title, isQuiet: pet.reproductiveStatus == .unknown)
                    PetInfoRow(systemImage: "ruler", title: "Size", value: pet.sizeCategory.title, isQuiet: pet.sizeCategory == .unknown)
                    PetInfoRow(systemImage: "tag", title: "Breed", value: PetProfileDetails.breedLine(for: pet), isQuiet: pet.breedIdentity == .unknown && pet.breed.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    PetInfoRow(systemImage: "scalemass", title: "Weight", value: PetProfileDisplay.weight(for: pet))
                    PetInfoRow(systemImage: "star", title: "Favorite toy", value: PetProfileDisplay.favoriteToy(for: pet))
                }
                .padding(.horizontal, NeoSpacing.screenMargin)

                PetCareLinks(pet: pet, editing: editing)
                    .padding(.horizontal, NeoSpacing.screenMargin)

                quickStats(for: pet)
                    .padding(.horizontal, NeoSpacing.screenMargin)

                if let statsError = viewModel.statsError {
                    VStack(alignment: .leading, spacing: NeoSpacing.sm) {
                        InlineErrorText(message: statsError)
                        Button("Retry") { Task { await viewModel.retry() } }
                            .buttonStyle(NeoSecondaryButtonStyle())
                    }
                    .padding(.horizontal, NeoSpacing.screenMargin)
                }

                VStack(alignment: .leading, spacing: NeoSpacing.sm) {
                    InlineErrorText(message: viewModel.deleteError)
                    if viewModel.deleteError != nil {
                        Button("Try Again") { Task { await viewModel.performDelete() } }
                            .buttonStyle(NeoSecondaryButtonStyle())
                            .disabled(viewModel.isDeleting)
                            .accessibilityIdentifier("retryDeletePet")
                    }
                    Button("Delete Pet", role: .destructive) {
                        viewModel.requestDelete()
                    }
                    .buttonStyle(NeoDestructiveButtonStyle())
                    .disabled(viewModel.isDeleting)
                    .accessibilityIdentifier("deletePet")
                }
                .padding(.horizontal, NeoSpacing.screenMargin)
            }
            .padding(.bottom, NeoSpacing.xl)
        }
        .refreshable {
            await viewModel.load()
        }
        .overlay {
            if viewModel.isDeleting {
                ZStack {
                    NeoColor.cream.opacity(0.72)
                    ProgressView("Deleting pet")
                        .padding(NeoSpacing.lg)
                        .background(NeoColor.white)
                        .clipShape(RoundedRectangle(cornerRadius: NeoSpacing.cardRadius, style: .continuous))
                }
                .accessibilityIdentifier("deletingPet")
            }
        }
        .confirmationDialog(
            "Delete \(library.activePet?.name ?? "this pet")?",
            isPresented: Binding(
                get: { viewModel.isConfirmingDelete },
                set: { isPresented in
                    if !isPresented { viewModel.cancelDelete() }
                }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete Pet", role: .destructive) {
                Task { await viewModel.performDelete() }
            }
            Button("Cancel", role: .cancel) {
                viewModel.cancelDelete()
            }
        } message: {
            Text("This deletes the pet, memories, photos, check-ins, and weight history.")
        }
    }

    private func hero(_ pet: Pet) -> some View {
        ZStack(alignment: .topTrailing) {
            heroPhoto(pet)
            LinearGradient(
                colors: [NeoColor.black.opacity(0.38), NeoColor.black.opacity(0)],
                startPoint: .top,
                endPoint: .center
            )
            .allowsHitTesting(false)
            .accessibilityHidden(true)

            NavigationLink {
                editDestination(pet: pet)
            } label: {
                Image(systemName: "pencil")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(NeoColor.espresso)
                    .frame(width: NeoSpacing.minTapTarget, height: NeoSpacing.minTapTarget)
                    .background(NeoColor.white)
                    .clipShape(Circle())
                    .shadow(color: NeoColor.black.opacity(0.12), radius: 8, y: 3)
            }
            .padding(.top, NeoSpacing.md)
            .padding(.trailing, NeoSpacing.md)
            .accessibilityLabel("Edit profile")
            .accessibilityIdentifier("editProfile")
        }
    }

    private func heroPhoto(_ pet: Pet) -> some View {
        Color.clear
            .frame(height: 380)
            .frame(maxWidth: .infinity)
            .overlay {
                if let url = viewModel.photoURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()
                        default:
                            heroPlaceholder
                        }
                    }
                } else {
                    heroPlaceholder
                }
            }
            .clipped()
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(viewModel.photoURL == nil ? "No photo for \(pet.name)" : "Photo of \(pet.name)")
    }

    private var heroPlaceholder: some View {
        ZStack {
            NeoColor.subtleBeige
            Image(systemName: "pawprint.fill")
                .font(.system(size: 56))
                .foregroundStyle(NeoColor.warmBrown)
        }
    }

    @ViewBuilder
    private func quickStats(for pet: Pet) -> some View {
        let cards = Group {
            PetStatCard(systemImage: "photo", value: "\(viewModel.momentCount)", title: "Moments")
            PetStatCard(systemImage: "flag", value: "\(viewModel.milestoneCount)", title: "Milestones")
            PetStatCard(
                systemImage: "calendar",
                value: PetProfileDisplay.daysTogether(for: pet),
                title: "Days Together"
            )
        }
        if dynamicTypeSize.isAccessibilitySize {
            VStack(spacing: NeoSpacing.sm) { cards }
        } else {
            HStack(alignment: .top, spacing: NeoSpacing.sm) { cards }
        }
    }

    private var empty: some View {
        ScreenScaffold {
            NeoLogoMark(maxWidth: 168)
                .frame(maxWidth: .infinity)
            EmptyStateView(
                title: "Their story starts here",
                message: "Create a profile for the companion you want to remember.",
                systemImage: "pawprint"
            )
            NavigationLink {
                editDestination(pet: nil)
            } label: {
                Text("Create Pet Profile")
            }
            .buttonStyle(NeoPrimaryButtonStyle())
            .accessibilityIdentifier("createPetProfile")
        }
    }

    private func failed(_ message: String) -> some View {
        ScreenScaffold {
            EmptyStateView(
                title: "Profile unavailable",
                message: message,
                systemImage: "wifi.exclamationmark"
            )
            Button("Retry") { Task { await viewModel.retry() } }
                .buttonStyle(NeoPrimaryButtonStyle())
                .accessibilityLabel("Retry loading profile")
        }
    }

    private var petSwitcher: some View {
        Menu {
            ForEach(library.pets) { pet in
                Button {
                    viewModel.select(pet)
                } label: {
                    if pet.id == library.activePet?.id {
                        Label(pet.name, systemImage: "checkmark")
                    } else {
                        Text(pet.name)
                    }
                }
            }
        } label: {
            Label(library.activePet?.name ?? "Pets", systemImage: "pawprint")
                .font(NeoFont.caption.weight(.semibold))
                .foregroundStyle(NeoColor.espresso)
                .frame(minHeight: NeoSpacing.minTapTarget)
        }
        .accessibilityLabel("Switch pet, current pet \(library.activePet?.name ?? "none")")
    }

    private func editDestination(pet: Pet?) -> some View {
        EditPetProfileView(
            ownerId: library.ownerId,
            pet: pet,
            editing: editing,
            library: library
        )
    }
}

private struct PetIdentityCard: View {
    var pet: Pet
    var onToggleFavorite: () -> Void

    var body: some View {
        NeoCard {
            HStack(alignment: .top, spacing: NeoSpacing.md) {
                VStack(alignment: .leading, spacing: NeoSpacing.xs) {
                    HStack(alignment: .firstTextBaseline, spacing: NeoSpacing.sm) {
                        Text(pet.name)
                            .font(NeoFont.displayName)
                            .foregroundStyle(NeoColor.black)
                            .fixedSize(horizontal: false, vertical: true)
                        Image(systemName: "pawprint.fill")
                            .font(.body)
                            .foregroundStyle(NeoColor.warmBrown)
                            .accessibilityHidden(true)
                    }
                    Text(pet.breed.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? PetProfileDisplay.missing : pet.breed)
                        .font(NeoFont.callout)
                        .foregroundStyle(NeoColor.warmBrown)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)

                Button(action: onToggleFavorite) {
                    Image(systemName: pet.isFavorite ? "heart.fill" : "heart")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(pet.isFavorite ? NeoColor.espresso : NeoColor.warmBrown)
                        .frame(width: NeoSpacing.minTapTarget, height: NeoSpacing.minTapTarget)
                        .background(NeoColor.subtleBeige)
                        .clipShape(Circle())
                }
                .accessibilityLabel(pet.isFavorite ? "Remove \(pet.name) from favorites" : "Favorite \(pet.name)")
            }
        }
    }
}

#if DEBUG
#Preview("Sample pet") {
    PetProfileSamplePreview(kind: .filled)
}

#Preview("Sample empty profile") {
    PetProfileSamplePreview(kind: .empty)
}

private struct PetProfileSamplePreview: View {
    enum Kind {
        case filled
        case empty
    }

    var kind: Kind
    @State private var library: PetLibrary?
    @State private var viewModel: PetProfileViewModel?
    @State private var editing: ProfileEditingDependencies?

    var body: some View {
        NavigationStack {
            if let library, let viewModel, let editing {
                PetProfileView(
                    library: library,
                    viewModel: viewModel,
                    editing: editing,
                    app: AppModel(dependencies: nil, configurationState: .missing),
                    onSignOut: {}
                )
            } else {
                ProgressView("Loading sample data")
            }
        }
        .task {
            let sample = await PetProfileSampleFactory.make(kind: kind)
            library = sample.library
            viewModel = sample.viewModel
            editing = sample.editing
        }
    }
}

@MainActor
private enum PetProfileSampleFactory {
    static func make(kind: PetProfileSamplePreview.Kind) async -> (
        library: PetLibrary,
        viewModel: PetProfileViewModel,
        editing: ProfileEditingDependencies
    ) {
        let owner = UUID(uuidString: "00000000-0000-0000-0000-0000000000A1")!
        let pets = InMemoryPetRepository()
        let moments = InMemoryMomentRepository()
        let memories = InMemoryMemoryRepository()
        let mediaStore = InMemoryMediaStore()
        if kind == .filled {
            let now = Date(timeIntervalSince1970: 1_762_000_000)
            let pet = Pet(
                id: UUID(uuidString: "00000000-0000-0000-0000-0000000000B1")!,
                ownerId: owner,
                name: "Milo (sample)",
                species: .dog,
                breed: "Sample mix",
                birthday: now.addingTimeInterval(-86_400 * 800),
                gender: .male,
                adoptionDate: now.addingTimeInterval(-86_400 * 120),
                weightValue: 28,
                weightUnit: .pounds,
                microchipId: nil,
                photoPath: nil,
                bio: "Sample data for the profile preview.",
                favoriteToy: "Sample rope",
                isFavorite: true,
                createdAt: now,
                updatedAt: now
            )
            _ = try? await pets.upsert(pet)
            _ = try? await moments.upsert(
                PetMoment(
                    id: UUID(),
                    ownerId: owner,
                    petId: pet.id,
                    title: "Sample moment",
                    caption: "Sample data for the profile preview.",
                    category: .daily,
                    momentDate: now,
                    isFavorite: false,
                    media: [],
                    createdAt: now,
                    updatedAt: now
                )
            )
            _ = try? await memories.upsert(
                Memory(
                    id: UUID(),
                    ownerId: owner,
                    petId: pet.id,
                    title: "Sample milestone",
                    notes: "Sample data only.",
                    category: .memory,
                    sentiment: nil,
                    photoPath: nil,
                    occurredAt: now,
                    createdAt: now,
                    updatedAt: now
                )
            )
        }
        let library = PetLibrary(ownerId: owner, repository: pets, selection: InMemoryActivePetStore())
        let editing = ProfileEditingDependencies(
            pets: pets,
            uploader: mediaStore,
            media: SignedMediaURLCache(signer: mediaStore),
            moments: moments,
            memories: memories
        )
        let viewModel = PetProfileViewModel(
            library: library,
            moments: moments,
            media: editing.media,
            pets: pets,
            board: MomentBoard(),
            petDeletion: PetDeletionService(
                pets: pets,
                moments: moments,
                uploader: mediaStore,
                removePet: { id, owner in
                    try await pets.deleteOwned(id: id, ownerId: owner)
                }
            )
        )
        return (library, viewModel, editing)
    }
}
#endif
