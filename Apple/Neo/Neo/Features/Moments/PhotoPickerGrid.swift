import PhotosUI
import SwiftUI

struct PhotoPickerGrid: View {
    var photos: [MomentPhotoDraft]
    var canAddMore: Bool
    var error: String?
    var onRemove: (UUID) -> Void
    var onMove: (Int, Int) -> Void
    var onPick: ([Data]) -> Void

    @State private var pickerItems: [PhotosPickerItem] = []

    var body: some View {
        VStack(alignment: .leading, spacing: NeoSpacing.xs) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: NeoSpacing.sm) {
                    ForEach(Array(photos.enumerated()), id: \.element.id) { index, photo in
                        thumbnail(photo, index: index)
                    }
                    if canAddMore {
                        addTile
                    }
                }
                .padding(.vertical, NeoSpacing.xs)
            }
            InlineErrorText(message: error)
        }
        .onChange(of: pickerItems) { _, items in
            guard !items.isEmpty else { return }
            let selected = items
            pickerItems = []
            Task { await load(selected) }
        }
    }

    private var addTile: some View {
        PhotosPicker(
            selection: $pickerItems,
            maxSelectionCount: max(MomentValidation.maximumPhotos - photos.count, 1),
            matching: .images
        ) {
            VStack(spacing: NeoSpacing.xs) {
                Image(systemName: "plus")
                    .font(.title3.weight(.semibold))
                Text("Add Photo")
                    .font(NeoFont.caption.weight(.semibold))
            }
            .foregroundStyle(NeoColor.espresso)
            .frame(width: 104, height: 104)
            .background(NeoColor.cream)
            .clipShape(RoundedRectangle(cornerRadius: NeoSpacing.controlRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: NeoSpacing.controlRadius, style: .continuous)
                    .stroke(NeoColor.warmBrown.opacity(0.7), style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add photo")
        .accessibilityHint("Opens your photo library. Video is not supported.")
        .accessibilityIdentifier("addMomentPhoto")
    }

    private func thumbnail(_ photo: MomentPhotoDraft, index: Int) -> some View {
        ZStack(alignment: .topTrailing) {
            Group {
                if let jpeg = photo.jpeg, let image = UIImage(data: jpeg) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else if let previewURL = photo.previewURL {
                    AsyncImage(url: previewURL) { phase in
                        if case .success(let image) = phase {
                            image.resizable().scaledToFill()
                        } else {
                            NeoColor.subtleBeige
                        }
                    }
                } else {
                    NeoColor.subtleBeige
                }
            }
            .frame(width: 104, height: 104)
            .clipShape(RoundedRectangle(cornerRadius: NeoSpacing.controlRadius, style: .continuous))
            Button {
                onRemove(photo.id)
            } label: {
                Image(systemName: "xmark")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(NeoColor.white)
                    .frame(width: 28, height: 28)
                    .background(NeoColor.espresso.opacity(0.88))
                    .clipShape(Circle())
                    .frame(width: NeoSpacing.minTapTarget, height: NeoSpacing.minTapTarget)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove photo \(index + 1)")
        }
        .draggable(photo.id.uuidString)
        .dropDestination(for: String.self) { items, _ in
            guard
                let raw = items.first,
                let dragged = UUID(uuidString: raw),
                let from = photos.firstIndex(where: { $0.id == dragged })
            else { return false }
            onMove(from, index)
            return true
        }
        .accessibilityElement(children: .contain)
        .accessibilityAction(named: "Move earlier") {
            onMove(index, max(index - 1, 0))
        }
        .accessibilityAction(named: "Move later") {
            onMove(index, min(index + 1, photos.count - 1))
        }
    }

    private func load(_ items: [PhotosPickerItem]) async {
        var batches: [Data] = []
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self) {
                batches.append(data)
            }
        }
        onPick(batches)
    }
}
