import XCTest

// Public audits inspect visible UI;
// they do not verify VoiceOver reading order, gestures or spoken experience.
final class AccessibilityAuditUITests: XCTestCase {
    @MainActor
    func testHomeAndRegisteredApplicationsAccessibilityAudit() throws {
        let environment = ProcessInfo.processInfo.environment
        guard (environment["BANANA_QA_ACCESSIBILITY"] ?? environment["TEST_RUNNER_BANANA_QA_ACCESSIBILITY"]) == "owned-simulator" else {
            throw XCTSkip("Requires the dedicated owned-simulator accessibility runner.")
        }
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        let email = app.buttons["bananaOS.app.email"].firstMatch
        ready(email, timeout: 20)
        settled(email, in: app)
        XCTAssertFalse(app.buttons["bananaOS.home"].exists)
        try audit(app, name: "Home")

        // Match PhoneAppRoute and existing LaunchSmokeTests. No app launch
        // arguments, save edits, injected unlocks or content replay are used.
        let routes = ["email", "browser", "social", "watchVideo", "messager",
                      "photoAlbum", "settings", "phone", "news", "aiAssistant",
                      "vrExperience", "snake", "pong", "xo", "evidence"]
        for route in routes {
            let id = "bananaOS.app.\(route)"
            let icon = app.buttons[id].firstMatch
            scrollTo(icon, id: id, in: app)
            icon.tap()
            let home = app.buttons["bananaOS.home"].firstMatch
            ready(home)
            settled(home, in: app)
            XCTAssertEqual(app.statusBars.count, 0, route)
            XCTAssertFalse(app.alerts.firstMatch.exists, route)
            try audit(app, name: "Application \(route)")
            home.tap()
            ready(email)
            settled(email, in: app)
            XCTAssertFalse(home.exists, route)
            XCTAssertEqual(app.buttons.matching(identifier: id).count, 1)
        }
    }

    @MainActor private func audit(_ app: XCUIApplication, name: String) throws {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Accessibility audit — \(name)"
        attachment.lifetime = .keepAlways
        add(attachment)
        // iOS 17+ public XCTest API, supported by the project's iOS 18 target.
        // Default issue reporting: no handler suppresses or filters findings.
        try app.performAccessibilityAudit()
    }

    @MainActor private func visible(_ element: XCUIElement, id: String, in app: XCUIApplication) -> Bool {
        guard element.exists, element.isHittable else { return false }
        let center = CGPoint(x: element.frame.midX, y: element.frame.midY)
        guard app.frame.insetBy(dx: 1, dy: 1).contains(center) else { return false }
        let owner = app.scrollViews.containing(.button, identifier: id).firstMatch
        return !owner.exists || owner.frame.insetBy(dx: 2, dy: 2).contains(center)
    }

    @MainActor private func scrollTo(_ element: XCUIElement, id: String, in app: XCUIApplication) {
        for _ in 0..<16 {
            if visible(element, id: id, in: app) { break }
            let owner = app.scrollViews.containing(.button, identifier: id).firstMatch
            if !owner.exists { XCTAssertEqual(app.scrollViews.count, 1, "Ambiguous scroll owner: \(id)") }
            guard owner.exists || app.scrollViews.count == 1 else { return }
            let scroll = owner.exists ? owner : app.scrollViews.element(boundBy: 0)
            let viewport = scroll.frame
            guard viewport.height > 0 else { XCTFail("Empty viewport: \(id)"); return }
            let movingDown = element.exists && element.frame.midY < viewport.midY
            let edge = movingDown ? viewport.minY : viewport.maxY
            let distance = element.exists
                ? min(viewport.height * 0.55, max(70, abs(element.frame.midY - edge) + 40))
                : viewport.height * 0.5
            let startY: CGFloat = movingDown ? 0.25 : 0.75
            let endY = startY + (movingDown ? 1 : -1) * distance / viewport.height
            scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: startY))
                .press(forDuration: 0.05, thenDragTo: scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: endY)))
        }
        ready(element)
        XCTAssertTrue(visible(element, id: id, in: app), "Control center must lie inside owning viewport: \(id)")
    }

    @MainActor private func settled(_ anchor: XCUIElement, in app: XCUIApplication) {
        // Require successive native observations with unchanged geometry; this
        // is readiness evidence, not a claim that screenshots prove animation.
        var previous: CGRect?
        var stableObservations = 0
        let condition = NSPredicate { _, _ in
            guard anchor.exists && anchor.isHittable && anchor.isEnabled else { return false }
            let frame = anchor.frame
            guard frame.width > 0, frame.height > 0, app.frame.contains(frame) else { return false }
            stableObservations = previous == frame ? stableObservations + 1 : 0
            previous = frame
            return stableObservations >= 2
        }
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: condition, object: anchor)], timeout: 8), .completed)
    }

    @MainActor private func ready(_ element: XCUIElement, timeout: TimeInterval = 8) {
        let condition = NSPredicate(format: "exists == true AND hittable == true AND enabled == true")
        let result = XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: condition, object: element)], timeout: timeout)
        if result != .completed { print(XCUIApplication().debugDescription) }
        XCTAssertEqual(result, .completed)
    }
}
