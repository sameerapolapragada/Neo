import SwiftUI

/// Serif styles are reserved for pet names and selected headings.
/// Forms and body copy use the system sans (SF Pro on iPhone), which scales with Dynamic Type.
enum NeoFont {
    static let displayName = Font.system(.largeTitle, design: .serif).weight(.semibold)
    static let sectionTitle = Font.system(.title2, design: .serif).weight(.semibold)
    static let cardTitle = Font.system(.title3, design: .serif).weight(.semibold)
    static let body = Font.body
    static let callout = Font.callout
    static let caption = Font.caption
    static let button = Font.body.weight(.semibold)
}
