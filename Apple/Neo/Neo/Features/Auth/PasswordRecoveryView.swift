import SwiftUI

struct ForgotPasswordView: View {
    @Bindable var viewModel: SignInViewModel
    var app: AppModel

    var body: some View {
        ScreenScaffold {
            VStack(alignment: .leading, spacing: NeoSpacing.sm) {
                Text("Reset password")
                    .font(NeoFont.sectionTitle)
                    .foregroundStyle(NeoColor.espresso)
                Text("We'll email a link that opens Neo on this iPhone.")
                    .font(NeoFont.body)
                    .foregroundStyle(NeoColor.warmBrown)
            }
            .padding(.top, NeoSpacing.xl)

            NeoTextField(title: "Email", text: $viewModel.email)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .textContentType(.username)
                .autocorrectionDisabled()

            InlineErrorText(message: viewModel.errorMessage ?? app.authError)
            if let info = viewModel.infoMessage {
                Text(info)
                    .font(NeoFont.callout)
                    .foregroundStyle(NeoColor.warmBrown)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !viewModel.didSendReset {
                SaveButton(title: "Send reset link", isSaving: viewModel.isWorking) {
                    Task { await viewModel.sendReset(using: app) }
                }
            }

            Button("Back to sign in") {
                viewModel.errorMessage = nil
                viewModel.infoMessage = nil
                app.authError = nil
                viewModel.isShowingForgotPassword = false
            }
            .buttonStyle(NeoQuietButtonStyle())
        }
    }
}

@MainActor
@Observable
final class ResetPasswordViewModel {
    var password = ""
    var confirmation = ""
    var errorMessage: String?
    var isWorking = false

    func save(using app: AppModel) async {
        errorMessage = nil
        if let validation = AuthFormValidation.passwordChoiceError(password, confirmation: confirmation) {
            errorMessage = validation
            return
        }
        guard !isWorking else { return }
        isWorking = true
        defer { isWorking = false }
        if await app.saveNewPassword(password) {
            password = ""
            confirmation = ""
        } else {
            errorMessage = app.authError
        }
    }
}

struct ResetPasswordView: View {
    var app: AppModel
    @State private var viewModel = ResetPasswordViewModel()

    var body: some View {
        ScreenScaffold {
            VStack(alignment: .leading, spacing: NeoSpacing.sm) {
                Text("Choose a new password")
                    .font(NeoFont.sectionTitle)
                    .foregroundStyle(NeoColor.espresso)
                Text("Use at least 8 characters. You'll stay signed in after it's saved.")
                    .font(NeoFont.body)
                    .foregroundStyle(NeoColor.warmBrown)
            }
            .padding(.top, NeoSpacing.xl)

            NeoTextField(title: "New password", text: $viewModel.password, isSecure: true)
                .textContentType(.newPassword)
            NeoTextField(title: "Confirm password", text: $viewModel.confirmation, isSecure: true)
                .textContentType(.newPassword)

            InlineErrorText(message: viewModel.errorMessage)

            SaveButton(title: "Save password", isSaving: viewModel.isWorking) {
                Task { await viewModel.save(using: app) }
            }

            Button("Cancel") {
                viewModel.password = ""
                viewModel.confirmation = ""
                Task { await app.signOut() }
            }
            .buttonStyle(NeoQuietButtonStyle())
        }
    }
}
