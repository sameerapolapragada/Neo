import Foundation
import Observation

struct EditPetDraft: Equatable {
    var name = ""
    var species: Species?
    var breed = ""
    var birthday: Date?
    var adoptionDate: Date?
    var weightText = ""
    var weightUnit: WeightUnit = .pounds
    var favoriteToy = ""
    var personality = ""
    var hasReplacementPhoto = false

    static func == (lhs: EditPetDraft, rhs: EditPetDraft) -> Bool {
        lhs.name == rhs.name
            && lhs.species == rhs.species
            && lhs.breed == rhs.breed
            && sameDay(lhs.birthday, rhs.birthday)
            && sameDay(lhs.adoptionDate, rhs.adoptionDate)
            && lhs.weightText == rhs.weightText
            && lhs.weightUnit == rhs.weightUnit
            && lhs.favoriteToy == rhs.favoriteToy
            && lhs.personality == rhs.personality
            && lhs.hasReplacementPhoto == rhs.hasReplacementPhoto
    }

    private static func sameDay(_ lhs: Date?, _ rhs: Date?) -> Bool {
        switch (lhs, rhs) {
        case (nil, nil):
            return true
        case let (left?, right?):
            return Calendar.current.isDate(left, inSameDayAs: right)
        default:
            return false
        }
    }
}

@MainActor
@Observable
final class EditPetProfileViewModel {
    let ownerId: UUID
    let petId: UUID
    private let pets: any PetRepository
    private let uploader: any MediaUploading
    private let media: any MediaURLResolving
    private let library: PetLibrary
    private let storageCleanup: (any StorageCleaning)?
    private var pendingPhotoRemoval: [String] = []

    var name = ""
    var species: Species?
    var breed = ""
    var birthday = Date()
    var hasBirthday = false
    var adoptionDate = Date()
    var hasAdoptionDate = false
    var weightText = ""
    var weightUnit: WeightUnit = .pounds
    var personality = ""
    var favoriteToy = ""
    var photoJPEG: Data?
    var existingPhotoPath: String?
    var existingPhotoURL: URL?
    var photoError: String?
    var fieldErrors: [PetField: String] = [:]
    var serverError: String?
    var isSaving = false
    var didSave = false

    private var gender: PetGender = .unknown
    private var microchip = ""
    private var isFavorite = false
    private var preservedCreatedAt: Date?
    private var baseline = EditPetDraft()

    var isNew: Bool { preservedCreatedAt == nil }

    var hasUnsavedChanges: Bool { currentDraft() != baseline }

    var speciesChoices: [Species] {
        var choices = Species.editChoices
        if let species, !choices.contains(species) {
            choices.append(species)
        }
        return choices
    }

    var personalityCount: Int {
        personality.trimmingCharacters(in: .whitespacesAndNewlines).count
    }

    init(
        ownerId: UUID,
        pet: Pet?,
        pets: any PetRepository,
        uploader: any MediaUploading,
        media: any MediaURLResolving,
        library: PetLibrary,
        storageCleanup: (any StorageCleaning)? = nil
    ) {
        self.ownerId = ownerId
        self.petId = pet?.id ?? UUID()
        self.pets = pets
        self.uploader = uploader
        self.media = media
        self.library = library
        self.storageCleanup = storageCleanup
        if let pet {
            apply(pet)
        }
        captureBaseline()
    }

    func load() async {
        guard !isNew else { return }
        let untouched = !hasUnsavedChanges
        do {
            let pet = try await pets.pet(id: petId, ownerId: ownerId)
            guard untouched, !hasUnsavedChanges else { return }
            apply(pet)
            captureBaseline()
            await loadPhoto()
            serverError = nil
        } catch {
            if untouched {
                serverError = error.localizedDescription
            }
        }
    }

    func stagePhoto(_ data: Data) {
        switch ProfilePhotoValidation.jpeg(from: data) {
        case .success(let jpeg):
            photoJPEG = jpeg
            photoError = nil
        case .failure(let issue):
            photoError = issue.message
        }
    }

    func rejectUnreadablePhoto() {
        photoError = "That photo could not be read."
    }

    func save() async {
        guard !isSaving, !didSave else { return }
        serverError = nil
        let errors = PetValidation.errors(
            name: name,
            species: species,
            weightText: weightText,
            personality: personality
        )
        fieldErrors = errors
        guard errors.isEmpty, let species else { return }

        isSaving = true
        defer { isSaving = false }

        let previousPhotoPath = existingPhotoPath
        let photoPath: String?
        var uploadedNow: String?
        if let photoJPEG {
            guard !photoJPEG.isEmpty else {
                photoError = ProfilePhotoValidation.Issue.unsupportedType.message
                return
            }
            do {
                let uploaded = try await uploader.uploadJPEG(photoJPEG, ownerId: ownerId, petId: petId)
                guard MediaObjectPath.isProfilePhoto(uploaded, ownerId: ownerId, petId: petId) else {
                    throw RepositoryError.invalidPhoto
                }
                photoPath = uploaded
                uploadedNow = uploaded
            } catch {
                serverError = error.localizedDescription
                return
            }
        } else {
            photoPath = existingPhotoPath
        }

        do {
            let saved = try await pets.upsert(makePet(species: species, photoPath: photoPath))
            library.noteSaved(saved)
            apply(saved)
            photoJPEG = nil
            captureBaseline()
            if let uploadedNow, uploadedNow == saved.photoPath, let previousPhotoPath, previousPhotoPath != uploadedNow {
                pendingPhotoRemoval.append(previousPhotoPath)
            }
            if let uploadedNow, saved.photoPath != uploadedNow {
                pendingPhotoRemoval.append(uploadedNow)
            }
            let failed = await finishPhotoCleanup()
            if failed.isEmpty {
                serverError = nil
                didSave = true
            } else {
                serverError = "The profile is saved. A previous photo could not be removed. Save again to retry."
                didSave = false
            }
        } catch {
            if let uploadedNow {
                pendingPhotoRemoval.append(uploadedNow)
                _ = await finishPhotoCleanup()
            }
            serverError = error.localizedDescription
        }
    }

    private func finishPhotoCleanup() async -> [String] {
        let unique = Array(Set(pendingPhotoRemoval)).filter { $0 != existingPhotoPath }
        let failed = await OwnedObjectCleanup.removeReportingFailures(unique, ownerId: ownerId, uploader: uploader)
        if failed.isEmpty {
            pendingPhotoRemoval = []
            if let storageCleanup, !unique.isEmpty {
                try? await storageCleanup.cleanupOwnedStorage(paths: unique)
            }
            return []
        }
        pendingPhotoRemoval = failed
        if let storageCleanup {
            try? await storageCleanup.cleanupOwnedStorage(paths: failed)
        }
        return failed
    }

    private func loadPhoto() async {
        existingPhotoURL = await media.displayURL(for: existingPhotoPath)
    }

    private func makePet(species: Species, photoPath: String?) -> Pet {
        let now = Date()
        let breedText = breed.trimmingCharacters(in: .whitespacesAndNewlines)
        let personalityText = personality.trimmingCharacters(in: .whitespacesAndNewlines)
        let toy = favoriteToy.trimmingCharacters(in: .whitespacesAndNewlines)
        let chip = microchip.trimmingCharacters(in: .whitespacesAndNewlines)
        return Pet(
            id: petId,
            ownerId: ownerId,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            species: species,
            breed: breedText,
            birthday: hasBirthday ? birthday : nil,
            gender: gender,
            adoptionDate: hasAdoptionDate ? adoptionDate : nil,
            weightValue: storedWeight,
            weightUnit: weightUnit,
            microchipId: chip.isEmpty ? nil : chip,
            photoPath: photoPath,
            bio: personalityText,
            favoriteToy: toy.isEmpty ? nil : toy,
            isFavorite: isFavorite,
            createdAt: preservedCreatedAt ?? now,
            updatedAt: now
        )
    }

    private var storedWeight: Double? {
        let trimmed = weightText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return WeightParser.value(from: trimmed)
    }

    private func apply(_ pet: Pet) {
        name = pet.name
        species = pet.species
        breed = pet.breed
        if let birthday = pet.birthday {
            self.birthday = birthday
            hasBirthday = true
        } else {
            hasBirthday = false
        }
        gender = pet.gender
        if let adoptionDate = pet.adoptionDate {
            self.adoptionDate = adoptionDate
            hasAdoptionDate = true
        } else {
            hasAdoptionDate = false
        }
        if let weightValue = pet.weightValue {
            weightText = Self.weightString(weightValue)
        } else {
            weightText = ""
        }
        weightUnit = pet.weightUnit
        microchip = pet.microchipId ?? ""
        personality = pet.bio
        favoriteToy = pet.favoriteToy ?? ""
        isFavorite = pet.isFavorite
        existingPhotoPath = pet.photoPath
        preservedCreatedAt = pet.createdAt
    }

    private func currentDraft() -> EditPetDraft {
        EditPetDraft(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            species: species,
            breed: breed.trimmingCharacters(in: .whitespacesAndNewlines),
            birthday: hasBirthday ? birthday : nil,
            adoptionDate: hasAdoptionDate ? adoptionDate : nil,
            weightText: weightText.trimmingCharacters(in: .whitespacesAndNewlines),
            weightUnit: weightUnit,
            favoriteToy: favoriteToy.trimmingCharacters(in: .whitespacesAndNewlines),
            personality: personality.trimmingCharacters(in: .whitespacesAndNewlines),
            hasReplacementPhoto: photoJPEG != nil
        )
    }

    private func captureBaseline() {
        baseline = currentDraft()
    }

    private static func weightString(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? String(value)
    }
}
