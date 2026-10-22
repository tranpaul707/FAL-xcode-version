import Foundation
import XCTest

final class AppLaunchTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunchSampleResetAndHistoryWithoutModels() {
        let app = XCUIApplication()
        app.launch()

        let editor = app.textViews["ingredientTextEditor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 15))
        XCTAssertFalse(app.otherElements["persistenceError"].exists)

        let sample = app.buttons["sampleButton"]
        XCTAssertTrue(sample.waitForExistence(timeout: 5))
        expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: sample)
        waitForExpectations(timeout: 10)
        sample.tap()
        let ingredients = editor.value as? String ?? ""
        XCTAssertGreaterThan(ingredients.count, 50)
        XCTAssertTrue(ingredients.contains(","))
        XCTAssertTrue(app.staticTexts["Sample Food Product"].exists)

        app.buttons["resetButton"].tap()
        XCTAssertEqual(editor.value as? String, "")

        app.buttons["historyButton"].tap()
        XCTAssertTrue(app.navigationBars["Analysis History"].waitForExistence(timeout: 5))
        app.buttons["Back"].tap()
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
    }
    private func scrollTo(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<10 {
            if element.exists && element.isHittable { return }
            // Scroll along the margin so the nested ingredient editor does not consume the gesture.
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.98, dy: 0.8))
                .press(forDuration: 0.01, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.98, dy: 0.25)))
        }
        XCTAssertTrue(element.exists && element.isHittable, "Expected control to be reachable: \(element)")
    }

    private func enterIngredients(_ text: String, in app: XCUIApplication) {
        let editor = app.textViews["ingredientTextEditor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 15))
        editor.tap()
        editor.typeText(text)
        app.staticTexts["Ingredient List"].tap() // Dismiss the keyboard.
    }

    func testDirectLookupSaveRelaunchAndDelete() {
        let app = XCUIApplication()
        app.launchEnvironment["FAL_UI_TEST_STORE_ID"] = UUID().uuidString
        app.launch()
        enterIngredients("WATER, CALCIUM PROPIONATE, ASCORBIC ACID", in: app)
        let analyze = app.buttons["analyzeButton"]
        scrollTo(analyze, in: app)
        expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: analyze)
        waitForExpectations(timeout: 15)
        analyze.tap()
        let ascorbic = app.staticTexts["additive-ASCORBIC ACID"]
        XCTAssertTrue(ascorbic.waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["analysisMode"].label.contains("Direct ingredient matches only"))
        scrollTo(app.staticTexts["additive-CALCIUM PROPIONATE"], in: app)
        let explanations = app.buttons["generateExplanationsButton"]
        scrollTo(explanations, in: app)
        XCTAssertFalse(explanations.isEnabled)

        let save = app.buttons["saveResultsButton"]
        scrollTo(save, in: app)
        save.tap()
        XCTAssertTrue(app.alerts["Success"].waitForExistence(timeout: 5))
        app.alerts["Success"].buttons["OK"].tap()
        app.terminate()
        app.launch()
        app.buttons["historyButton"].tap()
        let summary = app.staticTexts["Direct lookup: 2 matched additives"]
        XCTAssertTrue(summary.waitForExistence(timeout: 10))
        summary.tap()
        XCTAssertTrue(app.staticTexts["Knowledge Details"].exists)
        XCTAssertTrue(app.staticTexts["ANTIMICROBIAL AGENT|ANTIOXIDANT"].exists)
        summary.swipeLeft()
        app.buttons["Delete"].tap()
        expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: summary)
        waitForExpectations(timeout: 5)
        app.terminate()
        app.launch()
        app.buttons["historyButton"].tap()
        XCTAssertTrue(app.navigationBars["Analysis History"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Direct lookup: 2 matched additives"].exists)
    }

    func testEmptyAndUnmatchedIngredients() {
        let app = XCUIApplication()
        app.launchEnvironment["FAL_UI_TEST_STORE_ID"] = UUID().uuidString
        app.launch()
        let analyze = app.buttons["analyzeButton"]
        XCTAssertTrue(app.textViews["ingredientTextEditor"].waitForExistence(timeout: 15))
        scrollTo(analyze, in: app)
        XCTAssertFalse(analyze.isEnabled)
        for _ in 0..<6 {
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.98, dy: 0.25))
                .press(forDuration: 0.01, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.98, dy: 0.8)))
        }
        enterIngredients("WATER, SALT, ZZZUNMATCHEDINGREDIENTZZZ", in: app)
        scrollTo(analyze, in: app)
        expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: analyze)
        waitForExpectations(timeout: 15)
        analyze.tap()
        XCTAssertTrue(app.staticTexts["noMatchingRecords"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["saveResultsButton"].exists)
        for _ in 0..<6 {
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.98, dy: 0.25))
                .press(forDuration: 0.01, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.98, dy: 0.8)))
        }
        app.buttons["resetButton"].tap()
        XCTAssertEqual(app.textViews["ingredientTextEditor"].value as? String, "")
        XCTAssertFalse(app.staticTexts["noMatchingRecords"].exists)
    }

}
