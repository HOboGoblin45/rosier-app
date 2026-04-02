import UIKit
import UserNotifications
import BackgroundTasks
import SwiftUI

/// Application delegate for managing app lifecycle and push notifications.
class AppDelegate: NSObject, UIApplicationDelegate {
    // MARK: - Lifecycle Methods

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        setupPushNotifications()
        setupAppearance()
        setupAnalytics()
        setupBackgroundTasks()
        setupOfflineSync()

        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Resume any necessary services
        AnalyticsService.shared.startSession()
        PushNotificationService.shared.clearAllNotifications()

        // Schedule background tasks on resume
        BackgroundTaskService.shared.scheduleAppRefresh()
        BackgroundTaskService.shared.scheduleProcessingTask()
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Pause any services
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Save data and stop heavy processing
        Task {
            await SwipeEventService.shared.handleAppBackground()
            await OfflineSyncService.shared.performInitialSync()
        }
        AnalyticsService.shared.endSession()

        // Schedule background tasks when entering background
        BackgroundTaskService.shared.scheduleAppRefresh()
        BackgroundTaskService.shared.scheduleProcessingTask()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Refresh UI and restart services
        Task {
            await OfflineSyncService.shared.syncUnyncedSwipeEvents()
        }
    }

    // MARK: - Remote Notifications

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()

        // Register with push notification service
        Task {
            await PushNotificationService.shared.registerDeviceToken(token)
        }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("Failed to register for remote notifications: \(error)")
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo
        let actionIdentifier = notification.request.content.categoryIdentifier

        // Handle foreground notification
        handleNotificationAction(userInfo: userInfo, actionId: actionIdentifier)

        // Show notification in foreground
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let actionIdentifier = response.actionIdentifier

        // Handle notification action
        handleNotificationAction(userInfo: userInfo, actionId: actionIdentifier)

        completionHandler()
    }

    // MARK: - Private Methods

    /// Sets up push notification handling.
    private func setupPushNotifications() {
        UNUserNotificationCenter.current().delegate = self

        Task {
            let granted = await PushNotificationService.shared.requestNotificationPermissions()
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }

    /// Sets up background task handlers.
    private func setupBackgroundTasks() {
        BackgroundTaskService.shared.registerBackgroundTasks()
    }

    /// Sets up offline sync service.
    private func setupOfflineSync() {
        Task {
            await OfflineSyncService.shared.performInitialSync()
        }
    }

    /// Sets up global app appearance.
    private func setupAppearance() {
        // Configure navigation bar appearance
        let navigationAppearance = UINavigationBarAppearance()
        navigationAppearance.configureWithDefaultBackground()
        navigationAppearance.backgroundColor = UIColor(Color.surfaceCard)

        UINavigationBar.appearance().standardAppearance = navigationAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navigationAppearance

        // Configure tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithDefaultBackground()
        tabBarAppearance.backgroundColor = UIColor(Color.surfaceCard)

        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }

    /// Sets up analytics service.
    private func setupAnalytics() {
        AnalyticsService.shared.startSession()
    }

    /// Handles notification action.
    private func handleNotificationAction(userInfo: [AnyHashable: Any], actionId: String) {
        switch actionId {
        case "PRICE_DROP_SHOP", "PRICE_DROP_DISMISS":
            handlePriceDropAction(userInfo: userInfo, actionId: actionId)
        case "DAILY_DROP_VIEW":
            DeepLinkService.shared.handleURL(DeepLink.dailyDrop.universalURL() ?? URL(string: "rosier://")!)
        case "SALE_ALERT_VIEW":
            if let retailerIdString = userInfo["retailerId"] as? String,
               let retailerId = UUID(uuidString: retailerIdString) {
                let deepLink = DeepLink.dresserSaleFilter(retailerId: retailerId)
                DeepLinkService.shared.handleURL(deepLink.universalURL() ?? URL(string: "rosier://")!)
            }
        case "REENGAGEMENT_OPEN":
            DeepLinkService.shared.handleURL(DeepLink.swipeFeed.universalURL() ?? URL(string: "rosier://")!)
        case UNNotificationDefaultActionIdentifier:
            // Notification tapped without specific action
            PushNotificationService.shared.handleNotification(userInfo: userInfo)
        default:
            break
        }
    }

    /// Handles price drop notification action.
    private func handlePriceDropAction(userInfo: [AnyHashable: Any], actionId: String) {
        guard actionId == "PRICE_DROP_SHOP" else { return }

        if let productIdString = userInfo["productId"] as? String,
           let productId = UUID(uuidString: productIdString) {
            let deepLink = DeepLink.product(id: productId)
            if let url = deepLink.universalURL() {
                DeepLinkService.shared.handleURL(url)
            }
        }
    }
}

// MARK: - UNUserNotificationCenter Delegate

extension AppDelegate: UNUserNotificationCenterDelegate {
    // Already implemented above
}

