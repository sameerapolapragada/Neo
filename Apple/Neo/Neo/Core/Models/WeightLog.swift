import Foundation

struct WeightEntry: Identifiable, Equatable, Sendable {
    var id: UUID
    var ownerId: UUID
    var petId: UUID
    var measuredOn: Date
    var weightValue: Double
    var weightUnit: WeightUnit
    var source: String
    var createdAt: Date
    var updatedAt: Date

    static let sourceOwnerReported = "owner_reported"

    func converted(to unit: WeightUnit) -> Double {
        WeightConversion.convert(weightValue, from: weightUnit, to: unit)
    }

    func label() -> String {
        let formatted = weightValue.formatted(.number.precision(.fractionLength(0...2)))
        return "\(formatted) \(weightUnit.rawValue)"
    }
}

enum WeightConversion {
    static let poundsPerKilogram = 2.2046226218

    static func convert(_ value: Double, from source: WeightUnit, to destination: WeightUnit) -> Double {
        guard value > 0 else { return value }
        if source == destination { return value }
        switch (source, destination) {
        case (.pounds, .kilograms):
            return value / poundsPerKilogram
        case (.kilograms, .pounds):
            return value * poundsPerKilogram
        default:
            return value
        }
    }
}

enum WeightValidation {
    static func value(from text: String) -> Double? {
        let parsed = WeightParser.value(from: text)
        guard let parsed, parsed > 0 else { return nil }
        return parsed
    }
}

struct WeightChartPoint: Identifiable, Equatable, Sendable {
    var id: UUID
    var measuredOn: Date
    var value: Double
    var unit: WeightUnit
}

enum WeightLog {
    /// The newest dated measurement on or before today. Undated profile weights are not entries.
    static func current(_ entries: [WeightEntry], on day: Date = .now, calendar: Calendar = .current) -> WeightEntry? {
        let end = calendar.startOfDay(for: day)
        return entries
            .filter { calendar.startOfDay(for: $0.measuredOn) <= end }
            .sorted { comesAfter($0, $1, calendar: calendar) }
            .first
    }

    static func history(_ entries: [WeightEntry], calendar: Calendar = .current) -> [WeightEntry] {
        entries.sorted { comesAfter($0, $1, calendar: calendar) }
    }

    static func chart(_ entries: [WeightEntry], displayUnit: WeightUnit, calendar: Calendar = .current) -> [WeightChartPoint] {
        history(entries, calendar: calendar)
            .reversed()
            .map { entry in
                WeightChartPoint(
                    id: entry.id,
                    measuredOn: calendar.startOfDay(for: entry.measuredOn),
                    value: entry.converted(to: displayUnit),
                    unit: displayUnit
                )
            }
    }

    private static func comesAfter(_ lhs: WeightEntry, _ rhs: WeightEntry, calendar: Calendar) -> Bool {
        let left = calendar.startOfDay(for: lhs.measuredOn)
        let right = calendar.startOfDay(for: rhs.measuredOn)
        if left != right { return left > right }
        if lhs.createdAt != rhs.createdAt { return lhs.createdAt > rhs.createdAt }
        return lhs.id.uuidString > rhs.id.uuidString
    }
}
