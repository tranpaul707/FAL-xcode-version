import XCTest

final class AppLaunchTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunchExampleResetAndHistoryWithoutModels() {
        let app = XCUIApplication()
        app.launch()

        let editor = app.textViews["ingredientTextEditor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 15))
        XCTAssertFalse(app.otherElements["persistenceError"].exists)

        let example = app.buttons["sampleButton"]
        XCTAssertTrue(example.waitForExistence(timeout: 5))
        example.tap()
        XCTAssertTrue((editor.value as? String)?.contains("CALCIUM PROPIONATE") == true)

        app.buttons["resetButton"].tap()
        XCTAssertEqual(editor.value as? String, "")

        app.buttons["historyButton"].tap()
        XCTAssertTrue(app.navigationBars["Analysis History"].waitForExistence(timeout: 5))
        app.buttons["Back"].tap()
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
    }
}
