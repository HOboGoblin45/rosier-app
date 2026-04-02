import Foundation
@testable import Rosier

// MARK: - Mock Network Service

class MockNetworkService: NetworkService {
    var mockResponse: Any?
    var shouldSucceed = true
    var shouldThrowError: NetworkError?

    override func request<T: Decodable>(
        _ endpoint: String,
        method: HTTPMethod = .get,
        body: Encodable? = nil,
        headers: [String: String] = [:]
    ) async throws -> T {
        if let error = shouldThrowError {
            throw error
        }

        guard shouldSucceed else {
            throw NetworkError.unknown(NSError(domain: "Mock", code: -1))
        }

        if let response = mockResponse as? T {
            return response
        }

        throw NetworkError.decodingError(DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Mock error")))
    }

    override func requestEmpty(
        _ endpoint: String,
        method: HTTPMethod = .post,
        body: Encodable? = nil,
        headers: [String: String] = [:]
    ) async throws {
        if let error = shouldThrowError {
            throw error
        }

        guard shouldSucceed else {
            throw NetworkError.unknown(NSError(domain: "Mock", code: -1))
        }
    }
}

// MARK: - Mock Card Queue Service

class MockCardQueueService: CardQueueService {
    var queueToReturn: [CardQueueItem] = []
    var shouldFail = false

    override func initializeQueue() async {
        if shouldFail {
            await MainActor.run {
                self.error = .fetchFailed(NSError(domain: "Mock", code: -1))
            }
            return
        }

        await MainActor.run {
            self.queue = queueToReturn
            if !self.queue.isEmpty {
                self.currentCard = self.queue.removeFirst()
            }
        }
    }

    override func handleSwipe(action: SwipeAction, dwellTimeMs: Int) async {
        await MainActor.run {
            if !self.queue.isEmpty {
                self.currentCard = self.queue.removeFirst()
            } else {
                self.currentCard = nil
            }
        }
    }

    override func undo() async {
        // Mock implementation
    }

    override func refreshQueue() async {
        await initializeQueue()
    }
}

// MARK: - Mock Swipe Event Service

class MockSwipeEventService: SwipeEventService {
    var trackedEvents: [SwipeEvent] = []
    var uploadFailed = false

    override func trackEvent(_ event: SwipeEvent) async {
        trackedEvents.append(event)
    }

    override func uploadBatch() async {
        if uploadFailed {
            print("Mock upload failed")
        }
    }

    override func handleAppBackground() async {
        await uploadBatch()
    }
}

// MARK: - Mock Auth Service

class MockAuthService: AuthService {
    var mockUser: UserProfile?
    var mockToken: String?
    var shouldFail = false

    override func getValidToken() async throws -> String? {
        if shouldFail {
            throw AuthError.tokenRefreshFailed
        }
        return mockToken ?? "mock-token"
    }

    override func refreshToken() async throws {
        if shouldFail {
            throw AuthError.tokenRefreshFailed
        }
    }

    override func signOut() {
        mockUser = nil
        mockToken = nil
    }

    override func mergeSession() async throws {
        if shouldFail {
            throw AuthError.networkError(NSError(domain: "Mock", code: -1))
        }
    }
}

// MARK: - Mock Image Cache Service

class MockImageCacheService: ImageCacheService {
    var cachedImages: [URL: Data] = [:]

    override func preloadImage(from url: URL) {
        // Mock: just store reference
        cachedImages[url] = Data()
    }
}

// MARK: - Mock Offline Sync Service

class MockOfflineSyncService: OfflineSyncService {
    var syncCalled = false
    var prefetchCalled = false

    override func performInitialSync() async {
        syncCalled = true
    }

    override func syncUnyncedSwipeEvents() async {
        syncCalled = true
    }

    override func prefetchCardQueue() async {
        prefetchCalled = true
    }
}

// MARK: - Mock Persistence Controller

class MockPersistenceController: PersistenceController {
    var dataToReturn: [NSManagedObject] = []
    var shouldFail = false

    override func saveMainContext() throws {
        if shouldFail {
            throw NSError(domain: "Mock", code: -1)
        }
    }

    override func clearAllData() throws {
        if shouldFail {
            throw NSError(domain: "Mock", code: -1)
        }
    }

    override func cleanExpiredCache(olderThanDays days: Int = 7) throws {
        if shouldFail {
            throw NSError(domain: "Mock", code: -1)
        }
    }
}

// MARK: - Mock Deep Link Service

class MockDeepLinkService: DeepLinkService {
    var handledURLs: [URL] = []

    override func handleURL(_ url: URL) -> Bool {
        handledURLs.append(url)
        return true
    }
}

// MARK: - Mock Analytics Service

class MockAnalyticsService: AnalyticsService {
    var sessionStarted = false
    var sessionEnded = false

    override func startSession() {
        sessionStarted = true
    }

    override func endSession() {
        sessionEnded = true
    }
}
