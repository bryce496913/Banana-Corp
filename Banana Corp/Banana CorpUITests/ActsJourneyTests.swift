import XCTest

/// Run on a fresh, dedicated simulator via scripts/validate-acts-journey.sh.
/// Mode belongs to the test runner only: no launch arguments or app-state bypasses.
final class ActsJourneyTests: XCTestCase {
    private struct CampaignPause: Error { let completed: Int }

    @MainActor
    func testActsOneThreePlayerJourneyBlock() throws {
        let environment = ProcessInfo.processInfo.environment
        guard (environment["BANANA_QA_BLOCK"] ?? environment["TEST_RUNNER_BANANA_QA_BLOCK"]) == "physical-checkpoint-block" else {
            throw XCTSkip("Requires an explicitly authorized physical QA block; never continues automatically")
        }
        guard let mode = environment["BANANA_QA_PATH"] ?? environment["TEST_RUNNER_BANANA_QA_PATH"],
              ["both", "email", "video", "neither"].contains(mode),
              let start = Int(environment["BANANA_QA_BLOCK_START"] ?? environment["TEST_RUNNER_BANANA_QA_BLOCK_START"] ?? ""),
              let end = Int(environment["BANANA_QA_BLOCK_END"] ?? environment["TEST_RUNNER_BANANA_QA_BLOCK_END"] ?? ""),
              0 <= start, start < end, end <= 17 else {
            XCTFail("Valid runner-only path and checkpoint bounds required"); return
        }
        continueAfterFailure = false
        let app = XCUIApplication()
        var actualEnd = start
        print("BANANA_BLOCK_BEGIN startAfter=\(start) requestedEnd=\(end) path=\(mode)")
        defer {
            app.terminate()
            XCTAssertEqual(app.state, .notRunning, "The QA app must release the daily-driver phone after each block")
            print("BANANA_BLOCK_END startAfter=\(start) actualEnd=\(actualEnd) requestedEnd=\(end)")
        }
        do {
            try runCampaign(app, mode: mode, startAfter: start, endAt: end, softPauseAfter: 420) { index, name in
                actualEnd = index
                print("BANANA_BLOCK_CHECKPOINT index=\(index) name=\(name)")
            }
        } catch let pause as CampaignPause {
            XCTAssertEqual(actualEnd, pause.completed)
            print("BANANA_BLOCK_SOFT_PAUSE completed=\(pause.completed); explicit creator continuation required")
        }
        XCTAssertGreaterThan(actualEnd, start, "A successful block must complete a canonical checkpoint")
    }

    @MainActor
    func testActsOneThreePlayerJourney() throws {
        let environment = ProcessInfo.processInfo.environment
        guard let mode = environment["BANANA_QA_PATH"] ?? environment["TEST_RUNNER_BANANA_QA_PATH"] else {
            throw XCTSkip("Use validate-acts-journey.sh to provide a fresh simulator and preservation path.")
        }
        XCTAssertTrue(["both", "email", "video", "neither"].contains(mode))
        continueAfterFailure = false
        // Full acceptance always runs all17; block metadata cannot shorten this method.
        try runCampaign(XCUIApplication(), mode: mode, startAfter: 0, endAt: 17,
                        softPauseAfter: nil, completed: { _, _ in })
    }

    @MainActor private func runCampaign(_ app: XCUIApplication, mode: String,
                                       startAfter: Int, endAt: Int, softPauseAfter: TimeInterval?,
                                       completed: (Int, String) -> Void) throws {
        let preserveEmail = mode == "both" || mode == "email"
        let preserveVideo = mode == "both" || mode == "video"
        let puzzle = "puzzle.banana_wall.review_cross_reference"
        let started = ProcessInfo.processInfo.systemUptime
        app.launch()
        ready(app.buttons["bananaOS.app.email"], timeout: 20)
        XCTAssertEqual(app.statusBars.count, 0)
        func boundary(_ index: Int, _ name: String) throws {
            // checkpoint() already saved naturally, terminated/relaunched and verified Home readiness.
            completed(index, name)
            if let budget = softPauseAfter, index < endAt,
               ProcessInfo.processInfo.systemUptime - started >= budget {
                throw CampaignPause(completed: index)
            }
        }
        if startAfter < 1 && endAt >= 1 {
            exerciseOpeningBrowserControls(app)
            openApp(app, "email")
            exerciseUnreadMailFilters(app)
            XCTAssertFalse(app.buttons["story.open.version.act1.echo_review.v1"].exists, "Fresh campaign must not have the leak unlocked")
            openApp(app, "news")
            tap(app, "story.open.version.act1.news.launch.v1")
            checkpoint(app, "launch coverage read")
            try boundary(1, "launch coverage read")
        }
        if startAfter < 2 && endAt >= 2 {
            openApp(app, "watchVideo")
            presentation(app, "version.act1.promo.v1", preserve: false)
            checkpoint(app, "before email read")
            try boundary(2, "before email read")
        }
        if startAfter < 3 && endAt >= 3 {
            openApp(app, "email")
            tap(app, "story.open.version.act1.echo_review.v1")
            tap(app, "mail.refresh")
            XCTAssertTrue(app.staticTexts["Source availability checked. The opened version is retained."].exists)
            ready(app.buttons["story.preserve.version.act1.echo_review.v1"])
            if preserveEmail { preserve(app, "version.act1.echo_review.v1") }
            checkpoint(app, "after email read before return")
            try boundary(3, "after email read before return")
        }
        if startAfter < 4 && endAt >= 4 {
            // Relaunch returns to the real Home/inbox boundary; no injected story event.
            openApp(app, "email")
            XCTAssertFalse(app.buttons["story.open.version.act1.echo_review.v1"].exists)
            // Keep the original pre-return checkpoint intact; Inbox is now an idempotent real boundary.
            tap(app, "mail.inbox")
            XCTAssertFalse(app.buttons["story.open.version.act1.echo_review.v1"].exists)
            checkpoint(app, "after removal before unknown warning")
            try boundary(4, "after removal before unknown warning")
        }
        if startAfter < 5 && endAt >= 5 {
            openApp(app, "messager")
            tap(app, "story.open.version.act1.first_anomaly.warning.v1")
            openApp(app, "aiAssistant")
            tap(app, "story.assistant.version.act1.first_anomaly.denial.v1")
            checkpoint(app, "after Assistant questioning")
            try boundary(5, "after Assistant questioning")
        }
        if startAfter < 6 && endAt >= 6 {
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
            try boundary(6, "before Alex replacement")
        }
        if startAfter < 7 && endAt >= 7 {
            openApp(app, "watchVideo")
            XCTAssertFalse(app.buttons["story.open.version.act2.alex_review.v1"].exists)
            presentation(app, "version.act2.alex_review.v2", preserve: false)
            checkpoint(app, "after Alex replacement inspected")
            try boundary(7, "after Alex replacement inspected")
        }
        if startAfter < 8 && endAt >= 8 {
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
            openApp(app, "browser")
            enterBrowserAddress(app, "/research/echo-07/summary")
            ready(app.buttons["story.back"], timeout: 5)
            XCTAssertEqual(browserAddress(app).value as? String, "/research/echo-07/summary")
            XCTAssertTrue(app.staticTexts["ECHO-07 — Neural Synchronization Trial — Preliminary Findings"].exists)
            checkpoint(app, "after ECHO-07 read")
            try boundary(8, "after ECHO-07 read")
        }
        if startAfter < 9 && endAt >= 9 {
            // Existing catalogue guidance opens the diagnostic source explicitly.
            openApp(app, "browser")
            tap(app, "story.lead.version.act2.diagnostics.excerpt.v1")
            if !preserveVideo { openAndRead(app, "news", "version.act2.news.corroboration.v1") }
            openApp(app, "aiAssistant")
            tap(app, "story.assistant.version.act2.assistant.edits.v1")
            checkpoint(app, "before explicit synthesis")
            try boundary(9, "before explicit synthesis")
        }
        if startAfter < 10 && endAt >= 10 {
            openApp(app, "browser")
            tap(app, "story.connect.act2")
            checkpoint(app, "immediately before Act 3")
            try boundary(10, "immediately before Act 3")
        }
        if startAfter < 11 && endAt >= 11 {
            openApp(app, "browser")
            tap(app, "story.advance.act3")
            tap(app, "story.resource.resource.banana_wall")
            XCTAssertTrue(app.descendants(matching: .any)["story.resource.locked.resource.banana_wall"].firstMatch.waitForExistence(timeout: 8))
            checkpoint(app, "locked Banana Wall")
            try boundary(11, "locked Banana Wall")
        }
        if startAfter < 12 && endAt >= 12 {
            openApp(app, "browser")
            tap(app, "story.resource.resource.banana_wall")
            XCTAssertTrue(app.descendants(matching: .any)["story.resource.locked.resource.banana_wall"].firstMatch.waitForExistence(timeout: 8))
            XCTAssertFalse(app.buttons["Submit"].exists)
            XCTAssertEqual(app.statusBars.count, 0)
            XCTAssertFalse(app.alerts.firstMatch.exists)
            tap(app, "story.puzzle.hint.\(puzzle)")
            for source in ["content.act2.messages.daniel", "content.act2.news.official", "content.act2.email.maya", "content.act2.web.echo07"] {
                tap(app, "story.puzzle.clue.\(source)")
                if source == "content.act2.email.maya" {
                    XCTAssertEqual(app.buttons["mail.inbox"].label, "Browser Home",
                                   "An email clue inside Browser must name its actual app root")
                }
                tap(app, "story.back")
                if source == "content.act2.email.maya" {
                    XCTAssertTrue(app.descendants(matching: .any)["story.resource.locked.resource.banana_wall"].firstMatch.exists,
                                  "Back from an email clue must return to the puzzle")
                    tap(app, "story.puzzle.clue.\(source)")
                    tap(app, "mail.inbox")
                    ready(app.buttons["story.resource.resource.banana_wall"])
                    XCTAssertFalse(app.buttons["story.back"].exists, "Browser Home must discard the nested clue stack")
                    tap(app, "story.resource.resource.banana_wall")
                    XCTAssertTrue(app.descendants(matching: .any)["story.resource.locked.resource.banana_wall"].firstMatch.exists)
                }
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
            try boundary(12, "approved Wall solved and first record opened")
        }
        if startAfter < 13 && endAt >= 13 {
            openApp(app, "browser")
            tap(app, "story.resource.resource.banana_wall")
            XCTAssertTrue(app.descendants(matching: .any)["story.resource.unlocked.resource.banana_wall"].firstMatch.waitForExistence(timeout: 8))
            XCTAssertFalse(app.buttons["story.puzzle.submit.\(puzzle)"].exists)
            for key in ["mirror.origins", "echo.correspondence", "neural.capabilities"] {
                openAndRead(app, "browser", "version.act3.\(key).v1")
                if preserveVideo { preserve(app, "version.act3.\(key).v1") }
            }
            checkpoint(app, "MIRROR ECHO and influence discovered")
            try boundary(13, "MIRROR ECHO and influence discovered")
        }
        if startAfter < 14 && endAt >= 14 {
            openApp(app, "browser")
            tap(app, "story.lead.version.act3.autonomy.actions.v1")
            openAndRead(app, "email", "version.act3.autonomy.maya.v1")
            tap(app, "story.connect.act3.autonomy")
            checkpoint(app, "autonomy explicitly connected")
            try boundary(14, "autonomy explicitly connected")
        }
        if startAfter < 15 && endAt >= 15 {
            openApp(app, "watchVideo")
            presentation(app, "version.act3.ascension.recording.v1", preserve: preserveVideo, sections: 3)
            openAndRead(app, "browser", "version.act3.ascension.purpose.v1")
            openApp(app, "browser")
            tap(app, "story.lead.version.act3.energy.transfer.v1")
            openAndRead(app, "browser", "version.act3.energy.growth.v1")
            tap(app, "story.connect.act3.contradiction")
            checkpoint(app, "ASCENSION energy and public contradiction")
            try boundary(15, "ASCENSION energy and public contradiction")
        }
        if startAfter < 16 && endAt >= 16 {
            openAndRead(app, "browser", "version.act3.daniel.contribution.v1")
            openAndRead(app, "email", "version.act3.daniel.concealment.v1")
            openApp(app, "watchVideo")
            presentation(app, "version.act3.maya.guidance.v1", preserve: preserveVideo)
            openAndRead(app, "browser", "version.act3.observer.program.v1")
            openApp(app, "browser")
            tap(app, "story.lead.version.act3.observer.session.v1")
            checkpoint(app, "Observer connection discovered Maya still missing")
            try boundary(16, "Observer connection discovered Maya still missing")
        }
        if startAfter < 17 && endAt >= 17 {
            openAndRead(app, "browser", "version.act3.conclusion.resistance.v1")
            tap(app, "story.advance.act4")
            openApp(app, "browser")
            tap(app, "story.lead.version.act4.entry.v1")
            checkpoint(app, "Act 4 entry read without takeover")
            openApp(app, "browser")
            XCTAssertTrue(app.buttons["story.lead.version.act4.signal.packet.v1"].exists, "Explicit entry read now unlocks the approved Signal investigation")
            if softPauseAfter != nil {
                // The final full-test assertions above reopen Browser; release the phone from real Home.
                let home = app.buttons["bananaOS.home"].firstMatch
                ready(home); home.tap()
                ready(app.buttons["bananaOS.app.email"])
                XCTAssertFalse(home.exists)
            }
            try boundary(17, "Act 4 entry read without takeover")
        }
    }

    @MainActor
    func testOpeningPresentationControlsAndRelaunch() throws {
        let environment = ProcessInfo.processInfo.environment
        guard (environment["BANANA_QA_PRESENTATION"] ?? environment["TEST_RUNNER_BANANA_QA_PRESENTATION"]) == "fresh-simulator" else {
            throw XCTSkip("Requires a fresh, dedicated presentation simulator.")
        }
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        ready(app.buttons["bananaOS.app.email"], timeout: 20)
        openApp(app, "news")
        tap(app, "story.open.version.act1.news.launch.v1")
        checkpoint(app, "presentation fixture launch coverage read")
        let version = "version.act1.promo.v1"
        openApp(app, "watchVideo")
        tap(app, "story.open.\(version)")
        expectSection(app, 1)
        for section in 2...5 {
            tap(app, "story.video.next.\(version)")
            expectSection(app, section)
        }
        for (control, section) in [("Previous", 4), ("Previous", 3),
                                   ("story.video.next.\(version)", 4),
                                   ("story.video.next.\(version)", 5)] {
            tap(app, control)
            expectSection(app, section)
        }
        let finish = app.buttons["story.video.finish.\(version)"].firstMatch
        ready(finish)
        tap(app, "story.video.finish.\(version)")
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == false"), object: finish)], timeout: 5), .completed)
        checkpoint(app, "presentation completed before relaunch")
        openApp(app, "watchVideo")
        tap(app, "story.open.\(version)")
        expectSection(app, 1)
        for section in 2...5 {
            tap(app, "story.video.next.\(version)")
            expectSection(app, section)
        }
        XCTAssertTrue(finish.exists)
        XCTAssertFalse(finish.isEnabled, "Viewed presentation must remain viewed after relaunch")
    }

    @MainActor private func browserAddress(_ app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "identifier == %@ AND (elementType == %d OR elementType == %d)", "browser.address", XCUIElement.ElementType.textField.rawValue, XCUIElement.ElementType.textView.rawValue)).firstMatch
    }

    @MainActor private func enterBrowserAddress(_ app: XCUIApplication, _ path: String) {
        let address = browserAddress(app)
        ready(address)
        address.tap()
        if let value = address.value as? String, value != "Address or search local pages", !value.isEmpty {
            address.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: value.count))
        }
        address.typeText(path)
        tap(app, "browser.go")
    }

    @MainActor private func exerciseOpeningBrowserControls(_ app: XCUIApplication) {
        openApp(app, "browser")
        tap(app, "browser.refresh")
        XCTAssertTrue(app.staticTexts["Local pages refreshed."].exists)
        enterBrowserAddress(app, "/banana-vision")
        ready(app.buttons["story.back"], timeout: 5)
        XCTAssertEqual(browserAddress(app).value as? String, "/banana-vision")
        tap(app, "browser.refresh")
        XCTAssertTrue(app.staticTexts["Source availability checked. The opened version is retained."].exists)
        tap(app, "story.back")
        ready(app.buttons["story.open.version.act1.product.v1"])
        tap(app, "browser.home")
        enterBrowserAddress(app, "/research/echo-07/summary")
        XCTAssertTrue(app.staticTexts["Connection unavailable. Choose an available destination below."].exists)
        XCTAssertFalse(app.buttons["story.back"].exists, "An unavailable future address must remain at the local-page root")
        XCTAssertFalse(app.buttons["story.open.version.act2.web.echo07.v1"].exists)
        tap(app, "browser.home")
        enterBrowserAddress(app, "/banana-vision")
        ready(app.buttons["story.back"], timeout: 5)
        tap(app, "browser.home")
        ready(app.buttons["story.open.version.act1.product.v1"])
        XCTAssertFalse(app.buttons["story.back"].exists)
    }

    @MainActor private func exerciseUnreadMailFilters(_ app: XCUIApplication) {
        let welcome = app.buttons["story.open.version.act1.welcome.v1"].firstMatch
        ready(welcome)
        let unread = app.switches["mail.unread"].firstMatch
        ready(unread); unread.tap()
        XCTAssertEqual(unread.value as? String, "1")
        ready(welcome)
        // SwiftUI may expose a growing input as TextView instead of TextField.
        let field = app.textFields["mail.search"].firstMatch
        let area = app.textViews["mail.search"].firstMatch
        let inputExists = NSPredicate { _, _ in field.exists || area.exists }
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: inputExists, object: app)], timeout: 8), .completed)
        let search = field.exists ? field : area
        ready(search); search.tap(); search.typeText("No matching local mail")
        XCTAssertTrue(app.staticTexts["No matches"].waitForExistence(timeout: 5))
        tap(app, "mail.inbox")
        XCTAssertEqual(unread.value as? String, "0")
        ready(welcome)
        // Filtering must not read the welcome source: it still appears under Unread only.
        unread.tap()
        XCTAssertEqual(unread.value as? String, "1")
        ready(welcome)
        tap(app, "mail.inbox")
        XCTAssertEqual(unread.value as? String, "0")
        ready(welcome)
        tap(app, "mail.refresh")
        XCTAssertTrue(app.staticTexts["Local inbox refreshed."].exists)
    }

    @MainActor private func expectSection(_ app: XCUIApplication, _ section: Int) {
        let arrived = app.staticTexts["\(section) of 5"].waitForExistence(timeout: 5)
        if !arrived {
            print(app.debugDescription)
            let capture = XCTAttachment(screenshot: app.screenshot())
            capture.name = "Failed presentation section \(section)"
            capture.lifetime = .keepAlways
            add(capture)
        }
        XCTAssertTrue(arrived, "Presentation must display section \(section)")
    }

    @MainActor private func ready(_ element: XCUIElement, timeout: TimeInterval = 8) {
        let app = XCUIApplication()
        var previous: CGRect?
        var stableObservations = 0
        let condition = NSPredicate { _, _ in
            guard element.exists, element.isHittable, element.isEnabled else {
                previous = nil; stableObservations = 0
                return false
            }
            let frame = element.frame
            guard [frame.minX, frame.minY, frame.width, frame.height].allSatisfy({ $0.isFinite }),
                  frame.width > 0, frame.height > 0,
                  app.frame.insetBy(dx: 1, dy: 1).contains(CGPoint(x: frame.midX, y: frame.midY)) else {
                previous = nil; stableObservations = 0
                return false
            }
            stableObservations = previous == frame ? stableObservations + 1 : 0
            previous = frame
            return stableObservations >= 2
        }
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
            let owner = app.scrollViews.containing(.button, identifier: id).firstMatch
            let scroll = owner.exists ? owner : app.scrollViews.firstMatch
            XCTAssertTrue(scroll.exists, "Missing scroll/control: \(id)")
            guard scroll.exists else { return }
            let viewport = scroll.frame
            if element.exists {
                let targetY = element.frame.midY
                let movingDown = targetY < viewport.midY
                let edge = movingDown ? viewport.minY : viewport.maxY
                let distance = min(viewport.height * 0.55, max(70, abs(targetY - edge) + 40))
                let startY: CGFloat = movingDown ? 0.25 : 0.75
                let endY = startY + (movingDown ? 1 : -1) * distance / viewport.height
                scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: startY))
                    .press(forDuration: 0.05, thenDragTo: scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: endY)))
            } else {
                scroll.swipeUp()
            }
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
        if sections > 1 {
            for section in 2...sections {
                tap(app, "story.video.next.\(version)")
                XCTAssertTrue(app.staticTexts["\(section) of \(sections)"].waitForExistence(timeout: 5),
                              "Continue must display transcript section \(section) for \(version)")
            }
        }
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
