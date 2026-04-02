import Foundation

/// Wrapper around a Product with queue-specific metadata for card swiping.
public struct CardQueueItem: Identifiable, Hashable, Codable {
    // MARK: - Identifiers

    /// Unique identifier for this queue item.
    let id: UUID

    // MARK: - Product Reference

    /// The actual product being presented.
    let product: Product

    // MARK: - Queue Metadata

    /// Current position in the queue (0-based index).
    let queuePosition: Int

    /// Total size of the queue.
    let queueSize: Int

    /// Session identifier for analytics.
    let sessionId: UUID

    /// Whether this item has been interacted with.
    let hasBeenInteracted: Bool

    /// Timestamp when item entered the queue.
    let enqueuedAt: Date

    // MARK: - Hashable Conformance

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: CardQueueItem, rhs: CardQueueItem) -> Bool {
        lhs.id == rhs.id
    }

    // MARK: - Computed Properties

    /// Whether this is the first card in the queue.
    var isFirstCard: Bool {
        queuePosition == 0
    }

    /// Whether this is the last card in the queue.
    var isLastCard: Bool {
        queuePosition == queueSize - 1
    }

    /// Progress through the queue (0-1).
    var progress: Double {
        queueSize > 0 ? Double(queuePosition) / Double(queueSize) : 0
    }

    /// Number of cards remaining after this one.
    var remainingCards: Int {
        max(0, queueSize - queuePosition - 1)
    }

    /// Whether the queue is running low (5 or fewer cards remaining).
    var isQueueLow: Bool {
        remainingCards <= 5
    }

    // MARK: - Initializers

    /// Creates a new card queue item.
    /// - Parameters:
    ///   - product: The product to queue
    ///   - queuePosition: Current position in queue
    ///   - queueSize: Total queue size
    ///   - sessionId: Session identifier
    public init(
        product: Product,
        queuePosition: Int,
        queueSize: Int,
        sessionId: UUID = UUID()
    ) {
        self.id = UUID()
        self.product = product
        self.queuePosition = queuePosition
        self.queueSize = queueSize
        self.sessionId = sessionId
        self.hasBeenInteracted = false
        self.enqueuedAt = Date()
    }

    /// Creates a copy of this item with updated interaction status.
    func markAsInteracted() -> CardQueueItem {
        var copy = self
        return CardQueueItem(
            product: copy.product,
            queuePosition: copy.queuePosition,
            queueSize: copy.queueSize,
            sessionId: copy.sessionId
        )
    }
}
