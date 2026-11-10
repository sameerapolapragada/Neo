import SwiftUI

struct AccountSettingsView: View {
    var app: AppModel
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isConfirming = false
    @State private var isDeleting = false

    var body: some View {
        ScreenScaffold {
            VStack(alignment: .leading, spacing: NeoSpacing.sm) {
                Text("Account")
                    .font(NeoFont.displayName)
                    .foregroundStyle(NeoColor.espresso)
                Text("Deleting your account permanently removes your pets, moments, and photos. This can't be undone.")
                    .font(NeoFont.body)
                    .foregroundStyle(NeoColor.warmBrown)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, NeoSpacing.md)

            NeoTextField(title: "Password", text: $password, isSecure: true)
                .textContentType(.password)
                .accessibilityLabel("Password to confirm account deletion")

            InlineErrorText(message: errorMessage)

            if isDeleting {
                ProgressView("Deleting account")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityIdentifier("deletingAccount")
            }

            Button("Delete Account") {
                errorMessage = nil
                if password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    errorMessage = "Enter your password to confirm it's you."
                } else {
                    isConfirming = true
                }
            }
            .buttonStyle(NeoDestructiveButtonStyle())
            .disabled(isDeleting)
            .accessibilityLabel("Delete account")
            .accessibilityIdentifier("deleteAccount")
        }
        .navigationTitle("Account")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(NeoColor.cream, for: .navigationBar)
        .confirmationDialog(
            "Delete this account?",
            isPresented: $isConfirming,
            titleVisibility: .visible
        ) {
            Button("Delete Forever", role: .destructive) {
                Task { await delete() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently deletes your account, pets, moments, and photos. You'll need to enter your password, and nothing is finished until the server confirms.")
        }
    }

    private func delete() async {
        guard !isDeleting else { return }
        isDeleting = true
        defer { isDeleting = false }
        do {
            try await app.deleteAccount(password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
