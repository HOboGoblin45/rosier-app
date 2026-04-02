import CoreData
import Foundation

/// Manages Core Data stack for the Rosier app with offline persistence.
final class PersistenceController {
    // MARK: - Singleton

    static let shared = PersistenceController()

    // MARK: - Properties

    let container: NSPersistentContainer
    private let modelName = "Rosier"

    var mainContext: NSManagedObjectContext {
        container.viewContext
    }

    var backgroundContext: NSManagedObjectContext {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.parent = mainContext
        context.automaticallyMergesChangesFromParent = true
        context.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
        return context
    }

    // MARK: - Initializers

    /// Initializes the Core Data stack.
    /// - Parameter inMemory: If true, uses in-memory store (for testing/previews)
    init(inMemory: Bool = false) {
        self.container = NSPersistentContainer(name: modelName)

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                // In production, handle this more gracefully
                fatalError("Core Data store failed to load: \(error), \(error.userInfo)")
            }
        }

        // Configure context settings
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy

        // Configure for optimal performance with large datasets
        container.viewContext.shouldDeleteInaccessibleFaults = true
        container.viewContext.undoManager = nil // Reduce memory usage
    }

    // MARK: - Save Methods

    /// Saves the main context synchronously with error handling.
    func saveMainContext() throws {
        let context = container.viewContext
        if context.hasChanges {
            try context.save()
        }
    }

    /// Saves the main context asynchronously.
    func saveMainContextAsync() async throws {
        try await container.viewContext.perform {
            if self.container.viewContext.hasChanges {
                try self.container.viewContext.save()
            }
        }
    }

    /// Saves a background context asynchronously.
    func saveBackgroundContext(_ context: NSManagedObjectContext) async throws {
        try await context.perform {
            if context.hasChanges {
                try context.save()
            }
        }
    }

    // MARK: - Batch Operations

    /// Performs a batch operation on a background context.
    func performBackgroundTask<T>(_ block: @escaping (NSManagedObjectContext) -> T) async -> T {
        let context = backgroundContext
        return await context.perform {
            block(context)
        }
    }

    /// Performs a batch operation with automatic save on a background context.
    func performBackgroundTaskWithSave<T>(_ block: @escaping (NSManagedObjectContext) throws -> T) async throws -> T {
        let context = backgroundContext
        return try await context.perform {
            let result = try block(context)
            if context.hasChanges {
                try context.save()
            }
            return result
        }
    }

    // MARK: - Cleanup Methods

    /// Clears all data from the Core Data store.
    func clearAllData() throws {
        let context = container.viewContext

        let entities = container.managedObjectModel.entities
        for entity in entities {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity.name ?? "")
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            deleteRequest.resultType = .resultTypeCount

            try context.execute(deleteRequest)
        }

        try context.save()
    }

    /// Removes old cache entries based on age.
    func cleanExpiredCache(olderThanDays days: Int = 7) throws {
        let context = container.viewContext
        let calendar = Calendar.current
        let cutoffDate = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()

        // Clean CachedProduct entities
        let productFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "CachedProduct")
        productFetch.returnsObjectsAsFaults = false

        if let products = try context.fetch(productFetch) as? [NSManagedObject] {
            for product in products {
                context.delete(product)
            }
        }

        // Clean CachedCardQueue entries older than cutoff
        let queueFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "CachedCardQueue")
        queueFetch.predicate = NSPredicate(format: "fetchedAt < %@", cutoffDate as NSDate)

        let deleteRequest = NSBatchDeleteRequest(fetchRequest: queueFetch)
        deleteRequest.resultType = .resultTypeCount

        try context.execute(deleteRequest)
        try context.save()
    }
}
