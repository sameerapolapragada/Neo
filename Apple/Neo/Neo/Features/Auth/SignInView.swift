import Observation
import SwiftUI

@MainActor
@Observable
final class SignInViewModel {
    var email = ""
    var password = ""
    var isCreatingAccount = false
    var errorMessage: String?
    var infoMessage: String?
    var isWorking = false

    func submit(using app: AppModel) async {
        errorMessage = nil
        infoMessage = nil
        if let validation = AuthFormValidation.error(email: email, password: password) {
            errorMessage = validation
            return
        }
        isWorking = true
        defer { isWorking = false }
        await app.submitAuth(email: email, password: password, creatingAccount: isCreatingAccount)
        errorMessage = app.authError
        if app.gate == .confirmEmail {
            infoMessage = "Check your email to confirm the account, then sign in."
        }
    }
}

struct SignInView: View {
    @Bindable var viewModel: SignInViewModel
    var app: AppModel

    var body: some View {
        ScreenScaffold {
            VStack(alignment: .leading, spacing: NeoSpacing.sm) {
                Text("Neo")
                    .font(NeoFont.displayName)
                    .foregroundStyle(NeoColor.espresso)
                Text("A scrapbook for the life you share.")
                    .font(NeoFont.body)
                    .foregroundStyle(NeoColor.warmBrown)
            }
            .padding(.top, NeoSpacing.xl)

            NeoTextField(title: "Email", text: $viewModel.email)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .textContentType(.username)
                .autocorrectionDisabled()
            NeoTextField(title: "Password", text: $viewModel.password, isSecure: true)
                .textContentType(viewModel.isCreatingAccount ? .newPassword : .password)

            InlineErrorText(message: viewModel.errorMessage ?? app.authError)
            if let info = viewModel.infoMessage {
                Text(info)
                    .font(NeoFont.callout)
                    .foregroundStyle(NeoColor.warmBrown)
                    .fixedSize(horizontal: false, vertical: true)
            }

            SaveButton(
                title: viewModel.isCreatingAccount ? "Create Account" : "Sign In",
                isSaving: viewModel.isWorking
            ) {
                Task { await viewModel.submit(using: app) }
            }

            Button(viewModel.isCreatingAccount ? "I already have an account" : "Create an account") {
                viewModel.isCreatingAccount.toggle()
                viewModel.errorMessage = nil
                viewModel.infoMessage = nil
            }
            .buttonStyle(NeoQuietButtonStyle())
        }
    }
}
