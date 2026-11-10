import SwiftUI

struct MemoryDetailView: View {
    @State private var viewModel: MemoryDetailViewModel
    var editing: ProfileEditingDependencies
    var board: MomentBoard?
    @Environment(\.dismiss) private var dismiss
    @State private var isEditing = false
    @State private var isFullScreen = false
    @State private var isSharing = false

    init(momentId: UUID, pet: Pet, editing: ProfileEditingDependencies, board: MomentBoard? = nil) {
        self.editing = editing
        self.board = board
        _viewModel = State(
            initialValue: MemoryDetailViewModel(
                momentId: momentId,
                pet: pet,
                pets: editing.pets,
                moments: editing.moments,
                media: editing.media,
                uploader: editing.uploader,
                deletion: editing.momentDeletion,
                board: board
            )
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: NeoSpacing.lg) {
                switch viewModel.presentation {
                case .loading:
                    ProgressView("Loading memory")
                        .frame(maxWidth: .infinity)
                        .padding(.top, NeoSpacing.lg)
                case .unauthorized, .missing:
                    EmptyStateView(
                        title: "Memory unavailable",
                        message: viewModel.loadError ?? "That record is no longer available.",
                        systemImage: "photo"
                    )
                case .failed:
                    VStack(spacing: NeoSpacing.md) {
                        EmptyStateView(
                            title: "Memory unavailable",
                            message: viewModel.loadError ?? "We couldn't open this memory.",
                            systemImage: "wifi.exclamationmark"
                        )
                        Button("Retry") { Task { await viewModel.load() } }
                            .buttonStyle(NeoPrimaryButtonStyle())
                    }
                    .padding(.horizontal, NeoSpacing.screenMargin)
                case .loaded:
                    loaded
                }
            }
            .padding(.bottom, NeoSpacing.lg)
        }
        .background(NeoColor.cream.ignoresSafeArea())
        .overlay {
            if viewModel.isDeleting {
                ZStack {
                    NeoColor.cream.opacity(0.72)
                    ProgressView("Deleting memory")
                        .padding(NeoSpacing.lg)
                        .background(NeoColor.white)
                        .clipShape(RoundedRectangle(cornerRadius: NeoSpacing.cardRadius, style: .continuous))
                }
                .ignoresSafeArea()
                .accessibilityIdentifier("deletingMemory")
            }
        }
        .navigationTitle("Memory")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(NeoColor.cream, for: .navigationBar)
        .toolbar {
            if viewModel.moment != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Delete Memory", role: .destructive) {
                            viewModel.requestDelete()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .frame(width: NeoSpacing.minTapTarget, height: NeoSpacing.minTapTarget)
                    }
                    .accessibilityLabel("More")
                    .accessibilityIdentifier("memoryOverflow")
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if viewModel.moment != nil {
                actionBar
            }
        }
        .task { await viewModel.load() }
        .onChange(of: board?.changeToken) { _, _ in
            viewModel.applyBoard()
        }
        .confirmationDialog(
            "Delete this memory?",
            isPresented: Binding(
                get: { viewModel.isConfirmingDelete },
                set: { isPresented in
                    if !isPresented { viewModel.cancelDelete() }
                }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete Memory", role: .destructive) {
                Task { await viewModel.performDelete() }
            }
            Button("Cancel", role: .cancel) {
                viewModel.cancelDelete()
            }
        } message: {
            Text("This removes the memory and its photos from your scrapbook.")
        }
        .onChange(of: viewModel.didDelete) { _, deleted in
            if deleted { dismiss() }
        }
        .fullScreenCover(isPresented: $isFullScreen) {
            MomentPhotoFullscreen(urls: viewModel.photoURLs, index: photoIndexBinding)
        }
        .sheet(isPresented: $isEditing) {
            if let moment = viewModel.moment {
                NavigationStack {
                    CreatePetMomentView(
                        ownerId: moment.ownerId,
                        petId: moment.petId,
                        editing: editing,
                        moment: moment,
                        photoURLs: photoURLMap,
                        board: board
                    )
                }
            }
        }
        .onChange(of: isEditing) { _, showing in
            if !showing {
                Task { await viewModel.load() }
            }
        }
        .sheet(isPresented: $isSharing) {
            if let image = viewModel.shareImage {
                MomentShareSheet(image: image)
            }
        }
    }

    private var loaded: some View {
        VStack(alignment: .leading, spacing: NeoSpacing.lg) {
            MomentPhotoCarousel(
                urls: viewModel.photoURLs,
                index: photoIndexBinding,
                positionLabel: viewModel.positionLabel
            ) {
                isFullScreen = true
            }
            VStack(alignment: .leading, spacing: NeoSpacing.md) {
                if let moment = viewModel.moment {
                    Text(moment.title)
                        .font(.system(.largeTitle, design: .serif).weight(.bold))
                        .foregroundStyle(NeoColor.black)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("memoryTitle")
                    HStack(alignment: .center, spacing: NeoSpacing.sm) {
                        Text(viewModel.dateText)
                        Text("·")
                        Text(moment.category.rawValue)
                        Spacer(minLength: NeoSpacing.sm)
                        Button {
                            Task { await viewModel.toggleFavorite() }
                        } label: {
                            Image(systemName: moment.isFavorite ? "heart.fill" : "heart")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(NeoColor.espresso)
                                .frame(width: NeoSpacing.minTapTarget, height: NeoSpacing.minTapTarget)
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.isUpdatingFavorite)
                        .accessibilityLabel(moment.isFavorite ? "Unfavorite \(moment.title)" : "Favorite \(moment.title)")
                        .accessibilityIdentifier("memoryFavorite")
                    }
                    .font(NeoFont.callout)
                    .foregroundStyle(NeoColor.warmBrown)
                    if !moment.caption.isEmpty {
                        Text(moment.caption)
                            .font(NeoFont.body)
                            .foregroundStyle(NeoColor.black)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if !viewModel.tags.isEmpty {
                        tagChips
                    }
                }
                InlineErrorText(message: viewModel.actionError)
                if viewModel.deleteFailed {
                    Button("Try Again") { Task { await viewModel.performDelete() } }
                        .buttonStyle(NeoSecondaryButtonStyle())
                        .disabled(viewModel.isDeleting)
                        .accessibilityIdentifier("retryDeleteMemory")
                }
            }
            .padding(.horizontal, NeoSpacing.screenMargin)
        }
    }

    private var tagChips: some View {
        FlowingChips(titles: viewModel.tags)
    }

    private var actionBar: some View {
        HStack(spacing: NeoSpacing.sm) {
            Button {
                Task {
                    await viewModel.prepareShare()
                    isSharing = viewModel.shareImage != nil
                }
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(NeoPrimaryButtonStyle())
            .accessibilityIdentifier("shareMemory")
            Button("Edit") { isEditing = true }
                .buttonStyle(NeoSecondaryButtonStyle())
                .accessibilityIdentifier("editMemory")
        }
        .padding(.horizontal, NeoSpacing.screenMargin)
        .padding(.vertical, NeoSpacing.sm)
        .background(NeoColor.cream)
    }

    private var photoIndexBinding: Binding<Int> {
        Binding(
            get: { viewModel.photoIndex },
            set: { viewModel.selectPhoto($0) }
        )
    }

    private var photoURLMap: [UUID: URL] {
        var map: [UUID: URL] = [:]
        for (photo, url) in zip(viewModel.photos, viewModel.photoURLs) {
            if let url {
                map[photo.id] = url
            }
        }
        return map
    }
}

struct MomentPhotoCarousel: View {
    var urls: [URL?]
    @Binding var index: Int
    var positionLabel: String
    var onOpen: () -> Void

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if urls.isEmpty {
                RemoteImage(url: nil, cornerRadius: 0)
                    .frame(height: 280)
            } else {
                TabView(selection: $index) {
                    ForEach(Array(urls.enumerated()), id: \.offset) { offset, url in
                        RemoteImage(url: url, cornerRadius: 0)
                            .contentShape(Rectangle())
                            .onTapGesture(perform: onOpen)
                            .tag(offset)
                            .accessibilityLabel("Photo \(offset + 1)")
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 320)
            }
            if !urls.isEmpty {
                Text(positionLabel)
                    .font(NeoFont.caption.weight(.semibold))
                    .foregroundStyle(NeoColor.white)
                    .padding(.horizontal, NeoSpacing.md)
                    .padding(.vertical, NeoSpacing.sm)
                    .background(NeoColor.espresso.opacity(0.88))
                    .clipShape(Capsule())
                    .padding(NeoSpacing.md)
                    .accessibilityLabel("Photo \(positionLabel)")
            }
        }
        .clipShape(
            UnevenRoundedRectangle(
                bottomLeadingRadius: NeoSpacing.cardRadius,
                bottomTrailingRadius: NeoSpacing.cardRadius
            )
        )
        .accessibilityIdentifier("memoryPhotoCarousel")
    }
}

private struct MomentPhotoFullscreen: View {
    var urls: [URL?]
    @Binding var index: Int
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            NeoColor.black.ignoresSafeArea()
            TabView(selection: $index) {
                ForEach(Array(urls.enumerated()), id: \.offset) { offset, url in
                    ZoomableMomentPhoto(url: url)
                        .tag(offset)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            VStack {
                HStack {
                    Button("Close") { dismiss() }
                        .font(NeoFont.button)
                        .foregroundStyle(NeoColor.white)
                        .frame(minWidth: NeoSpacing.minTapTarget, minHeight: NeoSpacing.minTapTarget)
                    Spacer()
                    if !urls.isEmpty {
                        Text("\(min(index + 1, urls.count)) / \(urls.count)")
                            .font(NeoFont.caption.weight(.semibold))
                            .foregroundStyle(NeoColor.white)
                            .padding(.horizontal, NeoSpacing.md)
                            .padding(.vertical, NeoSpacing.sm)
                            .background(NeoColor.espresso.opacity(0.88))
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, NeoSpacing.screenMargin)
                Spacer()
            }
        }
    }
}

private struct ZoomableMomentPhoto: View {
    var url: URL?

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            default:
                Image(systemName: "pawprint")
                    .font(.largeTitle)
                    .foregroundStyle(NeoColor.warmBrown)
            }
        }
    }
}

struct ShareableMomentCard: View {
    var petName: String
    var title: String
    var dateText: String
    var captionExcerpt: String
    var photo: UIImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            ZStack(alignment: .topTrailing) {
                Group {
                    if let photo {
                        Image(uiImage: photo)
                            .resizable()
                            .scaledToFill()
                    } else {
                        NeoColor.subtleBeige
                            .overlay {
                                Image(systemName: "pawprint.fill")
                                    .font(.system(size: 48))
                                    .foregroundStyle(NeoColor.warmBrown)
                            }
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 390)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(NeoColor.espresso)
                    .padding(14)
                    .background(NeoColor.cream.opacity(0.92))
                    .clipShape(Circle())
                    .padding(14)
            }
            Text(petName)
                .font(.system(size: 18, weight: .semibold, design: .serif))
                .foregroundStyle(NeoColor.warmBrown)
            Text(title)
                .font(.system(size: 34, weight: .bold, design: .serif))
                .foregroundStyle(NeoColor.black)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
            Text(dateText)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(NeoColor.espresso)
            if !captionExcerpt.isEmpty {
                Text(captionExcerpt)
                    .font(.system(size: 16))
                    .foregroundStyle(NeoColor.black)
                    .lineLimit(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            HStack(spacing: 8) {
                Image(systemName: "pawprint")
                Text("Neo")
            }
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(NeoColor.espresso)
        }
        .padding(24)
        .frame(width: 360, height: 640, alignment: .topLeading)
        .background(NeoColor.cream)
    }
}

private struct FlowingChips: View {
    var titles: [String]

    var body: some View {
        HStack(spacing: NeoSpacing.sm) {
            ForEach(titles, id: \.self) { title in
                Text(title)
                    .font(NeoFont.caption.weight(.semibold))
                    .foregroundStyle(NeoColor.espresso)
                    .padding(.horizontal, NeoSpacing.md)
                    .padding(.vertical, NeoSpacing.sm)
                    .background(NeoColor.white)
                    .clipShape(Capsule())
            }
        }
    }
}

private struct MomentShareSheet: UIViewControllerRepresentable {
    var image: UIImage

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [image], applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
