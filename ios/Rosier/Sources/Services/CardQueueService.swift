import Foundation

/// Manages the card queue for the swipe interface with pre-fetching and caching.
final class CardQueueService: ObservableObject {
    // MARK: - Published Properties

    @Published var currentCard: CardQueueItem?
    @Published var queue: [CardQueueItem] = []
    @Published var isLoading = false
    @Published var error: CardQueueError?

    // MARK: - Properties

    private let networkService: NetworkService
    private let imageCacheService: ImageCacheService
    private let minQueueSize = 40
    private let lowQueueThreshold = 5

    private var sessionId = UUID()
    private var isRefetching = false
    private var cacheDirectory: URL?

    // MARK: - Initializers

    init(
        networkService: NetworkService = .shared,
        imageCacheService: ImageCacheService = .shared
    ) {
        self.networkService = networkService
        self.imageCacheService = imageCacheService
        setupCacheDirectory()
    }

    // MARK: - Public Methods

    /// Initializes the queue with the initial batch of cards.
    func initializeQueue() async {
        await MainActor.run {
            isLoading = true
        }

        do {
            try await fetchMoreCards(force: true)

            if !queue.isEmpty {
                await MainActor.run {
                    currentCard = queue.removeFirst()
                    isLoading = false
                }
            }
        } catch {
            await MainActor.run {
                self.error = .fetchFailed(error)
                isLoading = false
            }
        }
    }

    /// Handles a swipe action and updates the queue.
    func handleSwipe(action: SwipeAction, dwellTimeMs: Int) async {
        guard let current = currentCard else { return }

        // Create swipe event
        let event = SwipeEvent(
            action: action,
            productId: current.product.id,
            externalProductId: current.product.externalId,
            brandId: current.product.brandId,
            category: current.product.category,
            productTags: current.product.tags,
            sessionPosition: current.queuePosition,
            dwellTimeMs: dwellTimeMs
        )

        // Track the event
        await SwipeEventService.shared.trackEvent(event)

        // Move to next card
        await MainActor.run {
            if !queue.isEmpty {
                currentCard = queue.removeFirst()
            } else {
                currentCard = nil
            }
        }

        // Check if we need to fetch more cards
        if queue.count <= lowQueueThreshold {
            do {
                try await fetchMoreCards()
            } catch {
                // Silently handle fetch errors in background
            }
        }
    }

    /// Undoes the last swipe and restores the previous card.
    func undo() async {
        // In production, this would restore from a history
        // For now, we'll re-fetch the queue
        await refreshQueue()
    }

    /// Refreshes the entire queue.
    func refreshQueue() async {
        await MainActor.run {
            queue.removeAll()
            currentCard = nil
            isLoading = true
        }

        do {
            try await fetchMoreCards(force: true)

            if !queue.isEmpty {
                await MainActor.run {
                    currentCard = queue.removeFirst()
                    isLoading = false
                }
            }
        } catch {
            await MainActor.run {
                self.error = .fetchFailed(error)
                isLoading = false
            }
        }
    }

    // MARK: - Private Methods

    /// Fetches more cards from the API or cache.
    private func fetchMoreCards(force: Bool = false) async throws {
        guard !isRefetching || force else { return }

        let currentQueueSize = queue.count + (currentCard != nil ? 1 : 0)
        guard force || currentQueueSize < minQueueSize else { return }

        isRefetching = true
        defer { isRefetching = false }

        // Try to load from cache first
        if !force, let cachedCards = loadFromCache() {
            await MainActor.run {
                self.queue.append(contentsOf: cachedCards)
            }
            return
        }

        // Fetch from API
        let request = CardQueueRequest(limit: minQueueSize)
        let response: CardQueueResponse = try await networkService.request(
            "cards/queue",
            method: .post,
            body: request
        )

        let cardItems = response.products.enumerated().map { index, product in
            CardQueueItem(
                product: product,
                queuePosition: index,
                queueSize: response.products.count,
                sessionId: sessionId
            )
        }

        // Pre-fetch images
        for item in cardItems {
            for imageURL in item.product.imageURLs {
                imageCacheService.preloadImage(from: imageURL)
            }
        }

        // Save to cache
        saveToCache(cardItems)

        await MainActor.run {
            self.queue.append(contentsOf: cardItems)
        }
    }

    /// Sets up the cache directory.
    private func setupCacheDirectory() {
        let paths = FileManager.default.urls(
            for: .cachesDirectory,
            in: .userDomainMask
        )
        cacheDirectory = paths.first?.appendingPathComponent("CardQueue")

        if let cacheDir = cacheDirectory {
            try? FileManager.default.createDirectory(
                at: cacheDir,
                withIntermediateDirectories: true
            )
        }
    }

    /// Loads cards from local cache.
    private func loadFromCache() -> [CardQueueItem]? {
        guard let cacheDir = cacheDirectory else { return nil }

        let fileURL = cacheDir.appendingPathComponent("queue.json")

        guard FileManager.default.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL),
              let items = try? JSONDecoder().decode([CardQueueItem].self, from: data) else {
            return nil
        }

        return items
    }

    /// Saves cards to local cache.
    private func saveToCache(_ items: [CardQueueItem]) {
        guard let cacheDir = cacheDirectory else { return }

        let fileURL = cacheDir.appendingPathComponent("queue.json")

        if let encoded = try? JSONEncoder().encode(items) {
            try? encoded.write(to: fileURL)
        }
    }

    /// Clears the local cache.
    func clearCache() {
        guard let cacheDir = cacheDirectory else { return }

        let fileURL = cacheDir.appendingPathComponent("queue.json")
        try? FileManager.default.removeItem(at: fileURL)
    }
}

// MARK: - API Models

struct CardQueueRequest: Codable {
    let limit: Int
}

struct CardQueueResponse: Codable {
    let products: [Product]
    let totalCount: Int
}

// MARK: - Error Types

enum CardQueueError: LocalizedError {
    case fetchFailed(Error)
    case cacheFailed
    case invalidQueue

    var errorDescription: String? {
        switch self {
        case .fetchFailed(let error):
            return "Failed to fetch cards: \(error.localizedDescription)"
        case .cacheFailed:
            return "Failed to cache cards"
        case .invalidQueue:
            return "Invalid card queue state"
        }
    }
}
