import XCTest

/// Run on a fresh, dedicated simulator via scripts/validate-acts-journey.sh.
/// Mode belongs to the test runner only: no launch arguments or app-state bypasses.
final class ActsJourneyTests: XCTestCase {
    @MainActor
    func testActsOneThreePlayerJourney() throws {
        let environment = ProcessInfo.processInfo.environment
        guard let mode = environment["BANANA_QA_PATH"] ?? environment["TEST_RUNNER_BANANA_QA_PATH"] else {
            throw XCTSkip("Use validate-acts-journey.sh to provide a fresh simulator and preservation path.")
        }
        XCTAssertTrue(["both", "email", "video", "neither"].contains(mode))
        continueAfterFailure = false
        let preserveEmail = mode == "both" || mode == "email"
        let preserveVideo = mode == "both" || mode == "video"
        let app = XCUIApplication()
        app.launch()
        ready(app.buttons["bananaOS.app.email"], timeout: 20)
        XCTAssertEqual(app.statusBars.count, 0)
        openApp(app, "email")
        XCTAssertFalse(app.buttons["story.open.version.act1.echo_review.v1"].exists, "Fresh campaign must not have the leak unlocked")
        openApp(app, "news")
        tap(app, "story.open.version.act1.news.launch.v1")
        checkpoint(app, "launch coverage read")
        openApp(app, "watchVideo")
        presentation(app, "version.act1.promo.v1", preserve: false)
        checkpoint(app, "before email read")
        openApp(app, "email")
        tap(app, "story.open.version.act1.echo_review.v1")
        if preserveEmail { preserve(app, "version.act1.echo_review.v1") }
        checkpoint(app, "after email read before return")
        // Relaunch returns to the real Home/inbox boundary; no injected story event.
        openApp(app, "email")
        XCTAssertFalse(app.buttons["story.open.version.act1.echo_review.v1"].exists)
        checkpoint(app, "after removal before unknown warning")
        openApp(app, "messager")
        tap(app, "story.open.version.act1.first_anomaly.warning.v1")
        openApp(app, "aiAssistant")
        tap(app, "story.assistant.version.act1.first_anomaly.denial.v1")
        checkpoint(app, "after Assistant questioning")
        if preserveEmail {
            comparison(app, "evidence.act1.echo_review.v1")
            XCTAssertTrue(app.staticTexts["Current source unavailable"].waitForExistence(timeout: 8))
        } else {
            openApp(app, "evidence")
            XCTAssertFalse(app.buttons["story.evidence.evidence.act1.echo_review.v1"].exists)
            openApp(app, "email")
            tap(app, "story.open.version.act1.first_anomaly.trace.v1")
        }
        tap(app, "story.advance.act2")
        openApp(app, "watchVideo")
        presentation(app, "version.act2.alex_review.v1", preserve: preserveVideo)
        checkpoint(app, "before Alex replacement")
        openApp(app, "watchVideo")
        XCTAssertFalse(app.buttons["story.open.version.act2.alex_review.v1"].exists)
        presentation(app, "version.act2.alex_review.v2", preserve: false)
        checkpoint(app, "after Alex replacement inspected")
        if preserveVideo {
            comparison(app, "evidence.act2.alex_review.v1")
            XCTAssertTrue(app.staticTexts["Visible differences"].waitForExistence(timeout: 8))
        } else {
            openApp(app, "evidence")
            XCTAssertFalse(app.buttons["story.evidence.evidence.act2.alex_review.v1"].exists)
        }
        openAndRead(app, "news", "version.act2.news.concerns.v1")
        openAndRead(app, "news", "version.act2.news.official.v1")
        openAndRead(app, "messager", "version.act2.messages.daniel.v1")
        openAndRead(app, "email", "version.act2.email.maya.v1")
        openAndRead(app, "browser", "version.act2.web.echo07.v1")
        checkpoint(app, "after ECHO-07 read")
        // Existing catalogue guidance opens the diagnostic source explicitly.
        openApp(app, "browser")
        tap(app, "story.lead.version.act2.diagnostics.excerpt.v1")
        if !preserveVideo { openAndRead(app, "news", "version.act2.news.corroboration.v1") }
        openApp(app, "aiAssistant")
        tap(app, "story.assistant.version.act2.assistant.edits.v1")
        checkpoint(app, "before explicit synthesis")
        openApp(app, "browser")
        tap(app, "story.connect.act2")
        checkpoint(app, "immediately before Act 3")
        openApp(app, "browser")
        tap(app, "story.advance.act3")
        tap(app, "story.resource.resource.banana_wall")
        XCTAssertTrue(app.descendants(matching: .any)["story.resource.locked.resource.banana_wall"].firstMatch.waitForExistence(timeout: 8))
        checkpoint(app, "locked Banana Wall")
        openApp(app, "browser")
        tap(app, "story.resource.resource.banana_wall")
        XCTAssertTrue(app.descendants(matching: .any)["story.resource.locked.resource.banana_wall"].firstMatch.waitForExistence(timeout: 8))
        XCTAssertFalse(app.buttons["Submit"].exists)
        XCTAssertEqual(app.statusBars.count, 0)
        XCTAssertFalse(app.alerts.firstMatch.exists)
        let puzzle = "puzzle.banana_wall.review_cross_reference"
        tap(app, "story.puzzle.hint.\(puzzle)")
        for source in ["content.act2.messages.daniel", "content.act2.news.official", "content.act2.email.maya", "content.act2.web.echo07"] {
            tap(app, "story.puzzle.clue.\(source)")
            tap(app, "story.back")
        }
        let fields = [("discipline", "neural systems"), ("trial", "ECHO-07"), ("public_scope", "selected preferences"), ("research_scope", "recorded cognitive patterns")]
        for (id, value) in fields {
            let input = app.textFields["story.puzzle.input.input.banana_wall.\(id)"].firstMatch
            for _ in 0..<16 {
                if input.exists && input.isHittable { break }
                if input.exists && input.frame.midY < app.frame.midY { app.scrollViews.firstMatch.swipeDown() }
                else { app.scrollViews.firstMatch.swipeUp() }
            }
            ready(input); input.tap(); input.typeText(value)
            let done = app.keyboards.buttons["Done"].firstMatch
            ready(done); done.tap()
        }
        openApp(app, "browser")
        tap(app, "story.resource.resource.banana_wall")
        XCTAssertEqual(app.textFields["story.puzzle.input.input.banana_wall.discipline"].value as? String, "neural systems")
        tap(app, "story.puzzle.submit.\(puzzle)")
        XCTAssertTrue(app.descendants(matching: .any)["story.resource.unlocked.resource.banana_wall"].firstMatch.waitForExistence(timeout: 8))
        tap(app, "story.resource.open.content.act3.banana_wall.scope_record")
        XCTAssertTrue(app.buttons["story.preserve.version.act3.banana_wall.scope_record.v1"].waitForExistence(timeout: 8))
        checkpoint(app, "approved Wall solved and first record opened")
        openApp(app, "browser")
        tap(app, "story.resource.resource.banana_wall")
        XCTAssertTrue(app.descendants(matching: .any)["story.resource.unlocked.resource.banana_wall"].firstMatch.waitForExistence(timeout: 8))
        XCTAssertFalse(app.buttons["story.puzzle.submit.\(puzzle)"].exists)
        for key in ["mirror.origins", "echo.correspondence", "neural.capabilities"] {
            openAndRead(app, "browser", "version.act3.\(key).v1")
            if preserveVideo { preserve(app, "version.act3.\(key).v1") }
        }
        checkpoint(app, "MIRROR ECHO and influence discovered")
        openApp(app, "browser")
        tap(app, "story.lead.version.act3.autonomy.actions.v1")
        openAndRead(app, "email", "version.act3.autonomy.maya.v1")
        tap(app, "story.connect.act3.autonomy")
        checkpoint(app, "autonomy explicitly connected")
        openApp(app, "watchVideo")
        presentation(app, "version.act3.ascension.recording.v1", preserve: preserveVideo, sections: 3)
        openAndRead(app, "browser", "version.act3.ascension.purpose.v1")
        openApp(app, "browser")
        tap(app, "story.lead.version.act3.energy.transfer.v1")
        openAndRead(app, "browser", "version.act3.energy.growth.v1")
        tap(app, "story.connect.act3.contradiction")
        checkpoint(app, "ASCENSION energy and public contradiction")
        openAndRead(app, "browser", "version.act3.daniel.contribution.v1")
        openAndRead(app, "email", "version.act3.daniel.concealment.v1")
        openApp(app, "watchVideo")
        presentation(app, "version.act3.maya.guidance.v1", preserve: preserveVideo)
        openAndRead(app, "browser", "version.act3.observer.program.v1")
        openApp(app, "browser")
        tap(app, "story.lead.version.act3.observer.session.v1")
        checkpoint(app, "Observer connection discovered Maya still missing")
        openAndRead(app, "browser", "version.act3.conclusion.resistance.v1")
        tap(app, "story.advance.act4")
        openApp(app, "browser")
        tap(app, "story.lead.version.act4.entry.v1")
        checkpoint(app, "Act 4 entry read without takeover")
        openApp(app, "browser")
        XCTAssertTrue(app.buttons["story.lead.version.act4.entry.v1"].exists)
    }

    @MainActor private func ready(_ element: XCUIElement, timeout: TimeInterval = 8) {
        let condition = NSPredicate(format: "exists == true AND hittable == true AND enabled == true")
        let result = XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: condition, object: element)], timeout: timeout)
        if result != .completed {
            print(XCUIApplication().debugDescription)
            let capture = XCTAttachment(screenshot: XCUIApplication().screenshot())
            capture.name = "Failed readiness"
            capture.lifetime = .keepAlways
            add(capture)
        }
        XCTAssertEqual(result, .completed)
    }

    @MainActor private func tapTargetIsVisible(_ element: XCUIElement, in app: XCUIApplication, id: String) -> Bool {
        guard element.exists, element.isHittable else { return false }
        let center = CGPoint(x: element.frame.midX, y: element.frame.midY)
        guard app.frame.insetBy(dx: 1, dy: 1).contains(center) else { return false }
        let scroll = app.scrollViews.containing(.button, identifier: id).firstMatch
        return !scroll.exists || scroll.frame.insetBy(dx: 2, dy: 2).contains(center)
    }

    @MainActor private func tap(_ app: XCUIApplication, _ id: String) {
        let element = app.buttons[id].firstMatch
        for _ in 0..<16 {
            if tapTargetIsVisible(element, in: app, id: id) { break }
            let scroll = app.scrollViews.firstMatch
            XCTAssertTrue(scroll.exists, "Missing scroll/control: \(id)")
            if element.exists && element.frame.midY < app.frame.midY { scroll.swipeDown() }
            else { scroll.swipeUp() }
        }
        ready(element)
        let visible = tapTargetIsVisible(element, in: app, id: id)
        if !visible { print(app.debugDescription) }
        XCTAssertTrue(visible, "Control center must be inside its scroll viewport: \(id)")
        element.tap()
        XCTAssertFalse(app.alerts.firstMatch.exists, "Unexpected failure after \(id)")
    }

    @MainActor private func openApp(_ app: XCUIApplication, _ route: String) {
        let home = app.buttons["bananaOS.home"].firstMatch
        if home.exists { ready(home); home.tap() }
        tap(app, "bananaOS.app.\(route)")
        ready(app.buttons["bananaOS.home"].firstMatch)
    }

    @MainActor private func openAndRead(_ app: XCUIApplication, _ route: String, _ version: String) {
        openApp(app, route)
        tap(app, "story.open.\(version)")
        ready(app.buttons["story.back"], timeout: 5)
    }

    @MainActor private func preserve(_ app: XCUIApplication, _ version: String) {
        tap(app, "story.preserve.\(version)")
        let button = app.buttons["story.preserve.\(version)"].firstMatch
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == false"), object: button)], timeout: 5), .completed)
    }

    @MainActor private func presentation(_ app: XCUIApplication, _ version: String, preserve shouldPreserve: Bool, sections: Int = 5) {
        tap(app, "story.open.\(version)")
        if shouldPreserve { preserve(app, version) }
        // The actual catalogue supplies three or five transcript sections.
        for _ in 0..<(sections - 1) { tap(app, "story.video.next.\(version)") }
        tap(app, "story.video.finish.\(version)")
        let finished = app.buttons["story.video.finish.\(version)"].firstMatch
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == false"), object: finished)], timeout: 5), .completed)
    }

    @MainActor private func comparison(_ app: XCUIApplication, _ evidence: String) {
        openApp(app, "evidence")
        tap(app, "story.evidence.\(evidence)")
        tap(app, "story.compare.\(evidence)")
    }

    @MainActor private func checkpoint(_ app: XCUIApplication, _ name: String) {
        let capture = XCTAttachment(screenshot: app.screenshot())
        capture.name = name
        capture.lifetime = .keepAlways
        add(capture)
        app.terminate()
        app.launch()
        ready(app.buttons["bananaOS.app.email"], timeout: 20)
        XCTAssertEqual(app.statusBars.count, 0)
    }
}
