import SwiftUI

enum MomentRoute: Hashable {
    case create(petId: UUID, ownerId: UUID)
    case prompted(petId: UUID, ownerId: UUID, prefill: MomentDraftPrefill)
    case detail(momentId: UUID, petId: UUID, ownerId: UUID)
}

struct PetMomentsView: View {
    var library: PetLibrary
    @Bindable var viewModel: PetMomentsViewModel
    var editing: ProfileEditingDependencies
    var board: MomentBoard
    var littleMomentReveal: Int = 0
    @State private var path = NavigationPath()
    @State private var littleMoments = LittleMomentPresenter()
    @State private var consumedLittleMomentReveal = 0

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: NeoSpacing.lg) {
                    header
                    if let prompt = littleMoments.prompt, let pet = library.activePet, let draft = littleMoments.draft {
                        LittleMomentCard(
                            prompt: prompt,
                            isAlternative: littleMoments.isAlternative,
                            onCapture: {
                                path.append(MomentRoute.prompted(petId: pet.id, ownerId: pet.ownerId, prefill: draft))
                            },
                            onAnother: { littleMoments.anotherIdea() },
                            onDismiss: { littleMoments.dismissForToday() },
                            onReturn: { littleMoments.returnToScheduled() }
                        )
                        .padding(.horizontal, NeoSpacing.screenMargin)
                    }
                    MomentCategoryFilterBar(selection: viewModel.filter) { filter in
                        Task { await viewModel.apply(filter, pet: library.activePet) }
                    }
                    MomentTagFilterBar(selection: viewModel.tagFilter) { tag in
                        Task { await viewModel.apply(tag: tag, pet: library.activePet) }
                    }
                    feedContent
                }
                .padding(.vertical, NeoSpacing.lg)
            }
            .background(NeoColor.cream.ignoresSafeArea())
            .navigationDestination(for: MomentRoute.self) { route in
                destination(route)
            }
            .refreshable {
                await viewModel.load(pet: library.activePet)
            }
            .onChange(of: board.changeToken) { _, _ in
                Task { await viewModel.applyBoard() }
            }
            .onChange(of: littleMomentReveal) { _, token in
                guard token > consumedLittleMomentReveal, let pet = library.activePet else { return }
                consumedLittleMomentReveal = token
                littleMoments.refresh(ownerId: pet.ownerId, petId: pet.id, forceFeatured: true)
            }
        }
        .task(id: library.activePet?.id) {
            path = NavigationPath()
            if let pet = library.activePet {
                let forceFeatured = littleMomentReveal > consumedLittleMomentReveal
                consumedLittleMomentReveal = littleMomentReveal
                littleMoments.refresh(ownerId: pet.ownerId, petId: pet.id, forceFeatured: forceFeatured)
            } else {
                littleMoments.clear()
            }
            await viewModel.load(pet: library.activePet)
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: NeoSpacing.md) {
            VStack(alignment: .leading, spacing: NeoSpacing.xs) {
                Text(title)
                    .font(NeoFont.displayName)
                    .foregroundStyle(NeoColor.black)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Our journey, one memory at a time.")
                    .font(NeoFont.callout)
                    .foregroundStyle(NeoColor.warmBrown)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if let pet = library.activePet {
                NavigationLink(value: MomentRoute.create(petId: pet.id, ownerId: pet.ownerId)) {
                    Image(systemName: "plus")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(NeoColor.white)
                        .frame(width: 36, height: 36)
                        .background(NeoColor.espresso)
                        .clipShape(Circle())
                        .frame(width: NeoSpacing.minTapTarget, height: NeoSpacing.minTapTarget)
                }
                .accessibilityLabel("Add moment")
                .accessibilityIdentifier("addMoment")
            }
        }
        .padding(.horizontal, NeoSpacing.screenMargin)
    }

    @ViewBuilder
    private var feedContent: some View {
        switch viewModel.presentation(for: library.activePet) {
        case .noPet:
            EmptyStateView(
                title: "No moments yet",
                message: "Create a pet profile before saving a moment.",
                systemImage: "photo"
            )
            .padding(.horizontal, NeoSpacing.screenMargin)
        case .loading:
            VStack(spacing: NeoSpacing.md) {
                MomentCardSkeleton()
                MomentCardSkeleton()
            }
            .padding(.horizontal, NeoSpacing.screenMargin)
            .accessibilityLabel("Loading moments")
        case .failed:
            VStack(spacing: NeoSpacing.md) {
                EmptyStateView(
                    title: "Moments unavailable",
                    message: viewModel.loadError ?? "We couldn't open this scrapbook.",
                    systemImage: "wifi.exclamationmark"
                )
                Button("Retry") {
                    Task { await viewModel.load(pet: library.activePet) }
                }
                .buttonStyle(NeoPrimaryButtonStyle())
                .accessibilityLabel("Retry loading moments")
            }
            .padding(.horizontal, NeoSpacing.screenMargin)
        case .empty:
            emptyMoments
        case .filteredEmpty:
            EmptyStateView(
                title: "Nothing in \(viewModel.filter.rawValue) yet",
                message: "Try another category, or keep this one for the next day you want to remember.",
                systemImage: "photo.on.rectangle.angled"
            )
            .padding(.horizontal, NeoSpacing.screenMargin)
        case .loaded:
            LazyVStack(spacing: NeoSpacing.lg) {
                if let loadError = viewModel.loadError {
                    InlineErrorText(message: loadError)
                        .padding(.horizontal, NeoSpacing.screenMargin)
                    Button("Retry") {
                        Task { await viewModel.load(pet: library.activePet) }
                    }
                    .buttonStyle(NeoSecondaryButtonStyle())
                    .padding(.horizontal, NeoSpacing.screenMargin)
                }
                if let favoriteError = viewModel.favoriteError {
                    InlineErrorText(message: favoriteError)
                        .padding(.horizontal, NeoSpacing.screenMargin)
                }
                ForEach(viewModel.moments) { moment in
                    momentLink(moment)
                        .onAppear {
                            guard moment.id == viewModel.moments.last?.id else { return }
                            Task { await viewModel.loadMore() }
                        }
                }
                if viewModel.isLoadingMore {
                    ProgressView("Loading more")
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, NeoSpacing.md)
                }
            }
        }
    }

    private var emptyMoments: some View {
        VStack(spacing: NeoSpacing.md) {
            EmptyStateView(
                title: "No moments yet",
                message: "The first one can be small: a walk, a nap, the way they looked at you.",
                systemImage: "photo.on.rectangle.angled"
            )
            if let pet = library.activePet {
                NavigationLink(value: MomentRoute.create(petId: pet.id, ownerId: pet.ownerId)) {
                    Text("Add First Moment")
                }
                .buttonStyle(NeoPrimaryButtonStyle())
                .accessibilityIdentifier("addFirstMoment")
            }
        }
        .padding(.horizontal, NeoSpacing.screenMargin)
    }

    private func momentLink(_ moment: PetMoment) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            NavigationLink(value: MomentRoute.detail(momentId: moment.id, petId: moment.petId, ownerId: moment.ownerId)) {
                MomentCardBody(moment: moment, imageURL: viewModel.coverURL(for: moment.id))
            }
            .buttonStyle(.plain)
            HStack {
                Text(moment.dateLabel())
                    .font(NeoFont.caption)
                    .foregroundStyle(NeoColor.warmBrown)
                Spacer()
                Button {
                    Task { await viewModel.toggleFavorite(moment) }
                } label: {
                    Image(systemName: moment.isFavorite ? "heart.fill" : "heart")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(NeoColor.espresso)
                        .frame(width: NeoSpacing.minTapTarget, height: NeoSpacing.minTapTarget)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(moment.isFavorite ? "Unfavorite \(moment.title)" : "Favorite \(moment.title)")
                .accessibilityIdentifier("favoriteMoment")
            }
            .padding(.horizontal, NeoSpacing.md)
            .padding(.bottom, NeoSpacing.sm)
        }
        .background(NeoColor.white)
        .clipShape(RoundedRectangle(cornerRadius: NeoSpacing.cardRadius, style: .continuous))
        .shadow(color: NeoColor.espresso.opacity(0.08), radius: 16, y: 8)
        .padding(.horizontal, NeoSpacing.screenMargin)
        .accessibilityElement(children: .contain)
    }

    private var title: String {
        if let name = library.activePet?.name, !name.isEmpty {
            return "\(name)'s Moments"
        }
        return "Moments"
    }

    @ViewBuilder
    private func destination(_ route: MomentRoute) -> some View {
        switch route {
        case .create(let petId, let ownerId):
            CreatePetMomentView(ownerId: ownerId, petId: petId, editing: editing, board: board)
        case .prompted(let petId, let ownerId, let prefill):
            CreatePetMomentView(ownerId: ownerId, petId: petId, editing: editing, board: board, prefill: prefill)
        case .detail(let momentId, let petId, let ownerId):
            if let pet = library.activePet, pet.id == petId, pet.ownerId == ownerId {
                MemoryDetailView(momentId: momentId, pet: pet, editing: editing, board: board)
            } else {
                EmptyStateView(
                    title: "Memory unavailable",
                    message: "That memory isn't on this account.",
                    systemImage: "photo"
                )
            }
        }
    }
}

struct MomentCategoryFilterBar: View {
    var selection: MomentCategoryFilter
    var onSelect: (MomentCategoryFilter) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: NeoSpacing.sm) {
                ForEach(MomentCategoryFilter.allCases) { filter in
                    let isSelected = filter == selection
                    Button {
                        onSelect(filter)
                    } label: {
                        Text(filter.rawValue)
                            .font(NeoFont.caption.weight(.semibold))
                            .foregroundStyle(isSelected ? NeoColor.white : NeoColor.espresso)
                            .padding(.horizontal, NeoSpacing.md)
                            .frame(minHeight: NeoSpacing.minTapTarget)
                            .background(isSelected ? NeoColor.espresso : NeoColor.white)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(filter.rawValue)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                    .accessibilityIdentifier("momentFilter\(filter.rawValue)")
                }
            }
            .padding(.horizontal, NeoSpacing.screenMargin)
        }
    }
}

struct MomentTagFilterBar: View {
    var selection: MomentTag?
    var onSelect: (MomentTag?) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: NeoSpacing.sm) {
                tagButton(title: "Any tag", selected: selection == nil, identifier: "momentTagAll") {
                    onSelect(nil)
                }
                ForEach(MomentTag.allCases) { tag in
                    tagButton(
                        title: tag.title,
                        selected: selection == tag,
                        identifier: "momentTag\(tag.rawValue)"
                    ) {
                        onSelect(selection == tag ? nil : tag)
                    }
                }
            }
            .padding(.horizontal, NeoSpacing.screenMargin)
        }
    }

    private func tagButton(title: String, selected: Bool, identifier: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(NeoFont.caption.weight(.semibold))
                .foregroundStyle(selected ? NeoColor.white : NeoColor.warmBrown)
                .padding(.horizontal, NeoSpacing.md)
                .frame(minHeight: 36)
                .background(selected ? NeoColor.warmBrown : NeoColor.cream)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(NeoColor.subtleBeige, lineWidth: selected ? 0 : 1))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityIdentifier(identifier)
    }
}

struct MomentTagPicker: View {
    var tags: [MomentTag]
    var onToggle: (MomentTag) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: NeoSpacing.sm) {
            Text("Tags")
                .font(NeoFont.caption.weight(.semibold))
                .foregroundStyle(NeoColor.warmBrown)
            Text("Choose up to five. Tags are optional.")
                .font(NeoFont.caption)
                .foregroundStyle(NeoColor.warmBrown)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: NeoSpacing.sm)], spacing: NeoSpacing.sm) {
                ForEach(MomentTag.allCases) { tag in
                    let selected = tags.contains(tag)
                    let enabled = selected || tags.count < MomentTag.maximumPerMoment
                    Button {
                        onToggle(tag)
                    } label: {
                        Text(tag.title)
                            .font(NeoFont.caption.weight(.semibold))
                            .foregroundStyle(selected ? NeoColor.white : NeoColor.espresso)
                            .frame(maxWidth: .infinity, minHeight: NeoSpacing.minTapTarget)
                            .background(selected ? NeoColor.espresso : NeoColor.white)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(NeoColor.subtleBeige, lineWidth: selected ? 0 : 1))
                    }
                    .buttonStyle(.plain)
                    .disabled(!enabled)
                    .accessibilityAddTraits(selected ? .isSelected : [])
                    .accessibilityIdentifier("momentTagChoice\(tag.rawValue)")
                }
            }
        }
    }
}

struct MomentCardView: View {
    var moment: PetMoment
    var imageURL: URL?
    var onToggleFavorite: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            MomentCardBody(moment: moment, imageURL: imageURL)
            HStack {
                Text(moment.dateLabel())
                    .font(NeoFont.caption)
                    .foregroundStyle(NeoColor.warmBrown)
                Spacer()
                Button(action: onToggleFavorite) {
                    Image(systemName: moment.isFavorite ? "heart.fill" : "heart")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(NeoColor.espresso)
                        .frame(width: NeoSpacing.minTapTarget, height: NeoSpacing.minTapTarget)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(moment.isFavorite ? "Unfavorite \(moment.title)" : "Favorite \(moment.title)")
            }
            .padding(.horizontal, NeoSpacing.md)
            .padding(.bottom, NeoSpacing.sm)
        }
        .background(NeoColor.white)
        .clipShape(RoundedRectangle(cornerRadius: NeoSpacing.cardRadius, style: .continuous))
        .shadow(color: NeoColor.espresso.opacity(0.08), radius: 16, y: 8)
    }
}

struct FeedCoverImage: View {
    var url: URL?
    var path: String?
    @State private var image: UIImage?

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "pawprint")
                    .font(.title2)
                    .foregroundStyle(NeoColor.warmBrown)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(NeoColor.subtleBeige)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 220)
        .background(NeoColor.subtleBeige)
        .clipShape(RoundedRectangle(cornerRadius: NeoSpacing.cardRadius, style: .continuous))
        .clipped()
        .accessibilityHidden(true)
        .task(id: path) {
            await load()
        }
    }

    private func load() async {
        guard let path, let url else {
            image = nil
            return
        }
        let key = FeedImageSizing.cacheKey(path: path, maxPixel: FeedImageSizing.coverMaxPixel)
        if let cached = await TimelineThumbnailCache.shared.data(for: key), let decoded = UIImage(data: cached) {
            image = decoded
            return
        }
        guard let thumbnail = await TimelineThumbnailLoader.jpegThumbnail(from: url, maxPixel: FeedImageSizing.coverMaxPixel) else {
            return
        }
        await TimelineThumbnailCache.shared.store(thumbnail, for: key)
        image = UIImage(data: thumbnail)
    }
}

private struct MomentCardBody: View {
    var moment: PetMoment
    var imageURL: URL?

    var body: some View {
        VStack(alignment: .leading, spacing: NeoSpacing.sm) {
            ZStack(alignment: .topLeading) {
                FeedCoverImage(url: imageURL, path: moment.coverPath)
                Text(moment.category.rawValue)
                    .font(NeoFont.caption.weight(.semibold))
                    .foregroundStyle(NeoColor.espresso)
                    .padding(.horizontal, NeoSpacing.sm)
                    .padding(.vertical, NeoSpacing.xs)
                    .background(NeoColor.cream.opacity(0.94))
                    .clipShape(Capsule())
                    .padding(NeoSpacing.sm)
                    .accessibilityHidden(true)
            }
            Text(moment.title)
                .font(NeoFont.cardTitle)
                .foregroundStyle(NeoColor.black)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, NeoSpacing.md)
            if !moment.caption.isEmpty {
                Text(moment.caption)
                    .font(NeoFont.body)
                    .foregroundStyle(NeoColor.warmBrown)
                    .lineLimit(2)
                    .padding(.horizontal, NeoSpacing.md)
            }
        }
        .padding(.bottom, NeoSpacing.xs)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(moment.title), \(moment.category.rawValue), \(moment.dateLabel())")
    }
}

private struct MomentCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: NeoSpacing.sm) {
            RoundedRectangle(cornerRadius: NeoSpacing.cardRadius, style: .continuous)
                .fill(NeoColor.subtleBeige)
                .frame(height: 220)
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(NeoColor.subtleBeige)
                .frame(width: 180, height: 18)
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(NeoColor.subtleBeige)
                .frame(height: 14)
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(NeoColor.subtleBeige)
                .frame(width: 96, height: 12)
        }
        .padding(NeoSpacing.md)
        .background(NeoColor.white)
        .clipShape(RoundedRectangle(cornerRadius: NeoSpacing.cardRadius, style: .continuous))
        .shadow(color: NeoColor.espresso.opacity(0.06), radius: 14, y: 6)
        .accessibilityHidden(true)
    }
}

struct CreatePetMomentView: View {
    @State private var viewModel: CreatePetMomentViewModel
    @State private var confirmingCancel = false
    @Environment(\.dismiss) private var dismiss

    init(
        ownerId: UUID,
        petId: UUID,
        editing: ProfileEditingDependencies,
        moment: PetMoment? = nil,
        photoURLs: [UUID: URL] = [:],
        board: MomentBoard? = nil,
        prefill: MomentDraftPrefill? = nil
    ) {
        let model: CreatePetMomentViewModel
        if let moment {
            model = CreatePetMomentViewModel(
                ownerId: ownerId,
                petId: petId,
                moment: moment,
                photoURLs: photoURLs,
                pets: editing.pets,
                moments: editing.moments,
                uploader: editing.uploader,
                storageCleanup: editing.storageCleanup,
                board: board
            )
        } else {
            model = CreatePetMomentViewModel(
                ownerId: ownerId,
                petId: petId,
                pets: editing.pets,
                moments: editing.moments,
                uploader: editing.uploader,
                storageCleanup: editing.storageCleanup,
                board: board,
                prefill: prefill
            )
        }
        _viewModel = State(initialValue: model)
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        ScrollView {
            VStack(alignment: .leading, spacing: NeoSpacing.lg) {
                PhotoPickerGrid(
                    photos: viewModel.photos,
                    canAddMore: viewModel.canAddPhoto,
                    error: viewModel.photoError ?? viewModel.fieldErrors[.photos],
                    onRemove: { viewModel.removePhoto(id: $0) },
                    onMove: { viewModel.movePhoto(from: $0, to: $1) },
                    onPick: { viewModel.preparePhotos($0) }
                )
                momentField(title: "Title", error: viewModel.fieldErrors[.title], count: trimmedCount(viewModel.title), limit: MomentValidation.titleLimit) {
                    TextField("Title", text: $viewModel.title)
                        .accessibilityIdentifier("momentTitle")
                }
                momentField(title: "Caption", error: viewModel.fieldErrors[.caption], count: trimmedCount(viewModel.caption), limit: MomentValidation.captionLimit) {
                    TextField("Caption", text: $viewModel.caption, axis: .vertical)
                        .lineLimit(3...6)
                }
                momentField(title: "Memory date", error: nil, count: nil, limit: nil) {
                    DatePicker("Memory date", selection: $viewModel.momentDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                momentField(title: "Category", error: nil, count: nil, limit: nil) {
                    Picker("Category", selection: $viewModel.category) {
                        ForEach(MomentCategory.allCases) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                MomentTagPicker(tags: viewModel.tags) { tag in
                    viewModel.tags = MomentTag.toggle(tag, in: viewModel.tags)
                }
                InlineErrorText(message: viewModel.saveError)
            }
            .padding(.horizontal, NeoSpacing.screenMargin)
            .padding(.vertical, NeoSpacing.lg)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(NeoColor.white.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: NeoSpacing.xs) {
                if let progress = viewModel.progressLabel {
                    Text(progress)
                        .font(NeoFont.caption)
                        .foregroundStyle(NeoColor.warmBrown)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                SaveButton(title: viewModel.isEditing ? "Save Changes" : "Save Moment", isSaving: viewModel.isSaving) {
                    Task { await viewModel.save() }
                }
                .accessibilityIdentifier("saveMoment")
            }
            .padding(.horizontal, NeoSpacing.screenMargin)
            .padding(.top, NeoSpacing.sm)
            .padding(.bottom, NeoSpacing.sm)
            .background(NeoColor.cream)
        }
        .navigationTitle(viewModel.isEditing ? "Edit Moment" : "Create Moment")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(NeoColor.cream, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", action: requestCancel)
                    .foregroundStyle(NeoColor.espresso)
                    .accessibilityIdentifier("cancelMoment")
            }
        }
        .confirmationDialog(
            viewModel.isEditing ? "Discard changes?" : "Discard this moment?",
            isPresented: $confirmingCancel,
            titleVisibility: .visible
        ) {
            Button("Discard", role: .destructive) { dismiss() }
            Button("Keep Editing", role: .cancel) {}
        } message: {
            Text("Your photos and writing will not be saved.")
        }
        .onChange(of: viewModel.didSave) { _, saved in
            if saved { dismiss() }
        }
    }

    private func requestCancel() {
        if viewModel.hasUnsavedChanges {
            confirmingCancel = true
        } else {
            dismiss()
        }
    }

    private func trimmedCount(_ text: String) -> Int {
        text.trimmingCharacters(in: .whitespacesAndNewlines).count
    }

    private func momentField<Content: View>(
        title: String,
        error: String?,
        count: Int?,
        limit: Int?,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: NeoSpacing.xs) {
            Text(title)
                .font(NeoFont.caption.weight(.semibold))
                .foregroundStyle(NeoColor.warmBrown)
            content()
                .font(NeoFont.body)
                .foregroundStyle(NeoColor.black)
                .padding(NeoSpacing.md)
                .frame(maxWidth: .infinity, minHeight: NeoSpacing.minTapTarget, alignment: .leading)
                .background(NeoColor.white)
                .clipShape(RoundedRectangle(cornerRadius: NeoSpacing.controlRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: NeoSpacing.controlRadius, style: .continuous)
                        .stroke(error == nil ? NeoColor.subtleBeige : NeoColor.destructive, lineWidth: 1)
                )
            if let count, let limit {
                Text("\(count)/\(limit)")
                    .font(NeoFont.caption)
                    .foregroundStyle(count > limit ? NeoColor.destructive : NeoColor.warmBrown)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            InlineErrorText(message: error)
        }
    }
}

#if DEBUG
#Preview("Sample moments") {
    MomentFeedPreview()
}

private struct MomentFeedPreview: View {
    @State private var library: PetLibrary?
    @State private var viewModel: PetMomentsViewModel?
    @State private var editing: ProfileEditingDependencies?
    @State private var board = MomentBoard()

    var body: some View {
        Group {
            if let library, let viewModel, let editing {
                PetMomentsView(library: library, viewModel: viewModel, editing: editing, board: board)
            } else {
                ProgressView("Loading sample memories")
            }
        }
        .task {
            let sample = await MomentFeedSampleFactory.make()
            library = sample.library
            viewModel = sample.viewModel
            editing = sample.editing
        }
    }
}

@MainActor
private enum MomentFeedSampleFactory {
    static func make() async -> (
        library: PetLibrary,
        viewModel: PetMomentsViewModel,
        editing: ProfileEditingDependencies
    ) {
        let owner = UUID(uuidString: "00000000-0000-0000-0000-0000000000A2")!
        let petId = UUID(uuidString: "00000000-0000-0000-0000-0000000000B2")!
        let pets = InMemoryPetRepository()
        let moments = InMemoryMomentRepository()
        let memories = InMemoryMemoryRepository()
        let mediaStore = InMemoryMediaStore()
        let now = Date(timeIntervalSince1970: 1_762_000_000)
        let pet = Pet(
            id: petId,
            ownerId: owner,
            name: "Milo (sample)",
            species: .dog,
            breed: "Sample mix",
            birthday: nil,
            gender: .male,
            adoptionDate: nil,
            weightValue: nil,
            weightUnit: .pounds,
            microchipId: nil,
            photoPath: nil,
            bio: "",
            favoriteToy: nil,
            isFavorite: false,
            createdAt: now,
            updatedAt: now
        )
        _ = try? await pets.upsert(pet)
        let samples: [(String, String, MomentCategory, Int, Bool)] = [
            ("Sample morning", "Sample data for the moments preview.", .daily, 0, true),
            ("Sample trail", "A sample adventure, not a saved memory.", .adventure, 3, false),
            ("Sample first day", "Sample milestone copy only.", .milestone, 12, false)
        ]
        for (offset, sample) in samples.enumerated() {
            let day = now.addingTimeInterval(Double(-sample.3) * 86_400)
            let momentId = UUID(uuidString: "00000000-0000-0000-0000-00000000010\(offset)")!
            _ = try? await moments.upsert(
                PetMoment(
                    id: momentId,
                    ownerId: owner,
                    petId: petId,
                    title: sample.0,
                    caption: sample.1,
                    category: sample.2,
                    momentDate: day,
                    isFavorite: sample.4,
                    media: [],
                    createdAt: day,
                    updatedAt: day
                )
            )
        }
        let library = PetLibrary(ownerId: owner, repository: pets, selection: InMemoryActivePetStore())
        library.noteSaved(pet)
        let editing = ProfileEditingDependencies(
            pets: pets,
            uploader: mediaStore,
            media: SignedMediaURLCache(signer: mediaStore),
            moments: moments,
            memories: memories
        )
        let viewModel = PetMomentsViewModel(repository: moments, media: editing.media)
        return (library, viewModel, editing)
    }
}
#endif
