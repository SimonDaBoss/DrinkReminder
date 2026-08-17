import CoreData
import Foundation

enum PersistenceError: LocalizedError {
    case storeLoadFailed(Error)
    case missingPreferences

    var errorDescription: String? {
        switch self {
        case .storeLoadFailed(let error):
            return "The local hydration store could not be loaded: \(error.localizedDescription)"
        case .missingPreferences:
            return "Application preferences have not been initialized."
        }
    }
}

final class PersistenceController {
    let container: NSPersistentContainer

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    init(inMemory: Bool = false) throws {
        container = NSPersistentContainer(
            name: "DrinkReminder",
            managedObjectModel: ManagedObjectModelFactory.makeModel()
        )

        let description: NSPersistentStoreDescription
        if inMemory {
            description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            description.url = URL(fileURLWithPath: "/dev/null")
            container.persistentStoreDescriptions = [description]
        } else {
            guard let defaultDescription = container.persistentStoreDescriptions.first else {
                throw PersistenceError.storeLoadFailed(
                    NSError(domain: "DrinkReminder.Persistence", code: 1)
                )
            }
            description = defaultDescription
        }

        description.shouldAddStoreAsynchronously = false
        description.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
        description.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)

        var loadError: Error?
        container.loadPersistentStores { _, error in
            loadError = error
        }

        if let loadError {
            throw PersistenceError.storeLoadFailed(loadError)
        }

        viewContext.name = "DrinkReminder.viewContext"
        viewContext.automaticallyMergesChangesFromParent = true
        viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        viewContext.undoManager = nil
    }

    func saveIfNeeded() throws {
        guard viewContext.hasChanges else { return }
        try viewContext.save()
    }
}
