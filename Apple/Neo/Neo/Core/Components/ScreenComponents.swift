import SwiftUI
import UIKit

struct ScreenScaffold<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: NeoSpacing.lg) {
                content()
            }
            .padding(.horizontal, NeoSpacing.screenMargin)
            .padding(.vertical, NeoSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(NeoColor.cream.ignoresSafeArea())
    }
}

struct EmptyStateView: View {
    var title: String
    var message: String
    var systemImage: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: NeoSpacing.md) {
            Image(systemName: systemImage)
                .font(.system(size: 36))
                .foregroundStyle(NeoColor.warmBrown)
                .accessibilityHidden(true)
            Text(title)
                .font(NeoFont.sectionTitle)
                .foregroundStyle(NeoColor.black)
                .multilineTextAlignment(.center)
            Text(message)
                .font(NeoFont.body)
                .foregroundStyle(NeoColor.warmBrown)
                .multilineTextAlignment(.center)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(NeoPrimaryButtonStyle())
                    .padding(.top, NeoSpacing.sm)
            }
        }
        .padding(NeoSpacing.lg)
        .frame(maxWidth: .infinity)
    }
}

struct InlineErrorText: View {
    var message: String?

    var body: some View {
        if let message {
            Text(message)
                .font(NeoFont.caption)
                .foregroundStyle(NeoColor.destructive)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel("Error: \(message)")
        }
    }
}

struct NeoTextField: View {
    var title: String
    @Binding var text: String
    var error: String?
    var axis: Axis = .horizontal
    var isSecure = false

    var body: some View {
        VStack(alignment: .leading, spacing: NeoSpacing.xs) {
            Text(title)
                .font(NeoFont.caption.weight(.semibold))
                .foregroundStyle(NeoColor.warmBrown)
            Group {
                if isSecure {
                    SecureField(title, text: $text)
                } else {
                    TextField(title, text: $text, axis: axis)
                }
            }
            .font(NeoFont.body)
            .foregroundStyle(NeoColor.black)
            .textFieldStyle(.plain)
            .padding(NeoSpacing.md)
            .frame(minHeight: NeoSpacing.minTapTarget)
            .background(NeoColor.white)
            .clipShape(RoundedRectangle(cornerRadius: NeoSpacing.controlRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: NeoSpacing.controlRadius, style: .continuous)
                    .stroke(error == nil ? NeoColor.subtleBeige : NeoColor.destructive, lineWidth: 1)
            )
            InlineErrorText(message: error)
        }
    }
}

struct StatTile: View {
    var value: String
    var label: String

    var body: some View {
        VStack(spacing: NeoSpacing.xs) {
            Text(value)
                .font(NeoFont.cardTitle)
                .foregroundStyle(NeoColor.espresso)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(NeoFont.caption)
                .foregroundStyle(NeoColor.warmBrown)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, NeoSpacing.md)
        .background(NeoColor.white)
        .clipShape(RoundedRectangle(cornerRadius: NeoSpacing.cardRadius, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

struct RemoteImage: View {
    var url: URL?
    var localData: Data?
    var cornerRadius: CGFloat = NeoSpacing.cardRadius

    var body: some View {
        Color.clear
            .aspectRatio(4.0 / 3.0, contentMode: .fit)
            .overlay {
                image
                    .scaledToFill()
            }
            .clipped()
            .background(NeoColor.subtleBeige)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private var image: some View {
        if let localData, let uiImage = UIImage(data: localData) {
            Image(uiImage: uiImage)
                .resizable()
        } else if let url {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable()
                default:
                    placeholder
                }
            }
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        Image(systemName: "pawprint")
            .font(.largeTitle)
            .foregroundStyle(NeoColor.warmBrown)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(NeoColor.subtleBeige)
    }
}
