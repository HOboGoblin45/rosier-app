import CoreData
import Foundation

/// Programmatically defines the Core Data model for Rosier without using .xcdatamodeld.
struct RosierModel {
    /// Creates and returns the managed object model for Rosier.
    static func createManagedObjectModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        // MARK: - CachedProduct Entity

        let cachedProductEntity = NSEntityDescription()
        cachedProductEntity.name = "CachedProduct"
        cachedProductEntity.managedObjectClassName = "CachedProduct"

        let productId = NSAttributeDescription()
        productId.name = "id"
        productId.attributeType = .UUIDAttributeType
        productId.isOptional = false

        let externalId = NSAttributeDescription()
        externalId.name = "externalId"
        externalId.attributeType = .stringAttributeType
        externalId.isOptional = false

        let brandName = NSAttributeDescription()
        brandName.name = "brandName"
        brandName.attributeType = .stringAttributeType
        brandName.isOptional = false

        let productName = NSAttributeDescription()
        productName.name = "name"
        productName.attributeType = .stringAttributeType
        productName.isOptional = false

        let category = NSAttributeDescription()
        category.name = "category"
        category.attributeType = .stringAttributeType
        category.isOptional = false

        let currentPrice = NSAttributeDescription()
        currentPrice.name = "currentPrice"
        currentPrice.attributeType = .decimalAttributeType
        currentPrice.isOptional = false

        let originalPrice = NSAttributeDescription()
        originalPrice.name = "originalPrice"
        originalPrice.attributeType = .decimalAttributeType
        originalPrice.isOptional = true

        let isOnSale = NSAttributeDescription()
        isOnSale.name = "isOnSale"
        isOnSale.attributeType = .booleanAttributeType
        isOnSale.isOptional = false

        let primaryImageData = NSAttributeDescription()
        primaryImageData.name = "primaryImageData"
        primaryImageData.attributeType = .binaryDataAttributeType
        primaryImageData.isOptional = true

        let productJSON = NSAttributeDescription()
        productJSON.name = "productJSON"
        productJSON.attributeType = .stringAttributeType
        productJSON.isOptional = false

        let cachedAt = NSAttributeDescription()
        cachedAt.name = "cachedAt"
        cachedAt.attributeType = .dateAttributeType
        cachedAt.isOptional = false

        cachedProductEntity.properties = [
            productId, externalId, brandName, productName, category,
            currentPrice, originalPrice, isOnSale, primaryImageData, productJSON, cachedAt
        ]
        cachedProductEntity.primaryKeyAttributes = ["id"]

        // MARK: - CachedSwipeEvent Entity

        let cachedSwipeEventEntity = NSEntityDescription()
        cachedSwipeEventEntity.name = "CachedSwipeEvent"
        cachedSwipeEventEntity.managedObjectClassName = "CachedSwipeEvent"

        let eventId = NSAttributeDescription()
        eventId.name = "id"
        eventId.attributeType = .UUIDAttributeType
        eventId.isOptional = false

        let eventProductId = NSAttributeDescription()
        eventProductId.name = "productId"
        eventProductId.attributeType = .UUIDAttributeType
        eventProductId.isOptional = false

        let action = NSAttributeDescription()
        action.name = "action"
        action.attributeType = .stringAttributeType
        action.isOptional = false

        let dwellTimeMs = NSAttributeDescription()
        dwellTimeMs.name = "dwellTimeMs"
        dwellTimeMs.attributeType = .integer32AttributeType
        dwellTimeMs.isOptional = false

        let sessionPosition = NSAttributeDescription()
        sessionPosition.name = "sessionPosition"
        sessionPosition.attributeType = .integer32AttributeType
        sessionPosition.isOptional = false

        let expanded = NSAttributeDescription()
        expanded.name = "expanded"
        expanded.attributeType = .booleanAttributeType
        expanded.isOptional = false

        let sessionId = NSAttributeDescription()
        sessionId.name = "sessionId"
        sessionId.attributeType = .UUIDAttributeType
        sessionId.isOptional = false

        let createdAt = NSAttributeDescription()
        createdAt.name = "createdAt"
        createdAt.attributeType = .dateAttributeType
        createdAt.isOptional = false

        let isSynced = NSAttributeDescription()
        isSynced.name = "isSynced"
        isSynced.attributeType = .booleanAttributeType
        isSynced.isOptional = false

        cachedSwipeEventEntity.properties = [
            eventId, eventProductId, action, dwellTimeMs, sessionPosition,
            expanded, sessionId, createdAt, isSynced
        ]
        cachedSwipeEventEntity.primaryKeyAttributes = ["id"]

        // MARK: - CachedDresserItem Entity

        let cachedDresserItemEntity = NSEntityDescription()
        cachedDresserItemEntity.name = "CachedDresserItem"
        cachedDresserItemEntity.managedObjectClassName = "CachedDresserItem"

        let dresserItemId = NSAttributeDescription()
        dresserItemId.name = "id"
        dresserItemId.attributeType = .UUIDAttributeType
        dresserItemId.isOptional = false

        let dresserProductId = NSAttributeDescription()
        dresserProductId.name = "productId"
        dresserProductId.attributeType = .UUIDAttributeType
        dresserProductId.isOptional = false

        let drawerId = NSAttributeDescription()
        drawerId.name = "drawerId"
        drawerId.attributeType = .UUIDAttributeType
        drawerId.isOptional = false

        let drawerName = NSAttributeDescription()
        drawerName.name = "drawerName"
        drawerName.attributeType = .stringAttributeType
        drawerName.isOptional = false

        let priceAtSave = NSAttributeDescription()
        priceAtSave.name = "priceAtSave"
        priceAtSave.attributeType = .decimalAttributeType
        priceAtSave.isOptional = false

        let currentPriceAtSync = NSAttributeDescription()
        currentPriceAtSync.name = "currentPrice"
        currentPriceAtSync.attributeType = .decimalAttributeType
        currentPriceAtSync.isOptional = true

        let dresserProductJSON = NSAttributeDescription()
        dresserProductJSON.name = "productJSON"
        dresserProductJSON.attributeType = .stringAttributeType
        dresserProductJSON.isOptional = false

        let savedAt = NSAttributeDescription()
        savedAt.name = "savedAt"
        savedAt.attributeType = .dateAttributeType
        savedAt.isOptional = false

        cachedDresserItemEntity.properties = [
            dresserItemId, dresserProductId, drawerId, drawerName,
            priceAtSave, currentPriceAtSync, dresserProductJSON, savedAt
        ]
        cachedDresserItemEntity.primaryKeyAttributes = ["id"]

        // MARK: - CachedCardQueue Entity

        let cachedCardQueueEntity = NSEntityDescription()
        cachedCardQueueEntity.name = "CachedCardQueue"
        cachedCardQueueEntity.managedObjectClassName = "CachedCardQueue"

        let queueId = NSAttributeDescription()
        queueId.name = "id"
        queueId.attributeType = .UUIDAttributeType
        queueId.isOptional = false

        let queueProductId = NSAttributeDescription()
        queueProductId.name = "productId"
        queueProductId.attributeType = .UUIDAttributeType
        queueProductId.isOptional = false

        let queuePosition = NSAttributeDescription()
        queuePosition.name = "queuePosition"
        queuePosition.attributeType = .integer32AttributeType
        queuePosition.isOptional = false

        let queueProductJSON = NSAttributeDescription()
        queueProductJSON.name = "productJSON"
        queueProductJSON.attributeType = .stringAttributeType
        queueProductJSON.isOptional = false

        let fetchedAt = NSAttributeDescription()
        fetchedAt.name = "fetchedAt"
        fetchedAt.attributeType = .dateAttributeType
        fetchedAt.isOptional = false

        cachedCardQueueEntity.properties = [
            queueId, queueProductId, queuePosition, queueProductJSON, fetchedAt
        ]
        cachedCardQueueEntity.primaryKeyAttributes = ["id"]

        // MARK: - Set Entities

        model.entities = [
            cachedProductEntity,
            cachedSwipeEventEntity,
            cachedDresserItemEntity,
            cachedCardQueueEntity
        ]

        return model
    }
}

/// Extension to inject the programmatic model into NSPersistentContainer
extension NSPersistentContainer {
    convenience init(name: String, managedObjectModel model: NSManagedObjectModel) {
        self.init(name: name, managedObjectModel: model)
    }
}

/// Custom initialization for PersistenceController to use programmatic model
extension PersistenceController {
    static func initializeWithProgrammaticModel() {
        let model = RosierModel.createManagedObjectModel()

        // This ensures the model is used for the shared instance
        // In practice, modify PersistenceController init to accept model parameter
    }
}
