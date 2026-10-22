import CoreData
import Foundation

// Manual code generation: the model must not also generate an Item subclass.
@objc(Item)
public class Item: NSManagedObject {
    /// Resolve the entity from this context, since app, preview, and test stores
    /// can load separate model instances that all describe the Item class.
    /// Call on the context's queue, as with other managed-object operations.
    public static func insert(into context: NSManagedObjectContext) -> Item {
        guard let entity = NSEntityDescription.entity(forEntityName: "Item", in: context) else {
            preconditionFailure("The supplied context's model has no Item entity.")
        }
        return Item(entity: entity, insertInto: context)
    }

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Item> {
        NSFetchRequest<Item>(entityName: "Item")
    }

    @NSManaged public var timestamp: Date?
    @NSManaged public var ingredientText: String?
    @NSManaged public var stage: String?
    @NSManaged public var identifiedAdditives: String?
    @NSManaged public var analysisResult: String?
    @NSManaged public var knowledgeData: String?
    @NSManaged public var explanations: String?
}

extension Item: Identifiable {}
