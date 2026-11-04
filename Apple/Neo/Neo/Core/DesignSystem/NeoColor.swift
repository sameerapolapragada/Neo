import SwiftUI

/// Scrapbook palette. Values are fixed sRGB so the paper-and-ink look stays the same on every device.
enum NeoColor {
    static let espresso = Color(hex: 0x432B20)
    static let warmBrown = Color(hex: 0x8B6248)
    static let cream = Color(hex: 0xF7F2EB)
    static let white = Color(hex: 0xFFFFFF)
    static let black = Color(hex: 0x171717)
    static let subtleBeige = Color(hex: 0xEFE3D8)
    static let destructive = Color(hex: 0x8C3A32)

    static func hex(_ value: UInt) -> Color {
        Color(hex: value)
    }
}

extension Color {
    init(hex: UInt, opacity: Double = 1) {
        let red = Double((hex >> 16) & 0xFF) / 255
        let green = Double((hex >> 8) & 0xFF) / 255
        let blue = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }
}
