import SwiftUI

struct PetInfoRow: View {
    var systemImage: String
    var title: String
    var value: String
    var isQuiet = false

    private var isPlaceholder: Bool { isQuiet || value == PetProfileDisplay.missing }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: NeoSpacing.md) {
            Image(systemName: systemImage)
                .font(.body)
                .foregroundStyle(NeoColor.warmBrown)
                .frame(width: 24)
                .accessibilityHidden(true)
            Text(title)
                .font(NeoFont.callout)
                .foregroundStyle(NeoColor.warmBrown)
            Spacer(minLength: NeoSpacing.sm)
            Text(value)
                .font(NeoFont.body)
                .foregroundStyle(isPlaceholder ? NeoColor.warmBrown : NeoColor.black)
                .multilineTextAlignment(.trailing)
        }
        .frame(minHeight: NeoSpacing.minTapTarget)
        .accessibilityElement(children: .combine)
    }
}

struct PetStatCard: View {
    var systemImage: String
    var value: String
    var title: String

    var body: some View {
        VStack(spacing: NeoSpacing.sm) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(NeoColor.warmBrown)
                .accessibilityHidden(true)
            Text(value)
                .font(NeoFont.cardTitle)
                .foregroundStyle(NeoColor.espresso)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(title)
                .font(NeoFont.caption)
                .foregroundStyle(NeoColor.warmBrown)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 112)
        .padding(.vertical, NeoSpacing.md)
        .padding(.horizontal, NeoSpacing.xs)
        .background(NeoColor.white)
        .clipShape(RoundedRectangle(cornerRadius: NeoSpacing.cardRadius, style: .continuous))
        .shadow(color: NeoColor.espresso.opacity(0.06), radius: 14, y: 6)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        if value == PetProfileDisplay.missing {
            return "\(title), not added"
        }
        return "\(title), \(value)"
    }
}
