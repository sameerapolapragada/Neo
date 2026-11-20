import Foundation
import Observation
import SwiftUI
import UIKit

enum MemoryDetailPresentation: Equatable {
    case loading
    case loaded
    case missing
    case unauthorized
    case failed
}

@MainActor
@Observable
final class MemoryDetailViewModel {
    let momentId: UUID
    let pet: Pet

    private let pets: any PetRepository
    private let moments: any MomentRepository
    private let media: any MediaURLResolving
    private let deletion: any MomentDeleting
    private let board: MomentBoard?
    private var appliedDeltaID = 0

    private(set) var moment: PetMoment?
    private(set) var photos: [MomentMedia] = []
    private(set) var photoURLs: [URL?] = []
    private(set) var photoIndex = 0
    private(set) var isLoading = false
    private(set) var isUpdatingFavorite = false
    private(set) var isDeleting = false
    private(set) var isConfirmingDelete = false
    private(set) var didDelete = false
    private(set) var deleteFailed = false
    private(set) var shareImage: UIImage?
    private(set) var presentation: MemoryDetailPresentation = .loading
    var loadError: String?
    var actionError: String?

    var tags: [String] {
        (moment?.tags ?? []).map(\.title)
    }

    init(
        momentId: UUID,
        pet: Pet,
        pets: any PetRepository,
        moments: any MomentRepository,
        media: any MediaURLResolving,
        uploader: any MediaUploading,
        deletion: (any MomentDeleting)? = nil,
        board: MomentBoard? = nil
    ) {
        self.momentId = momentId
        self.pet = pet
        self.pets = pets
        self.moments = moments
        self.media = media
        self.deletion = deletion ?? MomentDeletionService(pets: pets, moments: moments, uploader: uploader)
        self.board = board
    }

    var positionLabel: String {
        guard !photos.isEmpty else { return "" }
        return "\(photoIndex + 1) / \(photos.count)"
    }

    var dateText: String {
        guard let moment else { return "" }
        return TimelineDateFormatting.fullDate(moment.momentDate)
    }

    var shareDescription: String {
        guard let moment else { return "" }
        return MomentShareRendering.visibleText(
            petName: pet.name,
            title: moment.title,
            dateText: dateText,
            caption: moment.caption
        )
    }

    func load() async {
        isLoading = moment == nil
        defer { isLoading = false }
        do {
            _ = try await pets.pet(id: pet.id, ownerId: pet.ownerId)
        } catch {
            moment = nil
            photos = []
            photoURLs = []
            shareImage = nil
            loadError = "That memory isn't on this account."
            presentation = .unauthorized
            return
        }
        do {
            let loaded = try await moments.moment(id: momentId, petId: pet.id, ownerId: pet.ownerId)
            guard loaded.ownerId == pet.ownerId, loaded.petId == pet.id else {
                throw RepositoryError.notFound
            }
            apply(loaded)
            await resolvePhotoURLs()
            loadError = nil
            presentation = .loaded
            applyBoard()
        } catch let error as RepositoryError where error == .notFound {
            moment = nil
            photos = []
            photoURLs = []
            shareImage = nil
            loadError = error.localizedDescription
            presentation = .missing
        } catch {
            moment = nil
            photos = []
            photoURLs = []
            shareImage = nil
            loadError = error.localizedDescription
            presentation = .failed
        }
    }

    func selectPhoto(_ index: Int) {
        guard photos.indices.contains(index) else { return }
        photoIndex = index
    }

    func toggleFavorite() async {
        guard let moment, !isUpdatingFavorite else { return }
        isUpdatingFavorite = true
        defer { isUpdatingFavorite = false }
        do {
            let saved = try await moments.setFavorite(
                id: moment.id,
                petId: moment.petId,
                ownerId: moment.ownerId,
                isFavorite: !moment.isFavorite
            )
            board?.noteSaved(saved)
            apply(saved)
            actionError = nil
            deleteFailed = false
        } catch {
            actionError = error.localizedDescription
        }
    }

    func applyBoard() {
        guard let board else { return }
        let changes = board.deltas(after: appliedDeltaID)
        if let last = changes.last?.id {
            appliedDeltaID = last
        }
        for change in changes {
            switch change.kind {
            case .deleted(let id) where id == momentId:
                moment = nil
                photos = []
                photoURLs = []
                shareImage = nil
                loadError = RepositoryError.notFound.localizedDescription
                presentation = .missing
            case .saved(let updated) where updated.id == momentId && updated.petId == pet.id && updated.ownerId == pet.ownerId:
                apply(updated)
                presentation = .loaded
            default:
                break
            }
        }
    }

    func requestDelete() {
        guard moment != nil, !isDeleting else { return }
        isConfirmingDelete = true
    }

    func cancelDelete() {
        isConfirmingDelete = false
    }

    func commitDelete() async {
        guard isConfirmingDelete else { return }
        await performDelete()
    }

    /// Runs after the person confirms in the dialog. The dialog may clear the flag before this starts.
    func performDelete() async {
        guard !isDeleting else { return }
        isConfirmingDelete = false
        isDeleting = true
        defer { isDeleting = false }
        do {
            try await deletion.delete(momentId: momentId, petId: pet.id, ownerId: pet.ownerId)
            board?.noteDeleted(id: momentId, petId: pet.id, ownerId: pet.ownerId)
            didDelete = true
            deleteFailed = false
            actionError = nil
        } catch {
            actionError = error.localizedDescription
            deleteFailed = true
            didDelete = false
        }
    }

    /// Builds the story card only after the person taps Share.
    func makeShareImage(photo: UIImage?) {
        guard let moment else { return }
        shareImage = MomentShareRendering.render(
            petName: pet.name,
            title: moment.title,
            dateText: dateText,
            caption: moment.caption,
            photo: photo
        )
        if shareImage == nil {
            actionError = "We couldn't prepare that card."
        }
    }

    func prepareShare() async {
        let photo = await downloadedCurrentPhoto()
        makeShareImage(photo: photo)
    }

    private func apply(_ loaded: PetMoment) {
        let previous = photoIndex
        moment = loaded
        photos = loaded.media.inDisplayOrder()
        photoIndex = photos.indices.contains(previous) ? previous : 0
        shareImage = nil
    }

    private func resolvePhotoURLs() async {
        var urls: [URL?] = []
        for photo in photos {
            urls.append(await media.displayURL(for: photo.storagePath))
        }
        photoURLs = urls
    }

    private func downloadedCurrentPhoto() async -> UIImage? {
        guard photos.indices.contains(photoIndex) else { return nil }
        let path = photos[photoIndex].storagePath
        guard let url = await media.displayURL(for: path) else { return nil }
        guard let jpeg = await TimelineThumbnailLoader.jpegThumbnail(from: url, maxPixel: 1080) else { return nil }
        return UIImage(data: jpeg)
    }
}

enum MomentShareRendering {
    @MainActor
    static func render(
        petName: String,
        title: String,
        dateText: String,
        caption: String,
        photo: UIImage?
    ) -> UIImage? {
        let card = ShareableMomentCard(
            petName: petName,
            title: title,
            dateText: dateText,
            captionExcerpt: TimelineCaption.preview(caption),
            photo: photo
        )
        let renderer = ImageRenderer(content: card)
        renderer.scale = 3
        renderer.isOpaque = true
        renderer.proposedSize = ProposedViewSize(width: 360, height: 640)
        guard let rendered = renderer.uiImage else { return nil }
        let format = UIGraphicsImageRendererFormat()
        format.opaque = true
        format.scale = rendered.scale
        let flattened = UIGraphicsImageRenderer(size: rendered.size, format: format).image { _ in
            UIColor(red: 247 / 255, green: 242 / 255, blue: 235 / 255, alpha: 1).setFill()
            UIRectFill(CGRect(origin: .zero, size: rendered.size))
            rendered.draw(in: CGRect(origin: .zero, size: rendered.size))
        }
        guard let jpeg = flattened.jpegData(compressionQuality: 0.92), let opaque = UIImage(data: jpeg) else {
            return flattened
        }
        return opaque
    }

    static func visibleText(petName: String, title: String, dateText: String, caption: String) -> String {
        let excerpt = TimelineCaption.preview(caption)
        return [petName, title, dateText, excerpt, "Neo"]
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }
}
