import Foundation

private final class FailingSlicePersistence: StoryPersistence {
    var bytes: Data?
    var fail = false
    func read() throws -> Data? { bytes }
    func write(_ data: Data) throws {
        if fail { throw StorySaveIssue.ioFailure("fixture failure") }
        bytes = data
    }
    func archiveForReset() throws {}
}

@main struct FirstAnomalyChecks {
    @MainActor static func main() throws {
        let resource = URL(fileURLWithPath: CommandLine.arguments[1])
        let catalogue = StoryContentCatalogueLoader.load(fileURL: resource, restrictedResourceIDs: ["resource.banana_wall", "resource.act3.mirror.origins", "resource.act3.echo.correspondence", "resource.act3.neural.capabilities", "resource.act3.assistant.mirror", "resource.act3.assistant.influence", "resource.act3.autonomy.actions", "resource.act3.autonomy.maya", "resource.act3.ascension.recording", "resource.act3.ascension.purpose", "resource.act3.energy.transfer", "resource.act3.energy.growth", "resource.act3.assistant.autonomy", "resource.act3.assistant.ascension", "resource.act3.assistant.energy", "resource.act3.daniel.contribution", "resource.act3.daniel.concealment", "resource.act3.maya.guidance", "resource.act3.observer.program", "resource.act3.observer.session", "resource.act3.conclusion.resistance", "resource.act3.assistant.daniel", "resource.act3.assistant.maya", "resource.act3.assistant.observer", "resource.act4.entry", "resource.act4.signal.packet", "resource.act4.vale.authorization", "resource.act4.vale.loss", "resource.act4.deployment.relay", "resource.act4.lantern.protocol", "resource.act4.maya.signature", "resource.act4.assistant.conflict.safety", "resource.act4.assistant.conflict.core", "resource.act4.echo.address", "resource.act5.entry"])
        let definitions = try catalogue.get()
        precondition(definitions.items.filter { $0.actAvailable == .thePerfectProduct && $0.id.hasPrefix("content.act1.") }.count == 25)
        precondition(definitions.itemsByID[FirstAnomalyContract.originalContent]!.versions.count == 1)
        if CommandLine.arguments.count == 4 {
            let story = StoryProgressionStore(persistence: StoryFilePersistence(fileURL: URL(fileURLWithPath: CommandLine.arguments[3])))
            let content = StoryContentStore(progression: story, catalogue: catalogue)
            let step = CommandLine.arguments[2]
            let preserved = step.hasSuffix("-preserved")
            let phase = step.replacingOccurrences(of: "-preserved", with: "").replacingOccurrences(of: "-unpreserved", with: "")
            switch phase {
            case "intro":
                prepare(content)
                precondition(content.availability(for: FirstAnomalyContract.originalContent) == .availableUnread)
            case "email":
                precondition(content.availability(for: FirstAnomalyContract.originalContent) == .availableUnread)
                read(content, FirstAnomalyContract.originalContent)
                if preserved { success(content.preserve(FirstAnomalyContract.originalContent, versionID: FirstAnomalyContract.originalVersion), .changed) }
                precondition(content.availability(for: FirstAnomalyContract.originalContent) == .read)
            case "before-change":
                precondition(content.availability(for: FirstAnomalyContract.originalContent) == .read)
                precondition(!story.state.completedEventIDs.contains(FirstAnomalyContract.removalEvent))
                precondition(content.preservedItems().count == (preserved ? 1 : 0))
            case "removed":
                precondition(content.availability(for: FirstAnomalyContract.originalContent) == .read)
                success(content.activateFirstAnomalyAtBoundary(), .changed)
                precondition(!story.state.readContentIDs.contains(FirstAnomalyContract.warningVersion))
            case "before-warning":
                precondition(content.availability(for: FirstAnomalyContract.originalContent) == .removed)
                precondition(content.unreadCount(for: .messages) == 2)
                precondition(content.preservedItems().count == (preserved ? 1 : 0))
                precondition(!story.state.readContentIDs.contains(FirstAnomalyContract.warningVersion))
                success(content.activateFirstAnomalyAtBoundary(), .unchanged)
                success(content.consumeFirstAnomalyPresentation(), .changed)
            case "questioned":
                read(content, FirstAnomalyContract.warning)
                read(content, FirstAnomalyContract.denial)
                precondition(!content.firstAnomalyHandoffAvailable)
            case "investigated":
                precondition(story.state.assistant.relationshipFacts.contains(FirstAnomalyContract.assistantQuestioned))
                precondition(story.state.currentAct == .thePerfectProduct)
                if preserved { success(content.recordComparison(FirstAnomalyContract.evidence), .changed) }
                else { read(content, FirstAnomalyContract.trace) }
                precondition(content.firstAnomalyHandoffAvailable)
            case "advanced":
                precondition(content.firstAnomalyHandoffAvailable)
                action(story.advanceAct(to: .somethingIsntRight), .changed)
            case "reopened":
                precondition(story.state.currentAct == .somethingIsntRight)
                precondition(content.availability(for: FirstAnomalyContract.originalContent) == .removed)
                precondition(content.preservedItems().count == (preserved ? 1 : 0))
                precondition(story.state.assistant.cooperation == .notEstablished)
                let before = story.state
                success(content.activateFirstAnomalyAtBoundary(), .unchanged)
                success(content.consumeFirstAnomalyPresentation(), .unchanged)
                read(content, FirstAnomalyContract.warning, .unchanged)
                read(content, FirstAnomalyContract.denial, .unchanged)
                precondition(story.state == before)
                precondition(content.pendingNotifications().isEmpty)
            default: preconditionFailure("Unknown test phase")
            }
            print("PASS: separate-process checkpoint \(step)")
            return
        }
        for preserving in [false, true] {
            let story = StoryProgressionStore(persistence: InMemoryStoryPersistence())
            let content = StoryContentStore(progression: story, catalogue: catalogue)
            fails(content.activateFirstAnomalyAtBoundary(), .progression(.prerequisitesNotMet))
            precondition(content.availability(for: FirstAnomalyContract.warning) == .hidden)
            precondition(content.availability(for: FirstAnomalyContract.denial) == .locked)
            prepare(content)
            fails(content.activateFirstAnomalyAtBoundary(), .progression(.prerequisitesNotMet))
            read(content, FirstAnomalyContract.originalContent)
            let original = content.currentVersion(for: FirstAnomalyContract.originalContent)!
            precondition(original.id == FirstAnomalyContract.originalVersion)
            let beforeBoundary = story.state
            // Querying, reading, relaunching and a save are not the content-change boundary.
            _ = content.availableItems(for: .email)
            action(story.save(), .unchanged)
            precondition(story.state == beforeBoundary)
            precondition(content.isPreservable(FirstAnomalyContract.originalContent, versionID: original.id))
            var evidenceBytes: Data?
            if preserving {
                success(content.preserve(FirstAnomalyContract.originalContent, versionID: original.id), .changed)
                evidenceBytes = content.preservedItem(FirstAnomalyContract.evidence)!.record.snapshot
                // An unchanged comparison before removal must not swallow the later investigation action.
                success(content.recordComparison(FirstAnomalyContract.evidence), .changed)
                precondition(!story.state.completedMilestoneIDs.contains(FirstAnomalyContract.investigated))
            }
            success(content.activateFirstAnomalyAtBoundary(), .changed)
            let removed = story.state
            success(content.activateFirstAnomalyAtBoundary(), .unchanged)
            precondition(story.state == removed)
            precondition(content.availability(for: FirstAnomalyContract.originalContent) == .removed)
            precondition(content.currentVersion(for: FirstAnomalyContract.originalContent) == original)
            precondition(content.originalVersion(for: FirstAnomalyContract.originalContent) == original)
            precondition(content.unreadCount(for: .messages) == 2)
            precondition(content.pendingNotifications().count == 1)
            precondition(content.preservedItems().count == (preserving ? 1 : 0))
            if preserving {
                precondition(content.preservedItem(FirstAnomalyContract.evidence)!.record.snapshot == evidenceBytes)
                if case .unavailable(.removed) = try content.comparison(for: FirstAnomalyContract.evidence).get().current {} else { preconditionFailure() }
            } else {
                fails(content.comparison(for: FirstAnomalyContract.evidence).map { _ in .changed }, .unknownEvidence(FirstAnomalyContract.evidence))
                fails(content.preserve(FirstAnomalyContract.originalContent, versionID: original.id), .contentUnavailable)
            }
            fails(content.read(FirstAnomalyContract.denial, versionID: "version.act1.first_anomaly.denial.v1"), .contentUnavailable)
            // At-most-once cosmetic delivery must not read the message, earn investigation or advance.
            success(content.consumeFirstAnomalyPresentation(), .changed)
            let delivered = story.state
            success(content.consumeFirstAnomalyPresentation(), .unchanged)
            precondition(story.state == delivered && content.pendingNotifications().isEmpty)
            precondition(!delivered.readContentIDs.contains(FirstAnomalyContract.warningVersion))
            precondition(delivered.compatibility.hasSeenFirstGlitch)
            guard case .messages(let warning) = content.currentVersion(for: FirstAnomalyContract.warning)!.payload else { preconditionFailure() }
            precondition(warning.messages.first!.text == "You found the email… Do not trust the assistant.")
            read(content, FirstAnomalyContract.warning)
            precondition(content.unreadCount(for: .messages) == 1)
            precondition(!content.firstAnomalyHandoffAvailable)
            read(content, FirstAnomalyContract.denial)
            precondition(story.state.assistant.relationshipFacts.contains(FirstAnomalyContract.assistantQuestioned))
            precondition(story.state.assistant.cooperation == .notEstablished)
            precondition(!content.firstAnomalyHandoffAvailable)
            if preserving {
                success(content.recordComparison(FirstAnomalyContract.evidence), .changed)
                precondition(content.preservedItem(FirstAnomalyContract.evidence)!.record.snapshot == evidenceBytes)
                read(content, FirstAnomalyContract.challenge)
            } else {
                precondition(content.availability(for: FirstAnomalyContract.challenge) == .locked)
                fails(content.read(FirstAnomalyContract.challenge, versionID: "version.act1.first_anomaly.challenge.v1"), .contentUnavailable)
                read(content, FirstAnomalyContract.trace)
                guard case .email(let trace) = content.currentVersion(for: FirstAnomalyContract.trace)!.payload else { preconditionFailure() }
                precondition(trace.blocks.allSatisfy { !$0.text.contains("unresolved cases") && !$0.text.contains("— D.") })
                precondition(story.state.preservedEvidence.isEmpty)
            }
            precondition(content.firstAnomalyHandoffAvailable)
            action(story.advanceAct(to: .somethingIsntRight), .changed)
            precondition(!content.firstAnomalyHandoffAvailable && story.state.currentAct == .somethingIsntRight)
            if case .failure(.prerequisitesNotMet) = story.advanceAct(to: .theConspiracy) {} else { preconditionFailure() }
            precondition(story.state.observerClueIDs.isEmpty && story.state.routePrerequisiteIDs.isEmpty)
        }
        // No mandatory optional app, trust/cooperation, elapsed-time or evidence gate.
        let rules = StoryProgressionRules.production
        precondition(Set(rules.actTransitions.keys) == [.somethingIsntRight, .theConspiracy, .theTakeover, .theFinalChoice])
        for omitted in ["normal", "promo", "original", "removal", "warning", "assistant", "investigation"] {
            let story = StoryProgressionStore(persistence: InMemoryStoryPersistence())
            var actions: [StoryAction] = [.recordMilestone(FirstAnomalyContract.suspiciousMaterial), .recordMilestone(FirstAnomalyContract.investigated), .recordAssistantFact(FirstAnomalyContract.assistantQuestioned)]
            if omitted != "normal" { actions.append(.recordMilestone("milestone.act1.news_context")) }
            if omitted != "promo" { actions.append(.recordMilestone("milestone.act1.promo_viewed")) }
            if omitted != "original" { actions += [.discoverContent(FirstAnomalyContract.originalVersion), .markContentRead(FirstAnomalyContract.originalVersion)] }
            if omitted != "warning" { actions += [.discoverContent(FirstAnomalyContract.warningVersion), .markContentRead(FirstAnomalyContract.warningVersion)] }
            if omitted == "assistant" { actions.removeAll { if case .recordAssistantFact = $0 { return true }; return false } }
            if omitted == "investigation" { actions.removeAll { if case .recordMilestone(FirstAnomalyContract.investigated) = $0 { return true }; return false } }
            if omitted != "removal" { action(story.completeEvent(FirstAnomalyContract.removalEvent, actions: []), .changed) }
            action(story.completeEvent("event.fixture.prerequisites", actions: actions), .changed)
            if case .failure(.prerequisitesNotMet) = story.advanceAct(to: .somethingIsntRight) {} else { preconditionFailure("Omitted \(omitted)") }
        }
        let disk = FailingSlicePersistence()
        let story = StoryProgressionStore(persistence: disk)
        let content = StoryContentStore(progression: story, catalogue: catalogue)
        prepare(content); read(content, FirstAnomalyContract.originalContent)
        let before = story.state; let bytes = disk.bytes
        disk.fail = true
        if case .failure(.progression(.persistenceFailed)) = content.activateFirstAnomalyAtBoundary() {} else { preconditionFailure() }
        precondition(story.state == before && disk.bytes == bytes)
        precondition(content.availability(for: FirstAnomalyContract.originalContent) == .read && content.pendingNotifications().isEmpty)
        disk.fail = false; success(content.activateFirstAnomalyAtBoundary(), .changed)
        let after = story.state; disk.fail = true
        if case .failure(.progression(.persistenceFailed)) = content.consumeFirstAnomalyPresentation() {} else { preconditionFailure() }
        precondition(story.state == after && !story.state.compatibility.hasSeenFirstGlitch)
        disk.fail = false; success(content.consumeFirstAnomalyPresentation(), .changed)
        read(content, FirstAnomalyContract.warning); read(content, FirstAnomalyContract.denial); read(content, FirstAnomalyContract.trace)
        disk.fail = true
        if case .failure(.persistenceFailed) = story.advanceAct(to: .somethingIsntRight) {} else { preconditionFailure() }
        precondition(story.state.currentAct == .thePerfectProduct && content.firstAnomalyHandoffAvailable)
        disk.fail = false; action(story.advanceAct(to: .somethingIsntRight), .changed)
        // Missing event resources cannot partially remove the mail or deliver a fabricated warning.
        let raw = try Data(contentsOf: resource)
        var document = try JSONSerialization.jsonObject(with: raw) as! [String: Any]
        var items = document["items"] as! [[String: Any]]
        items.removeAll { ($0["id"] as? String) == FirstAnomalyContract.notification }
        document["items"] = items
        let partial = StoryContentCatalogueLoader.load(data: try JSONSerialization.data(withJSONObject: document), restrictedResourceIDs: ["resource.banana_wall", "resource.act3.mirror.origins", "resource.act3.echo.correspondence", "resource.act3.neural.capabilities", "resource.act3.assistant.mirror", "resource.act3.assistant.influence", "resource.act3.autonomy.actions", "resource.act3.autonomy.maya", "resource.act3.ascension.recording", "resource.act3.ascension.purpose", "resource.act3.energy.transfer", "resource.act3.energy.growth", "resource.act3.assistant.autonomy", "resource.act3.assistant.ascension", "resource.act3.assistant.energy", "resource.act3.daniel.contribution", "resource.act3.daniel.concealment", "resource.act3.maya.guidance", "resource.act3.observer.program", "resource.act3.observer.session", "resource.act3.conclusion.resistance", "resource.act3.assistant.daniel", "resource.act3.assistant.maya", "resource.act3.assistant.observer", "resource.act4.entry", "resource.act4.signal.packet", "resource.act4.vale.authorization", "resource.act4.vale.loss", "resource.act4.deployment.relay", "resource.act4.lantern.protocol", "resource.act4.maya.signature", "resource.act4.assistant.conflict.safety", "resource.act4.assistant.conflict.core", "resource.act4.echo.address", "resource.act5.entry"])
        let partialStory = StoryProgressionStore(persistence: InMemoryStoryPersistence())
        let partialContent = StoryContentStore(progression: partialStory, catalogue: partial)
        prepare(partialContent); read(partialContent, FirstAnomalyContract.originalContent)
        let prior = partialStory.state
        fails(partialContent.activateFirstAnomalyAtBoundary(), .unknownContent(FirstAnomalyContract.notification))
        precondition(partialStory.state == prior)
        // Corrupt evidence stays retained, but must never be treated as saved proof for a challenge.
        let damagedStory = StoryProgressionStore(persistence: InMemoryStoryPersistence())
        let damagedContent = StoryContentStore(progression: damagedStory, catalogue: catalogue)
        prepare(damagedContent); read(damagedContent, FirstAnomalyContract.originalContent)
        action(damagedStory.perform(.preserveEvidence(.init(id: FirstAnomalyContract.evidence,
            sourceContentID: FirstAnomalyContract.originalContent, sourceVersionID: FirstAnomalyContract.originalVersion,
            capturedAt: Date(), snapshot: Data("unreadable snapshot".utf8)))), .changed)
        success(damagedContent.activateFirstAnomalyAtBoundary(), .changed)
        read(damagedContent, FirstAnomalyContract.warning)
        precondition(damagedContent.availability(for: FirstAnomalyContract.challenge) == .locked)
        precondition(damagedContent.preservedItem(FirstAnomalyContract.evidence) == nil && damagedContent.evidenceRecords().count == 1)
        read(damagedContent, FirstAnomalyContract.denial); read(damagedContent, FirstAnomalyContract.trace)
        precondition(damagedContent.firstAnomalyHandoffAvailable)
        #if DEBUG
        for preserving in [false, true] {
            let backend = InMemoryStoryPersistence()
            let debugStory = StoryProgressionStore(persistence: backend)
            let debugContent = StoryContentStore(progression: debugStory, catalogue: catalogue)
            action(debugStory.perform(.recordMilestone("milestone.fixture.previous")), .changed)
            action(debugStory.resetForNewGame(), .changed)
            precondition(backend.archives.count == 1)
            success(debugContent.debugReplayFirstAnomaly(preserving: preserving), .changed)
            precondition(debugContent.preservedItems().count == (preserving ? 1 : 0))
            precondition(debugContent.availability(for: FirstAnomalyContract.originalContent) == .removed)
            precondition(debugStory.state.currentAct == .thePerfectProduct)
        }
        #endif
        print("PASS: both evidence paths, exact original preservation, deterministic atomic removal/delivery, unread warning, conditional denial/challenge, explicit investigation, all handoff gates, once-only cosmetic consumption and failure recovery")
    }
    @MainActor static func prepare(_ content: StoryContentStore) {
        read(content, "content.act1.news.interface")
        let promo = content.currentVersion(for: "content.act1.promo")!
        guard case .video(let payload) = promo.payload else { preconditionFailure() }
        var panels = StoryPresentationProgress()
        for _ in 1..<(payload.transcript?.count ?? 1) { panels.advance(count: payload.transcript!.count) }
        success(content.completePresentation("content.act1.promo", versionID: promo.id, progress: panels), .changed)
    }
    @MainActor static func read(_ content: StoryContentStore, _ id: String, _ outcome: StoryActionOutcome = .changed) {
        success(content.read(id, versionID: content.currentVersion(for: id)!.id), outcome)
    }
    static func success(_ value: StoryContentDeliveryResult, _ expected: StoryActionOutcome) {
        guard case .success(let actual) = value, actual == expected else { preconditionFailure("Unexpected result: \(value)") }
    }
    static func action(_ value: StoryActionResult, _ expected: StoryActionOutcome) {
        guard case .success(let actual) = value, actual == expected else { preconditionFailure("Unexpected action: \(value)") }
    }
    static func fails(_ value: StoryContentDeliveryResult, _ expected: StoryContentDeliveryError) {
        guard case .failure(let actual) = value, actual == expected else { preconditionFailure("Unexpected error: \(value)") }
    }
}
