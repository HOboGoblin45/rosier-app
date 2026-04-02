import SwiftUI

/// Root coordinator that manages the app's overall navigation flow.
final class AppCoordinator: BaseCoordinator<MainScreen, SheetType, FullScreenCoverType> {
    // MARK: - Properties

    @Published var authState: AuthState = .checking
    private let authService = AuthService.shared
    private let deepLinkService = DeepLinkService.shared

    // MARK: - Nested Types

    enum AuthState {
        case checking
        case unauthenticated
        case authenticating
        case authenticated
        case onboarding
    }

    // MARK: - Initialization

    override init() {
        super.init()

        setupDeepLinkHandling()
        checkAuthenticationState()
    }

    // MARK: - Public Methods

    /// Handles authentication state changes.
    func handleAuthenticationStateChange() {
        authService.objectWillChange.sink { [weak self] in
            DispatchQueue.main.async {
                self?.updateAuthState()
            }
        }
        .store(in: &cancellables)
    }

    /// Handles deep link routing.
    override func handle(deepLink: DeepLink) {
        switch deepLink {
        case .product(let id):
            push(.productDetail(productId: id))

        case .dresser(let id):
            push(.drawerDetail(drawerId: id))

        case .styleDNA:
            presentFullScreenCover(.styleQuiz)

        case .invite(let code):
            // Handle invite code
            print("Handling invite: \(code)")

        case .sale:
            // Handle sale navigation
            break

        case .unknown:
            break
        }
    }

    // MARK: - Private Methods

    private var cancellables = Set<AnyCancellable>()

    /// Sets up deep link handling.
    private func setupDeepLinkHandling() {
        deepLinkService.setHandler { [weak self] deepLink in
            self?.handle(deepLink: deepLink)
        }
    }

    /// Checks the current authentication state.
    private func checkAuthenticationState() {
        if authService.isAuthenticated {
            if authService.currentUser?.hasCompletedOnboarding == true {
                authState = .authenticated
            } else {
                authState = .onboarding
            }
        } else {
            authState = .unauthenticated
        }
    }

    /// Updates auth state based on service changes.
    private func updateAuthState() {
        if authService.isAuthenticated {
            if authService.currentUser?.hasCompletedOnboarding == true {
                authState = .authenticated
            } else {
                authState = .onboarding
            }
        } else {
            authState = .unauthenticated
        }
    }

    /// Presents the authentication flow.
    func showAuthentication() {
        presentFullScreenCover(.authentication)
    }

    /// Completes onboarding flow.
    func completeOnboarding() {
        authState = .authenticated
    }

    /// Signs out the current user.
    func signOut() {
        authService.signOut()
        authState = .unauthenticated
        popToRoot()
    }
}

// MARK: - Combine Import

import Combine
