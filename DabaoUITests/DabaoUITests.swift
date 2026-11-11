import XCTest

final class DabaoUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = true
    }

    func testRestaurantListAccessibility() throws {
        let app = XCUIApplication()
        app.launch()

        // Wait for the restaurants to load
        XCTAssertTrue(app.cells.firstMatch.waitForExistence(timeout: 5))

        try app.performAccessibilityAudit()
    }
}
