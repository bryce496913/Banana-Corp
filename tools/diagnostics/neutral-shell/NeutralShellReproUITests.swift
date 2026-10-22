import XCTest

/// Neutral fixture only. No campaign content, application flags, or tap retries.
final class NeutralShellReproUITests: XCTestCase {
    @MainActor func testTwoRoundsFifteenApplicationsAndHome() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        // Eleven grid controls and four dock controls; four extra neutral grid cells remain visible/scrollable.
        let routes = Array(0..<11) + Array(15..<19)
        for round in 0..<2 {
            for route in routes {
                let icon = app.buttons["neutral.app.\(route)"].firstMatch
                ready(icon)
                icon.tap()
                let home = app.buttons["neutral.home"].firstMatch
                ready(home)
                XCTAssertTrue(app.staticTexts["neutral.destination.\(route)"].exists)
                XCTAssertFalse(app.alerts.firstMatch.exists)
                home.tap()
                ready(icon)
                XCTAssertFalse(home.exists, "Round \(round), route \(route)")
            }
        }
    }

    @MainActor func testReservedStripUpwardSwipe() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        let icon = app.buttons["neutral.app.15"].firstMatch
        ready(icon)
        icon.tap()
        let home = app.buttons["neutral.home"].firstMatch
        ready(home)
        let start = home.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        start.press(forDuration: 0.05, thenDragTo: start.withOffset(CGVector(dx: 0, dy: -90)))
        ready(icon)
        XCTAssertFalse(home.exists)
    }

    @MainActor private func ready(_ element: XCUIElement) {
        let condition = NSPredicate(format: "exists == true AND enabled == true AND hittable == true")
        let result = XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: condition, object: element)], timeout: 8)
        if result != .completed {
            print(XCUIApplication().debugDescription)
            let capture = XCTAttachment(screenshot: XCUIApplication().screenshot())
            capture.name = "Neutral fixture readiness failure"
            capture.lifetime = .keepAlways
            add(capture)
        }
        XCTAssertEqual(result, .completed)
    }
}
