import CoreData
import Foundation

// Manual code generation: the model must not also generate an Item subclass.
@objc(Item)
public class Item: NSManagedObject {
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
