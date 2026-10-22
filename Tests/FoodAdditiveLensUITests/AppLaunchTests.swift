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
}
