import Foundation
import SwiftUI


/// ViewModel for the swipe interface, managing card queue, events, and state.
@Observable
final class SwipeViewModel {
    // MARK: - Published State

    var currentCard: CardQueueItem?
    var nextCard: CardQueueItem?
    var thirdCard: CardQueueItem?
    var queue: [CardQueueItem] = []

    var isLoading = false
    var error: CardQueueError?
    var isOffline = false
    var newItemsCount = 0

    // MARK: - Properties

    private let cardQueueService: CardQueueService
    private let swipeEventService = SwipeEventService.shared
    private let hapticsManager = HapticsManager.shared

    private var sessionId: UUID
    private var positionCounter = 0
    private var cardDwellStartTime: Date?
    private var undoStack: CardQueueItem?
    private var lastSwipeAction: SwipeAction?

    private var networkMonitor: NetworkStatusMonitor?

    // MARK: - Initializers

    init(cardQueueService: CardQueueService = CardQueueService()) {
        self.cardQueueService = cardQueueService
        self.sessionId = UUID()
        setupNetworkMonitoring()
    }

    // MARK: - Public Methods

    /// Initializes the swipe view and loads the initial card queue.
    func initializeSwipeView() async {
        await MainActor.run {
            isLoading = true
        }

        await cardQueueService.initializeQueue()

        await MainActor.run {
            isLoading = false
            updateVisibleCards()
        }
    }

    /// Handles a swipe action (like, reject, super like).
    func handleSwipe(_ action: SwipeAction) {
        guard let card = currentCard else { return }

        // Record dwell time
        let dwellTimeMs = dwellTimeMilliseconds()

        // Trigger haptic feedback
        triggerHapticFeedback(for: action)

        // Track the event
        Task {
            await swipeEventService.trackEvent(
                SwipeEvent(
                    action: action,
                    productId: card.product.id,
                    externalProductId: card.product.externalId,
                    brandId: card.product.brandId,
                    category: card.product.category,
                    productTags: card.product.tags,
                    sessionPosition: positionCounter,
                    dwellTimeMs: dwellTimeMs
                )
            )
        }

        // Store for undo capability
        undoStack = currentCard
        lastSwipeAction = action

        // Move to next card
        moveToNextCard()

        // Check if we need to pre-fetch more cards
        checkForPrefetch()
    }

    /// Handles a view detail action (tap on card).
    func handleViewDetail() {
        guard let card = currentCard else { return }

        let dwellTimeMs = dwellTimeMilliseconds()

        Task {
            var event = SwipeEvent(
                action: .viewDetail,
                productId: card.product.id,
                externalProductId: card.product.externalId,
                brandId: card.product.brandId,
                category: card.product.category,
                productTags: card.product.tags,
                sessionPosition: positionCounter,
                dwellTimeMs: dwellTimeMs
            )
            // Mark as expanded
            await swipeEventService.trackEvent(event)
        }
    }

    /// Undoes the last swipe action and restores the previous card.
    func undo() {
        guard let previousCard = undoStack else { return }

        hapticsManager.undo()

        // Restore the card to the front of the queue
        currentCard = previousCard

        // Restore next and third cards by shifting
        if !queue.isEmpty {
            nextCard = queue.first
            thirdCard = queue.count > 1 ? queue[1] : nil
        } else {
            nextCard = nil
            thirdCard = nil
        }

        // Clear undo stack
        undoStack = nil
        lastSwipeAction = nil

        // Reset dwell timer
        startDwellTracking()
    }

    /// Starts dwell time tracking for the current card.
    func startDwellTracking() {
        cardDwellStartTime = Date()
    }

    // MARK: - Private Methods

    /// Updates the visible card state based on the queue.
    private func updateVisibleCards() {
        if queue.isEmpty && cardQueueService.currentCard == nil {
            currentCard = nil
            nextCard = nil
            thirdCard = nil
            return
        }

        if currentCard == nil {
            currentCard = cardQueueService.currentCard
        }

        nextCard = queue.count > 0 ? queue[0] : nil
        thirdCard = queue.count > 1 ? queue[1] : nil
    }

    /// Moves to the next card in the queue.
    private func moveToNextCard() {
        positionCounter += 1

        if !queue.isEmpty {
            currentCard = queue.removeFirst()
            updateVisibleCards()
            startDwellTracking()
        } else {
            currentCard = nil
            nextCard = nil
            thirdCard = nil
        }
    }

    /// Checks if we need to pre-fetch more cards.
    private func checkForPrefetch() {
        guard let current = currentCard else { return }

        if current.isQueueLow {
            Task {
                await cardQueueService.handleSwipe(
                    action: lastSwipeAction ?? .reject,
                    dwellTimeMs: dwellTimeMilliseconds()
                )
            }
        }
    }

    /// Calculates dwell time in milliseconds.
    private func dwellTimeMilliseconds() -> Int {
        guard let startTime = cardDwellStartTime else { return 0 }
        let elapsed = Date().timeIntervalSince(startTime)
        return Int(elapsed * 1000)
    }

    /// Triggers appropriate haptic feedback for the swipe action.
    private func triggerHapticFeedback(for action: SwipeAction) {
        switch action {
        case .like:
            hapticsManager.swipeRight()
        case .reject:
            hapticsManager.swipeLeft()
        case .superLike:
            hapticsManager.superLike()
        case .undo:
            hapticsManager.undo()
        case .viewDetail:
            hapticsManager.buttonPress()
        case .shopClick:
            hapticsManager.selection()
        }
    }

    /// Sets up network status monitoring.
    private func setupNetworkMonitoring() {
        networkMonitor = NetworkStatusMonitor { [weak self] isOnline in
            Task { @MainActor in
                self?.isOffline = !isOnline
            }
        }
    }
}

// MARK: - Network Status Monitor

/// Monitors network connectivity status.
final class NetworkStatusMonitor {
    private let onChange: (Bool) -> Void

    init(onChange: @escaping (Bool) -> Void) {
        self.onChange = onChange
        // In production, use Network framework to monitor actual connectivity
        // For now, assume online
        onChange(true)
    }
}
