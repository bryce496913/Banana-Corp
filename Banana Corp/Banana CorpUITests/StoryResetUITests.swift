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
        XCTAssertFalse(app.buttons[preserveID].firstMatch.isEnabled)
        assertPreservedNews(app)

        // Cancel must retain meaningful progress, not merely the initial state.
        diagnostics(app)
        resetDialog(app, confirming: false)
        assertPreservedNews(app)
        open(app, "news")
        ready(source)
        XCTAssertFalse(source.label.contains("Unread"), source.label)
        XCTAssertFalse(app.buttons[preserveID].firstMatch.isEnabled)

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
        ready(app.buttons[preserveID].firstMatch)
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
        let reset = app.buttons["Reset story slice"].firstMatch
        scrollTo(app, reset, description: "Reset story slice")
        reset.tap()
        // Automatic title visibility can hide the title on iPhone. Identify the
        // dialog by its unique destructive action, then require Cancel inside it.
        let sheet = app.sheets.containing(.button, identifier: "Reset and continue").firstMatch
        let alert = app.alerts.containing(.button, identifier: "Reset and continue").firstMatch
        let appeared = NSPredicate { _, _ in sheet.exists || alert.exists }
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: appeared, object: app)], timeout: 8), .completed)
        let dialog = sheet.exists ? sheet : alert
        ready(dialog.buttons["Cancel"].firstMatch)
        let action = dialog.buttons[confirming ? "Reset and continue" : "Cancel"].firstMatch
        ready(action)
        action.tap()
        let dismissed = NSPredicate(format: "exists == false")
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: dismissed, object: dialog)], timeout: 8), .completed)
        XCTAssertFalse(app.alerts.firstMatch.exists, "Unexpected reset failure alert")
    }

    @MainActor private func open(_ app: XCUIApplication, _ route: String) {
        let home = app.buttons["bananaOS.home"].firstMatch
        if home.exists { ready(home); home.tap() }
        tap(app, "bananaOS.app.\(route)")
        ready(app.buttons["bananaOS.home"].firstMatch)
    }

    @MainActor private func tap(_ app: XCUIApplication, _ id: String) {
        let button = app.buttons[id].firstMatch
        scrollTo(app, button, description: id)
        button.tap()
        XCTAssertFalse(app.alerts.firstMatch.exists, "Unexpected alert after \(id)")
    }

    @MainActor private func scrollTo(_ app: XCUIApplication, _ button: XCUIElement, description: String) {
        func visible() -> Bool {
            guard button.exists, button.isHittable else { return false }
            let center = CGPoint(x: button.frame.midX, y: button.frame.midY)
            guard app.frame.insetBy(dx: 1, dy: 1).contains(center) else { return false }
            let owner = app.scrollViews.containing(.button, identifier: description).firstMatch
            return !owner.exists || owner.frame.insetBy(dx: 2, dy: 2).contains(center)
        }
        for _ in 0..<16 {
            if visible() { break }
            let owner = app.scrollViews.containing(.button, identifier: description).firstMatch
            // If laziness has not materialized the button, choose only an
            // unambiguous viewport rather than scrolling a hidden nested stack.
            if !owner.exists { XCTAssertEqual(app.scrollViews.count, 1, "Ambiguous scroll owner: \(description)") }
            guard owner.exists || app.scrollViews.count == 1 else { return }
            let scroll = owner.exists ? owner : app.scrollViews.element(boundBy: 0)
            XCTAssertTrue(scroll.exists, "Missing scroll/control: \(description)")
            guard scroll.exists, scroll.frame.height > 0 else { return }
            let viewport = scroll.frame
            let movingDown = button.exists && button.frame.midY < viewport.midY
            let edge = movingDown ? viewport.minY : viewport.maxY
            let distance = button.exists
                ? min(viewport.height * 0.55, max(70, abs(button.frame.midY - edge) + 40))
                : viewport.height * 0.5
            let startY: CGFloat = movingDown ? 0.25 : 0.75
            let endY = startY + (movingDown ? 1 : -1) * distance / viewport.height
            scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: startY))
                .press(forDuration: 0.05, thenDragTo: scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: endY)))
        }
        ready(button)
        XCTAssertTrue(visible(), "Control center must be inside its owning viewport: \(description)")
    }

    @MainActor private func ready(_ element: XCUIElement, timeout: TimeInterval = 8) {
        let predicate = NSPredicate(format: "exists == true AND hittable == true AND enabled == true")
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: predicate, object: element)], timeout: timeout), .completed)
    }
}
