import Foundation

enum PetField: String, Hashable, Sendable {
    case name
    case species
    case weight
    case personality
}

enum MomentField: String, Hashable, Sendable {
    case photos
    case title
    case caption
}

enum MemoryField: String, Hashable, Sendable {
    case title
    case notes
}

enum PetValidation {
    /// Personality is stored in companion_pets.personality. The Swift model still calls that field bio.
    static let personalityLimit = 200

    static func errors(
        name: String,
        species: Species?,
        weightText: String,
        personality: String
    ) -> [PetField: String] {
        var errors: [PetField: String] = [:]
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedName.isEmpty {
            errors[.name] = "Name is required"
        } else if trimmedName.count < 2 {
            errors[.name] = "Name must be at least 2 characters"
        }
        if species == nil {
            errors[.species] = "Species is required"
        }
        let weight = weightText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !weight.isEmpty {
            if let value = WeightParser.value(from: weight) {
                if value <= 0 {
                    errors[.weight] = "Enter a weight greater than zero"
                }
            } else {
                errors[.weight] = "Enter a valid weight"
            }
        }
        if personality.trimmingCharacters(in: .whitespacesAndNewlines).count > personalityLimit {
            errors[.personality] = "Personality must be \(personalityLimit) characters or less"
        }
        return errors
    }
}

enum MomentValidation {
    static let titleLimit = 100
    static let captionLimit = 300
    static let minimumPhotos = 1
    static let maximumPhotos = 5

    static func errors(title: String, caption: String, photoCount: Int) -> [MomentField: String] {
        var errors: [MomentField: String] = [:]
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedTitle.isEmpty {
            errors[.title] = "Title is required"
        } else if trimmedTitle.count > titleLimit {
            errors[.title] = "Title must be \(titleLimit) characters or less"
        }
        if caption.trimmingCharacters(in: .whitespacesAndNewlines).count > captionLimit {
            errors[.caption] = "Caption must be \(captionLimit) characters or less"
        }
        if photoCount < minimumPhotos {
            errors[.photos] = "Add at least one photo"
        } else if photoCount > maximumPhotos {
            errors[.photos] = "You can add up to \(maximumPhotos) photos"
        }
        return errors
    }
}

enum MemoryValidation {
    static let notesLimit = 500
    static let titleLimit = 160

    static func errors(title: String, notes: String) -> [MemoryField: String] {
        var errors: [MemoryField: String] = [:]
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedTitle.count < 2 {
            errors[.title] = "Title must be at least 2 characters"
        } else if trimmedTitle.count > titleLimit {
            errors[.title] = "Title must be \(titleLimit) characters or less"
        }
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedNotes.count < 5 {
            errors[.notes] = "Add a little more about this memory"
        } else if trimmedNotes.count > notesLimit {
            errors[.notes] = "Notes must be \(notesLimit) characters or less"
        }
        return errors
    }
}

enum AuthFormValidation {
    static func error(email: String, password: String) -> String? {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = trimmed.split(separator: "@", omittingEmptySubsequences: false)
        let domain = parts.count == 2 ? String(parts[1]) : ""
        if parts.count != 2 || parts[0].isEmpty || !domain.contains(".") || domain.hasPrefix(".") || domain.hasSuffix(".") {
            return "Enter a valid email address."
        }
        if password.count < 8 {
            return "Use at least 8 characters for the password."
        }
        return nil
    }
}

enum WeightParser {
    static func value(from text: String) -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let normalized = trimmed.replacingOccurrences(of: ",", with: ".")
        return Double(normalized)
    }
}
