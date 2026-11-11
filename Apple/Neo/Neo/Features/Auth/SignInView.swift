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
    var isShowingForgotPassword = false
    var didSendReset = false

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
            infoMessage = "Check your email and open the link on this iPhone. It returns to Neo."
        }
    }

    func sendReset(using app: AppModel) async {
        errorMessage = nil
        infoMessage = nil
        if let validation = AuthFormValidation.emailError(email) {
            errorMessage = validation
            return
        }
        guard !isWorking else { return }
        isWorking = true
        defer { isWorking = false }
        if await app.sendPasswordReset(email: email) {
            didSendReset = true
            infoMessage = "If an account exists for that email, we sent a link. Open it on this iPhone. It returns to Neo so you can choose a new password."
        } else {
            errorMessage = app.authError
        }
    }
}

struct SignInView: View {
    @Bindable var viewModel: SignInViewModel
    var app: AppModel

    var body: some View {
        if viewModel.isShowingForgotPassword {
            ForgotPasswordView(viewModel: viewModel, app: app)
        } else {
            credentials
        }
    }

    private var credentials: some View {
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

            if !viewModel.isCreatingAccount {
                Button("Forgot password?") {
                    viewModel.errorMessage = nil
                    viewModel.infoMessage = nil
                    app.authError = nil
                    viewModel.didSendReset = false
                    viewModel.isShowingForgotPassword = true
                }
                .buttonStyle(NeoQuietButtonStyle())
            }
        }
    }
}
