import SwiftUI

/// Coordinator managing authentication flows (Sign In, Sign Up).
final class AuthCoordinator: BaseCoordinator<AuthScreen, SheetType, FullScreenCoverType> {
    // MARK: - Properties

    @Published var isLoading = false
    @Published var error: String?

    private let authService = AuthService.shared
    private var onSuccess: (() -> Void)?

    enum AuthScreen: Hashable {
        case signIn
        case signUp
        case forgotPassword
        case appleSignIn
    }

    // MARK: - Initialization

    init(onSuccess: @escaping () -> Void) {
        self.onSuccess = onSuccess
        super.init()
    }

    // MARK: - Public Methods

    /// Starts the sign in flow.
    func startSignIn() {
        navigationPath = NavigationPath()
        push(.signIn)
    }

    /// Starts the sign up flow.
    func startSignUp() {
        navigationPath = NavigationPath()
        push(.signUp)
    }

    /// Handles Apple Sign-In.
    func handleAppleSignIn() {
        isLoading = true
        error = nil

        Task {
            do {
                try await authService.signInWithApple()

                // Merge anonymous session with authenticated user
                try await authService.mergeSession()

                DispatchQueue.main.async {
                    self.isLoading = false
                    self.onSuccess?()
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.error = error.localizedDescription
                }
            }
        }
    }

    /// Handles email/password sign in.
    func signIn(email: String, password: String) {
        isLoading = true
        error = nil

        Task {
            do {
                try await authService.signInWithEmail(email, password: password)

                // Merge anonymous session with authenticated user
                try await authService.mergeSession()

                DispatchQueue.main.async {
                    self.isLoading = false
                    self.onSuccess?()
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.error = error.localizedDescription
                }
            }
        }
    }

    /// Handles email/password sign up.
    func signUp(email: String, password: String, displayName: String) {
        isLoading = true
        error = nil

        Task {
            do {
                try await authService.signUpWithEmail(
                    email: email,
                    password: password,
                    displayName: displayName
                )

                // Merge anonymous session with authenticated user
                try await authService.mergeSession()

                DispatchQueue.main.async {
                    self.isLoading = false
                    self.onSuccess?()
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.error = error.localizedDescription
                }
            }
        }
    }

    /// Handles forgot password flow.
    func requestPasswordReset(email: String) {
        isLoading = true
        error = nil

        Task {
            do {
                // Call API to send password reset email
                let request = PasswordResetRequest(email: email)
                try await authService.networkService.requestEmpty(
                    "auth/forgot-password",
                    method: .post,
                    body: request
                )

                DispatchQueue.main.async {
                    self.isLoading = false
                    self.error = nil
                    self.pop() // Return to sign in
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.error = error.localizedDescription
                }
            }
        }
    }

    /// Dismisses the auth flow.
    func dismiss() {
        navigationPath = NavigationPath()
        dismissFullScreenCover()
    }

    override func handle(deepLink: DeepLink) {
        // Auth coordinator doesn't handle deep links
    }
}

// MARK: - API Models

struct PasswordResetRequest: Codable {
    let email: String
}
