import Foundation

enum Species: String, CaseIterable, Identifiable, Sendable {
    case dog = "Dog"
    case cat = "Cat"
    case rabbit = "Rabbit"
    case bird = "Bird"
    case guineaPig = "Guinea Pig"
    case other = "Other"

    var id: String { rawValue }

    /// Choices offered when creating or editing a profile.
    /// A stored species outside this list stays selected so saving does not rewrite it.
    static let editChoices: [Species] = [.dog, .cat, .other]

    static func fromStored(_ value: String) -> Species {
        Species(rawValue: value) ?? .other
    }
}

enum PetGender: String, CaseIterable, Identifiable, Sendable {
    case male = "Male"
    case female = "Female"
    case neutered = "Neutered"
    case spayed = "Spayed"
    case unknown = "Unknown"

    var id: String { rawValue }

    static func fromStored(_ value: String) -> PetGender {
        PetGender(rawValue: value) ?? .unknown
    }
}

enum WeightUnit: String, CaseIterable, Identifiable, Sendable {
    case pounds = "lbs"
    case kilograms = "kg"

    var id: String { rawValue }

    static func fromStored(_ value: String) -> WeightUnit {
        WeightUnit(rawValue: value) ?? .pounds
    }
}

struct Pet: Identifiable, Equatable, Sendable {
    let id: UUID
    var ownerId: UUID
    var name: String
    var species: Species
    var breed: String
    var birthday: Date?
    var gender: PetGender
    var adoptionDate: Date?
    var weightValue: Double?
    var weightUnit: WeightUnit
    var microchipId: String?
    var photoPath: String?
    var bio: String
    var favoriteToy: String?
    var isFavorite: Bool
    var createdAt: Date
    var updatedAt: Date
}

extension Pet {
    func ageText(now: Date = .now, calendar: Calendar = .current) -> String {
        guard let birthday else { return "—" }
        return PetAge.description(from: birthday, now: now, calendar: calendar)
    }

    func weightLabel() -> String {
        guard let weightValue else { return "—" }
        let formatted = weightValue.formatted(.number.precision(.fractionLength(0...1)))
        return "\(formatted) \(weightUnit.rawValue)"
    }

    func birthdayLabel() -> String {
        guard let birthday else { return "—" }
        return birthday.formatted(date: .abbreviated, time: .omitted)
    }

    func adoptionLabel() -> String {
        guard let adoptionDate else { return "—" }
        return adoptionDate.formatted(date: .abbreviated, time: .omitted)
    }

    var microchipLabel: String {
        let trimmed = microchipId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? "—" : trimmed
    }

    var bioLabel: String {
        let trimmed = bio.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Add a few words about \(name)." : trimmed
    }
}

enum PetAge {
    static func description(from birthday: Date, now: Date = .now, calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.year, .month], from: birthday, to: now)
        let years = parts.year ?? 0
        let months = parts.month ?? 0
        if years < 0 || (years == 0 && months < 0) {
            return "Not yet"
        }
        if years == 0 && months == 0 {
            return "Newborn"
        }
        if years == 0 {
            return months == 1 ? "1 month" : "\(months) months"
        }
        if months == 0 {
            return years == 1 ? "1 year" : "\(years) years"
        }
        return "\(years) yr \(months) mo"
    }
}

enum PetCompanionship {
    /// Whole days from the adoption date through `now`. Missing and future dates stay unknown.
    static func daysTogether(from adoptionDate: Date?, now: Date = .now, calendar: Calendar = .current) -> Int? {
        guard let adoptionDate else { return nil }
        let start = calendar.startOfDay(for: adoptionDate)
        let end = calendar.startOfDay(for: now)
        guard let days = calendar.dateComponents([.day], from: start, to: end).day, days >= 0 else {
            return nil
        }
        return days
    }
}

enum PetProfileDisplay {
    static let missing = "Not added"

    static func age(for pet: Pet, now: Date = .now, calendar: Calendar = .current) -> String {
        guard let birthday = pet.birthday else { return missing }
        return PetAge.description(from: birthday, now: now, calendar: calendar)
    }

    static func birthday(for pet: Pet) -> String {
        guard let birthday = pet.birthday else { return missing }
        return birthday.formatted(date: .abbreviated, time: .omitted)
    }

    static func weight(for pet: Pet) -> String {
        guard pet.weightValue != nil else { return missing }
        return pet.weightLabel()
    }

    static func favoriteToy(for pet: Pet) -> String {
        let toy = pet.favoriteToy?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return toy.isEmpty ? missing : toy
    }

    static func daysTogether(for pet: Pet, now: Date = .now, calendar: Calendar = .current) -> String {
        guard let days = PetCompanionship.daysTogether(from: pet.adoptionDate, now: now, calendar: calendar) else {
            return missing
        }
        return String(days)
    }
}
