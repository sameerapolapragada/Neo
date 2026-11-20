import PhotosUI
import SwiftUI

struct EditPetProfileView: View {
    @State private var viewModel: EditPetProfileViewModel
    @State private var pickerItem: PhotosPickerItem?
    @State private var confirmingCancel = false
    @Environment(\.dismiss) private var dismiss

    init(ownerId: UUID, pet: Pet?, editing: ProfileEditingDependencies, library: PetLibrary) {
        _viewModel = State(
            initialValue: EditPetProfileViewModel(
                ownerId: ownerId,
                pet: pet,
                pets: editing.pets,
                uploader: editing.uploader,
                media: editing.media,
                library: library,
                storageCleanup: editing.storageCleanup
            )
        )
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        ScreenScaffold {
            EditProfilePortrait(
                imageData: viewModel.photoJPEG,
                remoteURL: viewModel.existingPhotoURL,
                pickerItem: $pickerItem
            )
            InlineErrorText(message: viewModel.photoError)

            EditProfileTextField(
                systemImage: "pencil",
                title: "Name",
                text: $viewModel.name,
                error: viewModel.fieldErrors[.name],
                identifier: "petName"
            )
            EditProfilePickerField(
                systemImage: "pawprint",
                title: "Species",
                selection: $viewModel.species,
                error: viewModel.fieldErrors[.species],
                identifier: "petSpecies"
            ) {
                Text("Select").tag(Optional<Species>.none)
                ForEach(viewModel.speciesChoices) { species in
                    Text(species.rawValue).tag(Optional(species))
                }
            }
            EditProfileTextField(
                systemImage: "tag",
                title: "Breed",
                text: $viewModel.breed,
                identifier: "petBreed"
            )
            EditProfilePickerField(
                systemImage: "pawprint",
                title: "Breed identification",
                selection: $viewModel.breedIdentity,
                identifier: "petBreedIdentity"
            ) {
                ForEach(BreedIdentity.allCases) { identity in
                    Text(identity.title).tag(identity)
                }
            }
            EditProfilePickerField(
                systemImage: "person",
                title: "Sex",
                selection: $viewModel.sex,
                identifier: "petSex"
            ) {
                ForEach(PetSex.allCases) { sex in
                    Text(sex.title).tag(sex)
                }
            }
            EditProfilePickerField(
                systemImage: "heart",
                title: "Spayed or neutered",
                selection: $viewModel.reproductiveStatus,
                identifier: "petReproductiveStatus"
            ) {
                ForEach(ReproductiveStatus.allCases) { status in
                    Text(status.title).tag(status)
                }
            }
            EditProfilePickerField(
                systemImage: "ruler",
                title: "Size",
                selection: $viewModel.sizeCategory,
                identifier: "petSize"
            ) {
                ForEach(PetSize.allCases) { size in
                    Text(size.title).tag(size)
                }
            }
            EditProfilePickerField(
                systemImage: "gift",
                title: "Age",
                selection: $viewModel.ageStatus,
                identifier: "petAgeStatus"
            ) {
                ForEach(AgeStatus.allCases) { status in
                    Text(status.title).tag(status)
                }
            }
            .onChange(of: viewModel.ageStatus) { _, status in
                viewModel.hasBirthday = status == .known
            }
            if viewModel.ageStatus == .known {
                DatePicker("Birthday", selection: $viewModel.birthday, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityIdentifier("petBirthday")
            }
            if viewModel.ageStatus == .approximate {
                EditProfileTextField(
                    systemImage: "clock",
                    title: "Approximate age",
                    text: $viewModel.approximateAge,
                    error: viewModel.approximateError,
                    footer: "For example, about 3 years",
                    identifier: "petApproximateAge"
                )
            }
            Text("Leave anything you are not sure about.")
                .font(NeoFont.caption)
                .foregroundStyle(NeoColor.warmBrown)
            EditProfileDateField(
                systemImage: "house",
                title: "Adoption date",
                isSet: $viewModel.hasAdoptionDate,
                date: $viewModel.adoptionDate
            )
            EditProfileWeightField(
                weightText: $viewModel.weightText,
                unit: $viewModel.weightUnit,
                error: viewModel.fieldErrors[.weight]
            )
            EditProfileTextField(
                systemImage: "star",
                title: "Favorite toy",
                text: $viewModel.favoriteToy,
                identifier: "petFavoriteToy"
            )
            EditProfileTextField(
                systemImage: "text.quote",
                title: "Personality",
                text: $viewModel.personality,
                error: viewModel.fieldErrors[.personality],
                axis: .vertical,
                footer: "\(viewModel.personalityCount)/\(PetValidation.personalityLimit)",
                footerIsError: viewModel.personalityCount > PetValidation.personalityLimit,
                identifier: "petPersonality"
            )
            InlineErrorText(message: viewModel.serverError)
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(NeoColor.cream, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", action: requestCancel)
                    .foregroundStyle(NeoColor.espresso)
                    .accessibilityIdentifier("cancelPetProfile")
            }
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    Task { await viewModel.save() }
                } label: {
                    Text("Save")
                        .font(NeoFont.button)
                }
                .foregroundStyle(NeoColor.espresso)
                .disabled(viewModel.isSaving)
                .accessibilityIdentifier("savePetProfile")
                .accessibilityHint(viewModel.isSaving ? "Saving" : "Saves the profile")
            }
        }
        .confirmationDialog(
            "Discard changes?",
            isPresented: $confirmingCancel,
            titleVisibility: .visible
        ) {
            Button("Discard Changes", role: .destructive) { dismiss() }
            Button("Keep Editing", role: .cancel) {}
        } message: {
            Text("Your edits to this profile will not be saved.")
        }
        .task { await viewModel.load() }
        .onChange(of: pickerItem) { _, item in
            guard let item else { return }
            Task { await loadPhoto(from: item) }
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

    private func loadPhoto(from item: PhotosPickerItem) async {
        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                viewModel.stagePhoto(data)
            } else {
                viewModel.rejectUnreadablePhoto()
            }
        } catch {
            viewModel.rejectUnreadablePhoto()
        }
    }
}
