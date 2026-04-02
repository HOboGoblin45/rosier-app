import CoreData
import Foundation
import Network

/// Manages offline caching and sync between Core Data cache and remote API.
final class OfflineSyncService: NSObject, ObservableObject {
    // MARK: - Singleton

    static let shared = OfflineSyncService()

    // MARK: - Published Properties

    @Published var isSyncing = false
    @Published var isOnline = true

    // MARK: - Properties

    private let persistenceController: PersistenceController
    private let networkService: NetworkService
    private let pathMonitor = NWPathMonitor()
    private let pathQueue = DispatchQueue(label: "com.rosier.pathmonitor")

    private let minQueueCacheSize = 40
    private let cardCacheBatchSize = 50

    // MARK: - Initializers

    override init() {
        self.persistenceController = PersistenceController.shared
        self.networkService = NetworkService.shared

        super.init()

        setupNetworkMonitoring()
    }

    // MARK: - Public Methods

    /// Performs initial sync on app launch (syncs unsynced events, caches queue).
    func performInitialSync() async {
        await syncUnyncedSwipeEvents()
        await prefetchCardQueue()
    }

    /// Syncs any unsynced swipe events to the backend.
    func syncUnyncedSwipeEvents() async {
        guard isOnline else { return }

        await MainActor.run {
            isSyncing = true
        }

        defer {
            MainActor.run {
                isSyncing = false
            }
        }

        do {
            try await persistenceController.performBackgroundTaskWithSave { context in
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "CachedSwipeEvent")
                fetchRequest.predicate = NSPredicate(format: "isSynced == false")

                guard let events = try context.fetch(fetchRequest) as? [NSManagedObject] else {
                    return
                }

                if events.isEmpty {
                    return
                }

                // Convert to SwipeEvent models
                let swipeEvents = events.compactMap { object -> SwipeEvent? in
                    guard
                        let id = object.value(forKey: "id") as? UUID,
                        let productId = object.value(forKey: "productId") as? UUID,
                        let actionString = object.value(forKey: "action") as? String,
                        let action = SwipeAction(rawValue: actionString),
                        let dwellTime = object.value(forKey: "dwellTimeMs") as? Int,
                        let position = object.value(forKey: "sessionPosition") as? Int,
                        let expanded = object.value(forKey: "expanded") as? Bool,
                        let createdAt = object.value(forKey: "createdAt") as? Date
                    else {
                        return nil
                    }

                    // Note: Creating a minimal SwipeEvent for upload
                    // In production, store full event data or reconstruct from JSON
                    var event = SwipeEvent(
                        action: action,
                        productId: productId,
                        externalProductId: "",
                        brandId: UUID(),
                        category: .clothing,
                        sessionPosition: position,
                        dwellTimeMs: dwellTime,
                        expanded: expanded
                    )
                    event.id = id
                    return event
                }

                // Upload to backend
                if !swipeEvents.isEmpty {
                    let request = SwipeEventBatchRequest(events: swipeEvents)
                    try await self.networkService.requestEmpty(
                        "analytics/swipes",
                        method: .post,
                        body: request
                    )

                    // Mark as synced
                    for object in events {
                        object.setValue(true, forKey: "isSynced")
                    }
                }
            }
        } catch {
            print("Failed to sync swipe events: \(error)")
        }
    }

    /// Caches the card queue for offline swiping.
    func prefetchCardQueue() async {
        guard isOnline else { return }

        do {
            // Check if we already have enough cached cards
            let cachedCount = try await getCardQueueCacheCount()
            if cachedCount >= minQueueCacheSize {
                return
            }

            // Fetch cards from API
            let request = CardQueueRequest(limit: cardCacheBatchSize)
            let response: CardQueueResponse = try await networkService.request(
                "cards/queue",
                method: .post,
                body: request
            )

            // Cache products to Core Data
            try await persistenceController.performBackgroundTaskWithSave { context in
                for (index, product) in response.products.enumerated() {
                    // Cache product
                    let productEntity = NSEntityDescription.insertNewObject(
                        forEntityName: "CachedProduct",
                        into: context
                    )
                    productEntity.setValue(product.id, forKey: "id")
                    productEntity.setValue(product.externalId, forKey: "externalId")
                    productEntity.setValue(product.brandName, forKey: "brandName")
                    productEntity.setValue(product.name, forKey: "name")
                    productEntity.setValue(product.category.rawValue, forKey: "category")
                    productEntity.setValue(product.currentPrice, forKey: "currentPrice")
                    productEntity.setValue(product.originalPrice, forKey: "originalPrice")
                    productEntity.setValue(product.isOnSale, forKey: "isOnSale")
                    productEntity.setValue(Date(), forKey: "cachedAt")

                    // Cache as JSON for reconstruction
                    if let jsonData = try? JSONEncoder().encode(product),
                       let jsonString = String(data: jsonData, encoding: .utf8) {
                        productEntity.setValue(jsonString, forKey: "productJSON")
                    }

                    // Cache queue entry
                    let queueEntity = NSEntityDescription.insertNewObject(
                        forEntityName: "CachedCardQueue",
                        into: context
                    )
                    queueEntity.setValue(UUID(), forKey: "id")
                    queueEntity.setValue(product.id, forKey: "productId")
                    queueEntity.setValue(index, forKey: "queuePosition")
                    queueEntity.setValue(Date(), forKey: "fetchedAt")

                    if let jsonData = try? JSONEncoder().encode(product),
                       let jsonString = String(data: jsonData, encoding: .utf8) {
                        queueEntity.setValue(jsonString, forKey: "productJSON")
                    }
                }
            }
        } catch {
            print("Failed to prefetch card queue: \(error)")
        }
    }

    /// Caches a dresser item locally for offline access.
    func cacheDresserItem(
        _ product: Product,
        to drawerId: UUID,
        drawerName: String,
        priceAtSave: Decimal
    ) async {
        do {
            try await persistenceController.performBackgroundTaskWithSave { context in
                let entity = NSEntityDescription.insertNewObject(
                    forEntityName: "CachedDresserItem",
                    into: context
                )

                entity.setValue(UUID(), forKey: "id")
                entity.setValue(product.id, forKey: "productId")
                entity.setValue(drawerId, forKey: "drawerId")
                entity.setValue(drawerName, forKey: "drawerName")
                entity.setValue(priceAtSave, forKey: "priceAtSave")
                entity.setValue(product.currentPrice, forKey: "currentPrice")
                entity.setValue(Date(), forKey: "savedAt")

                if let jsonData = try? JSONEncoder().encode(product),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    entity.setValue(jsonString, forKey: "productJSON")
                }
            }
        } catch {
            print("Failed to cache dresser item: \(error)")
        }
    }

    /// Gets offline card queue from cache.
    func getOfflineCardQueue() async -> [Product] {
        do {
            return try await persistenceController.performBackgroundTask { context in
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "CachedCardQueue")
                fetchRequest.sortDescriptors = [NSSortDescriptor(key: "queuePosition", ascending: true)]

                guard let results = try context.fetch(fetchRequest) as? [NSManagedObject] else {
                    return []
                }

                return results.compactMap { object in
                    guard let jsonString = object.value(forKey: "productJSON") as? String,
                          let jsonData = jsonString.data(using: .utf8) else {
                        return nil
                    }

                    return try? JSONDecoder().decode(Product.self, from: jsonData)
                }
            }
        } catch {
            print("Failed to fetch offline queue: \(error)")
            return []
        }
    }

    /// Checks dresser for price drops and updates cache.
    func checkDresserPriceDrops() async {
        guard isOnline else { return }

        do {
            try await persistenceController.performBackgroundTask { context in
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "CachedDresserItem")
                guard let items = try context.fetch(fetchRequest) as? [NSManagedObject] else {
                    return
                }

                for item in items {
                    guard let priceAtSave = item.value(forKey: "priceAtSave") as? Decimal else {
                        continue
                    }

                    guard let currentPrice = item.value(forKey: "currentPrice") as? Decimal else {
                        continue
                    }

                    // Check if price dropped
                    if currentPrice < priceAtSave {
                        // Price drop detected - in production, trigger notification
                        print("Price drop detected for item: \(item.value(forKey: "id") ?? "unknown")")
                    }
                }
            }
        } catch {
            print("Failed to check dresser price drops: \(error)")
        }
    }

    // MARK: - Private Methods

    /// Sets up network connectivity monitoring.
    private func setupNetworkMonitoring() {
        pathMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isOnline = path.status == .satisfied
            }

            // Sync when reconnected
            if path.status == .satisfied {
                Task {
                    await self?.syncUnyncedSwipeEvents()
                    await self?.prefetchCardQueue()
                }
            }
        }

        pathMonitor.start(queue: pathQueue)
    }

    /// Gets the count of cached cards in the queue.
    private func getCardQueueCacheCount() async throws -> Int {
        return try await persistenceController.performBackgroundTask { context in
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "CachedCardQueue")
            return try context.count(for: fetchRequest)
        }
    }

    deinit {
        pathMonitor.cancel()
    }
}
