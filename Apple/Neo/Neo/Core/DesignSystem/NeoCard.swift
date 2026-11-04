import SwiftUI

struct NeoCard<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: NeoSpacing.sm) {
            content()
        }
        .padding(NeoSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(NeoColor.white)
        .clipShape(RoundedRectangle(cornerRadius: NeoSpacing.cardRadius, style: .continuous))
        .shadow(color: NeoColor.espresso.opacity(0.06), radius: 14, y: 6)
    }
}

struct NeoEyebrow: View {
    var text: String

    var body: some View {
        Text(text)
            .font(NeoFont.caption.weight(.semibold))
            .foregroundStyle(NeoColor.warmBrown)
            .textCase(.uppercase)
            .accessibilityAddTraits(.isHeader)
    }
}

struct NeoProfileRow: View {
    var label: String
    var value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: NeoSpacing.md) {
            Text(label)
                .font(NeoFont.callout)
                .foregroundStyle(NeoColor.warmBrown)
            Spacer(minLength: NeoSpacing.sm)
            Text(value)
                .font(NeoFont.body)
                .foregroundStyle(NeoColor.black)
                .multilineTextAlignment(.trailing)
        }
        .accessibilityElement(children: .combine)
    }
}
