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

    /// Focused regression check only; a pass is not a full accessibility audit.
    @MainActor
    func testHomeDynamicTypeAccessibilityAudit() throws {
        let environment = ProcessInfo.processInfo.environment
        guard (environment["BANANA_QA_ACCESSIBILITY_TYPE"] ?? environment["TEST_RUNNER_BANANA_QA_ACCESSIBILITY_TYPE"]) == "owned-simulator" else {
            throw XCTSkip("Requires the dedicated owned-simulator Dynamic Type runner.")
        }
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        let email = app.buttons["bananaOS.app.email"].firstMatch
        ready(email, timeout: 20)
        settled(email, in: app)
        XCTAssertFalse(app.buttons["bananaOS.home"].exists)
        XCTAssertEqual(app.statusBars.count, 0)
        XCTAssertFalse(app.alerts.firstMatch.exists)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Focused Home Dynamic Type audit"
        attachment.lifetime = .keepAlways
        add(attachment)
        // Public iOS 17+ API; no issue handler or suppressed findings.
        try app.performAccessibilityAudit(for: .dynamicType)
    }

    /// Diagnostic isolation only; separate category results are not a full audit pass.
    @MainActor
    func testHomeSingleCategoryAccessibilityDiagnostic() throws {
        let environment = ProcessInfo.processInfo.environment
        guard (environment["BANANA_QA_ACCESSIBILITY_CATEGORY"] ?? environment["TEST_RUNNER_BANANA_QA_ACCESSIBILITY_CATEGORY"]) == "owned-simulator" else {
            throw XCTSkip("Requires the dedicated owned-simulator category diagnostic runner.")
        }
        let category = environment["BANANA_QA_AUDIT_CATEGORY"] ?? environment["TEST_RUNNER_BANANA_QA_AUDIT_CATEGORY"] ?? ""
        let auditType: XCUIAccessibilityAuditType
        switch category {
        case "contrast": auditType = .contrast
        case "element-detection": auditType = .elementDetection
        case "hit-region": auditType = .hitRegion
        case "element-description": auditType = .sufficientElementDescription
        case "dynamic-type": auditType = .dynamicType
        case "text-clipped": auditType = .textClipped
        case "trait": auditType = .trait
        default:
            XCTFail("Unknown accessibility diagnostic category: \(category)")
            return
        }
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        let email = app.buttons["bananaOS.app.email"].firstMatch
        ready(email, timeout: 20)
        settled(email, in: app)
        XCTAssertFalse(app.buttons["bananaOS.home"].exists)
        XCTAssertEqual(app.statusBars.count, 0)
        XCTAssertFalse(app.alerts.firstMatch.exists)
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Category diagnostic Home — \(category)"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        let hierarchy = XCTAttachment(string: app.debugDescription)
        hierarchy.name = "Category diagnostic pre-audit AX — \(category)"
        hierarchy.lifetime = .keepAlways
        add(hierarchy)
        print("BANANA_CATEGORY_AUDIT_START \(category)")
        // Public iOS 17+ category audit. No issue handler or error suppression.
        try app.performAccessibilityAudit(for: auditType)
        print("BANANA_CATEGORY_AUDIT_END \(category)")
    }

    @MainActor private func audit(_ app: XCUIApplication, name: String) throws {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Accessibility audit — \(name)"
        attachment.lifetime = .keepAlways
        add(attachment)
        // iOS 17+ public XCTest API, supported by the project's iOS 18 target.
        // Default acceptance runs retain the unmodified public audit.
        let environment = ProcessInfo.processInfo.environment
        if (environment["BANANA_QA_AUDIT_LOG_NODES"] ?? environment["TEST_RUNNER_BANANA_QA_AUDIT_LOG_NODES"]) == "1" {
            try app.performAccessibilityAudit { issue in
                var details = "AUDIT_NODE_BEGIN\ncompact: \(issue.compactDescription)\ndetailed: \(issue.detailedDescription)\n"
                if let element = issue.element {
                    details += "element: \(element.debugDescription)\nlabel: \(element.label)\nidentifier: \(element.identifier)\ntype: \(element.elementType.rawValue)\nframe: \(element.frame)\n"
                }
                details += "AUDIT_NODE_END"
                print(details)
                let diagnostic = XCTAttachment(string: details)
                diagnostic.name = "Accessibility audit issue node"
                diagnostic.lifetime = .keepAlways
                self.add(diagnostic)
                // False records the issue normally; no finding is suppressed.
                return false
            }
        } else {
            try app.performAccessibilityAudit()
        }
    }

    @MainActor private func visible(_ element: XCUIElement, id: String, in app: XCUIApplication) -> Bool {
        guard let frame = usableFrame(element, in: app), element.isHittable else { return false }
        let center = CGPoint(x: frame.midX, y: frame.midY)
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
            guard let viewport = usableFrame(scroll, in: app) else {
                XCTFail("Unavailable scroll viewport: \(id)")
                return
            }
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
            guard let frame = self.usableFrame(anchor, in: app),
                  anchor.isEnabled, anchor.isHittable else {
                previous = nil
                stableObservations = 0
                return false
            }
            stableObservations = previous == frame ? stableObservations + 1 : 0
            previous = frame
            return stableObservations >= 2
        }
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: condition, object: anchor)], timeout: 8), .completed)
    }

    // XCTest can expose a transient zero-sized/infinite AX snapshot even when
    // Home is visibly rendered. Do not ask it for a hit point for that geometry.
    @MainActor private func usableFrame(_ element: XCUIElement, in app: XCUIApplication) -> CGRect? {
        guard element.exists else { return nil }
        let frame = element.frame
        let window = app.frame
        guard [frame.minX, frame.minY, frame.width, frame.height,
               window.minX, window.minY, window.width, window.height].allSatisfy({ $0.isFinite }),
              frame.width > 0, frame.height > 0, window.width > 0, window.height > 0,
              window.contains(frame) else { return nil }
        return frame
    }

    @MainActor private func ready(_ element: XCUIElement, timeout: TimeInterval = 8) {
        let app = XCUIApplication()
        let condition = NSPredicate { _, _ in
            guard self.usableFrame(element, in: app) != nil else { return false }
            return element.isEnabled && element.isHittable
        }
        let result = XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: condition, object: element)], timeout: timeout)
        if result != .completed { print(XCUIApplication().debugDescription) }
        XCTAssertEqual(result, .completed)
    }
}
