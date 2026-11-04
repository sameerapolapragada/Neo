import SwiftUI

struct NeoPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(NeoFont.button)
            .foregroundStyle(NeoColor.white)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
            .padding(.horizontal, NeoSpacing.md)
            .background(NeoColor.espresso.opacity(configuration.isPressed ? 0.82 : 1))
            .clipShape(RoundedRectangle(cornerRadius: NeoSpacing.controlRadius, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

struct NeoSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(NeoFont.button)
            .foregroundStyle(NeoColor.espresso)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
            .padding(.horizontal, NeoSpacing.md)
            .background(NeoColor.subtleBeige.opacity(configuration.isPressed ? 0.7 : 1))
            .clipShape(RoundedRectangle(cornerRadius: NeoSpacing.controlRadius, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

struct NeoQuietButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(NeoFont.button)
            .foregroundStyle(NeoColor.warmBrown)
            .frame(maxWidth: .infinity)
            .frame(minHeight: NeoSpacing.minTapTarget)
            .opacity(configuration.isPressed ? 0.65 : 1)
    }
}

struct NeoDestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(NeoFont.button)
            .foregroundStyle(NeoColor.destructive)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
            .padding(.horizontal, NeoSpacing.md)
            .background(NeoColor.white.opacity(configuration.isPressed ? 0.85 : 1))
            .clipShape(RoundedRectangle(cornerRadius: NeoSpacing.controlRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: NeoSpacing.controlRadius, style: .continuous)
                    .stroke(NeoColor.subtleBeige, lineWidth: 1)
            )
    }
}
