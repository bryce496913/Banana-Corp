import XCTest

// Run on a fresh, dedicated simulator.
// Never add this destructive test to a run against a player's simulator.
final class StoryResetUITests: XCTestCase {
    @MainActor
    func testSettingsResetCancelConfirmAndRelaunch() throws {
        #if !DEBUG
        throw XCTSkip("Story reset is an existing Debug-only control.")
        #else
        // Runner metadata only; never forwarded as an app launch flag or used to
        // bypass gameplay. The dedicated runner must create a fresh simulator.
        let environment = ProcessInfo.processInfo.environment
        guard (environment["BANANA_QA_RESET"] ?? environment["TEST_RUNNER_BANANA_QA_RESET"]) == "fresh-simulator" else {
            throw XCTSkip("Requires the dedicated fresh-simulator reset runner.")
        }
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        ready(app.buttons["bananaOS.app.email"].firstMatch, timeout: 20)

        // Establish and validate the fresh fixture through ordinary controls.
        open(app, "evidence")
        XCTAssertTrue(app.staticTexts["No preserved evidence"].waitForExistence(timeout: 8))
        open(app, "news")
        let sourceID = "story.open.version.act1.news.launch.v1"
        let preserveID = "story.preserve.version.act1.news.launch.v1"
        let source = app.buttons[sourceID].firstMatch
        ready(source)
        // AppListRow combines its visible Unread marker into the row label.
        // Confirm the concrete accessibility representation on the first native run.
        XCTAssertTrue(source.label.contains("Unread"), source.label)
        tap(app, sourceID)
        tap(app, preserveID)
        guard let preservedButton = activeTarget(app, id: preserveID, type: .button)?.0 else { return }
        XCTAssertFalse(preservedButton.isEnabled)
        assertPreservedNews(app)

        // Cancel must retain meaningful progress, not merely the initial state.
        diagnostics(app)
        resetDialog(app, confirming: false)
        assertPreservedNews(app)
        open(app, "news")
        ready(source)
        XCTAssertFalse(source.label.contains("Unread"), source.label)
        guard let retainedButton = activeTarget(app, id: preserveID, type: .button)?.0 else { return }
        XCTAssertFalse(retainedButton.isEnabled)

        diagnostics(app)
        resetDialog(app, confirming: true)
        // AppState.resetStoryForNewGame explicitly returns to Home.
        ready(app.buttons["bananaOS.app.email"].firstMatch)
        XCTAssertFalse(app.alerts.firstMatch.exists)
        assertFreshReset(app, sourceID: sourceID, preserveID: preserveID)

        app.terminate()
        app.launch()
        ready(app.buttons["bananaOS.app.email"].firstMatch, timeout: 20)
        assertFreshReset(app, sourceID: sourceID, preserveID: preserveID)
        #endif
    }

    @MainActor
    func testReleaseSettingsOmitsDevelopmentDiagnostics() throws {
        #if DEBUG
        throw XCTSkip("Run this assertion against the Release app.")
        #else
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        ready(app.buttons["bananaOS.app.email"].firstMatch, timeout: 20)
        open(app, "settings")
        XCTAssertTrue(app.staticTexts["DEVICE SETTINGS"].waitForExistence(timeout: 8))
        XCTAssertFalse(app.buttons["Story slice diagnostics"].exists)
        XCTAssertFalse(app.staticTexts["Story slice diagnostics"].exists)
        XCTAssertFalse(app.buttons["Reset story slice"].exists)
        XCTAssertFalse(app.buttons["Replay with preserved email"].exists)
        XCTAssertFalse(app.buttons["Replay without preserved email"].exists)
        #endif
    }

    @MainActor private func assertPreservedNews(_ app: XCUIApplication) {
        open(app, "evidence")
        ready(app.buttons["story.evidence.evidence.act1.news.launch.v1"].firstMatch)
    }

    @MainActor private func assertFreshReset(_ app: XCUIApplication, sourceID: String, preserveID: String) {
        open(app, "evidence")
        XCTAssertTrue(app.staticTexts["No preserved evidence"].waitForExistence(timeout: 8))
        XCTAssertFalse(app.buttons["story.evidence.evidence.act1.news.launch.v1"].exists)
        open(app, "email")
        XCTAssertFalse(app.buttons["story.open.version.act1.echo_review.v1"].exists)
        open(app, "news")
        let source = app.buttons[sourceID].firstMatch
        ready(source)
        XCTAssertTrue(source.label.contains("Unread"), source.label)
        guard let freshPreserveButton = activeTarget(app, id: preserveID, type: .button)?.0 else { return }
        ready(freshPreserveButton)
        // Do not open/preserve again: leave the reset source unread across relaunch.
    }

    @MainActor private func diagnostics(_ app: XCUIApplication) {
        open(app, "settings")
        tap(app, "Story slice diagnostics")
        XCTAssertTrue(app.staticTexts["Development only"].waitForExistence(timeout: 8))
    }

    @MainActor private func resetDialog(_ app: XCUIApplication, confirming: Bool) {
        // A SwiftUI confirmationDialog can be exposed as a sheet or alert.
        // Opening it is intentional, so do not call the generic no-alert tap.
        guard let reset = scrollTo(id: "Reset story slice", in: app) else { return }
        reset.tap()
        // Identify the native dialog by its unique destructive action. Compact
        // sheets expose Cancel; adaptive popovers expose an outside dismiss region.
        let sheet = app.sheets.containing(.button, identifier: "Reset and continue").firstMatch
        let alert = app.alerts.containing(.button, identifier: "Reset and continue").firstMatch
        let appeared = NSPredicate { _, _ in sheet.exists || alert.exists }
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: appeared, object: app)], timeout: 8), .completed)
        let dialog = sheet.exists ? sheet : alert
        if confirming || dialog.buttons["Cancel"].firstMatch.exists {
            let action = dialog.buttons[confirming ? "Reset and continue" : "Cancel"].firstMatch
            ready(action)
            action.tap()
        } else {
            let backdrop = app.otherElements["PopoverDismissRegion"].firstMatch
            ready(backdrop)
            guard let region = usableFrame(backdrop, in: app),
                  let modal = finiteFrame(dialog) else { XCTFail("Missing native popover dismissal geometry"); return }
            let inset = region.insetBy(dx: 24, dy: 24)
            let points = [CGPoint(x: inset.minX, y: inset.midY),
                          CGPoint(x: inset.maxX, y: inset.midY),
                          CGPoint(x: inset.midX, y: inset.minY),
                          CGPoint(x: inset.midX, y: inset.maxY)]
            guard let point = points.first(where: { region.contains($0) && !modal.insetBy(dx: -16, dy: -16).contains($0) }) else {
                XCTFail("No safe point in native popover dismiss region")
                return
            }
            backdrop.coordinate(withNormalizedOffset: .zero)
                .withOffset(CGVector(dx: point.x - region.minX, dy: point.y - region.minY)).tap()
        }
        let dismissed = NSPredicate(format: "exists == false")
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: dismissed, object: dialog)], timeout: 8), .completed)
        XCTAssertFalse(app.alerts.firstMatch.exists, "Unexpected reset failure alert")
    }

    @MainActor private func open(_ app: XCUIApplication, _ route: String) {
        if app.buttons.matching(identifier: "bananaOS.home").count > 0 { tap(app, "bananaOS.home") }
        // The closing app may leave transient AX frames before Home is ready.
        // Wait for the real Home anchor before inspecting/scanning its icons.
        ready(app.buttons["bananaOS.app.email"].firstMatch)
        XCTAssertEqual(app.buttons.matching(identifier: "bananaOS.home").count, 0, "Previous app must finish returning Home")
        tap(app, "bananaOS.app.\(route)")
        readyHome(app)
    }

    @MainActor private func finiteFrame(_ element: XCUIElement) -> CGRect? {
        guard element.exists else { return nil }
        let frame = element.frame
        guard [frame.minX, frame.minY, frame.maxX, frame.maxY, frame.width, frame.height].allSatisfy({ $0.isFinite }),
              frame.width > 0, frame.height > 0 else { return nil }
        return frame
    }

    @MainActor private func usableFrame(_ element: XCUIElement, in app: XCUIApplication) -> CGRect? {
        guard let frame = finiteFrame(element), let window = finiteFrame(app), window.contains(frame) else { return nil }
        return frame
    }

    @MainActor private func resolutionFailure(_ app: XCUIApplication, id: String) {
        print(app.debugDescription)
        let owners = app.scrollViews.containing(.any, identifier: id)
        for index in 0..<owners.count {
            let owner = owners.element(boundBy: index)
            let frame = finiteFrame(owner)
            print("Owner \(index) for \(id): frame=\(String(describing: frame)); hittable=\(frame == nil ? "unavailable" : String(owner.isHittable))")
        }
        let capture = XCTAttachment(screenshot: app.screenshot())
        capture.name = "Failed active owner — \(id)"
        capture.lifetime = .keepAlways
        add(capture)
    }

    @MainActor private func activeTarget(_ app: XCUIApplication, id: String, type: XCUIElement.ElementType) -> (XCUIElement, XCUIElement?)? {
        let owners = app.scrollViews.containing(.any, identifier: id)
        let activeOwners = (0..<owners.count).map { owners.element(boundBy: $0) }.filter {
            usableFrame($0, in: app) != nil && $0.isHittable
        }
        if activeOwners.count == 1 {
            let owner = activeOwners[0]
            let targets = owner.descendants(matching: type).matching(identifier: id)
            guard targets.count == 1 else {
                resolutionFailure(app, id: id)
                XCTFail("Ambiguous target inside active viewport: \(id)")
                return nil
            }
            let target = targets.element(boundBy: 0)
            guard finiteFrame(target) != nil else {
                resolutionFailure(app, id: id)
                XCTFail("Unavailable target geometry inside active viewport: \(id)")
                return nil
            }
            return (target, owner)
        }
        guard activeOwners.isEmpty && owners.count == 0 else {
            resolutionFailure(app, id: id)
            XCTFail("Missing or ambiguous active scroll owner: \(id)")
            return nil
        }
        let targets = app.descendants(matching: type).matching(identifier: id)
        let activeTargets = (0..<targets.count).map { targets.element(boundBy: $0) }.filter {
            usableFrame($0, in: app) != nil && $0.isEnabled && $0.isHittable
        }
        if activeTargets.count == 1 { return (activeTargets[0], nil) }
        // Lazy controls may not yet exist. Search only a unique active viewport.
        let scrolls = app.scrollViews
        let activeScrolls = (0..<scrolls.count).map { scrolls.element(boundBy: $0) }.filter {
            usableFrame($0, in: app) != nil && $0.isHittable
        }
        if targets.count == 0 && activeTargets.isEmpty && activeScrolls.count == 1 {
            return (activeScrolls[0].descendants(matching: type).matching(identifier: id).element(boundBy: 0), activeScrolls[0])
        }
        resolutionFailure(app, id: id)
        XCTFail("Missing or ambiguous active control: \(id)")
        return nil
    }

    @MainActor private func targetIsVisible(_ element: XCUIElement, owner: XCUIElement?, in app: XCUIApplication) -> Bool {
        guard let frame = usableFrame(element, in: app), element.isEnabled, element.isHittable else { return false }
        guard let owner else { return true }
        guard let viewport = usableFrame(owner, in: app), owner.isHittable else { return false }
        return viewport.insetBy(dx: 2, dy: 2).contains(CGPoint(x: frame.midX, y: frame.midY))
    }

    @MainActor private func readyHome(_ app: XCUIApplication) {
        var previous: CGRect?
        var stableObservations = 0
        let condition = NSPredicate { _, _ in
            let candidates = app.buttons.matching(identifier: "bananaOS.home")
            let active = (0..<candidates.count).map { candidates.element(boundBy: $0) }.filter {
                self.usableFrame($0, in: app) != nil && $0.isEnabled && $0.isHittable
            }
            guard active.count == 1, let frame = self.usableFrame(active[0], in: app) else {
                previous = nil
                stableObservations = 0
                return false
            }
            stableObservations = previous == frame ? stableObservations + 1 : 0
            previous = frame
            return stableObservations >= 2
        }
        let result = XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: condition, object: app)], timeout: 8)
        if result != .completed { resolutionFailure(app, id: "bananaOS.home") }
        XCTAssertEqual(result, .completed)
    }

    @MainActor private func ready(_ element: XCUIElement, timeout: TimeInterval = 8) {
        let app = XCUIApplication()
        var previous: CGRect?
        var stableObservations = 0
        let condition = NSPredicate { _, _ in
            guard let frame = self.usableFrame(element, in: app), element.isEnabled, element.isHittable else {
                previous = nil
                stableObservations = 0
                return false
            }
            stableObservations = previous == frame ? stableObservations + 1 : 0
            previous = frame
            return stableObservations >= 2
        }
        let result = XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: condition, object: element)], timeout: timeout)
        if result != .completed {
            print(app.debugDescription)
            let capture = XCTAttachment(screenshot: app.screenshot())
            capture.name = "Failed readiness"
            capture.lifetime = .keepAlways
            add(capture)
        }
        XCTAssertEqual(result, .completed)
    }

    @MainActor private func scrollTo(id: String, in app: XCUIApplication, type: XCUIElement.ElementType = .button) -> XCUIElement? {
        var resolved: (XCUIElement, XCUIElement?)?
        for _ in 0..<16 {
            guard let target = activeTarget(app, id: id, type: type) else { return nil }
            resolved = target
            if targetIsVisible(target.0, owner: target.1, in: app) { break }
            guard let scroll = target.1, let viewport = usableFrame(scroll, in: app), scroll.isHittable else {
                resolutionFailure(app, id: id)
                XCTFail("Unavailable active scroll viewport: \(id)")
                return nil
            }
            let frame = finiteFrame(target.0)
            let movingDown = frame.map { $0.midY < viewport.midY } ?? false
            let edge = movingDown ? viewport.minY : viewport.maxY
            let distance = frame.map { min(viewport.height * 0.55, max(70, abs($0.midY - edge) + 40)) } ?? viewport.height * 0.5
            let startY: CGFloat = movingDown ? 0.25 : 0.75
            let endY = startY + (movingDown ? 1 : -1) * distance / viewport.height
            scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: startY))
                .press(forDuration: 0.05, thenDragTo: scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: endY)))
        }
        guard let target = resolved else { return nil }
        ready(target.0)
        let visible = targetIsVisible(target.0, owner: target.1, in: app)
        if !visible { resolutionFailure(app, id: id) }
        XCTAssertTrue(visible, "Control center must lie inside its active owning viewport: \(id)")
        return visible ? target.0 : nil
    }

    @MainActor private func tap(_ app: XCUIApplication, _ id: String) {
        guard let element = scrollTo(id: id, in: app) else { return }
        element.tap()
        XCTAssertFalse(app.alerts.firstMatch.exists, "Unexpected failure after \(id)")
    }

}
