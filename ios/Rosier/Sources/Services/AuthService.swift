import Foundation
import AuthenticationServices

/// Authentication service handling sign-in, token management, and session persistence.
final class AuthService: NSObject, ObservableObject {
    // MARK: - Singleton

    static let shared = AuthService()

    // MARK: - Published Properties

    @Published var isAuthenticated = false
    @Published var currentUser: UserProfile?
    @Published var isLoading = false
    @Published var error: AuthError?

    // MARK: - Private Properties

    private let networkService: NetworkService
    private let keychainHelper = KeychainHelper()
    private let userDefaults = UserDefaults.standard

    private var accessToken: String?
    private var refreshToken: String?
    private var sessionId: String

    private let accessTokenKey = "rosier_access_token"
    private let refreshTokenKey = "rosier_refresh_token"
    private let sessionIdKey = "rosier_session_id"
    private let userProfileKey = "rosier_user_profile"

    // MARK: - Initializers

    override init() {
        self.networkService = NetworkService.shared
        self.sessionId = UUID().uuidString

        super.init()

        // Load persisted tokens and session
        self.accessToken = keychainHelper.retrieve(key: accessTokenKey)
        self.refreshToken = keychainHelper.retrieve(key: refreshTokenKey)

        if let savedSessionId = userDefaults.string(forKey: sessionIdKey) {
            self.sessionId = savedSessionId
        } else {
            userDefaults.set(self.sessionId, forKey: sessionIdKey)
        }

        // Check if user is already authenticated
        if accessToken != nil {
            isAuthenticated = true
            restoreUserProfile()
        }

        networkService.setAuthService(self)
    }

    // MARK: - Public Methods

    /// Gets a valid access token, refreshing if necessary.
    func getValidToken() async throws -> String? {
        if let token = accessToken, !isTokenExpired(token) {
            return token
        }

        try await refreshToken()
        return accessToken
    }

    /// Authenticates with Apple Sign-In.
    func signInWithApple() async throws {
        isLoading = true
        defer { isLoading = false }

        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]

        // For now, we'll simulate the response. In a real app, this would be handled
        // via ASAuthorizationControllerDelegate
        let appleId = "000000.applesignin.provider"
        let email = "user@example.com"

        try await authenticateWithBackend(appleId: appleId, email: email, method: .apple)
    }

    /// Authenticates with email and password.
    func signInWithEmail(_ email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }

        let credentials = EmailCredentials(email: email, password: password)
        try await authenticateWithBackend(credentials: credentials, method: .email)
    }

    /// Registers a new account with email.
    func signUpWithEmail(
        email: String,
        password: String,
        displayName: String
    ) async throws {
        isLoading = true
        defer { isLoading = false }

        let registration = EmailRegistration(
            email: email,
            password: password,
            displayName: displayName
        )

        let response: AuthResponse = try await networkService.request(
            "auth/register",
            method: .post,
            body: registration
        )

        saveTokens(accessToken: response.accessToken, refreshToken: response.refreshToken)
        try await fetchCurrentUser()
    }

    /// Refreshes the access token using the refresh token.
    func refreshToken() async throws {
        guard let refreshToken = refreshToken else {
            throw AuthError.noRefreshToken
        }

        let request = RefreshTokenRequest(refreshToken: refreshToken)

        do {
            let response: AuthResponse = try await networkService.request(
                "auth/refresh",
                method: .post,
                body: request
            )

            saveTokens(accessToken: response.accessToken, refreshToken: response.refreshToken)
        } catch {
            signOut()
            throw AuthError.tokenRefreshFailed
        }
    }

    /// Merges an anonymous session with a newly authenticated user.
    func mergeSession() async throws {
        let mergeRequest = MergeSessionRequest(sessionId: sessionId)
        try await networkService.requestEmpty(
            "auth/merge-session",
            method: .post,
            body: mergeRequest
        )
    }

    /// Fetches the current user's profile from the backend.
    func fetchCurrentUser() async throws {
        let profile: UserProfile = try await networkService.request("users/me")
        DispatchQueue.main.async {
            self.currentUser = profile
            self.isAuthenticated = true
            self.saveUserProfile(profile)
        }
    }

    /// Signs out the current user.
    func signOut() {
        accessToken = nil
        refreshToken = nil
        currentUser = nil
        isAuthenticated = false

        keychainHelper.delete(key: accessTokenKey)
        keychainHelper.delete(key: refreshTokenKey)
        userDefaults.removeObject(forKey: userProfileKey)
    }

    // MARK: - Private Methods

    /// Authenticates with the backend via various methods.
    private func authenticateWithBackend(
        appleId: String? = nil,
        email: String? = nil,
        credentials: EmailCredentials? = nil,
        method: AuthMethod
    ) async throws {
        switch method {
        case .apple:
            let request = AppleAuthRequest(
                appleId: appleId ?? "",
                email: email ?? "",
                sessionId: sessionId
            )
            let response: AuthResponse = try await networkService.request(
                "auth/apple",
                method: .post,
                body: request
            )
            saveTokens(accessToken: response.accessToken, refreshToken: response.refreshToken)

        case .email:
            guard let credentials = credentials else {
                throw AuthError.invalidCredentials
            }
            let response: AuthResponse = try await networkService.request(
                "auth/email",
                method: .post,
                body: credentials
            )
            saveTokens(accessToken: response.accessToken, refreshToken: response.refreshToken)
        }

        try await fetchCurrentUser()
    }

    /// Saves tokens to secure storage.
    private func saveTokens(accessToken: String, refreshToken: String) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken

        keychainHelper.save(key: accessTokenKey, value: accessToken)
        keychainHelper.save(key: refreshTokenKey, value: refreshToken)
    }

    /// Saves user profile to persistent storage.
    private func saveUserProfile(_ profile: UserProfile) {
        if let encoded = try? JSONEncoder().encode(profile) {
            userDefaults.set(encoded, forKey: userProfileKey)
        }
    }

    /// Restores user profile from persistent storage.
    private func restoreUserProfile() {
        guard let data = userDefaults.data(forKey: userProfileKey),
              let profile = try? JSONDecoder().decode(UserProfile.self, from: data) else {
            return
        }
        DispatchQueue.main.async {
            self.currentUser = profile
        }
    }

    /// Checks if a JWT token is expired.
    private func isTokenExpired(_ token: String) -> Bool {
        // Simplified check: tokens expire in 1 hour
        // In production, decode the JWT and check the exp claim
        return false
    }
}

// MARK: - Auth Models

struct AuthResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
}

struct AppleAuthRequest: Codable {
    let appleId: String
    let email: String
    let sessionId: String
}

struct EmailCredentials: Codable {
    let email: String
    let password: String
}

struct EmailRegistration: Codable {
    let email: String
    let password: String
    let displayName: String
}

struct RefreshTokenRequest: Codable {
    let refreshToken: String
}

struct MergeSessionRequest: Codable {
    let sessionId: String
}

enum AuthMethod {
    case apple
    case email
}

// MARK: - Auth Error

enum AuthError: LocalizedError {
    case invalidCredentials
    case noRefreshToken
    case tokenRefreshFailed
    case userNotFound
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password"
        case .noRefreshToken:
            return "No refresh token available"
        case .tokenRefreshFailed:
            return "Failed to refresh token"
        case .userNotFound:
            return "User not found"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Keychain Helper

final class KeychainHelper {
    func save(key: String, value: String) {
        let data = value.data(using: .utf8) ?? Data()
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
        ]

        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    func retrieve(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
        ]

        SecItemDelete(query as CFDictionary)
    }
}
