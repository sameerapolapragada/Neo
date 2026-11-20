import Foundation

enum PetSex: String, CaseIterable, Identifiable, Sendable {
    case male
    case female
    case unknown

    var id: String { rawValue }

    var title: String {
        switch self {
        case .male: "Male"
        case .female: "Female"
        case .unknown: "Not sure"
        }
    }

    static func fromStored(_ value: String) -> PetSex {
        PetSex(rawValue: value) ?? .unknown
    }
}

enum ReproductiveStatus: String, CaseIterable, Identifiable, Sendable {
    case yes
    case no
    case unknown

    var id: String { rawValue }

    var title: String {
        switch self {
        case .yes: "Yes"
        case .no: "No"
        case .unknown: "Not sure"
        }
    }

    static func fromStored(_ value: String) -> ReproductiveStatus {
        ReproductiveStatus(rawValue: value) ?? .unknown
    }
}

enum AgeStatus: String, CaseIterable, Identifiable, Sendable {
    case known
    case approximate
    case unknown

    var id: String { rawValue }

    var title: String {
        switch self {
        case .known: "Exact birthday"
        case .approximate: "Approximate"
        case .unknown: "Not sure"
        }
    }

    static func fromStored(_ value: String) -> AgeStatus {
        AgeStatus(rawValue: value) ?? .unknown
    }
}

enum PetSize: String, CaseIterable, Identifiable, Sendable {
    case small
    case medium
    case large
    case extraLarge = "extra_large"
    case unknown

    var id: String { rawValue }

    var title: String {
        switch self {
        case .small: "Small"
        case .medium: "Medium"
        case .large: "Large"
        case .extraLarge: "Extra large"
        case .unknown: "Not sure"
        }
    }

    static func fromStored(_ value: String) -> PetSize {
        PetSize(rawValue: value) ?? .unknown
    }
}

enum BreedIdentity: String, CaseIterable, Identifiable, Sendable {
    case known
    case mixed
    case unknown

    var id: String { rawValue }

    var title: String {
        switch self {
        case .known: "Known breed"
        case .mixed: "Mixed breed"
        case .unknown: "Not sure"
        }
    }

    static func fromStored(_ value: String) -> BreedIdentity {
        BreedIdentity(rawValue: value) ?? .unknown
    }
}

enum PetLegacyGender {
    /// Keeps the older gender column valid without treating spayed or neutered as a sex.
    static func stored(
        sex: PetSex,
        reproductiveStatus: ReproductiveStatus,
        previous: PetGender
    ) -> PetGender {
        switch (sex, reproductiveStatus) {
        case (.male, .yes):
            return .neutered
        case (.female, .yes):
            return .spayed
        case (.male, _):
            return .male
        case (.female, _):
            return .female
        case (.unknown, .yes):
            if previous == .neutered || previous == .spayed {
                return previous
            }
            return .unknown
        case (.unknown, _):
            return .unknown
        }
    }
}

enum PetProfileDetails {
    static let approximateAgeLimit = 40

    static func approximateAge(from text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return String(trimmed.prefix(approximateAgeLimit))
    }

    static func breedLine(for pet: Pet) -> String {
        let breed = pet.breed.trimmingCharacters(in: .whitespacesAndNewlines)
        switch pet.breedIdentity {
        case .known:
            return breed.isEmpty ? "Known breed" : breed
        case .mixed:
            return breed.isEmpty ? "Mixed breed" : "Mixed · \(breed)"
        case .unknown:
            return breed.isEmpty ? "Not sure" : breed
        }
    }

    static func ageLine(for pet: Pet, now: Date = .now, calendar: Calendar = .current) -> String {
        if let birthday = pet.birthday {
            return PetAge.description(from: birthday, now: now, calendar: calendar)
        }
        if pet.ageStatus == .approximate,
           let approximate = approximateAge(from: pet.approximateAge ?? "") {
            return approximate
        }
        return "Not sure"
    }
}
