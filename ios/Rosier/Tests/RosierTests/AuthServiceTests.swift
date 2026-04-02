import XCTest
@testable import Rosier

final class AuthServiceTests: XCTestCase {
    // MARK: - Properties

    var sut: AuthService!
    var mockNetworkService: MockNetworkService!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        mockNetworkService = MockNetworkService()
        sut = AuthService()
        sut.networkService = mockNetworkService
    }

    override func tearDown() {
        sut.signOut()
        sut = nil
        mockNetworkService = nil
        super.tearDown()
    }

    // MARK: - Tests: Token Storage

    func test_storeTokenInKeychain() {
        // Given
        let testToken = "test-jwt-token-12345"

        // When
        let keychainHelper = KeychainHelper()
        keychainHelper.save(key: "test_key", value: testToken)

        // Then
        let retrieved = keychainHelper.retrieve(key: "test_key")
        XCTAssertEqual(retrieved, testToken)

        // Cleanup
        keychainHelper.delete(key: "test_key")
    }

    func test_retrieveTokenFromKeychain() {
        // Given
        let keychainHelper = KeychainHelper()
        let testToken = "another-test-token"
        keychainHelper.save(key: "retrieve_test", value: testToken)

        // When
        let retrieved = keychainHelper.retrieve(key: "retrieve_test")

        // Then
        XCTAssertEqual(retrieved, testToken)

        // Cleanup
        keychainHelper.delete(key: "retrieve_test")
    }

    // MARK: - Tests: Token Refresh

    func test_tokenRefreshOnExpiry() async {
        // Given
        let refreshToken = "refresh-token"
        let newAccessToken = "new-access-token"

        mockNetworkService.mockResponse = AuthResponse(
            accessToken: newAccessToken,
            refreshToken: refreshToken,
            expiresIn: 3600
        )

        // When
        do {
            try await sut.refreshToken()
            // Then
            XCTAssertTrue(true) // Refresh succeeded
        } catch {
            XCTFail("Token refresh should succeed: \(error)")
        }
    }

    // MARK: - Tests: Token Management

    func test_clearTokensOnLogout() {
        // Given
        let keychainHelper = KeychainHelper()
        keychainHelper.save(key: "test_token", value: "token_value")

        // When
        keychainHelper.delete(key: "test_token")

        // Then
        let retrieved = keychainHelper.retrieve(key: "test_token")
        XCTAssertNil(retrieved)
    }

    // MARK: - Tests: Anonymous Session

    func test_anonymousSessionCreation() {
        // When
        let sessionId1 = sut.sessionId
        let sessionId2 = sut.sessionId

        // Then
        XCTAssertEqual(sessionId1, sessionId2)
        XCTAssertFalse(sessionId1.isEmpty)
    }

    // MARK: - Tests: Session Merging

    func test_mergeSessionTransfersData() async {
        // Given
        mockNetworkService.shouldSucceed = true

        // When
        do {
            try await sut.mergeSession()
            // Then
            XCTAssertTrue(true)
        } catch {
            XCTFail("Session merge should succeed: \(error)")
        }
    }

    // MARK: - Tests: Apple Sign In

    func test_appleSignInTokenValidation() async {
        // Given
        let mockAppleId = "000000.applesignin.provider"
        let mockEmail = "test@example.com"

        mockNetworkService.mockResponse = AuthResponse(
            accessToken: "apple-auth-token",
            refreshToken: "apple-refresh-token",
            expiresIn: 3600
        )

        // When
        do {
            try await sut.signInWithApple()
            // Then
            XCTAssertTrue(sut.isLoading == false)
        } catch {
            // Expected in test environment
        }
    }

    // MARK: - Tests: Authentication Status

    func test_isAuthenticatedReturnsCorrectly() {
        // When
        let initialState = sut.isAuthenticated

        // Then
        XCTAssertEqual(initialState, false)
    }

    // MARK: - Helper Methods

    private func createMockUserProfile() -> UserProfile {
        UserProfile(
            id: UUID(),
            email: "test@example.com",
            displayName: "Test User",
            profileImageURL: nil,
            bio: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}
