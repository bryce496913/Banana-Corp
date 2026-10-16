import XCTest

final class LaunchSmokeTests: XCTestCase {
    @MainActor
    func testEveryApplicationOpensAndReturnsHome() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        waitUntilReady(app.buttons["bananaOS.app.email"].firstMatch, timeout: 20)

        // Match the registered production routes, using only ordinary Home controls.
        let routes = ["email", "browser", "social", "watchVideo", "messager",
                      "photoAlbum", "settings", "phone", "news", "aiAssistant",
                      "vrExperience", "snake", "pong", "xo", "evidence"]
        for route in routes {
            let icon = app.buttons["bananaOS.app.\(route)"].firstMatch
            // Grid apps can be below the fold on compact phones or custom layouts.
            for _ in 0..<8 {
                if icon.exists && icon.isHittable { break }
                let scroll = app.scrollViews.firstMatch
                XCTAssertTrue(scroll.exists, "Missing Home grid for \(route)")
                if icon.exists && icon.frame.midY < app.frame.midY { scroll.swipeDown() }
                else { scroll.swipeUp() }
            }
            waitUntilReady(icon)
            icon.tap()
            let home = app.buttons["bananaOS.home"].firstMatch
            waitUntilReady(home)
            XCTAssertEqual(app.statusBars.count, 0, route)
            XCTAssertFalse(app.alerts.firstMatch.exists, route)
            let capture = XCTAttachment(screenshot: app.screenshot())
            capture.name = "Application \(route)"
            capture.lifetime = .keepAlways
            add(capture)
            home.tap()
            waitUntilReady(app.buttons["bananaOS.app.email"].firstMatch)
            XCTAssertFalse(app.buttons["bananaOS.home"].exists, route)
            XCTAssertEqual(app.buttons.matching(identifier: "bananaOS.app.\(route)").count, 1)
        }
    }

    @MainActor
    func testReservedHomeStripAcceptsUpwardSwipe() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        let email = app.buttons["bananaOS.app.email"].firstMatch
        waitUntilReady(email, timeout: 20)
        email.tap()
        let home = app.buttons["bananaOS.home"].firstMatch
        waitUntilReady(home)
        // Start inside the fictional strip, above the actual system Home gesture.
        let start = home.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let end = start.withOffset(CGVector(dx: 0, dy: -90))
        start.press(forDuration: 0.05, thenDragTo: end)
        waitUntilReady(email)
        XCTAssertFalse(home.exists)
        XCTAssertEqual(app.statusBars.count, 0)
    }

    @MainActor
    private func waitUntilReady(_ element: XCUIElement, timeout: TimeInterval = 8) {
        let ready = NSPredicate(format: "exists == true AND hittable == true AND enabled == true")
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: ready, object: element)], timeout: timeout), .completed)
    }

    @MainActor
    func testLaunchAndRepeatedReturnHome() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        // Wait for accessibility state, including the unchanged splash, rather than sleeping.
        let email = app.buttons["bananaOS.app.email"].firstMatch
        let emailAppeared = email.waitForExistence(timeout: 20)
        if !emailAppeared { print(app.debugDescription) }
        XCTAssertTrue(emailAppeared)
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
