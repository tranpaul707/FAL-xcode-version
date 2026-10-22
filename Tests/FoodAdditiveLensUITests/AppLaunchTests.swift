import Foundation
import XCTest

final class AppLaunchTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        if let run = testRun, run.failureCount > 0 {
            let app = XCUIApplication()
            let hierarchy = XCTAttachment(string: app.debugDescription)
            hierarchy.name = "UI hierarchy at failure"
            hierarchy.lifetime = .keepAlways
            add(hierarchy)
            if app.state == .runningForeground {
                let screenshot = XCTAttachment(screenshot: app.screenshot())
                screenshot.name = "UI at failure"
                screenshot.lifetime = .keepAlways
                add(screenshot)
            }
        }
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
        scrollTo(sample, in: app)
        sample.tap()
        expectation(for: NSPredicate { _, _ in
            let value = editor.value as? String ?? ""
            return value.count > 50 && value.contains(",")
        }, evaluatedWith: editor)
        waitForExpectations(timeout: 10)
        let ingredients = editor.value as? String ?? ""
        XCTAssertGreaterThan(ingredients.count, 50)
        XCTAssertTrue(ingredients.contains(","))
        XCTAssertTrue(app.staticTexts["Sample Food Product"].exists)

        let reset = app.buttons["resetButton"]
        scrollTo(reset, in: app, towardTop: true)
        reset.tap()
        expectation(for: NSPredicate(format: "value == %@", ""), evaluatedWith: editor)
        waitForExpectations(timeout: 5)
        XCTAssertEqual(editor.value as? String, "")

        app.buttons["historyButton"].tap()
        XCTAssertTrue(app.navigationBars["Analysis History"].waitForExistence(timeout: 5))
        app.buttons["Back"].tap()
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
    }
    private func scrollTo(_ element: XCUIElement, in app: XCUIApplication, towardTop: Bool = false) {
        for _ in 0..<10 {
            if element.exists && element.isHittable { return }
            // Scroll along the margin so the nested ingredient editor does not consume the gesture.
            let start = CGVector(dx: 0.98, dy: towardTop ? 0.25 : 0.8)
            let end = CGVector(dx: 0.98, dy: towardTop ? 0.8 : 0.25)
            app.coordinate(withNormalizedOffset: start)
                .press(forDuration: 0.01, thenDragTo: app.coordinate(withNormalizedOffset: end))
        }
        XCTAssertTrue(element.exists && element.isHittable, "Expected control to be reachable: \(element)")
    }

    private func enterIngredients(_ text: String, in app: XCUIApplication) {
        let editor = app.textViews["ingredientTextEditor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 15))
        scrollTo(editor, in: app)
        expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: editor)
        waitForExpectations(timeout: 10)
        editor.tap()
        editor.typeText(text)
        XCTAssertEqual(editor.value as? String, text, "The ingredient editor must contain the exact lookup input.")
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
        // Results are below the button. LazyVStack rows may not exist until scrolled into view.
        let mode = app.staticTexts["analysisMode"]
        scrollTo(mode, in: app)
        XCTAssertTrue(mode.label.contains("Direct ingredient matches only"))
        let ascorbic = app.staticTexts["additive-ASCORBIC ACID"]
        scrollTo(ascorbic, in: app)
        XCTAssertTrue(ascorbic.waitForExistence(timeout: 10))
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
        scrollTo(app.textViews["ingredientTextEditor"], in: app, towardTop: true)
        enterIngredients("WATER, SALT, ZZZUNMATCHEDINGREDIENTZZZ", in: app)
        scrollTo(analyze, in: app)
        expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: analyze)
        waitForExpectations(timeout: 15)
        analyze.tap()
        XCTAssertTrue(app.staticTexts["noMatchingRecords"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["saveResultsButton"].exists)
        scrollTo(app.buttons["resetButton"], in: app, towardTop: true)
        app.buttons["resetButton"].tap()
        XCTAssertEqual(app.textViews["ingredientTextEditor"].value as? String, "")
        XCTAssertFalse(app.staticTexts["noMatchingRecords"].exists)
    }

}
