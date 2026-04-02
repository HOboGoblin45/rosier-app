import BackgroundTasks
import Foundation

/// Manages iOS Background Tasks for syncing and cache management.
public final class BackgroundTaskService {
    // MARK: - Singleton

    public static let shared = BackgroundTaskService()

    // MARK: - Constants

    private let appRefreshTaskId = "com.rosier.app.refresh"
    private let processingTaskId = "com.rosier.app.processing"

    // MARK: - Properties

    private let offlineSyncService = OfflineSyncService.shared
    private let persistenceController = PersistenceController.shared

    // MARK: - Initialization

    /// Registers background task handlers. Call from AppDelegate.
    public func registerBackgroundTasks() {
        registerAppRefreshTask()
        registerProcessingTask()
    }

    /// Schedules the app refresh background task.
    public func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: appRefreshTaskId)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 2 * 60 * 60) // 2 hours

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Failed to schedule app refresh task: \(error)")
        }
    }

    /// Schedules the processing background task.
    func scheduleProcessingTask() {
        let request = BGProcessingTaskRequest(identifier: processingTaskId)
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = true

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Failed to schedule processing task: \(error)")
        }
    }

    // MARK: - Private Methods

    /// Registers the app refresh task handler.
    private func registerAppRefreshTask() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: appRefreshTaskId,
            using: nil
        ) { [weak self] task in
            self?.handleAppRefreshTask(task as! BGAppRefreshTask)
        }
    }

    /// Registers the processing task handler.
    private func registerProcessingTask() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: processingTaskId,
            using: nil
        ) { [weak self] task in
            self?.handleProcessingTask(task as! BGProcessingTask)
        }
    }

    /// Handles the app refresh background task.
    private func handleAppRefreshTask(_ task: BGAppRefreshTask) {
        // Schedule next refresh
        scheduleAppRefresh()

        let taskQueue = OperationQueue()
        taskQueue.maxConcurrentOperationCount = 1

        let backgroundTask = BlockOperation {
            Task {
                do {
                    // Sync unsynced swipe events
                    await self.offlineSyncService.syncUnyncedSwipeEvents()

                    // Refresh card queue cache
                    await self.offlineSyncService.prefetchCardQueue()

                    // Check for price updates on dresser items
                    await self.offlineSyncService.checkDresserPriceDrops()

                    // Mark task as complete
                    DispatchQueue.main.async {
                        task.setTaskCompleted(success: true)
                    }
                } catch {
                    print("App refresh task failed: \(error)")
                    DispatchQueue.main.async {
                        task.setTaskCompleted(success: false)
                    }
                }
            }
        }

        task.expirationHandler = {
            taskQueue.cancelAllOperations()
            task.setTaskCompleted(success: false)
        }

        taskQueue.addOperation(backgroundTask)
    }

    /// Handles the processing background task.
    private func handleProcessingTask(_ task: BGProcessingTask) {
        // Schedule next processing task
        scheduleProcessingTask()

        let taskQueue = OperationQueue()
        taskQueue.maxConcurrentOperationCount = 1

        let backgroundTask = BlockOperation {
            Task {
                do {
                    // Download and cache next batch of card images
                    await self.cacheCardImages()

                    // Clean expired cache entries
                    try self.persistenceController.cleanExpiredCache(olderThanDays: 7)

                    // Mark task as complete
                    DispatchQueue.main.async {
                        task.setTaskCompleted(success: true)
                    }
                } catch {
                    print("Processing task failed: \(error)")
                    DispatchQueue.main.async {
                        task.setTaskCompleted(success: false)
                    }
                }
            }
        }

        task.expirationHandler = {
            taskQueue.cancelAllOperations()
            task.setTaskCompleted(success: false)
        }

        taskQueue.addOperation(backgroundTask)
    }

    /// Caches card images for offline access.
    private func cacheCardImages() async {
        let imageCacheService = ImageCacheService.shared

        let cachedProducts = await offlineSyncService.getOfflineCardQueue()

        for product in cachedProducts {
            for imageURL in product.imageURLs {
                imageCacheService.preloadImage(from: imageURL)
            }
        }
    }
}
