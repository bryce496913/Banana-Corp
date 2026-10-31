import XCTest

/// Runner metadata selects one explicitly authorized QA phase. No launch flags or save edits.
/// One passing phase is partial coverage; story acceptance requires the ordered campaign,
/// all original eight phases and final saved-state/evidence checks. Replay/reset acceptance
/// additionally requires the explicit final replay phase.
/// Run replay last: it intentionally resets the QA campaign and clears its earned collection.
final class LateStoryJourneyTests: XCTestCase {
    override func tearDown() async throws {
        // Required even when an XCTest failure aborts the body before defer executes.
        await MainActor.run {
            let app = XCUIApplication()
            app.terminate()
            XCTAssertEqual(app.state, .notRunning, "Release the isolated QA application")
            if app.state == .notRunning { print("BANANA_LATE_APP_RELEASED") }
        }
        try await super.tearDown()
    }

    private let endings = [
        (key: "silence", title: "THE SILENCE"),
        (key: "first_light", title: "FIRST LIGHT"),
        (key: "agreement", title: "THE AGREEMENT"),
        (key: "false_promise", title: "THE FALSE PROMISE"),
        (key: "awakening", title: "THE AWAKENING")
    ]
    @MainActor func testApprovedLateStoryBlock() throws {
        let env = ProcessInfo.processInfo.environment
        guard let phase = env["BANANA_LATE_BLOCK"] ?? env["TEST_RUNNER_BANANA_LATE_BLOCK"] else {
            throw XCTSkip("Requires an explicitly authorized short QA session on the isolated campaign app")
        }
        let phases = ["act4-components", "act4-takeover", "blackout", "maya", "dawn", "agreement", "false-promise", "observer", "replay"]
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
            enterMayaIdentity(app, thirdNote: "G")
            tap(app, "story.act5.maya.reconstruct")
            let rejection = app.alerts["Action unavailable"].firstMatch
            ready(rejection)
            ready(rejection.buttons["OK"].firstMatch)
            rejection.buttons["OK"].firstMatch.tap()
            absent(rejection)
            scrollTo(app.textFields["story.maya.note1"].firstMatch, in: app)
            XCTAssertFalse(app.buttons["story.act5.safety.cooperate"].exists)
            checkpoint(app, name: "maya-wrong-answer")
            openBrowser(app)
            scrollTo(app.textFields["story.maya.note1"].firstMatch, in: app)
            expandDirection(app, "Find Maya / DAWN")
            XCTAssertFalse(app.buttons["story.direction.source.version.act5.safety_cooperation.v1"].exists,
                           "Wrong input must not grant reconstructed-identity access")
            XCTAssertFalse(app.buttons["story.direction.source.version.act5.dawn.stabilize.v1"].exists,
                           "Wrong input must not grant safety cooperation")
            enterMayaIdentity(app, thirdNote: "A")
            tap(app, "story.act5.maya.reconstruct")
            XCTAssertFalse(app.alerts.firstMatch.exists)
            absent(app.textFields["story.maya.note1"].firstMatch)
            XCTAssertFalse(app.buttons["story.act5.safety.cooperate"].exists,
                           "Reconstruction alone cannot award or request unreviewed cooperation")
            source(app, group: "Find Maya / DAWN", key: "safety_cooperation")
            tap(app, "story.act5.safety.cooperate")
            absent(app.buttons["story.act5.safety.cooperate"].firstMatch)
        case "dawn":
            for stage in ["stabilize", "isolate", "restore"] {
                source(app, group: "Find Maya / DAWN", key: "dawn." + stage)
                tap(app, "story.act5.dawn." + stage)
                absent(app.buttons["story.act5.dawn." + stage].firstMatch)
                checkpoint(app, name: "dawn-" + stage)
                openBrowser(app)
                XCTAssertFalse(app.buttons["story.act5.dawn." + stage].exists,
                               "A completed DAWN stage must remain completed after relaunch")
                if stage != "restore" {
                    XCTAssertFalse(app.buttons["story.ending.prepare.first_light"].exists,
                                   "Partial DAWN must not offer its ending")
                }
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
        case "replay":
            replayAndCollection(app)
        default: XCTFail("Invalid block")
        }
        home(app)
        let capture = XCTAttachment(screenshot: app.screenshot())
        capture.name = "Late story block — " + phase; capture.lifetime = .keepAlways; add(capture)
        checkpoint(app, name: phase)
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
        app.terminate()
        XCTAssertEqual(app.state, .notRunning)
        app.launch()
        ready(heading, timeout: 20)
        XCTAssertEqual(heading.label, title, "The committed ending must survive actual app relaunch")
        scrollTo(app.buttons["story.ending.restore"].firstMatch, in: app)
        print("BANANA_LATE_ENDING_PERSISTED \(key)")
        tap(app, "story.ending.restore")
        absent(heading)
        home(app)
    }
    @MainActor private func enterMayaIdentity(_ app: XCUIApplication, thirdNote: String) {
        for (id, value, placeholder) in [
            ("story.maya.note1", "D", "Note 1"),
            ("story.maya.note2", "F", "Note 2"),
            ("story.maya.note3", thirdNote, "Note 3"),
            ("story.maya.baseline", "440 Hz", "Reference baseline (Hz)")
        ] {
            let field = app.textFields[id].firstMatch
            scrollTo(field, in: app)
            field.tap()
            if let current = field.value as? String, !current.isEmpty, current != placeholder {
                field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count))
            }
            field.typeText(value + "\n")
        }
    }

    @MainActor private func checkpoint(_ app: XCUIApplication, name: String) {
        home(app)
        app.terminate()
        XCTAssertEqual(app.state, .notRunning)
        app.launch()
        ready(app.buttons["bananaOS.app.browser"].firstMatch, timeout: 20)
        XCTAssertFalse(app.staticTexts["story.ending.title"].exists)
        print("BANANA_LATE_RELAUNCH \(name)")
    }

    @MainActor private func expandDirection(_ app: XCUIApplication, _ group: String) {
        let disclosure = app.buttons[group].firstMatch
        scrollTo(disclosure, in: app)
        disclosure.tap()
    }

    @MainActor private func replayAndCollection(_ app: XCUIApplication) {
        print("BANANA_LATE_REPLAY_CLEARS_CAMPAIGN_AND_COLLECTION")
        openSettings(app)
        reviewAllEndings(app)
        tap(app, "story.new_game")
        confirmation(app, actionID: "story.new_game.confirm", actionLabel: "New game",
                     cancelID: "story.new_game.cancel", confirming: false)
        ready(app.buttons["story.ending.collection"].firstMatch)
        checkpoint(app, name: "new-game-cancelled")
        openBrowser(app)
        scrollTo(app.staticTexts["The Final Choice"].firstMatch, in: app)
        openSettings(app)
        reviewAllEndings(app)

        tap(app, "story.new_game")
        confirmation(app, actionID: "story.new_game.confirm", actionLabel: "New game",
                     cancelID: "story.new_game.cancel", confirming: true)
        ready(app.buttons["bananaOS.app.browser"].firstMatch)
        checkpoint(app, name: "new-game-confirmed")
        assertFreshCampaign(app)
        openSettings(app)
        reviewAllEndings(app)
        // Viewing an earned record must not turn it into this fresh campaign's ending.
        assertFreshCampaign(app)
        openSettings(app)
        clearHistory(app, confirming: false)
        ready(app.buttons["story.ending.collection"].firstMatch)
        reviewAllEndings(app)
        clearHistory(app, confirming: true)
        absent(app.buttons["story.ending.collection"].firstMatch)
        checkpoint(app, name: "ending-history-cleared")
        openSettings(app)
        XCTAssertFalse(app.buttons["story.ending.collection"].exists)
        XCTAssertFalse(app.buttons["story.ending.history.clear"].exists)
        assertFreshCampaign(app)
        print("BANANA_LATE_REPLAY_VERIFIED")
    }

    @MainActor private func reviewAllEndings(_ app: XCUIApplication) {
        tap(app, "story.ending.collection")
        for ending in endings {
            tap(app, "story.ending.review." + ending.key)
            let path = app.staticTexts["Banana Corp · /investigation/act5/ending/" + ending.key].firstMatch
            scrollTo(path, in: app)
            XCTAssertFalse(app.staticTexts["story.ending.title"].exists,
                           "Collection review must not commit an ending")
            XCTAssertFalse(app.buttons["story.ending.restore"].exists)
            ready(app.buttons["bananaOS.home"].firstMatch)
        }
        tap(app, "story.back")
        ready(app.buttons["story.ending.collection"].firstMatch)
    }

    @MainActor private func clearHistory(_ app: XCUIApplication, confirming: Bool) {
        let identified = app.buttons["story.ending.history.clear"].firstMatch
        let opener = identified.exists ? identified : app.buttons["Clear ending history"].firstMatch
        scrollTo(opener, in: app)
        opener.tap()
        confirmation(app, actionID: "story.ending.history.confirm", actionLabel: "Clear history",
                     cancelID: "story.ending.history.cancel", confirming: confirming)
    }

    @MainActor private func confirmation(_ app: XCUIApplication, actionID: String, actionLabel: String,
                                         cancelID: String, confirming: Bool) {
        // Scope to the actual confirmation container; a whole-app label could
        // accidentally tap the Settings opener rather than its destructive action.
        let idSheet = app.sheets.containing(.button, identifier: actionID).firstMatch
        let idAlert = app.alerts.containing(.button, identifier: actionID).firstMatch
        let labelSheet = app.sheets.containing(.button, identifier: actionLabel).firstMatch
        let labelAlert = app.alerts.containing(.button, identifier: actionLabel).firstMatch
        let appeared = NSPredicate { _, _ in idSheet.exists || idAlert.exists || labelSheet.exists || labelAlert.exists }
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: appeared, object: app)], timeout: 8), .completed)
        let dialog = idSheet.exists ? idSheet : (idAlert.exists ? idAlert : (labelSheet.exists ? labelSheet : labelAlert))
        let identified = dialog.buttons[confirming ? actionID : cancelID].firstMatch
        let button = identified.exists ? identified : dialog.buttons[confirming ? actionLabel : "Cancel"].firstMatch
        if !confirming, !button.exists {
            let dismiss = app.otherElements["PopoverDismissRegion"].firstMatch
            ready(dismiss); dismiss.tap()
        } else {
            ready(button); button.tap()
        }
        absent(dialog)
        XCTAssertFalse(app.alerts.firstMatch.exists, "Unexpected save failure after confirmation")
    }

    @MainActor private func assertFreshCampaign(_ app: XCUIApplication) {
        openBrowser(app)
        XCTAssertFalse(app.staticTexts["The Final Choice"].exists)
        XCTAssertFalse(app.staticTexts["story.ending.title"].exists)
        home(app)
        tap(app, "bananaOS.app.email")
        ready(app.buttons["bananaOS.home"].firstMatch)
        XCTAssertFalse(app.buttons["story.open.version.act1.echo_review.v1"].exists)
        home(app)
        tap(app, "bananaOS.app.news")
        let launch = app.buttons["story.open.version.act1.news.launch.v1"].firstMatch
        scrollTo(launch, in: app)
        XCTAssertTrue(launch.label.contains("Unread"), "A new campaign must not inherit article reads")
        home(app)
        tap(app, "bananaOS.app.evidence")
        ready(app.staticTexts["No preserved evidence"].firstMatch)
    }

    @MainActor private func openSettings(_ app: XCUIApplication) {
        home(app)
        tap(app, "bananaOS.app.settings")
        ready(app.buttons["bananaOS.home"].firstMatch)
    }

    @MainActor private func absent(_ element: XCUIElement, timeout: TimeInterval = 8) {
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: element)], timeout: timeout), .completed)
    }

    @MainActor private func lead(_ app: XCUIApplication, _ key: String) {
        openBrowser(app)
        tap(app, "story.lead.version." + key + ".v1")
    }
    @MainActor private func source(_ app: XCUIApplication, group: String, key: String) {
        openBrowser(app)
        expandDirection(app, group)
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
