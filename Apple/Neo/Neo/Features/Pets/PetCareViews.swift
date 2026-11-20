import Charts
import SwiftUI

struct PetCareLinks: View {
    var pet: Pet
    var editing: ProfileEditingDependencies

    var body: some View {
        VStack(alignment: .leading, spacing: NeoSpacing.sm) {
            if let wellness = editing.wellness {
                NavigationLink {
                    PawCheckView(pet: pet, wellness: wellness)
                } label: {
                    careRow(
                        systemImage: "sun.max",
                        title: "Daily Paw Check",
                        message: "A few seconds to note how \(pet.name) seems today."
                    )
                }
                .accessibilityIdentifier("openPawCheck")
                NavigationLink {
                    WeightTrackerView(pet: pet, wellness: wellness, profileWeight: pet.weightLabel())
                } label: {
                    careRow(
                        systemImage: "scalemass",
                        title: "Weight log",
                        message: "Dated weights stay separate from the profile weight."
                    )
                }
                .accessibilityIdentifier("openWeightLog")
            }
        }
        .buttonStyle(.plain)
    }

    private func careRow(systemImage: String, title: String, message: String) -> some View {
        HStack(alignment: .center, spacing: NeoSpacing.md) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(NeoColor.warmBrown)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: NeoSpacing.xs) {
                Text(title)
                    .font(NeoFont.cardTitle)
                    .foregroundStyle(NeoColor.espresso)
                Text(message)
                    .font(NeoFont.caption)
                    .foregroundStyle(NeoColor.warmBrown)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: NeoSpacing.sm)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(NeoColor.warmBrown)
        }
        .padding(NeoSpacing.md)
        .frame(maxWidth: .infinity, minHeight: NeoSpacing.minTapTarget, alignment: .leading)
        .background(NeoColor.white)
        .clipShape(RoundedRectangle(cornerRadius: NeoSpacing.cardRadius, style: .continuous))
    }
}

@MainActor
@Observable
final class PawCheckViewModel {
    let pet: Pet
    private let wellness: any PetWellnessRepository

    var date = Date()
    var appetite: PawAppetite?
    var energy: PawEnergy?
    var mood: PawMood?
    var observations: [PawObservation] = []
    var note = ""
    private(set) var history: [PawCheck] = []
    private(set) var isSaving = false
    var errorMessage: String?
    private var editingId: UUID?
    private var createdAt = Date()

    init(pet: Pet, wellness: any PetWellnessRepository, now: Date = .now) {
        self.pet = pet
        self.wellness = wellness
        self.date = now
    }

    var checkedToday: Bool {
        PawCheckRules.sameDay(history, petId: pet.id, ownerId: pet.ownerId, day: Date()) != nil
    }

    func load() async {
        do {
            history = try await wellness.pawChecks(petId: pet.id, ownerId: pet.ownerId)
            apply(PawCheckRules.sameDay(history, petId: pet.id, ownerId: pet.ownerId, day: date))
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func select(date: Date) {
        self.date = date
        apply(PawCheckRules.sameDay(history, petId: pet.id, ownerId: pet.ownerId, day: date))
    }

    func toggle(_ observation: PawObservation) {
        observations = PawCheckRules.observations(selecting: observation, in: observations)
    }

    func save() async {
        guard !isSaving else { return }
        isSaving = true
        defer { isSaving = false }
        let now = Date()
        let check = PawCheck(
            id: editingId ?? UUID(),
            ownerId: pet.ownerId,
            petId: pet.id,
            observationDate: date,
            appetite: appetite,
            energy: energy,
            mood: mood,
            observations: observations,
            note: PawCheckRules.note(from: note),
            source: PawCheck.sourceOwnerReported,
            createdAt: createdAt,
            updatedAt: now
        )
        do {
            let saved = try await wellness.save(check, pet: pet)
            editingId = saved.id
            createdAt = saved.createdAt
            history = try await wellness.pawChecks(petId: pet.id, ownerId: pet.ownerId)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func apply(_ check: PawCheck?) {
        editingId = check?.id
        createdAt = check?.createdAt ?? Date()
        appetite = check?.appetite
        energy = check?.energy
        mood = check?.mood
        observations = check?.observations ?? []
        note = check?.note ?? ""
    }
}

struct PawCheckView: View {
    @State private var viewModel: PawCheckViewModel

    init(pet: Pet, wellness: any PetWellnessRepository) {
        _viewModel = State(initialValue: PawCheckViewModel(pet: pet, wellness: wellness))
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        ScreenScaffold {
            VStack(alignment: .leading, spacing: NeoSpacing.xs) {
                Text("How is \(viewModel.pet.name) feeling today?")
                    .font(NeoFont.sectionTitle)
                    .foregroundStyle(NeoColor.espresso)
                Text(viewModel.checkedToday ? "Checked today. You can still correct it." : "Nothing is required. Skip any question.")
                    .font(NeoFont.body)
                    .foregroundStyle(NeoColor.warmBrown)
            }
            DatePicker(
                "Date",
                selection: Binding(
                    get: { viewModel.date },
                    set: { viewModel.select(date: $0) }
                ),
                displayedComponents: .date
            )
            .tint(NeoColor.espresso)
            choiceSection("Appetite") {
                ForEach(PawAppetite.allCases) { choice in
                    choiceChip(choice.title, selected: viewModel.appetite == choice) {
                        viewModel.appetite = viewModel.appetite == choice ? nil : choice
                    }
                }
            }
            choiceSection("Energy") {
                ForEach(PawEnergy.allCases) { choice in
                    choiceChip(choice.title, selected: viewModel.energy == choice) {
                        viewModel.energy = viewModel.energy == choice ? nil : choice
                    }
                }
            }
            choiceSection("Mood or behavior") {
                ForEach(PawMood.allCases) { choice in
                    choiceChip(choice.title, selected: viewModel.mood == choice) {
                        viewModel.mood = viewModel.mood == choice ? nil : choice
                    }
                }
            }
            VStack(alignment: .leading, spacing: NeoSpacing.sm) {
                Text("Anything unusual?")
                    .font(NeoFont.cardTitle)
                    .foregroundStyle(NeoColor.espresso)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: NeoSpacing.sm)], spacing: NeoSpacing.sm) {
                    ForEach(PawObservation.allCases) { observation in
                        let selected = viewModel.observations.contains(observation)
                        Button(observation.title) { viewModel.toggle(observation) }
                            .buttonStyle(.plain)
                            .font(NeoFont.caption.weight(.semibold))
                            .foregroundStyle(selected ? NeoColor.white : NeoColor.espresso)
                            .padding(.horizontal, NeoSpacing.md)
                            .frame(maxWidth: .infinity, minHeight: NeoSpacing.minTapTarget)
                            .background(selected ? NeoColor.espresso : NeoColor.white)
                            .clipShape(Capsule())
                    }
                }
            }
            if viewModel.observations.contains(where: \.isSerious) {
                Text(PawCheck.veterinarianPrompt)
                    .font(NeoFont.callout)
                    .foregroundStyle(NeoColor.espresso)
                    .padding(NeoSpacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(NeoColor.subtleBeige)
                    .clipShape(RoundedRectangle(cornerRadius: NeoSpacing.controlRadius, style: .continuous))
            }
            EditProfileTextField(
                systemImage: "text.quote",
                title: "Note",
                text: $viewModel.note,
                axis: .vertical,
                footer: "\(min(viewModel.note.count, PawCheck.noteLimit))/\(PawCheck.noteLimit)",
                identifier: "pawCheckNote"
            )
            Text("This is your observation. Neo does not decide whether \(viewModel.pet.name) is well.")
                .font(NeoFont.caption)
                .foregroundStyle(NeoColor.warmBrown)
            Button(viewModel.isSaving ? "Saving" : "Save check-in") {
                Task { await viewModel.save() }
            }
            .buttonStyle(NeoPrimaryButtonStyle())
            .disabled(viewModel.isSaving)
            .accessibilityIdentifier("savePawCheck")
            InlineErrorText(message: viewModel.errorMessage)
            if !viewModel.history.isEmpty {
                Text("Recent check-ins")
                    .font(NeoFont.cardTitle)
                    .foregroundStyle(NeoColor.espresso)
                ForEach(viewModel.history) { check in
                    Button {
                        viewModel.select(date: check.observationDate)
                    } label: {
                        HStack {
                            Text(check.observationDate.formatted(date: .abbreviated, time: .omitted))
                            Spacer()
                            Text(check.mood?.title ?? check.appetite?.title ?? "Saved")
                        }
                        .font(NeoFont.body)
                        .foregroundStyle(NeoColor.black)
                        .frame(minHeight: NeoSpacing.minTapTarget)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle("Paw Check")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
    }

    private func choiceSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: NeoSpacing.sm) {
            Text(title)
                .font(NeoFont.cardTitle)
                .foregroundStyle(NeoColor.espresso)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: NeoSpacing.sm)], spacing: NeoSpacing.sm) {
                content()
            }
        }
    }

    private func choiceChip(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .buttonStyle(.plain)
            .font(NeoFont.caption.weight(.semibold))
            .foregroundStyle(selected ? NeoColor.white : NeoColor.espresso)
            .padding(.horizontal, NeoSpacing.sm)
            .frame(maxWidth: .infinity, minHeight: NeoSpacing.minTapTarget)
            .background(selected ? NeoColor.warmBrown : NeoColor.white)
            .clipShape(Capsule())
    }
}

@MainActor
@Observable
final class WeightTrackerViewModel {
    let pet: Pet
    let profileWeight: String
    private let wellness: any PetWellnessRepository

    private(set) var entries: [WeightEntry] = []
    var displayUnit: WeightUnit = .pounds
    var draftText = ""
    var draftUnit: WeightUnit = .pounds
    var draftDate = Date()
    var isEditing = false
    private var editingId: UUID?
    private var editingCreatedAt = Date()
    var errorMessage: String?
    private(set) var isSaving = false

    init(pet: Pet, wellness: any PetWellnessRepository, profileWeight: String) {
        self.pet = pet
        self.wellness = wellness
        self.profileWeight = profileWeight
        self.displayUnit = pet.weightUnit
        self.draftUnit = pet.weightUnit
    }

    var current: WeightEntry? { WeightLog.current(entries) }

    var chartPoints: [WeightChartPoint] { WeightLog.chart(entries, displayUnit: displayUnit) }

    func load() async {
        do {
            entries = try await wellness.weightEntries(petId: pet.id, ownerId: pet.ownerId)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func beginNew() {
        editingId = nil
        editingCreatedAt = Date()
        draftText = ""
        draftUnit = displayUnit
        draftDate = Date()
        isEditing = true
        errorMessage = nil
    }

    func beginEdit(_ entry: WeightEntry) {
        editingId = entry.id
        editingCreatedAt = entry.createdAt
        draftText = entry.weightValue.formatted(.number.precision(.fractionLength(0...2)))
        draftUnit = entry.weightUnit
        draftDate = entry.measuredOn
        isEditing = true
        errorMessage = nil
    }

    func saveDraft() async {
        guard let value = WeightValidation.value(from: draftText) else {
            errorMessage = "Enter a weight greater than zero"
            return
        }
        isSaving = true
        defer { isSaving = false }
        let entry = WeightEntry(
            id: editingId ?? UUID(),
            ownerId: pet.ownerId,
            petId: pet.id,
            measuredOn: draftDate,
            weightValue: value,
            weightUnit: draftUnit,
            source: WeightEntry.sourceOwnerReported,
            createdAt: editingCreatedAt,
            updatedAt: Date()
        )
        do {
            _ = try await wellness.save(entry, pet: pet)
            isEditing = false
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete(_ entry: WeightEntry) async {
        do {
            try await wellness.deleteWeight(id: entry.id, petId: pet.id, ownerId: pet.ownerId)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct WeightTrackerView: View {
    @State private var viewModel: WeightTrackerViewModel

    init(pet: Pet, wellness: any PetWellnessRepository, profileWeight: String) {
        _viewModel = State(initialValue: WeightTrackerViewModel(pet: pet, wellness: wellness, profileWeight: profileWeight))
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        ScreenScaffold {
            VStack(alignment: .leading, spacing: NeoSpacing.xs) {
                Text("Logged weight")
                    .font(NeoFont.caption.weight(.semibold))
                    .foregroundStyle(NeoColor.warmBrown)
                Text(viewModel.current?.label() ?? "No dated weight yet")
                    .font(NeoFont.sectionTitle)
                    .foregroundStyle(NeoColor.espresso)
                if viewModel.profileWeight != "—" && viewModel.profileWeight != PetProfileDisplay.missing {
                    Text("Profile weight, no measurement date: \(viewModel.profileWeight). It stays off this chart until you add a date.")
                        .font(NeoFont.caption)
                        .foregroundStyle(NeoColor.warmBrown)
                }
            }
            Picker("Chart unit", selection: $viewModel.displayUnit) {
                ForEach(WeightUnit.allCases) { unit in
                    Text(unit.rawValue).tag(unit)
                }
            }
            .pickerStyle(.segmented)
            if viewModel.chartPoints.count >= 2 {
                Chart(viewModel.chartPoints) { point in
                    LineMark(
                        x: .value("Date", point.measuredOn),
                        y: .value("Weight", point.value)
                    )
                    .foregroundStyle(NeoColor.warmBrown)
                    PointMark(
                        x: .value("Date", point.measuredOn),
                        y: .value("Weight", point.value)
                    )
                    .foregroundStyle(NeoColor.espresso)
                }
                .frame(height: 180)
                .accessibilityLabel("Weight over time")
            }
            Button("Add Weight") { viewModel.beginNew() }
                .buttonStyle(NeoPrimaryButtonStyle())
                .accessibilityIdentifier("addWeight")
            if viewModel.isEditing {
                EditProfileWeightField(
                    weightText: $viewModel.draftText,
                    unit: $viewModel.draftUnit,
                    error: nil
                )
                DatePicker("Measured on", selection: $viewModel.draftDate, displayedComponents: .date)
                    .tint(NeoColor.espresso)
                Button(viewModel.isSaving ? "Saving" : "Save weight") {
                    Task { await viewModel.saveDraft() }
                }
                .buttonStyle(NeoSecondaryButtonStyle())
                .disabled(viewModel.isSaving)
                .accessibilityIdentifier("saveWeight")
            }
            InlineErrorText(message: viewModel.errorMessage)
            ForEach(viewModel.entries) { entry in
                HStack {
                    VStack(alignment: .leading, spacing: NeoSpacing.xs) {
                        Text(entry.label())
                            .font(NeoFont.body)
                            .foregroundStyle(NeoColor.black)
                        Text(entry.measuredOn.formatted(date: .abbreviated, time: .omitted))
                            .font(NeoFont.caption)
                            .foregroundStyle(NeoColor.warmBrown)
                    }
                    Spacer()
                    Button("Edit") { viewModel.beginEdit(entry) }
                        .font(NeoFont.caption.weight(.semibold))
                        .foregroundStyle(NeoColor.espresso)
                    Button("Remove", role: .destructive) {
                        Task { await viewModel.delete(entry) }
                    }
                    .font(NeoFont.caption.weight(.semibold))
                    .foregroundStyle(NeoColor.destructive)
                }
                .frame(minHeight: NeoSpacing.minTapTarget)
            }
        }
        .navigationTitle("Weight")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
    }
}
