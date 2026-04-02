import Foundation

/// Comprehensive analytics events enum with type-safe event definitions.
/// Each case maps to a specific event name and properties dictionary.
enum AnalyticsEvent {
    // MARK: - Onboarding Events

    /// User starts the onboarding flow.
    /// - Parameter source: Where onboarding was initiated ("app_launch", "settings", etc.)
    case onboardingStarted(source: String)

    /// User answers a quiz question.
    /// - Parameters:
    ///   - questionNumber: 1-indexed question number
    ///   - questionType: Type of question ("visual", "preference", etc.)
    ///   - answers: Selected answer indices or IDs
    ///   - timeSpentMs: Time spent on this question
    case quizQuestionAnswered(questionNumber: Int, questionType: String, answers: [String], timeSpentMs: Int)

    /// User completes the style quiz.
    /// - Parameter totalTimeMs: Total time spent on all questions
    case quizCompleted(totalTimeMs: Int)

    /// User abandons the quiz without completing it.
    /// - Parameters:
    ///   - lastQuestion: Last question number reached (1-indexed)
    ///   - timeSpentMs: Total time spent before abandoning
    case quizAbandoned(lastQuestion: Int, timeSpentMs: Int)

    /// User dismisses the onboarding tutorial.
    /// - Parameter method: How it was dismissed ("tap_x", "swipe_down", etc.)
    case tutorialDismissed(method: String)

    // MARK: - Swipe Events

    /// A product card is shown to the user.
    /// - Parameters:
    ///   - productId: UUID of the product
    ///   - brandId: UUID of the brand
    ///   - category: Product category
    ///   - price: Current price
    ///   - isOnSale: Whether the product is on sale
    ///   - retailerId: UUID of the retailer
    ///   - positionInSession: Position in the current swipe session (0-indexed)
    case cardImpression(
        productId: String,
        brandId: String,
        category: String,
        price: String,
        isOnSale: Bool,
        retailerId: String,
        positionInSession: Int
    )

    /// User swipes a card left or right.
    /// - Parameters:
    ///   - productId: UUID of the product
    ///   - direction: "left" (reject) or "right" (like)
    ///   - dwellTimeMs: Time spent viewing the card
    ///   - expandedBeforeSwipe: Whether user expanded the card before swiping
    case cardSwiped(
        productId: String,
        direction: String,
        dwellTimeMs: Int,
        expandedBeforeSwipe: Bool
    )

    /// User undoes a previous swipe.
    /// - Parameters:
    ///   - productId: UUID of the product
    ///   - originalDirection: Direction of the original swipe ("left" or "right")
    ///   - timeSinceSwipeMs: Time elapsed since the original swipe
    case cardUndo(
        productId: String,
        originalDirection: String,
        timeSinceSwipeMs: Int
    )

    /// User taps to expand a card for more details.
    /// - Parameters:
    ///   - productId: UUID of the product
    ///   - imagesViewedCount: Number of images viewed in detail
    ///   - timeInDetailMs: Time spent in detail view
    ///   - scrolledToSimilar: Whether user scrolled to similar items section
    case cardExpanded(
        productId: String,
        imagesViewedCount: Int,
        timeInDetailMs: Int,
        scrolledToSimilar: Bool
    )

    /// User clicks "Shop" to visit the retailer.
    /// - Parameters:
    ///   - productId: UUID of the product
    ///   - retailerId: UUID of the retailer
    ///   - price: Product price
    ///   - isOnSale: Whether the product is on sale
    ///   - affiliateNetwork: Affiliate network used ("commission_junction", "shareasale", etc.)
    case shopClicked(
        productId: String,
        retailerId: String,
        price: String,
        isOnSale: Bool,
        affiliateNetwork: String
    )

    /// User taps a similar item suggestion.
    /// - Parameters:
    ///   - sourceProductId: UUID of the original product
    ///   - tappedProductId: UUID of the similar item tapped
    case similarItemTapped(
        sourceProductId: String,
        tappedProductId: String
    )

    /// User reaches the end of the swipe feed.
    /// - Parameters:
    ///   - cardsSwipedInSession: Total cards swiped in this session
    ///   - sessionDurationMs: Total duration of the session
    case feedEndReached(cardsSwipedInSession: Int, sessionDurationMs: Int)

    // MARK: - Dresser Events

    /// User opens the Dresser.
    /// - Parameter source: Where the dresser was opened from ("swipe_feed", "tab_bar", etc.)
    case dresserOpened(source: String)

    /// User creates a new drawer.
    /// - Parameters:
    ///   - name: Name of the drawer
    ///   - totalDrawers: Total number of drawers after creation
    case drawerCreated(name: String, totalDrawers: Int)

    /// User renames a drawer.
    /// - Parameters:
    ///   - oldName: Previous drawer name
    ///   - newName: New drawer name
    case drawerRenamed(oldName: String, newName: String)

    /// User moves an item between drawers.
    /// - Parameters:
    ///   - productId: UUID of the product
    ///   - fromDrawer: Name of the source drawer
    ///   - toDrawer: Name of the destination drawer
    case dresserItemMoved(
        productId: String,
        fromDrawer: String,
        toDrawer: String
    )

    /// User removes an item from the dresser.
    /// - Parameters:
    ///   - productId: UUID of the product
    ///   - drawerId: UUID of the drawer
    case dresserItemRemoved(productId: String, drawerId: String)

    /// User shares a drawer or moodboard.
    /// - Parameters:
    ///   - drawerId: UUID of the drawer
    ///   - shareMethod: Share method ("instagram_stories", "messages", "copy_link", etc.)
    ///   - itemCount: Number of items in the shared drawer
    case dresserShared(
        drawerId: String,
        shareMethod: String,
        itemCount: Int
    )

    // MARK: - Profile & Style DNA Events

    /// User views their Style DNA.
    /// - Parameters:
    ///   - swipeCount: Total number of swipes used to generate the DNA
    ///   - archetype: Primary style archetype
    case styleDNAViewed(swipeCount: Int, archetype: String)

    /// User shares their Style DNA.
    /// - Parameters:
    ///   - shareMethod: Share method ("instagram_stories", "messages", "copy_link", etc.)
    ///   - archetype: Primary style archetype
    case styleDNAShared(shareMethod: String, archetype: String)

    /// User changes a setting.
    /// - Parameters:
    ///   - settingName: Name of the setting
    ///   - oldValue: Previous setting value
    ///   - newValue: New setting value
    case settingsChanged(
        settingName: String,
        oldValue: String,
        newValue: String
    )

    // MARK: - Notification Events

    /// User receives a notification.
    /// - Parameter type: Type of notification ("sale_alert", "new_items", "saved_items", etc.)
    case notificationReceived(type: String)

    /// User taps a notification.
    /// - Parameters:
    ///   - type: Type of notification
    ///   - productId: UUID of associated product (if applicable)
    ///   - timeSinceDeliveryMs: Time elapsed since notification delivery
    case notificationTapped(
        type: String,
        productId: String?,
        timeSinceDeliveryMs: Int
    )

    // MARK: - Session Events

    /// App session starts.
    /// - Parameters:
    ///   - daysSinceLastSession: Days since last session (0 if same day)
    ///   - entryPoint: Where the user entered the app ("home", "notification", "deep_link", etc.)
    case appSessionStart(daysSinceLastSession: Int, entryPoint: String)

    /// App session ends.
    /// - Parameters:
    ///   - durationMs: Total session duration
    ///   - cardsSwiped: Number of cards swiped in this session
    ///   - itemsSaved: Number of items saved in this session
    ///   - shopClicks: Number of times user clicked shop
    case appSessionEnd(
        durationMs: Int,
        cardsSwiped: Int,
        itemsSaved: Int,
        shopClicks: Int
    )

    // MARK: - Event Name and Properties

    /// Converts the event case to a user-friendly event name string.
    var eventName: String {
        switch self {
        case .onboardingStarted:
            return "onboarding_started"
        case .quizQuestionAnswered:
            return "quiz_question_answered"
        case .quizCompleted:
            return "quiz_completed"
        case .quizAbandoned:
            return "quiz_abandoned"
        case .tutorialDismissed:
            return "tutorial_dismissed"
        case .cardImpression:
            return "card_impression"
        case .cardSwiped:
            return "card_swiped"
        case .cardUndo:
            return "card_undo"
        case .cardExpanded:
            return "card_expanded"
        case .shopClicked:
            return "shop_clicked"
        case .similarItemTapped:
            return "similar_item_tapped"
        case .feedEndReached:
            return "feed_end_reached"
        case .dresserOpened:
            return "dresser_opened"
        case .drawerCreated:
            return "drawer_created"
        case .drawerRenamed:
            return "drawer_renamed"
        case .dresserItemMoved:
            return "dresser_item_moved"
        case .dresserItemRemoved:
            return "dresser_item_removed"
        case .dresserShared:
            return "dresser_shared"
        case .styleDNAViewed:
            return "style_dna_viewed"
        case .styleDNAShared:
            return "style_dna_shared"
        case .settingsChanged:
            return "settings_changed"
        case .notificationReceived:
            return "notification_received"
        case .notificationTapped:
            return "notification_tapped"
        case .appSessionStart:
            return "app_session_start"
        case .appSessionEnd:
            return "app_session_end"
        }
    }

    /// Converts the event case to a properties dictionary.
    var properties: [String: Any] {
        switch self {
        case let .onboardingStarted(source):
            return ["source": source]

        case let .quizQuestionAnswered(questionNumber, questionType, answers, timeSpentMs):
            return [
                "question_number": questionNumber,
                "question_type": questionType,
                "answers": answers,
                "time_spent_ms": timeSpentMs
            ]

        case let .quizCompleted(totalTimeMs):
            return ["total_time_ms": totalTimeMs]

        case let .quizAbandoned(lastQuestion, timeSpentMs):
            return [
                "last_question": lastQuestion,
                "time_spent_ms": timeSpentMs
            ]

        case let .tutorialDismissed(method):
            return ["method": method]

        case let .cardImpression(productId, brandId, category, price, isOnSale, retailerId, positionInSession):
            return [
                "product_id": productId,
                "brand_id": brandId,
                "category": category,
                "price": price,
                "is_on_sale": isOnSale,
                "retailer_id": retailerId,
                "position_in_session": positionInSession
            ]

        case let .cardSwiped(productId, direction, dwellTimeMs, expandedBeforeSwipe):
            return [
                "product_id": productId,
                "direction": direction,
                "dwell_time_ms": dwellTimeMs,
                "expanded_before_swipe": expandedBeforeSwipe
            ]

        case let .cardUndo(productId, originalDirection, timeSinceSwipeMs):
            return [
                "product_id": productId,
                "original_direction": originalDirection,
                "time_since_swipe_ms": timeSinceSwipeMs
            ]

        case let .cardExpanded(productId, imagesViewedCount, timeInDetailMs, scrolledToSimilar):
            return [
                "product_id": productId,
                "images_viewed_count": imagesViewedCount,
                "time_in_detail_ms": timeInDetailMs,
                "scrolled_to_similar": scrolledToSimilar
            ]

        case let .shopClicked(productId, retailerId, price, isOnSale, affiliateNetwork):
            return [
                "product_id": productId,
                "retailer_id": retailerId,
                "price": price,
                "is_on_sale": isOnSale,
                "affiliate_network": affiliateNetwork
            ]

        case let .similarItemTapped(sourceProductId, tappedProductId):
            return [
                "source_product_id": sourceProductId,
                "tapped_product_id": tappedProductId
            ]

        case let .feedEndReached(cardsSwipedInSession, sessionDurationMs):
            return [
                "cards_swiped_in_session": cardsSwipedInSession,
                "session_duration_ms": sessionDurationMs
            ]

        case let .dresserOpened(source):
            return ["source": source]

        case let .drawerCreated(name, totalDrawers):
            return [
                "drawer_name": name,
                "total_drawers": totalDrawers
            ]

        case let .drawerRenamed(oldName, newName):
            return [
                "old_name": oldName,
                "new_name": newName
            ]

        case let .dresserItemMoved(productId, fromDrawer, toDrawer):
            return [
                "product_id": productId,
                "from_drawer": fromDrawer,
                "to_drawer": toDrawer
            ]

        case let .dresserItemRemoved(productId, drawerId):
            return [
                "product_id": productId,
                "drawer_id": drawerId
            ]

        case let .dresserShared(drawerId, shareMethod, itemCount):
            return [
                "drawer_id": drawerId,
                "share_method": shareMethod,
                "item_count": itemCount
            ]

        case let .styleDNAViewed(swipeCount, archetype):
            return [
                "swipe_count": swipeCount,
                "archetype": archetype
            ]

        case let .styleDNAShared(shareMethod, archetype):
            return [
                "share_method": shareMethod,
                "archetype": archetype
            ]

        case let .settingsChanged(settingName, oldValue, newValue):
            return [
                "setting_name": settingName,
                "old_value": oldValue,
                "new_value": newValue
            ]

        case let .notificationReceived(type):
            return ["notification_type": type]

        case let .notificationTapped(type, productId, timeSinceDeliveryMs):
            var props: [String: Any] = [
                "notification_type": type,
                "time_since_delivery_ms": timeSinceDeliveryMs
            ]
            if let productId = productId {
                props["product_id"] = productId
            }
            return props

        case let .appSessionStart(daysSinceLastSession, entryPoint):
            return [
                "days_since_last_session": daysSinceLastSession,
                "entry_point": entryPoint
            ]

        case let .appSessionEnd(durationMs, cardsSwiped, itemsSaved, shopClicks):
            return [
                "duration_ms": durationMs,
                "cards_swiped": cardsSwiped,
                "items_saved": itemsSaved,
                "shop_clicks": shopClicks
            ]
        }
    }
}
