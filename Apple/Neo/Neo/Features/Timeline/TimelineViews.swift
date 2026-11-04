import SwiftUI

struct MemoryTimelineView: View {
    var library: PetLibrary
    @Bindable var viewModel: MemoryTimelineViewModel
    var editing: ProfileEditingDependencies
    var board: MomentBoard
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    header
                    timelineContent
                }
                .padding(.horizontal, NeoSpacing.screenMargin)
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
        }
        .task(id: library.activePet?.id) {
            path = NavigationPath()
            await viewModel.load(pet: library.activePet)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: NeoSpacing.xs) {
            Text(title)
                .font(NeoFont.displayName)
                .foregroundStyle(NeoColor.black)
                .fixedSize(horizontal: false, vertical: true)
            Text("A chronological journey of our memories.")
                .font(NeoFont.callout)
                .foregroundStyle(NeoColor.warmBrown)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, NeoSpacing.lg)
    }

    @ViewBuilder
    private var timelineContent: some View {
        switch viewModel.presentation(for: library.activePet) {
        case .noPet:
            EmptyStateView(
                title: "No timeline yet",
                message: "Create a pet profile to start the memory timeline.",
                systemImage: "book.closed"
            )
        case .loading:
            VStack(spacing: NeoSpacing.md) {
                TimelineCardSkeleton()
                TimelineCardSkeleton()
            }
            .accessibilityLabel("Loading timeline")
        case .failed:
            VStack(spacing: NeoSpacing.md) {
                EmptyStateView(
                    title: "Timeline unavailable",
                    message: viewModel.loadError ?? "We couldn't open this scrapbook.",
                    systemImage: "wifi.exclamationmark"
                )
                Button("Retry") {
                    Task { await viewModel.load(pet: library.activePet) }
                }
                .buttonStyle(NeoPrimaryButtonStyle())
                .accessibilityLabel("Retry loading timeline")
            }
        case .empty:
            VStack(spacing: NeoSpacing.md) {
                EmptyStateView(
                    title: "The timeline is waiting",
                    message: "Moments you save will appear here, in the order they happened.",
                    systemImage: "book.closed"
                )
                if let pet = library.activePet {
                    NavigationLink(value: MomentRoute.create(petId: pet.id, ownerId: pet.ownerId)) {
                        Text("Add a moment")
                    }
                    .buttonStyle(NeoPrimaryButtonStyle())
                    .accessibilityIdentifier("addTimelineMoment")
                }
            }
        case .loaded:
            if let loadError = viewModel.loadError {
                InlineErrorText(message: loadError)
                    .padding(.bottom, NeoSpacing.sm)
            }
            ForEach(Array(viewModel.years.enumerated()), id: \.element.id) { yearIndex, year in
                TimelineYearHeader(title: year.title, connectsAbove: yearIndex > 0)
                ForEach(year.moments) { moment in
                    let isLast = moment.id == viewModel.moments.last?.id
                    NavigationLink(value: TimelineNavigation.detailRoute(for: moment)) {
                        HStack(alignment: .top, spacing: NeoSpacing.sm) {
                            TimelineMarker(category: moment.category, continues: !isLast)
                            TimelineMemoryCard(
                                moment: moment,
                                dateText: viewModel.dateLabel(for: moment),
                                imageURL: viewModel.coverURL(for: moment.id)
                            )
                            .padding(.bottom, isLast ? 0 : NeoSpacing.md)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("timelineEntry")
                    .onAppear {
                        guard isLast else { return }
                        Task { await viewModel.loadMore() }
                    }
                }
            }
            if viewModel.isLoadingMore {
                ProgressView("Loading older memories")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, NeoSpacing.md)
            }
        }
    }

    private var title: String {
        if let name = library.activePet?.name, !name.isEmpty {
            return "\(name)'s Timeline"
        }
        return "Timeline"
    }

    @ViewBuilder
    private func destination(_ route: MomentRoute) -> some View {
        switch route {
        case .create(let petId, let ownerId):
            CreatePetMomentView(ownerId: ownerId, petId: petId, editing: editing, board: board)
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

struct TimelineYearHeader: View {
    var title: String
    var connectsAbove: Bool

    var body: some View {
        HStack(alignment: .center, spacing: NeoSpacing.sm) {
            VStack(spacing: 0) {
                Rectangle()
                    .fill(connectsAbove ? TimelineMarker.line : Color.clear)
                    .frame(width: TimelineMarker.lineWidth, height: 14)
                Circle()
                    .fill(NeoColor.warmBrown)
                    .frame(width: 8, height: 8)
                Rectangle()
                    .fill(TimelineMarker.line)
                    .frame(width: TimelineMarker.lineWidth, height: 14)
            }
            .frame(width: TimelineMarker.columnWidth)
            .accessibilityHidden(true)
            Text(title)
                .font(NeoFont.caption.weight(.semibold))
                .foregroundStyle(NeoColor.espresso)
                .padding(.horizontal, NeoSpacing.md)
                .padding(.vertical, NeoSpacing.sm)
                .background(NeoColor.white)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(NeoColor.subtleBeige, lineWidth: 1))
            Spacer(minLength: 0)
        }
        .accessibilityAddTraits(.isHeader)
        .accessibilityLabel(title)
    }
}

struct TimelineMarker: View {
    static let columnWidth: CGFloat = 28
    static let lineWidth: CGFloat = 1.5
    static let line = NeoColor.warmBrown.opacity(0.55)

    var category: MomentCategory
    var continues: Bool

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(category == .milestone ? NeoColor.espresso : NeoColor.white)
                Circle()
                    .stroke(category == .milestone ? NeoColor.espresso : NeoColor.warmBrown, lineWidth: 1.5)
                Image(systemName: symbol)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(category == .milestone ? NeoColor.white : NeoColor.warmBrown)
            }
            .frame(width: 28, height: 28)
            if continues {
                Rectangle()
                    .fill(Self.line)
                    .frame(width: Self.lineWidth)
                    .frame(maxHeight: .infinity)
            }
        }
        .frame(width: Self.columnWidth, alignment: .top)
        .frame(maxHeight: .infinity, alignment: .top)
        .accessibilityHidden(true)
    }

    private var symbol: String {
        switch category {
        case .daily: "sun.max"
        case .adventure: "map"
        case .milestone: "star.fill"
        }
    }
}

struct TimelineMemoryCard: View {
    var moment: PetMoment
    var dateText: String
    var imageURL: URL?

    var body: some View {
        HStack(alignment: .top, spacing: NeoSpacing.sm) {
            VStack(alignment: .leading, spacing: NeoSpacing.xs) {
                if moment.category == .milestone {
                    Text("Milestone")
                        .font(NeoFont.caption.weight(.semibold))
                        .foregroundStyle(NeoColor.espresso)
                }
                Text(moment.title)
                    .font(NeoFont.cardTitle)
                    .foregroundStyle(NeoColor.black)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                let preview = TimelineCaption.preview(moment.caption)
                if !preview.isEmpty {
                    Text(preview)
                        .font(NeoFont.caption)
                        .foregroundStyle(NeoColor.warmBrown)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                Text(dateText)
                    .font(NeoFont.caption)
                    .foregroundStyle(NeoColor.warmBrown)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            TimelineThumbnail(url: imageURL, path: moment.coverPath)
        }
        .padding(NeoSpacing.md)
        .frame(maxWidth: .infinity, minHeight: NeoSpacing.minTapTarget, alignment: .leading)
        .background(NeoColor.white)
        .clipShape(RoundedRectangle(cornerRadius: NeoSpacing.controlRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: NeoSpacing.controlRadius, style: .continuous)
                .stroke(
                    moment.category == .milestone ? NeoColor.espresso.opacity(0.35) : NeoColor.subtleBeige,
                    lineWidth: moment.category == .milestone ? 1.5 : 1
                )
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
        .accessibilityHint("Opens this memory")
    }

    private var accessibilityText: String {
        let preview = TimelineCaption.preview(moment.caption)
        if preview.isEmpty {
            return "\(moment.title), \(moment.category.rawValue), \(dateText)"
        }
        return "\(moment.title), \(moment.category.rawValue), \(dateText). \(preview)"
    }
}

private struct TimelineThumbnail: View {
    var url: URL?
    var path: String?
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "pawprint")
                    .font(.body)
                    .foregroundStyle(NeoColor.warmBrown)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(NeoColor.subtleBeige)
            }
        }
        .frame(width: 72, height: 72)
        .background(NeoColor.subtleBeige)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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
        let key = FeedImageSizing.cacheKey(path: path, maxPixel: TimelineImageSizing.thumbnailMaxPixel)
        if let cached = await TimelineThumbnailCache.shared.data(for: key), let decoded = UIImage(data: cached) {
            image = decoded
            return
        }
        guard let thumbnail = await TimelineThumbnailLoader.jpegThumbnail(from: url) else { return }
        await TimelineThumbnailCache.shared.store(thumbnail, for: key)
        image = UIImage(data: thumbnail)
    }
}

private struct TimelineCardSkeleton: View {
    var body: some View {
        HStack(spacing: NeoSpacing.sm) {
            Circle()
                .fill(NeoColor.subtleBeige)
                .frame(width: 28, height: 28)
            RoundedRectangle(cornerRadius: NeoSpacing.controlRadius, style: .continuous)
                .fill(NeoColor.white)
                .frame(height: 88)
        }
        .accessibilityHidden(true)
    }
}

