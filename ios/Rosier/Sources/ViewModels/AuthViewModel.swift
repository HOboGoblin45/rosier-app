import Foundation
import AuthenticationServices
import SwiftUI

/// ViewModel managing authentication flows including Apple Sign-In, email, and Google.
@Observable final class AuthViewModel: NSObject, ASAuthorizationControllerDelegate {
    // MARK: - Published Properties

    var isSigningUp = false
    var isLoading = false
    var error: String?

    // Sign-in form state
    var signInEmail = ""
    var signInPassword = ""

    // Sign-up form state
    var signUpEmail = ""
    var signUpPassword = ""
    var signUpConfirmPassword = ""
    var signUpDisplayName = ""

    var isSignUpMode = false

    // MARK: - Private Properties

    private let authService = AuthService.shared

    // MARK: - Computed Properties

    var isSignInFormValid: Bool {
        !signInEmail.isEmpty && !signInPassword.isEmpty && signInEmail.contains("@")
    }

    var isSignUpFormValid: Bool {
        !signUpEmail.isEmpty &&
            !signUpPassword.isEmpty &&
            !signUpConfirmPassword.isEmpty &&
            !signUpDisplayName.isEmpty &&
            signUpPassword == signUpConfirmPassword &&
            signUpPassword.count >= 8 &&
            signUpEmail.contains("@")
    }

    var signUpPasswordStrength: PasswordStrength {
        getPasswordStrength(signUpPassword)
    }

    // MARK: - Public Methods

    func signInWithApple() {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.performRequests()
    }

    func signInWithEmail() {
        isLoading = true
        error = nil

        Task {
            do {
                try await authService.signInWithEmail(signInEmail, password: signInPassword)
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.error = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }

    func signUpWithEmail() {
        guard isSignUpFormValid else { return }

        isLoading = true
        error = nil

        Task {
            do {
                try await authService.signUpWithEmail(
                    email: signUpEmail,
                    password: signUpPassword,
                    displayName: signUpDisplayName
                )
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.error = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }

    func resetForm() {
        signInEmail = ""
        signInPassword = ""
        signUpEmail = ""
        signUpPassword = ""
        signUpConfirmPassword = ""
        signUpDisplayName = ""
        error = nil
    }

    func toggleMode() {
        isSignUpMode.toggle()
        resetForm()
    }

    // MARK: - ASAuthorizationControllerDelegate

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            DispatchQueue.main.async {
                self.error = "Failed to get Apple credentials"
            }
            return
        }

        let appleId = credential.user
        let email = credential.email ?? ""

        isLoading = true
        error = nil

        Task {
            do {
                let request = AppleAuthRequest(
                    appleId: appleId,
                    email: email,
                    sessionId: authService.sessionId
                )

                let networkService = NetworkService.shared
                let response: AuthResponse = try await networkService.request(
                    "auth/apple",
                    method: .post,
                    body: request
                )

                // Save tokens (this would be done by AuthService)
                try await authService.fetchCurrentUser()

                DispatchQueue.main.async {
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.error = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        DispatchQueue.main.async {
            if let error = error as? ASAuthorizationError {
                if error.code != .canceled {
                    self.error = "Apple Sign-In failed: \(error.localizedDescription)"
                }
            } else {
                self.error = error.localizedDescription
            }
        }
    }

    // MARK: - Private Methods

    private func getPasswordStrength(_ password: String) -> PasswordStrength {
        var strength = 0

        if password.count >= 8 { strength += 1 }
        if password.count >= 12 { strength += 1 }
        if password.range(of: "[0-9]", options: .regularExpression) != nil { strength += 1 }
        if password.range(of: "[A-Z]", options: .regularExpression) != nil { strength += 1 }
        if password.range(of: "[!@#$%^&*()_+-=\\[\\]{};':\"\\,.<>?]", options: .regularExpression) != nil { strength += 1 }

        switch strength {
        case 0...1:
            return .weak
        case 2...3:
            return .fair
        case 4...:
            return .strong
        default:
            return .weak
        }
    }
}

// MARK: - Helper Types

enum PasswordStrength {
    case weak
    case fair
    case strong

    var displayName: String {
        switch self {
        case .weak:
            return "Weak"
        case .fair:
            return "Fair"
        case .strong:
            return "Strong"
        }
    }

    var color: Color {
        switch self {
        case .weak:
            return Color.saleRed
        case .fair:
            return Color(UIColor.systemOrange)
        case .strong:
            return Color.successGreen
        }
    }
}

// Extension to AuthService for sessionId access
extension AuthService {
    var sessionId: String {
        UUID().uuidString // In production, expose the actual session ID
    }
}
