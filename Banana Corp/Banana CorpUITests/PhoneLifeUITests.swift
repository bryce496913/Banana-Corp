import XCTest

/// Explicit QA-only opt-in. Uses ordinary controls and never injects a save or app launch arguments.
final class PhoneLifeUITests: XCTestCase {
    override func tearDown() async throws {
        await MainActor.run {
            let app = XCUIApplication(); app.terminate()
            XCTAssertEqual(app.state, .notRunning)
            if app.state == .notRunning { print("BANANA_PHONE_LIFE_APP_RELEASED") }
        }
        try await super.tearDown()
    }
    @MainActor private func launch() throws -> XCUIApplication {
        let env = ProcessInfo.processInfo.environment
        guard (env["TEST_RUNNER_BANANA_PHONE_LIFE"] ?? env["BANANA_PHONE_LIFE"]) == "owned-qa" else {
            throw XCTSkip("Requires the separate explicitly authorized QA installation")
        }
        continueAfterFailure = false
        let app = XCUIApplication(); app.terminate(); app.launch()
        ready(app.buttons["bananaOS.app.banking"])
        return app
    }
    @MainActor func testResetOptionalPhoneLifeThroughSettings() throws {
        let env = ProcessInfo.processInfo.environment
        guard (env["TEST_RUNNER_BANANA_PHONE_LIFE_RESET"] ?? env["BANANA_PHONE_LIFE_RESET"]) == "owned-qa" else {
            throw XCTSkip("Separate explicit QA-only reset invocation; never resets during normal coverage")
        }
        let app = try launch(); open(app, "settings")
        tap(app, "story.new_game")
        dialog(app, "Cancel")
        XCTAssertTrue(app.buttons["story.new_game"].exists, "Cancel must retain the current campaign")
        tap(app, "story.new_game")
        dialog(app, "New game")
        ready(app.buttons["bananaOS.app.email"])
        app.terminate(); app.launch()
        open(app, "banking"); expectBalance(app, 100)
        XCTAssertTrue(app.buttons["shop.purchase"].exists)
        home(app)
        print("BANANA_PHONE_LIFE_EXPLICIT_NEW_GAME_PASS")
    }
    @MainActor func testBankPurchaseAndPrizeRecovery() throws {
        let app = try launch()
        open(app, "banking")
        expectBalance(app, 100)
        for task in ["orientation", "survey", "delivery"] {
            tap(app, "bank.task." + task)
            tap(app, "bank.task.complete")
        }
        expectBalance(app, 400)
        tap(app, "shop.purchase")
        dialog(app, "Cancel")
        expectBalance(app, 400)
        tap(app, "shop.purchase")
        dialog(app, "Confirm reservation")
        let purchased = app.descendants(matching: .any).matching(identifier: "shop.purchased").firstMatch
        ready(purchased)
        XCTAssertTrue(purchased.label.contains("Reservation confirmed"), "A confirmed purchase must render its persisted reservation status")
        expectBalance(app, 100)
        home(app); app.terminate(); app.launch()
        open(app, "banking"); expectBalance(app, 100)
        XCTAssertFalse(app.buttons["shop.purchase"].exists)
        home(app); open(app, "email")
        tap(app, "story.open.version.device.mail.prize.v1")
        tap(app, "mail.prize.open")
        tap(app, "prize.share")
        dialog(app, "Share profile")
        home(app); open(app, "banking"); expectBalance(app, 50)
        home(app); open(app, "settings")
        tap(app, "settings.security"); tap(app, "security.recover")
        dialog(app, "Revoke and recover credits")
        home(app); app.terminate(); app.launch()
        open(app, "banking"); expectBalance(app, 100)
        home(app)
        print("BANANA_PHONE_LIFE_BANK_PURCHASE_PHISHING_RECOVERY_PASS")
    }
    @MainActor func testAuthoredChatAndSettingsRelaunch() throws {
        let app = try launch()
        open(app, "aiAssistant")
        send(app, channel: "assistant", text: "What is Banana Vision?")
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "AR/VR headset")).firstMatch.waitForExistence(timeout: 5))
        home(app); open(app, "messager")
        send(app, channel: "messages", text: "Hello support")
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "automated service channel")).firstMatch.waitForExistence(timeout: 5))
        home(app); open(app, "social")
        send(app, channel: "social", text: "Ready for launch")
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "acknowledges it automatically")).firstMatch.waitForExistence(timeout: 5))
        home(app); open(app, "settings")
        let haptics = app.switches["settings.haptics"].firstMatch
        scrollTo(haptics, app: app, id: "settings.haptics")
        let original = haptics.value as? String
        XCTAssertTrue(original == "0" || original == "1"); haptics.tap()
        home(app); app.terminate(); app.launch(); open(app, "settings")
        scrollTo(haptics, app: app, id: "settings.haptics"); XCTAssertEqual(haptics.value as? String, original == "1" ? "0" : "1"); haptics.tap()
        home(app); open(app, "aiAssistant")
        XCTAssertTrue(app.staticTexts["What is Banana Vision?"].firstMatch.waitForExistence(timeout: 5))
        let savedEntries = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH %@", "device.chat.assistant.entry."))
        XCTAssertGreaterThanOrEqual(savedEntries.count, 2, "The saved player question and Assistant reply must survive relaunch")
        for _ in 0..<4 { send(app, channel: "assistant", text: "Explain Banana Corp company policy") }
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "You have asked several questions about Banana Corp")).firstMatch.waitForExistence(timeout: 5))
        send(app, channel: "assistant", text: "Tell me about Banana Corp's Banana Vision headset")
        let earnedAnswer = app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@ AND label CONTAINS %@", "AR/VR headset", "You have asked several questions about Banana Corp")).firstMatch
        XCTAssertTrue(earnedAnswer.waitForExistence(timeout: 5), "Pushback must not withhold an available authored answer")
        home(app)
        print("BANANA_PHONE_LIFE_CHAT_SETTINGS_RELAUNCH_PASS")
    }
    @MainActor func testBrowserConnectionAndLeadingEdgeBack() throws {
        let app = try launch(); open(app, "browser")
        address(app, "https://banana.example/store")
        ready(app.buttons["story.back"])
        edgeBack(app)
        XCTAssertTrue(app.buttons["browser.home"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["story.back"].exists)
        address(app, "https://unavailable.example")
        ready(app.buttons["browser.recovery.home"].firstMatch)
        XCTAssertTrue(app.staticTexts["Connection unavailable. This address cannot be reached on the Banana network."].firstMatch.exists)
        edgeBack(app)
        ready(app.buttons["bananaOS.app.browser"])
        print("BANANA_PHONE_LIFE_BROWSER_EDGE_BACK_PASS")
    }
    @MainActor private func send(_ app: XCUIApplication, channel: String, text: String) {
        let id = "device.chat." + channel + ".input"
        let input = app.descendants(matching: .any).matching(NSPredicate(format: "identifier == %@ AND (elementType == %d OR elementType == %d)", id, XCUIElement.ElementType.textField.rawValue, XCUIElement.ElementType.textView.rawValue)).firstMatch
        scrollTo(input, app: app, id: id); input.tap(); input.typeText(text)
        tap(app, "device.chat." + channel + ".send")
    }
    @MainActor private func address(_ app: XCUIApplication, _ text: String) {
        let field = app.descendants(matching: .any).matching(NSPredicate(format: "identifier == %@ AND (elementType == %d OR elementType == %d)", "browser.address", XCUIElement.ElementType.textField.rawValue, XCUIElement.ElementType.textView.rawValue)).firstMatch
        ready(field); field.tap()
        if let old = field.value as? String, old != "Address or search local pages", !old.isEmpty {
            field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: old.count))
        }
        field.typeText(text); tap(app, "browser.go")
    }
    @MainActor private func expectBalance(_ app: XCUIApplication, _ value: Int) {
        let label = app.staticTexts["bank.balance"].firstMatch; scrollTo(label, app: app, id: "bank.balance")
        XCTAssertEqual(label.label, "\(value) BC")
    }
    @MainActor private func open(_ app: XCUIApplication, _ route: String) {
        ready(app.buttons["bananaOS.app.email"].firstMatch)
        tap(app, "bananaOS.app." + route)
        ready(app.buttons["bananaOS.home"])
    }
    @MainActor private func home(_ app: XCUIApplication) {
        let button = app.buttons["bananaOS.home"].firstMatch; ready(button); button.tap()
        ready(app.buttons["bananaOS.app.email"])
    }
    @MainActor private func edgeBack(_ app: XCUIApplication) {
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.02, dy: 0.45))
            .press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.7, dy: 0.45)))
    }
    @MainActor private func tap(_ app: XCUIApplication, _ id: String) {
        let item = app.buttons[id].firstMatch; scrollTo(item, app: app, id: id); item.tap()
    }
    @MainActor private func dialog(_ app: XCUIApplication, _ label: String) {
        // Native confirmation controls live outside the application's scroll owner.
        let sheet = app.sheets.firstMatch
        let button = sheet.exists ? sheet.buttons[label].firstMatch : app.buttons[label].firstMatch
        if label == "Cancel", !button.exists {
            // iOS popover confirmations expose dismissal instead of a Cancel row.
            let dismiss = app.otherElements["PopoverDismissRegion"].firstMatch
            ready(dismiss); dismiss.tap()
        } else { ready(button); button.tap() }
        if sheet.exists {
            XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: sheet)], timeout: 8), .completed)
        }
    }
    @MainActor private func finiteFrame(_ element: XCUIElement) -> CGRect? {
        guard element.exists else { return nil }
        let frame = element.frame
        guard [frame.minX, frame.minY, frame.width, frame.height].allSatisfy({ $0.isFinite }),
              frame.width > 0, frame.height > 0 else { return nil }
        return frame
    }
    @MainActor private func ready(_ element: XCUIElement, timeout: TimeInterval = 15) {
        let app = XCUIApplication()
        var previous: CGRect?
        var stableObservations = 0
        let condition = NSPredicate { _, _ in
            guard let frame = self.finiteFrame(element), element.isEnabled, element.isHittable,
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
            print(app.debugDescription)
            let capture = XCTAttachment(screenshot: app.screenshot())
            capture.name = "Phone life readiness failure"; capture.lifetime = .keepAlways; add(capture)
        }
        XCTAssertEqual(result, .completed, "Required control must be finite, stable, enabled and hittable")
    }
    @MainActor private func visible(_ element: XCUIElement, app: XCUIApplication, id: String) -> Bool {
        guard let frame = finiteFrame(element), element.isHittable else { return false }
        let center = CGPoint(x: frame.midX, y: frame.midY)
        guard app.frame.insetBy(dx: 1, dy: 1).contains(center) else { return false }
        let owner = app.scrollViews.containing(.any, identifier: id).firstMatch
        guard owner.exists else { return true }
        guard let viewport = finiteFrame(owner) else { return false }
        return viewport.insetBy(dx: 2, dy: 2).contains(center)
    }
    @MainActor private func scrollTo(_ element: XCUIElement, app: XCUIApplication, id: String) {
        for _ in 0..<16 {
            if visible(element, app: app, id: id) { break }
            let owner = app.scrollViews.containing(.any, identifier: id).firstMatch
            if !owner.exists { XCTAssertEqual(app.scrollViews.count, 1, "Missing or ambiguous scroll owner: \(id)") }
            guard owner.exists || app.scrollViews.count == 1 else { return }
            let scroll = owner.exists ? owner : app.scrollViews.element(boundBy: 0)
            guard let viewport = finiteFrame(scroll), app.frame.intersects(viewport) else {
                XCTFail("Unavailable scroll viewport: \(id)"); return
            }
            let target = finiteFrame(element)
            let movingDown = target.map { $0.midY < viewport.midY } ?? false
            let edge = movingDown ? viewport.minY : viewport.maxY
            let distance = target.map { min(viewport.height * 0.55, max(70, abs($0.midY - edge) + 40)) }
                ?? viewport.height * 0.5
            let startY: CGFloat = movingDown ? 0.25 : 0.75
            let endY = startY + (movingDown ? 1 : -1) * distance / viewport.height
            scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: startY))
                .press(forDuration: 0.05, thenDragTo: scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: endY)))
        }
        ready(element)
        XCTAssertTrue(visible(element, app: app, id: id), "Control center must lie inside its owning viewport: \(id)")
    }
}
