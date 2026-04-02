import Foundation
import UserNotifications
import SafariServices
import UIKit

/// Manages push notifications including permissions, registration, and deep linking.
public final class PushNotificationService: NSObject, ObservableObject {
    // MARK: - Singleton

    public static let shared = PushNotificationService()

    // MARK: - Published Properties

    @Published public var notificationEnabled = false
    @Published public var badgeCount = 0

    // MARK: - Properties

    private let networkService = NetworkService.shared
    private let notificationCenter = UNUserNotificationCenter.current()

    private let categories: [UNNotificationCategory] = [
        createPriceDropCategory(),
        createDailyDropCategory(),
        createSaleAlertCategory(),
        createReEngagementCategory()
    ]

    // MARK: - Initializers

    override init() {
        super.init()
        notificationCenter.setNotificationCategories(Set(categories))
    }

    // MARK: - Public Methods

    /// Requests notification permissions and registers for remote notifications.
    public func requestNotificationPermissions() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(
                options: [.alert, .sound, .badge]
            )

            if granted {
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                    self.notificationEnabled = true
                }
            }

            return granted
        } catch {
            print("Failed to request notification permissions: \(error)")
            return false
        }
    }

    /// Registers device token with the backend.
    func registerDeviceToken(_ token: String) async {
        do {
            let request = DeviceTokenRequest(deviceToken: token)
            try await networkService.requestEmpty(
                "profile/device_token",
                method: .post,
                body: request
            )
        } catch {
            print("Failed to register device token: \(error)")
        }
    }

    /// Handles an incoming notification.
    func handleNotification(userInfo: [AnyHashable: Any]) {
        guard let notificationType = userInfo["type"] as? String else {
            return
        }

        switch notificationType {
        case "price_drop":
            handlePriceDropNotification(userInfo)
        case "daily_drop":
            handleDailyDropNotification(userInfo)
        case "sale_alert":
            handleSaleAlertNotification(userInfo)
        case "re_engagement":
            handleReEngagementNotification(userInfo)
        default:
            break
        }

        // Check for deep link
        if let deepLinkString = userInfo["deepLink"] as? String,
           let deepLinkURL = URL(string: deepLinkString) {
            DeepLinkService.shared.handleURL(deepLinkURL)
        }
    }

    /// Sets the badge count on the app icon.
    func setBadgeCount(_ count: Int) {
        Task { @MainActor in
            self.badgeCount = count
            UIApplication.shared.applicationIconBadgeNumber = count
        }
    }

    /// Clears all notifications.
    func clearAllNotifications() {
        notificationCenter.removeAllDeliveredNotifications()
        setBadgeCount(0)
    }

    // MARK: - Private Methods

    /// Handles price drop notifications.
    private func handlePriceDropNotification(_ userInfo: [AnyHashable: Any]) {
        guard let productIdString = userInfo["productId"] as? String,
              let productId = UUID(uuidString: productIdString) else {
            return
        }

        let deepLink = DeepLink.product(id: productId)
        if let url = deepLink.universalURL() {
            DeepLinkService.shared.handleURL(url)
        }
    }

    /// Handles daily drop notifications.
    private func handleDailyDropNotification(_ userInfo: [AnyHashable: Any]) {
        // Navigate to daily 5 screen
        let deepLink = DeepLink.dailyDrop
        if let url = deepLink.universalURL() {
            DeepLinkService.shared.handleURL(url)
        }
    }

    /// Handles sale alert notifications.
    private func handleSaleAlertNotification(_ userInfo: [AnyHashable: Any]) {
        guard let retailerIdString = userInfo["retailerId"] as? String,
              let retailerId = UUID(uuidString: retailerIdString) else {
            return
        }

        let deepLink = DeepLink.dresserSaleFilter(retailerId: retailerId)
        if let url = deepLink.universalURL() {
            DeepLinkService.shared.handleURL(url)
        }
    }

    /// Handles re-engagement notifications.
    private func handleReEngagementNotification(_ userInfo: [AnyHashable: Any]) {
        // Open app to swipe feed
        let deepLink = DeepLink.swipeFeed
        if let url = deepLink.universalURL() {
            DeepLinkService.shared.handleURL(url)
        }
    }

    // MARK: - Category Creators

    /// Creates the price drop notification category.
    private static func createPriceDropCategory() -> UNNotificationCategory {
        let shopNowAction = UNNotificationAction(
            identifier: "PRICE_DROP_SHOP",
            title: "Shop Now",
            options: .foreground
        )

        let dismissAction = UNNotificationAction(
            identifier: "PRICE_DROP_DISMISS",
            title: "Dismiss",
            options: []
        )

        return UNNotificationCategory(
            identifier: "PRICE_DROP",
            actions: [shopNowAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )
    }

    /// Creates the daily drop notification category.
    private static func createDailyDropCategory() -> UNNotificationCategory {
        let viewAction = UNNotificationAction(
            identifier: "DAILY_DROP_VIEW",
            title: "View",
            options: .foreground
        )

        return UNNotificationCategory(
            identifier: "DAILY_DROP",
            actions: [viewAction],
            intentIdentifiers: [],
            options: []
        )
    }

    /// Creates the sale alert notification category.
    private static func createSaleAlertCategory() -> UNNotificationCategory {
        let viewSalesAction = UNNotificationAction(
            identifier: "SALE_ALERT_VIEW",
            title: "View Sales",
            options: .foreground
        )

        return UNNotificationCategory(
            identifier: "SALE_ALERT",
            actions: [viewSalesAction],
            intentIdentifiers: [],
            options: []
        )
    }

    /// Creates the re-engagement notification category.
    private static func createReEngagementCategory() -> UNNotificationCategory {
        let openAction = UNNotificationAction(
            identifier: "REENGAGEMENT_OPEN",
            title: "Open",
            options: .foreground
        )

        return UNNotificationCategory(
            identifier: "RE_ENGAGEMENT",
            actions: [openAction],
            intentIdentifiers: [],
            options: []
        )
    }
}

// MARK: - API Models

struct DeviceTokenRequest: Codable {
    let deviceToken: String
}

