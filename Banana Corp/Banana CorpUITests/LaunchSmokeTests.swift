import XCTest

final class LaunchSmokeTests: XCTestCase {
    @MainActor
    func testLaunchAndRepeatedReturnHome() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        // Wait for accessibility state, including the unchanged splash, rather than sleeping.
        let email = app.buttons["bananaOS.app.email"].firstMatch
        XCTAssertTrue(email.waitForExistence(timeout: 20))
        XCTAssertEqual(app.statusBars.count, 0, "Only the fictional status bar should be visible")
        for _ in 0..<2 {
            XCTAssertTrue(email.waitForExistence(timeout: 5))
            XCTAssertTrue(email.isHittable)
            email.tap()
            let home = app.buttons["bananaOS.home"].firstMatch
            XCTAssertTrue(home.waitForExistence(timeout: 5))
            let ready = NSPredicate(format: "hittable == true")
            let expectation = XCTNSPredicateExpectation(predicate: ready, object: home)
            XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: 5), .completed)
            XCTAssertEqual(app.statusBars.count, 0)
            home.tap()
            let homeReady = XCTNSPredicateExpectation(predicate: ready, object: email)
            XCTAssertEqual(XCTWaiter.wait(for: [homeReady], timeout: 5), .completed)
            XCTAssertEqual(app.buttons.matching(identifier: "bananaOS.app.email").count, 1)
        }
        app.terminate()
        app.launch()
        XCTAssertTrue(email.waitForExistence(timeout: 20))
    }
}
