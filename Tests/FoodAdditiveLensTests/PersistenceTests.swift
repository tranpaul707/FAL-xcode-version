import CoreData
import XCTest
@testable import FoodAdditiveLens

final class PersistenceTests: XCTestCase {
    @MainActor
    func testAnalysisFieldsCanBeSavedFetchedAndDeleted() async throws {
        let persistence = PersistenceController(inMemory: true)
        // Keep another model/store alive, as happens with the hosted app and previews.
        let otherPersistence = PersistenceController(inMemory: true)
        XCTAssertNil(persistence.loadError)
        XCTAssertNil(otherPersistence.loadError)
        let context = persistence.container.viewContext
        let otherContext = otherPersistence.container.viewContext
        let timestamp = Date(timeIntervalSince1970: 1_750_000_000)

        let otherItem = Item.insert(into: otherContext)
        otherItem.ingredientText = "OTHER STORE"
        try otherContext.save()

        let item = Item.insert(into: context)
        let expectedEntity = try XCTUnwrap(persistence.container.managedObjectModel.entitiesByName["Item"])
        let otherExpectedEntity = try XCTUnwrap(otherPersistence.container.managedObjectModel.entitiesByName["Item"])
        XCTAssertTrue(item.entity === expectedEntity)
        XCTAssertTrue(otherItem.entity === otherExpectedEntity)
        XCTAssertTrue(item.managedObjectContext === context)
        XCTAssertTrue(otherItem.managedObjectContext === otherContext)
        item.timestamp = timestamp
        item.ingredientText = "WATER, CALCIUM PROPIONATE"
        item.stage = "After Knowledge Lookup"
        item.identifiedAdditives = "CALCIUM PROPIONATE"
        item.analysisResult = "Identified 1 additives"
        item.knowledgeData = "CALCIUM PROPIONATE→CALCIUM PROPIONATE→ANTIMICROBIAL AGENT"
        item.explanations = nil
        try context.save()
        context.reset()

        let saved = try XCTUnwrap(context.fetch(Item.fetchRequest()).first)
        XCTAssertEqual(saved.timestamp, timestamp)
        XCTAssertEqual(saved.ingredientText, "WATER, CALCIUM PROPIONATE")
        XCTAssertEqual(saved.stage, "After Knowledge Lookup")
        XCTAssertEqual(saved.identifiedAdditives, "CALCIUM PROPIONATE")
        XCTAssertEqual(saved.analysisResult, "Identified 1 additives")
        XCTAssertEqual(saved.knowledgeData, "CALCIUM PROPIONATE→CALCIUM PROPIONATE→ANTIMICROBIAL AGENT")
        XCTAssertNil(saved.explanations)

        saved.explanations = "A saved explanation from an existing analysis."
        saved.stage = "Complete Analysis"
        try context.save()
        context.reset()
        let complete = try XCTUnwrap(context.fetch(Item.fetchRequest()).first)
        XCTAssertEqual(complete.explanations, "A saved explanation from an existing analysis.")
        XCTAssertEqual(complete.stage, "Complete Analysis")

        context.delete(complete)
        try context.save()
        XCTAssertEqual(try context.count(for: Item.fetchRequest()), 0)
        let otherItems = try otherContext.fetch(Item.fetchRequest())
        XCTAssertEqual(otherItems.count, 1)
        XCTAssertEqual(otherItems.first?.ingredientText, "OTHER STORE")
    }

    @MainActor
    func testSQLiteHistorySurvivesStoreReopening() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let storeURL = directory.appendingPathComponent("History.sqlite")

        let first = PersistenceController(storeURL: storeURL)
        XCTAssertNil(first.loadError)
        let item = Item.insert(into: first.container.viewContext)
        item.ingredientText = "ASCORBIC ACID"
        item.stage = "After Knowledge Lookup"
        try first.container.viewContext.save()
        for store in first.container.persistentStoreCoordinator.persistentStores {
            try first.container.persistentStoreCoordinator.remove(store)
        }

        let reopened = PersistenceController(storeURL: storeURL)
        XCTAssertNil(reopened.loadError)
        let items = try reopened.container.viewContext.fetch(Item.fetchRequest())
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.ingredientText, "ASCORBIC ACID")
        XCTAssertEqual(items.first?.stage, "After Knowledge Lookup")
        for store in reopened.container.persistentStoreCoordinator.persistentStores {
            try reopened.container.persistentStoreCoordinator.remove(store)
        }
    }
}
