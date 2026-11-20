import Foundation

enum LittleMomentRotation {
    static let cycleLength = 60
    static let windowLength = 2

    static func elapsedDays(from anchorDay: String, to today: Date, calendar: Calendar) -> Int {
        guard let anchor = date(fromDay: anchorDay, calendar: calendar) else { return 0 }
        let start = calendar.startOfDay(for: anchor)
        let current = calendar.startOfDay(for: today)
        let days = calendar.dateComponents([.day], from: start, to: current).day ?? 0
        return max(0, days)
    }

    static func dayKey(_ date: Date, calendar: Calendar) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: calendar.startOfDay(for: date))
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    static func date(fromDay key: String, calendar: Calendar) -> Date? {
        let pieces = key.split(separator: "-")
        guard pieces.count == 3, let year = Int(pieces[0]), let month = Int(pieces[1]), let day = Int(pieces[2]) else {
            return nil
        }
        var parts = DateComponents()
        parts.year = year
        parts.month = month
        parts.day = day
        parts.calendar = calendar
        parts.timeZone = calendar.timeZone
        return calendar.date(from: parts)
    }

    static func order(forCycle cycle: Int, count: Int = LittleMomentCatalog.expectedCount) -> [Int] {
        guard count > 1 else { return Array(0..<count) }
        if cycle <= 0 { return Array(0..<count) }
        var previous = Array(0..<count)
        for index in 1...cycle {
            previous = shuffled(count: count, cycle: index, previousLast: previous[count - 1])
        }
        return previous
    }

    static func promptIndex(elapsedDays: Int, count: Int = LittleMomentCatalog.expectedCount) -> Int {
        let cycle = elapsedDays / cycleLength
        let slot = (elapsedDays % cycleLength) / windowLength
        let sequence = order(forCycle: cycle, count: count)
        return sequence[min(slot, sequence.count - 1)]
    }

    static func prompt(
        elapsedDays: Int,
        prompts: [LittleMomentPrompt]
    ) -> LittleMomentPrompt {
        prompts[promptIndex(elapsedDays: elapsedDays, count: prompts.count)]
    }

    private static func shuffled(count: Int, cycle: Int, previousLast: Int) -> [Int] {
        var indices = Array(0..<count)
        var generator = SplitMix64(state: seed(for: cycle))
        var cursor = count - 1
        while cursor > 0 {
            let swap = Int(generator.next() % UInt64(cursor + 1))
            indices.swapAt(cursor, swap)
            cursor -= 1
        }
        if indices[0] == previousLast {
            indices.swapAt(0, 1)
        }
        return indices
    }

    private static func seed(for cycle: Int) -> UInt64 {
        UInt64(cycle) &* 0xD1B54A32D192ED03 &+ 0xA0761D6478BD642F
    }
}

private struct SplitMix64 {
    var state: UInt64

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var mixed = state
        mixed = (mixed ^ (mixed >> 30)) &* 0xBF58476D1CE4E5B9
        mixed = (mixed ^ (mixed >> 27)) &* 0x94D049BB133111EB
        return mixed ^ (mixed >> 31)
    }
}
