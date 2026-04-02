import SwiftUI
import AuthenticationServices

/// Authentication sheet with Apple Sign-In, email/password, and Google options.
struct SignInView: View {
    @Bindable var viewModel: AuthViewModel
    var onSuccess: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                Color.surfaceBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Text(viewModel.isSignUpMode ? "Create Account" : "Welcome Back")
                                .styleTitleLarge()
                                .foregroundColor(.textPrimary)

                            Text(viewModel.isSignUpMode ?
                                 "Join the Rosier community" :
                                 "Sign in to your account")
                                .font(Typography.body)
                                .foregroundColor(.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        // Error message
                        if let error = viewModel.error {
                            HStack(spacing: 12) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.destructiveRed)

                                Text(error)
                                    .font(Typography.caption)
                                    .foregroundColor(.destructiveRed)
                                    .lineLimit(3)
                            }
                            .padding(12)
                            .background(Color.destructiveRed.opacity(0.1))
                            .cornerRadius(8)
                        }

                        // Apple Sign-In button
                        if !viewModel.isSignUpMode {
                            SignInWithAppleButton(
                                onRequest: { _ in },
                                onCompletion: { result in
                                    switch result {
                                    case .success:
                                        onSuccess()
                                    case .failure(let error):
                                        viewModel.error = error.localizedDescription
                                    }
                                }
                            )
                            .frame(height: 50)
                            .cornerRadius(12)
                        }

                        // Divider
                        HStack(spacing: 12) {
                            VStack {
                                Divider()
                            }
                            Text("Or with Email")
                                .font(Typography.caption)
                                .foregroundColor(.textSecondary)
                            VStack {
                                Divider()
                            }
                        }

                        // Form fields
                        if viewModel.isSignUpMode {
                            // Sign-up form
                            VStack(spacing: 16) {
                                // Display name
                                TextField("Full Name", text: $viewModel.signUpDisplayName)
                                    .textContentType(.name)
                                    .padding(12)
                                    .background(Color.surfaceCard)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.textTertiary.opacity(0.1), lineWidth: 1)
                                    )
                                    .frame(height: 44)

                                // Email
                                TextField("Email Address", text: $viewModel.signUpEmail)
                                    .textContentType(.emailAddress)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .padding(12)
                                    .background(Color.surfaceCard)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.textTertiary.opacity(0.1), lineWidth: 1)
                                    )
                                    .frame(height: 44)

                                // Password
                                SecureField("Password (min. 8 characters)", text: $viewModel.signUpPassword)
                                    .textContentType(.newPassword)
                                    .padding(12)
                                    .background(Color.surfaceCard)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.textTertiary.opacity(0.1), lineWidth: 1)
                                    )
                                    .frame(height: 44)

                                // Password strength indicator
                                if !viewModel.signUpPassword.isEmpty {
                                    HStack(spacing: 8) {
                                        Text("Strength:")
                                            .font(Typography.caption)
                                            .foregroundColor(.textSecondary)

                                        HStack(spacing: 4) {
                                            ForEach(0..<5, id: \.self) { index in
                                                RoundedRectangle(cornerRadius: 2)
                                                    .fill(
                                                        index < strengthLevel(viewModel.signUpPasswordStrength) ?
                                                        viewModel.signUpPasswordStrength.color :
                                                        Color.textTertiary.opacity(0.2)
                                                    )
                                                    .frame(height: 4)
                                            }
                                        }

                                        Text(viewModel.signUpPasswordStrength.displayName)
                                            .font(Typography.caption)
                                            .foregroundColor(viewModel.signUpPasswordStrength.color)
                                    }
                                }

                                // Confirm password
                                SecureField("Confirm Password", text: $viewModel.signUpConfirmPassword)
                                    .textContentType(.newPassword)
                                    .padding(12)
                                    .background(Color.surfaceCard)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(
                                                !viewModel.signUpPassword.isEmpty &&
                                                viewModel.signUpPassword != viewModel.signUpConfirmPassword ?
                                                Color.saleRed : Color.textTertiary.opacity(0.1),
                                                lineWidth: 1
                                            )
                                    )
                                    .frame(height: 44)

                                if !viewModel.signUpPassword.isEmpty &&
                                   viewModel.signUpPassword != viewModel.signUpConfirmPassword {
                                    Text("Passwords do not match")
                                        .font(Typography.caption)
                                        .foregroundColor(.saleRed)
                                }
                            }
                        } else {
                            // Sign-in form
                            VStack(spacing: 16) {
                                TextField("Email Address", text: $viewModel.signInEmail)
                                    .textContentType(.emailAddress)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .padding(12)
                                    .background(Color.surfaceCard)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.textTertiary.opacity(0.1), lineWidth: 1)
                                    )
                                    .frame(height: 44)

                                SecureField("Password", text: $viewModel.signInPassword)
                                    .textContentType(.password)
                                    .padding(12)
                                    .background(Color.surfaceCard)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.textTertiary.opacity(0.1), lineWidth: 1)
                                    )
                                    .frame(height: 44)

                                Button(action: {}) {
                                    Text("Forgot password?")
                                        .font(Typography.caption)
                                        .foregroundColor(.brandAccent)
                                        .frame(maxWidth: .infinity, alignment: .trailing)
                                }
                            }
                        }

                        // Primary action button
                        Button(action: viewModel.isSignUpMode ? viewModel.signUpWithEmail : viewModel.signInWithEmail) {
                            HStack(spacing: 8) {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .tint(.brandPrimary)
                                }
                                Text(viewModel.isSignUpMode ? "Create Account" : "Sign In")
                                    .font(Typography.bodyBold)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                viewModel.isSignUpMode ? viewModel.isSignUpFormValid : viewModel.isSignInFormValid ?
                                Color.brandAccent : Color.textTertiary.opacity(0.2)
                            )
                            .foregroundColor(.brandPrimary)
                            .cornerRadius(12)
                        }
                        .disabled(viewModel.isLoading || (!viewModel.isSignUpMode && !viewModel.isSignInFormValid) || (viewModel.isSignUpMode && !viewModel.isSignUpFormValid))

                        // Toggle mode
                        HStack(spacing: 4) {
                            Text(viewModel.isSignUpMode ? "Already have an account? " : "Don't have an account? ")
                                .font(Typography.caption)
                                .foregroundColor(.textSecondary)

                            Button(action: { viewModel.toggleMode() }) {
                                Text(viewModel.isSignUpMode ? "Sign In" : "Sign Up")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.brandAccent)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Helper Methods

    private func strengthLevel(_ strength: PasswordStrength) -> Int {
        switch strength {
        case .weak:
            return 2
        case .fair:
            return 3
        case .strong:
            return 5
        }
    }
}

// MARK: - Preview

#Preview {
    @State var viewModel = AuthViewModel()
    return SignInView(viewModel: viewModel) {}
        .preferredColorScheme(.light)
}
