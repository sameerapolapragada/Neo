import Foundation

struct TimelineYear: Identifiable, Equatable, Sendable {
    var year: Int
    var moments: [PetMoment]

    var id: Int { year }
    var title: String { String(year) }
}

enum TimelineGrouping {
    /// Newest year first. Moments inside a year follow the feed order: moment date, then write time, then id.
    static func years(from moments: [PetMoment], calendar: Calendar = .current) -> [TimelineYear] {
        let sorted = MomentFeedSorting.ordered(moments)
        var groups: [TimelineYear] = []
        var indexByYear: [Int: Int] = [:]
        for moment in sorted {
            let year = calendar.component(.year, from: moment.momentDate)
            if let index = indexByYear[year] {
                groups[index].moments.append(moment)
            } else {
                indexByYear[year] = groups.count
                groups.append(TimelineYear(year: year, moments: [moment]))
            }
        }
        return groups
    }
}

enum TimelineDateFormatting {
    static func fullDate(_ date: Date, calendar: Calendar = .current) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = calendar.locale ?? Locale(identifier: "en_US")
        formatter.timeZone = calendar.timeZone
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

enum TimelineCaption {
    static let previewLimit = 90

    static func preview(_ caption: String) -> String {
        let collapsed = caption
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        guard collapsed.count > previewLimit else { return collapsed }
        let end = collapsed.index(collapsed.startIndex, offsetBy: previewLimit)
        return collapsed[..<end].trimmingCharacters(in: .whitespaces) + "…"
    }
}

enum TimelineNavigation {
    static func detailRoute(for moment: PetMoment) -> MomentRoute {
        .detail(momentId: moment.id, petId: moment.petId, ownerId: moment.ownerId)
    }
}
