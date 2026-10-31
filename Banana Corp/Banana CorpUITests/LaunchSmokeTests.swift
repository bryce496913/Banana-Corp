import XCTest

final class LaunchSmokeTests: XCTestCase {
    @MainActor
    func testHomeEditingGridReorderPersistsAndBlankTapExits() throws {
        let environment = ProcessInfo.processInfo.environment
        guard (environment["BANANA_QA_HOME_EDITING"] ?? environment["TEST_RUNNER_BANANA_QA_HOME_EDITING"]) == "fresh-physical-qa" else {
            throw XCTSkip("Requires runner-verified fresh dedicated physical QA identity")
        }
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        let email = app.buttons["bananaOS.app.email"].firstMatch
        waitUntilReady(email, timeout: 20)
        let web = app.buttons["bananaOS.app.browser"].firstMatch
        let social = app.buttons["bananaOS.app.social"].firstMatch
        let done = app.buttons["Done"].firstMatch
        func frame(_ element: XCUIElement) -> CGRect? {
            guard element.exists else { return nil }
            let f = element.frame
            guard [f.minX, f.minY, f.width, f.height].allSatisfy({ $0.isFinite }),
                  f.width > 0, f.height > 0, app.frame.contains(f) else { return nil }
            return f
        }
        func requireState(_ name: String, _ condition: @escaping () -> Bool) -> Bool {
            let result = XCTWaiter.wait(for: [XCTNSPredicateExpectation(
                predicate: NSPredicate { _, _ in condition() }, object: app)], timeout: 8)
            if result != .completed {
                print(app.debugDescription)
                let image = XCTAttachment(screenshot: app.screenshot())
                image.name = name; image.lifetime = .keepAlways; add(image)
            }
            XCTAssertEqual(result, .completed, name)
            return result == .completed
        }
        // Explicitly bounded to the reviewed physical 393x852-point presentation.
        XCTAssertTrue([app.frame.width, app.frame.height].allSatisfy({ $0.isFinite }))
        XCTAssertEqual(app.frame.width, 393, accuracy: 1)
        XCTAssertEqual(app.frame.height, 852, accuracy: 1)
        XCTAssertEqual(app.statusBars.count, 0)
        XCTAssertFalse(app.buttons["bananaOS.home"].exists)
        guard requireState("Fresh ordered grid", {
            guard let w = frame(web), let s = frame(social) else { return false }
            return web.isHittable && social.isHittable && abs(w.minY - s.minY) < 2 && w.midX < s.midX
        }) else { return }
        // Real long press; do not invoke accessibility action or edit AppState.
        social.press(forDuration: 0.6)
        guard requireState("Editing entered", {
            done.exists && done.isEnabled && done.isHittable && frame(done) != nil
                && String(describing: social.value ?? "").contains("Editing")
        }) else { return }
        // Move SECOND grid item before FIRST, which cannot be an accepted no-op.
        // Both items are in grid; no drop into the already-full dock.
        guard let initialWeb = frame(web), let initialSocial = frame(social) else {
            XCTFail("Invalid drag source/target geometry"); return
        }
        XCTAssertLessThan(initialWeb.midX, initialSocial.midX)
        social.press(forDuration: 0.6, thenDragTo: web)
        guard requireState("Grid order actually changed", {
            guard let w = frame(web), let s = frame(social) else { return false }
            return abs(w.minY - s.minY) < 2 && s.midX < w.midX
                && done.exists && String(describing: social.value ?? "").contains("Editing")
        }) else { return }
        waitUntilReady(done); done.tap()
        guard requireState("Done exits editing", {
            !done.exists && !String(describing: social.value ?? "").contains("Editing")
        }) else { return }
        app.terminate(); app.launch()
        waitUntilReady(email, timeout: 20)
        guard requireState("Reordered grid survives process relaunch", {
            guard let w = frame(web), let s = frame(social) else { return false }
            return abs(w.minY - s.minY) < 2 && s.midX < w.midX
                && !done.exists && !String(describing: social.value ?? "").contains("Editing")
        }) else { return }
        social.press(forDuration: 0.6)
        guard requireState("Editing reentered", {
            done.exists && done.isHittable && String(describing: social.value ?? "").contains("Editing")
        }) else { return }
        // Choose a verified blank point BELOW every grid button, inside its viewport.
        let viewport = app.scrollViews.containing(.button, identifier: "bananaOS.app.browser")
        XCTAssertEqual(viewport.count, 1)
        guard viewport.count == 1, let bounds = frame(viewport.firstMatch) else {
            XCTFail("Ambiguous/invalid grid viewport"); return
        }
        let gridButtons = viewport.firstMatch.buttons.allElementsBoundByIndex
        var bottom = bounds.minY
        for button in gridButtons {
            guard let b = frame(button) else { XCTFail("Invalid grid-button geometry"); return }
            bottom = max(bottom, b.maxY)
        }
        let blank = CGPoint(x: bounds.midX, y: bottom + 20)
        guard bounds.insetBy(dx: 8, dy: 8).contains(blank),
              app.frame.insetBy(dx: 8, dy: 8).contains(blank) else {
            XCTFail("No verified blank area in reviewed viewport"); return
        }
        for button in app.buttons.allElementsBoundByIndex where button.exists {
            if let b = frame(button) { XCTAssertFalse(b.insetBy(dx: -4, dy: -4).contains(blank)) }
        }
        app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: blank.x, dy: blank.y)).tap()
        guard requireState("Blank tap exits editing", {
            !done.exists && !String(describing: social.value ?? "").contains("Editing")
        }) else { return }
        waitUntilReady(web); web.tap()
        let home = app.buttons["bananaOS.home"].firstMatch
        waitUntilReady(home); home.tap()
        waitUntilReady(email)
        XCTAssertFalse(home.exists)
        XCTAssertEqual(app.statusBars.count, 0)
        guard let finalWeb = frame(web), let finalSocial = frame(social) else {
            XCTFail("Final grid geometry missing"); return
        }
        XCTAssertLessThan(finalSocial.midX, finalWeb.midX)
        XCTAssertEqual(app.buttons.matching(identifier: "bananaOS.app.browser").count, 1)
        XCTAssertEqual(app.buttons.matching(identifier: "bananaOS.app.social").count, 1)
    }

    @MainActor
    func testEveryApplicationOpensAndReturnsHome() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        waitUntilReady(app.buttons["bananaOS.app.email"].firstMatch, timeout: 20)

        // Match the registered production routes, using only ordinary Home controls.
        let routes = ["email", "browser", "social", "watchVideo", "messager",
                      "photoAlbum", "settings", "phone", "news", "aiAssistant",
                      "vrExperience", "snake", "pong", "xo", "evidence", "banking"]
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
        let result = XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: ready, object: element)], timeout: timeout)
        if result != .completed { print(XCUIApplication().debugDescription) }
        XCTAssertEqual(result, .completed)
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
