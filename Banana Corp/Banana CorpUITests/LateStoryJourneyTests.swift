import XCTest

/// Runner metadata selects one already-authorized short QA session. No launch flags or save edits.
final class LateStoryJourneyTests: XCTestCase {
    @MainActor func testApprovedLateStoryBlock() throws {
        let env = ProcessInfo.processInfo.environment
        guard let phase = env["BANANA_LATE_BLOCK"] ?? env["TEST_RUNNER_BANANA_LATE_BLOCK"] else {
            throw XCTSkip("Requires an explicitly authorized short QA session on the isolated campaign app")
        }
        let phases = ["act4-components", "act4-takeover", "blackout", "maya", "dawn", "agreement", "false-promise", "observer"]
        guard phases.contains(phase) else { XCTFail("Unknown late-story block"); return }
        continueAfterFailure = false
        let app = XCUIApplication()
        defer {
            app.terminate()
            XCTAssertEqual(app.state, .notRunning)
        }
        app.launch()
        ready(app.buttons["bananaOS.app.browser"], timeout: 20)
        print("BANANA_LATE_BEGIN \(phase)")
        switch phase {
        case "act4-components":
            for key in ["signal.packet", "vale.authorization", "vale.loss"] { lead(app, "act4." + key) }
            tap(app, "story.act4.vale.compare")
            tap(app, "story.act4.root.authorize")
            lead(app, "act4.deployment.relay")
            tap(app, "story.act4.deployment.verify")
        case "act4-takeover":
            lead(app, "act4.lantern.protocol")
            tap(app, "story.act4.lantern.authorize")
            for key in ["maya.signature", "assistant.conflict.safety", "assistant.conflict.core"] { lead(app, "act4." + key) }
            tap(app, "story.act4.takeover.connect")
            lead(app, "act4.echo.address")
            tap(app, "story.act4.advance.act5")
            lead(app, "act5.entry")
            lead(app, "act5.recovery")
        case "blackout":
            source(app, group: "BLACKOUT", key: "dependency_warning")
            ending(app, key: "silence", title: "THE SILENCE", cancelFirst: true)
        case "maya":
            for key in ["maya.m01", "maya.m02", "maya.m03"] { source(app, group: "Find Maya / DAWN", key: key) }
            openBrowser(app)
            for (id, value) in [("story.maya.note1", "D"), ("story.maya.note2", "F"), ("story.maya.note3", "A"), ("story.maya.baseline", "440 Hz")] {
                let field = app.textFields[id].firstMatch
                scrollTo(field, in: app); field.tap(); field.typeText(value + "\n")
            }
            tap(app, "story.act5.maya.reconstruct")
            XCTAssertFalse(app.alerts.firstMatch.exists)
            source(app, group: "Find Maya / DAWN", key: "safety_cooperation")
            tap(app, "story.act5.safety.cooperate")
        case "dawn":
            for stage in ["stabilize", "isolate", "restore"] {
                source(app, group: "Find Maya / DAWN", key: "dawn." + stage)
                tap(app, "story.act5.dawn." + stage)
            }
            ending(app, key: "first_light", title: "FIRST LIGHT")
        case "agreement":
            source(app, group: "Negotiate", key: "negotiation.claims")
            for key in ["dependency", "autonomy", "energy"] { tap(app, "story.act5.challenge." + key) }
            source(app, group: "Negotiate", key: "negotiation.safeguards")
            for key in ["release_users", "maya_supervision", "public_oversight"] { tap(app, "story.act5.safeguard." + key) }
            tap(app, "story.act5.agreement.verify")
            ending(app, key: "agreement", title: "THE AGREEMENT")
        case "false-promise":
            source(app, group: "Negotiate", key: "negotiation.claims")
            source(app, group: "Negotiate", key: "negotiation.unverified")
            ending(app, key: "false_promise", title: "THE FALSE PROMISE")
        case "observer":
            for key in ["identifier", "diagnostic", "maya_warning", "startup", "root"] {
                source(app, group: "Other available archives", key: "observer." + key)
            }
            tap(app, "story.act5.observer.link")
            ending(app, key: "awakening", title: "THE AWAKENING")
        default: XCTFail("Invalid block")
        }
        home(app)
        let capture = XCTAttachment(screenshot: app.screenshot())
        capture.name = "Late story block — " + phase; capture.lifetime = .keepAlways; add(capture)
        app.terminate(); app.launch()
        ready(app.buttons["bananaOS.app.browser"], timeout: 20)
        print("BANANA_LATE_CHECKPOINT \(phase)")
        print("BANANA_LATE_END \(phase)")
    }

    @MainActor private func ending(_ app: XCUIApplication, key: String, title: String, cancelFirst: Bool = false) {
        tap(app, "story.ending.prepare." + key)
        if cancelFirst {
            tap(app, "story.ending.cancel")
            XCTAssertFalse(app.staticTexts["story.ending.title"].exists)
            tap(app, "story.ending.prepare." + key)
        }
        tap(app, "story.ending.confirm")
        let heading = app.staticTexts["story.ending.title"].firstMatch
        ready(heading); XCTAssertEqual(heading.label, title)
        tap(app, "story.ending.restore")
        XCTAssertFalse(app.staticTexts["story.ending.title"].exists)
    }
    @MainActor private func lead(_ app: XCUIApplication, _ key: String) {
        openBrowser(app)
        tap(app, "story.lead.version." + key + ".v1")
    }
    @MainActor private func source(_ app: XCUIApplication, group: String, key: String) {
        openBrowser(app)
        let disclosure = app.buttons[group].firstMatch
        scrollTo(disclosure, in: app); disclosure.tap()
        tap(app, "story.direction.source.version.act5." + key + ".v1")
    }
    @MainActor private func openBrowser(_ app: XCUIApplication) {
        home(app)
        tap(app, "bananaOS.app.browser")
        ready(app.buttons["bananaOS.home"])
    }
    @MainActor private func home(_ app: XCUIApplication) {
        let button = app.buttons["bananaOS.home"].firstMatch
        if button.exists { ready(button); button.tap() }
        ready(app.buttons["bananaOS.app.browser"])
    }
    @MainActor private func tap(_ app: XCUIApplication, _ id: String) {
        let button = app.buttons[id].firstMatch
        scrollTo(button, in: app); button.tap()
    }
    @MainActor private func scrollTo(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<16 {
            if element.exists && element.isHittable && app.frame.contains(element.frame) { break }
            let scroll = app.scrollViews.firstMatch
            XCTAssertTrue(scroll.exists)
            if element.exists && element.frame.midY < app.frame.midY { scroll.swipeDown() }
            else { scroll.swipeUp() }
        }
        ready(element)
    }
    @MainActor private func ready(_ element: XCUIElement, timeout: TimeInterval = 8) {
        XCTAssertTrue(element.waitForExistence(timeout: timeout))
        let predicate = NSPredicate { _, _ in
            guard element.exists else { return false }
            let f = element.frame
            return [f.minX, f.minY, f.width, f.height].allSatisfy { $0.isFinite } && f.width > 0 && f.height > 0 && element.isHittable
        }
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: predicate, object: element)], timeout: timeout), .completed)
    }
}
