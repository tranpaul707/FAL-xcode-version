import CoreData
import Foundation

@MainActor
final class PersistenceController {
    static let shared = PersistenceController()
    static let preview = PersistenceController(inMemory: true)

    let container: NSPersistentContainer
    private(set) var loadError: Error?

    /// A caller-supplied URL allows persistence tests to use an isolated SQLite store.
    init(inMemory: Bool = false, storeURL: URL? = nil) {
        container = NSPersistentContainer(name: "FoodAdditiveLens")

        if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [description]
        } else if let storeURL {
            container.persistentStoreDescriptions = [NSPersistentStoreDescription(url: storeURL)]
        }

        // Finish loading before the app exposes a context to its views.
        for description in container.persistentStoreDescriptions {
            description.shouldAddStoreAsynchronously = false
            description.shouldMigrateStoreAutomatically = true
            description.shouldInferMappingModelAutomatically = true
        }

        container.loadPersistentStores { [weak self] _, error in
            self?.loadError = error
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}
