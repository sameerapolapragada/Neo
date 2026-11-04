import PhotosUI
import SwiftUI

struct EditProfilePortrait: View {
    var imageData: Data?
    var remoteURL: URL?
    @Binding var pickerItem: PhotosPickerItem?

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            portrait
                .frame(width: 168, height: 168)
                .clipShape(Circle())
                .overlay(Circle().stroke(NeoColor.white, lineWidth: 4))
            PhotosPicker(selection: $pickerItem, matching: .images) {
                Image(systemName: "camera.fill")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(NeoColor.white)
                    .frame(width: NeoSpacing.minTapTarget, height: NeoSpacing.minTapTarget)
                    .background(NeoColor.espresso)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(NeoColor.cream, lineWidth: 3))
            }
            .accessibilityLabel("Change photo")
            .accessibilityIdentifier("changePetPhoto")
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private var portrait: some View {
        if let imageData, let image = UIImage(data: imageData) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .accessibilityLabel("Selected profile photo")
        } else if let remoteURL {
            AsyncImage(url: remoteURL) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    placeholder
                }
            }
            .accessibilityLabel("Current profile photo")
        } else {
            placeholder
                .accessibilityLabel("No profile photo")
        }
    }

    private var placeholder: some View {
        ZStack {
            NeoColor.subtleBeige
            Image(systemName: "pawprint.fill")
                .font(.system(size: 44))
                .foregroundStyle(NeoColor.warmBrown)
        }
    }
}

struct EditProfileTextField: View {
    var systemImage: String
    var title: String
    @Binding var text: String
    var error: String?
    var axis: Axis = .horizontal
    var keyboard: UIKeyboardType = .default
    var footer: String?
    var footerIsError = false
    var identifier: String?

    var body: some View {
        VStack(alignment: .leading, spacing: NeoSpacing.xs) {
            sectionLabel(systemImage: systemImage, title: title)
            TextField(title, text: $text, axis: axis)
                .keyboardType(keyboard)
                .font(NeoFont.body)
                .foregroundStyle(NeoColor.black)
                .textFieldStyle(.plain)
                .lineLimit(axis == .vertical ? 4...8 : 1...1)
                .modifier(EditFieldSurface(isError: error != nil))
                .accessibilityIdentifier(identifier ?? title)
            if let footer {
                Text(footer)
                    .font(NeoFont.caption)
                    .foregroundStyle(footerIsError ? NeoColor.destructive : NeoColor.warmBrown)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            InlineErrorText(message: error)
        }
    }
}

struct EditProfilePickerField<Selection: Hashable, Content: View>: View {
    var systemImage: String
    var title: String
    @Binding var selection: Selection
    var error: String?
    var identifier: String?
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: NeoSpacing.xs) {
            sectionLabel(systemImage: systemImage, title: title)
            Picker(title, selection: $selection) {
                content()
            }
            .pickerStyle(.menu)
            .tint(NeoColor.espresso)
            .font(NeoFont.body)
            .modifier(EditFieldSurface(isError: error != nil))
            .accessibilityIdentifier(identifier ?? title)
            InlineErrorText(message: error)
        }
    }
}

struct EditProfileDateField: View {
    var systemImage: String
    var title: String
    @Binding var isSet: Bool
    @Binding var date: Date

    var body: some View {
        VStack(alignment: .leading, spacing: NeoSpacing.xs) {
            sectionLabel(systemImage: systemImage, title: title)
            VStack(alignment: .leading, spacing: NeoSpacing.sm) {
                Toggle(isOn: $isSet) {
                    Text(isSet ? title : "Add \(title.lowercased())")
                        .font(NeoFont.body)
                        .foregroundStyle(NeoColor.black)
                }
                .tint(NeoColor.espresso)
                if isSet {
                    DatePicker(title, selection: $date, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(minHeight: NeoSpacing.minTapTarget)
                }
            }
            .modifier(EditFieldSurface(isError: false))
        }
    }
}

struct EditProfileWeightField: View {
    @Binding var weightText: String
    @Binding var unit: WeightUnit
    var error: String?

    var body: some View {
        VStack(alignment: .leading, spacing: NeoSpacing.xs) {
            sectionLabel(systemImage: "scalemass", title: "Weight")
            HStack(spacing: NeoSpacing.sm) {
                TextField("Weight", text: $weightText)
                    .keyboardType(.decimalPad)
                    .font(NeoFont.body)
                    .foregroundStyle(NeoColor.black)
                    .textFieldStyle(.plain)
                    .accessibilityIdentifier("petWeight")
                Picker("Unit", selection: $unit) {
                    ForEach(WeightUnit.allCases) { unit in
                        Text(unit.rawValue).tag(unit)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 120)
            }
            .modifier(EditFieldSurface(isError: error != nil))
            InlineErrorText(message: error)
        }
    }
}

func sectionLabel(systemImage: String, title: String) -> some View {
    Label(title, systemImage: systemImage)
        .font(NeoFont.caption.weight(.semibold))
        .foregroundStyle(NeoColor.warmBrown)
        .labelStyle(.titleAndIcon)
}

private struct EditFieldSurface: ViewModifier {
    var isError: Bool

    func body(content: Content) -> some View {
        content
            .padding(NeoSpacing.md)
            .frame(maxWidth: .infinity, minHeight: NeoSpacing.minTapTarget, alignment: .leading)
            .background(NeoColor.white)
            .clipShape(RoundedRectangle(cornerRadius: NeoSpacing.controlRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: NeoSpacing.controlRadius, style: .continuous)
                    .stroke(isError ? NeoColor.destructive : NeoColor.subtleBeige, lineWidth: 1)
            )
    }
}
