import Foundation

/// Batches swipe events and sends them to the backend with retry logic.
final class SwipeEventService {
    // MARK: - Singleton

    static let shared = SwipeEventService()

    // MARK: - Properties

    private let networkService: NetworkService
    private var eventQueue: [SwipeEvent] = []
    private var timer: Timer?
    private var isUploading = false
    private let batchInterval: TimeInterval = 10.0
    private let persistenceKey = "rosier_swipe_events"

    // MARK: - Initializers

    init(networkService: NetworkService = .shared) {
        self.networkService = networkService
        loadPersistedEvents()
        startBatchTimer()
    }

    deinit {
        stopBatchTimer()
    }

    // MARK: - Public Methods

    /// Tracks a swipe event and adds it to the batch queue.
    func trackEvent(_ event: SwipeEvent) async {
        await MainActor.run {
            eventQueue.append(event)
            persistEvents()
        }

        // If we have a reasonable number of events, upload immediately
        if eventQueue.count >= 10 {
            await uploadBatch()
        }
    }

    /// Uploads batched events immediately.
    func uploadBatch() async {
        guard !isUploading, !eventQueue.isEmpty else { return }

        isUploading = true
        defer { isUploading = false }

        let eventsToUpload = eventQueue
        let request = SwipeEventBatchRequest(events: eventsToUpload)

        do {
            try await networkService.requestEmpty(
                "analytics/swipes",
                method: .post,
                body: request
            )

            await MainActor.run {
                self.eventQueue.removeAll()
                self.persistEvents()
            }
        } catch {
            // Keep events in queue for retry
            print("Failed to upload events: \(error)")
        }
    }

    // MARK: - Private Methods

    /// Starts the batch timer for periodic uploads.
    private func startBatchTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: batchInterval, repeats: true) { [weak self] _ in
            Task {
                await self?.uploadBatch()
            }
        }
    }

    /// Stops the batch timer.
    private func stopBatchTimer() {
        timer?.invalidate()
        timer = nil
    }

    /// Persists events to disk.
    private func persistEvents() {
        guard let encoded = try? JSONEncoder().encode(eventQueue) else { return }
        UserDefaults.standard.set(encoded, forKey: persistenceKey)
    }

    /// Loads persisted events from disk.
    private func loadPersistedEvents() {
        guard let data = UserDefaults.standard.data(forKey: persistenceKey),
              let events = try? JSONDecoder().decode([SwipeEvent].self, from: data) else {
            return
        }
        eventQueue = events
    }

    /// Handles app background notification.
    func handleAppBackground() async {
        await uploadBatch()
    }
}

// MARK: - API Models

struct SwipeEventBatchRequest: Codable {
    let events: [SwipeEvent]
}
