import PhotosUI
import SwiftUI

struct PhotoPickButton: View {
    @Binding var pickerItem: PhotosPickerItem?
    var imageData: Data?
    var remoteURL: URL?
    var title: String
    var onJPEG: (Data?) -> Void

    var body: some View {
        PhotosPicker(selection: $pickerItem, matching: .images) {
            ZStack {
                RemoteImage(url: remoteURL, localData: imageData, cornerRadius: NeoSpacing.cardRadius)
                if imageData == nil && remoteURL == nil {
                    VStack(spacing: NeoSpacing.sm) {
                        Image(systemName: "camera")
                            .font(.title2)
                        Text(title)
                            .font(NeoFont.callout)
                    }
                    .foregroundStyle(NeoColor.warmBrown)
                    .padding(NeoSpacing.md)
                }
            }
            .frame(minHeight: 180)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityHint("Opens your photo library")
        .onChange(of: pickerItem) { _, item in
            guard let item else { return }
            Task {
                let data = try? await item.loadTransferable(type: Data.self)
                let jpeg = data.flatMap { PhotoEncoding.jpegData(from: $0) }
                onJPEG(jpeg)
            }
        }
    }
}

struct SaveButton: View {
    var title: String
    var isSaving: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            if isSaving {
                ProgressView()
                    .tint(NeoColor.white)
            } else {
                Text(title)
            }
        }
        .buttonStyle(NeoPrimaryButtonStyle())
        .disabled(isSaving)
        .accessibilityLabel(isSaving ? "Saving" : title)
    }
}
