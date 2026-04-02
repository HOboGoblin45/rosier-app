import Foundation

/// Analytics service protocol for flexible provider implementation.
public protocol AnalyticsServiceProtocol {
    func trackEvent(_ name: String, properties: [String: Any]?)
    func trackScreenView(_ screenName: String)
    func trackUserAction(_ action: UserAction)
    func setUserProperty(_ property: String, value: Any)
    func startSession()
    func endSession()
    func flush()
}

/// Concrete analytics service implementation.
public final class AnalyticsService: AnalyticsServiceProtocol {
    // MARK: - Singleton

    public static let shared = AnalyticsService()

    // MARK: - Properties

    private let sessionId = UUID().uuidString
    private var sessionStartTime = Date()
    private var events: [AnalyticsEventRecord] = []
    private let networkService: NetworkService
    private let maxBufferSize = 100

    // MARK: - Initializers

    public init(networkService: NetworkService = .shared) {
        self.networkService = networkService
    }

    // MARK: - Public Methods

    /// Tracks a custom analytics event.
    public func trackEvent(_ name: String, properties: [String: Any]? = nil) {
        let event = AnalyticsEventRecord(
            sessionId: sessionId,
            name: name,
            properties: properties ?? [:],
            timestamp: Date()
        )

        events.append(event)

        if events.count >= maxBufferSize {
            flush()
        }
    }

    /// Tracks a screen view.
    public func trackScreenView(_ screenName: String) {
        trackEvent("screen_view", properties: ["screen_name": screenName])
    }

    /// Tracks a user action.
    public func trackUserAction(_ action: UserAction) {
        let properties: [String: Any] = [
            "action_type": action.type.rawValue,
            "action_name": action.name,
            "timestamp": Date().timeIntervalSince1970,
        ]

        trackEvent("user_action", properties: properties)
    }

    /// Sets a user property for segmentation.
    public func setUserProperty(_ property: String, value: Any) {
        trackEvent("user_property", properties: [
            "property": property,
            "value": String(describing: value),
        ])
    }

    /// Starts a new analytics session.
    public func startSession() {
        sessionStartTime = Date()
        trackEvent("session_start")
    }

    /// Ends the current analytics session.
    public func endSession() {
        let duration = Date().timeIntervalSince(sessionStartTime)
        trackEvent("session_end", properties: ["duration_seconds": duration])
        flush()
    }

    /// Flushes buffered events to the server.
    public func flush() {
        guard !events.isEmpty else { return }

        let eventsToSend = events
        events.removeAll()

        Task {
            do {
                let request = AnalyticsEventBatch(events: eventsToSend)
                try await networkService.requestEmpty(
                    "analytics/events",
                    method: .post,
                    body: request
                )
            } catch {
                // Re-add events on failure for retry
                self.events.append(contentsOf: eventsToSend)
                print("Failed to flush analytics events: \(error)")
            }
        }
    }

    // MARK: - Swipe-Specific Analytics

    /// Tracks a card swipe action.
    func trackSwipe(
        productId: UUID,
        action: SwipeAction,
        dwellTimeMs: Int,
        position: Int
    ) {
        let properties: [String: Any] = [
            "product_id": productId.uuidString,
            "action": action.rawValue,
            "dwell_time_ms": dwellTimeMs,
            "position": position,
        ]

        trackEvent("card_swiped", properties: properties)
    }

    /// Tracks when a product detail is viewed.
    func trackProductViewed(_ product: Product, source: String = "swipe") {
        let properties: [String: Any] = [
            "product_id": product.id.uuidString,
            "brand_id": product.brandId.uuidString,
            "brand_name": product.brandName,
            "category": product.category.rawValue,
            "price": product.currentPrice.description,
            "source": source,
        ]

        trackEvent("product_viewed", properties: properties)
    }

    /// Tracks when a product is saved to dresser.
    func trackProductSaved(_ product: Product, drawer: DresserDrawer) {
        let properties: [String: Any] = [
            "product_id": product.id.uuidString,
            "drawer_id": drawer.id.uuidString,
            "brand_name": product.brandName,
            "category": product.category.rawValue,
        ]

        trackEvent("product_saved", properties: properties)
    }

    /// Tracks a shop click.
    func trackShopClick(
        productId: UUID,
        brandName: String,
        retailerName: String
    ) {
        let properties: [String: Any] = [
            "product_id": productId.uuidString,
            "brand_name": brandName,
            "retailer_name": retailerName,
        ]

        trackEvent("shop_click", properties: properties)
    }

    /// Tracks sign in event.
    func trackSignIn(method: String) {
        trackEvent("sign_in", properties: ["method": method])
    }

    /// Tracks style quiz completion.
    func trackQuizCompleted(archetype: String) {
        trackEvent("quiz_completed", properties: ["archetype": archetype])
    }
}

// MARK: - Analytics Models

struct AnalyticsEventRecord: Codable {
    let sessionId: String
    let name: String
    let properties: [String: String]
    let timestamp: Date

    init(
        sessionId: String,
        name: String,
        properties: [String: Any],
        timestamp: Date
    ) {
        self.sessionId = sessionId
        self.name = name
        self.timestamp = timestamp

        // Convert all properties to strings
        self.properties = properties.mapValues { value in
            String(describing: value)
        }
    }
}

struct AnalyticsEventBatch: Codable {
    let events: [AnalyticsEventRecord]
}

// MARK: - User Action Model

struct UserAction {
    enum ActionType: String {
        case swipe
        case tap
        case scroll
        case search
        case filter
        case share
        case custom
    }

    let type: ActionType
    let name: String
    let metadata: [String: Any]?

    init(
        type: ActionType = .custom,
        name: String,
        metadata: [String: Any]? = nil
    ) {
        self.type = type
        self.name = name
        self.metadata = metadata
    }
}
