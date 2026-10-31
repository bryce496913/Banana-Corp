import Foundation

private final class ActTwoFailingPersistence: StoryPersistence {
    var data: Data?
    var failing = false
    func read() throws -> Data? { data }
    func write(_ data: Data) throws {
        if failing { throw StorySaveIssue.ioFailure("fixture write failure") }
        self.data = data
    }
    func archiveForReset() throws {}
}

@main struct ActTwoChecks {
    @MainActor static func main() throws {
        let url = URL(fileURLWithPath: CommandLine.arguments[1])
        let catalogue = StoryContentCatalogueLoader.load(fileURL: url, restrictedResourceIDs: ["resource.banana_wall", "resource.act3.mirror.origins", "resource.act3.echo.correspondence", "resource.act3.neural.capabilities", "resource.act3.assistant.mirror", "resource.act3.assistant.influence", "resource.act3.autonomy.actions", "resource.act3.autonomy.maya", "resource.act3.ascension.recording", "resource.act3.ascension.purpose", "resource.act3.energy.transfer", "resource.act3.energy.growth", "resource.act3.assistant.autonomy", "resource.act3.assistant.ascension", "resource.act3.assistant.energy", "resource.act3.daniel.contribution", "resource.act3.daniel.concealment", "resource.act3.maya.guidance", "resource.act3.observer.program", "resource.act3.observer.session", "resource.act3.conclusion.resistance", "resource.act3.assistant.daniel", "resource.act3.assistant.maya", "resource.act3.assistant.observer", "resource.act4.entry", "resource.act4.signal.packet", "resource.act4.vale.authorization", "resource.act4.vale.loss", "resource.act4.deployment.relay", "resource.act4.lantern.protocol", "resource.act4.maya.signature", "resource.act4.assistant.conflict.safety", "resource.act4.assistant.conflict.core", "resource.act4.echo.address", "resource.act5.entry"])
        let definitions = try catalogue.get()
        precondition(definitions.items.filter { $0.actAvailable.rawValue <= 2 && ($0.id.hasPrefix("content.act1.") || $0.id.hasPrefix("content.act2.")) }.count == 45)
        precondition(definitions.items.filter { $0.actAvailable == .somethingIsntRight }.count == 20)
        if CommandLine.arguments.count == 4 {
            let story = StoryProgressionStore(persistence: StoryFilePersistence(fileURL: URL(fileURLWithPath: CommandLine.arguments[3])))
            let store = StoryContentStore(progression: story, catalogue: catalogue)
            let command = CommandLine.arguments[2]
            let preserving = command.hasSuffix("-preserved")
            let phase = command.replacingOccurrences(of: "-preserved", with: "").replacingOccurrences(of: "-unpreserved", with: "")
            switch phase {
            case "entry": enter(story, store)
            case "warning":
                precondition(story.state.currentAct == .somethingIsntRight)
                if preserving { result(store.preserve(ActTwoContract.alex, versionID: ActTwoContract.originalWarning), .changed) }
                video(store, ActTwoContract.alex)
                precondition(store.currentVersion(for: ActTwoContract.alex)!.id == ActTwoContract.originalWarning)
            case "before-replacement":
                precondition(store.currentVersion(for: ActTwoContract.alex)!.id == ActTwoContract.originalWarning)
                precondition((store.preservedItem(ActTwoContract.warningEvidence) != nil) == preserving)
                precondition(!story.state.completedEventIDs.contains(ActTwoContract.alexReplaced))
            case "replacement": result(store.activateActTwoChangesAtBoundary(surface: .video), .changed)
            case "leads":
                precondition(store.currentVersion(for: ActTwoContract.alex)!.id == ActTwoContract.replacementWarning)
                video(store, ActTwoContract.alex)
                read(store, "content.act2.news.concerns")
                read(store, "content.act2.news.official")
                read(store, "content.act2.messages.daniel")
                read(store, "content.act2.email.maya")
                read(store, "content.act2.web.echo07")
                read(store, "content.act2.diagnostics.excerpt")
            case "proof":
                if preserving { result(store.recordComparison(ActTwoContract.warningEvidence), .changed) }
                else { read(store, "content.act2.news.corroboration") }
                read(store, "content.act2.assistant.edits")
                precondition(store.actTwoConfirmationAvailable && !store.actThreeHandoffAvailable)
            case "connected": result(store.confirmActTwoInvestigation(), .changed)
            case "advanced":
                precondition(store.actThreeHandoffAvailable)
                action(story.advanceAct(to: .theConspiracy), .changed)
            case "reopened":
                precondition(story.state.currentAct == .theConspiracy)
                precondition(store.currentVersion(for: ActTwoContract.alex)!.id == ActTwoContract.replacementWarning)
                precondition((store.preservedItem(ActTwoContract.warningEvidence) != nil) == preserving)
                let before = story.state
                result(store.confirmActTwoInvestigation(), .unchanged)
                result(store.activateActTwoChangesAtBoundary(), .unchanged)
                precondition(story.state == before && before.solvedPuzzleIDs.isEmpty && before.accessMilestoneIDs.isEmpty)
            default: preconditionFailure("Unknown phase")
            }
            print("PASS: Act 2 separate-process checkpoint \(command)")
            return
        }
        for preserving in [false, true] {
            let story = StoryProgressionStore(persistence: InMemoryStoryPersistence())
            let store = StoryContentStore(progression: story, catalogue: catalogue)
            precondition(store.availability(for: ActTwoContract.alex) == .locked)
            precondition(store.availableItems(for: .video).allSatisfy { !$0.id.hasPrefix("content.act2.") })
            result(store.activateActTwoChangesAtBoundary(), .unchanged)
            fail(store.read(ActTwoContract.alex, versionID: ActTwoContract.originalWarning), .contentUnavailable)
            enter(story, store)
            let entry = story.state
            for surface in StoryAppSurface.allCases { _ = store.availableItems(for: surface) }
            precondition(story.state == entry)
            precondition(store.currentVersion(for: ActTwoContract.alex)!.id == ActTwoContract.originalWarning)
            precondition(store.availability(for: "content.act2.messages.daniel") == .locked)
            precondition(store.availability(for: "content.act2.assistant.echo07") == .locked)
            if preserving { result(store.preserve(ActTwoContract.alex, versionID: ActTwoContract.originalWarning), .changed) }
            // Saving is not viewing. No change fires before the deliberate presentation completion.
            result(store.activateActTwoChangesAtBoundary(), .unchanged)
            fail(store.completePresentation(ActTwoContract.alex, versionID: ActTwoContract.originalWarning, progress: StoryPresentationProgress()), .presentationIncomplete)
            video(store, ActTwoContract.alex)
            let original = store.currentVersion(for: ActTwoContract.alex)!
            guard case .video(let payload) = original.payload else { preconditionFailure() }
            precondition(payload.mediaAssetID == nil && payload.durationSeconds == nil)
            precondition(payload.sourcePath == "/watch/alexrivera/banana-vision-preview")
            precondition(store.availability(for: "content.act2.assistant.alex_original").isAvailable)
            if preserving { result(store.recordComparison(ActTwoContract.warningEvidence), .changed) }
            let preserved = store.preservedItem(ActTwoContract.warningEvidence)?.record
            result(store.activateActTwoChangesAtBoundary(surface: .social), .unchanged)
            precondition(store.currentVersion(for: ActTwoContract.alex)!.id == original.id)
            result(store.activateActTwoChangesAtBoundary(surface: .video), .changed)
            let replaced = story.state
            result(store.activateActTwoChangesAtBoundary(surface: .video), .unchanged)
            precondition(story.state == replaced)
            precondition(store.originalVersion(for: ActTwoContract.alex) == original)
            precondition(store.currentVersion(for: ActTwoContract.alex)!.id == ActTwoContract.replacementWarning)
            precondition(store.availability(for: "content.act2.assistant.alex_original") == .removed)
            precondition(store.preservedItem(ActTwoContract.warningEvidence)?.record == preserved)
            precondition(!store.actTwoConfirmationAvailable)
            video(store, ActTwoContract.alex)
            precondition(store.availability(for: "content.act2.messages.daniel") == .locked)
            read(store, "content.act2.social.behavior") // Either social or news is a valid report route.
            read(store, "content.act2.news.official")
            precondition(store.availability(for: "content.act2.messages.daniel").isAvailable)
            precondition(store.availability(for: "content.act2.email.maya") == .locked)
            read(store, "content.act2.messages.daniel")
            precondition(store.availability(for: "content.act2.email.maya").isAvailable)
            precondition(store.availability(for: "content.act2.assistant.echo07") == .locked)
            read(store, "content.act2.email.maya")
            read(store, "content.act2.web.echo07")
            precondition(store.availability(for: "content.act2.assistant.echo07").isAvailable)
            read(store, "content.act2.diagnostics.excerpt")
            if preserving {
                let comparison = try store.comparison(for: ActTwoContract.warningEvidence).get()
                precondition(comparison.hasVisibleDifferences)
                if case .live(let current) = comparison.current { precondition(current.id == ActTwoContract.replacementWarning) } else { preconditionFailure() }
                result(store.recordComparison(ActTwoContract.warningEvidence), .changed)
                precondition(store.preservedItem(ActTwoContract.warningEvidence)?.record == preserved)
                read(store, ActTwoContract.assistantEvidenceChallenge)
                precondition(!story.state.completedMilestoneIDs.contains(ActTwoContract.independentRead))
            } else {
                precondition(store.preservedItem(ActTwoContract.warningEvidence) == nil)
                fail(store.preserve(ActTwoContract.alex, versionID: ActTwoContract.originalWarning), .contentUnavailable)
                precondition(store.availability(for: ActTwoContract.assistantEvidenceChallenge) == .locked)
                read(store, "content.act2.news.corroboration")
                read(store, "content.act2.assistant.edits")
                precondition(!story.state.completedMilestoneIDs.contains(ActTwoContract.savedCompared))
            }
            precondition(store.actTwoConfirmationAvailable && !store.actThreeHandoffAvailable)
            if case .failure(.prerequisitesNotMet) = story.advanceAct(to: .theConspiracy) {} else { preconditionFailure() }
            result(store.confirmActTwoInvestigation(), .changed)
            let confirmed = story.state
            result(store.confirmActTwoInvestigation(), .unchanged)
            precondition(story.state == confirmed && store.actThreeHandoffAvailable)
            precondition(store.availability(for: ActTwoContract.summary).isAvailable)
            action(story.advanceAct(to: .theConspiracy), .changed)
            if case .failure(.prerequisitesNotMet) = story.advanceAct(to: .theTakeover) {} else { preconditionFailure() }
            precondition(story.state.assistant.cooperation == .notEstablished)
            precondition(story.state.observerClueIDs.isEmpty && story.state.routePrerequisiteIDs.isEmpty && story.state.accessMilestoneIDs.isEmpty)
        }
        // Preserve and compare every changed format; internal read receipts never become evidence.
        let story = StoryProgressionStore(persistence: InMemoryStoryPersistence())
        let store = StoryContentStore(progression: story, catalogue: catalogue)
        enter(story, store); video(store, ActTwoContract.alex)
        let targets = ["content.act2.social.disorientation", "content.act2.social.memory", "content.act2.news.concerns", "content.act2.web.preview_notes"]
        var originals: [String: PreservedEvidenceRecord] = [:]
        for id in targets {
            let version = store.currentVersion(for: id)!
            result(store.preserve(id, versionID: version.id), .changed)
            originals[id] = store.preservedItem(version.preservedEvidenceID!)!.record
            read(store, id)
        }
        result(store.activateActTwoChangesAtBoundary(), .changed)
        for id in targets {
            let record = originals[id]!
            precondition(store.preservedItem(record.id)!.record == record)
            let comparison = try store.comparison(for: record.id).get()
            if id.hasSuffix("memory") {
                if case .unavailable(.removed) = comparison.current {} else { preconditionFailure() }
            } else { precondition(comparison.hasVisibleDifferences) }
            result(store.recordComparison(record.id), .changed)
        }
        precondition(!story.state.completedMilestoneIDs.contains(ActTwoContract.savedCompared))
        precondition(store.availability(for: "content.act2.assistant.removed").isAvailable)
        let changed = story.state; result(store.activateActTwoChangesAtBoundary(), .unchanged); precondition(changed == story.state)
        // Write failure leaves the current original and all event effects intact for retry.
        let disk = ActTwoFailingPersistence()
        let failureStory = StoryProgressionStore(persistence: disk)
        let failureStore = StoryContentStore(progression: failureStory, catalogue: catalogue)
        enter(failureStory, failureStore); video(failureStore, ActTwoContract.alex)
        let before = failureStory.state; let bytes = disk.data
        disk.failing = true
        if case .failure(.progression(.persistenceFailed)) = failureStore.activateActTwoChangesAtBoundary(surface: .video) {} else { preconditionFailure() }
        precondition(failureStory.state == before && disk.data == bytes && failureStore.currentVersion(for: ActTwoContract.alex)!.id == ActTwoContract.originalWarning)
        disk.failing = false; result(failureStore.activateActTwoChangesAtBoundary(surface: .video), .changed)
        video(failureStore, ActTwoContract.alex)
        read(failureStore, "content.act2.news.concerns"); read(failureStore, "content.act2.news.official")
        read(failureStore, "content.act2.messages.daniel"); read(failureStore, "content.act2.email.maya")
        read(failureStore, "content.act2.web.echo07"); read(failureStore, "content.act2.diagnostics.excerpt")
        read(failureStore, "content.act2.news.corroboration"); read(failureStore, "content.act2.assistant.edits")
        let beforeSynthesis = failureStory.state
        disk.failing = true
        if case .failure(.progression(.persistenceFailed)) = failureStore.confirmActTwoInvestigation() {} else { preconditionFailure() }
        precondition(failureStory.state == beforeSynthesis && !failureStore.actThreeHandoffAvailable)
        disk.failing = false; result(failureStore.confirmActTwoInvestigation(), .changed)
        disk.failing = true
        if case .failure(.persistenceFailed) = failureStory.advanceAct(to: .theConspiracy) {} else { preconditionFailure() }
        precondition(failureStory.state.currentAct == .somethingIsntRight && failureStore.actThreeHandoffAvailable)
        disk.failing = false; action(failureStory.advanceAct(to: .theConspiracy), .changed)
        // An invalid archive is retained, but cannot offer an Assistant claim of authentic saved proof.
        let damagedStory = StoryProgressionStore(persistence: InMemoryStoryPersistence())
        let damagedStore = StoryContentStore(progression: damagedStory, catalogue: catalogue)
        enter(damagedStory, damagedStore); video(damagedStore, ActTwoContract.alex)
        action(damagedStory.perform(.preserveEvidence(.init(id: ActTwoContract.warningEvidence,
            sourceContentID: ActTwoContract.alex, sourceVersionID: ActTwoContract.originalWarning,
            capturedAt: Date(), snapshot: Data("unreadable transcript record".utf8)))), .changed)
        result(damagedStore.activateActTwoChangesAtBoundary(surface: .video), .changed)
        video(damagedStore, ActTwoContract.alex)
        precondition(damagedStore.availability(for: ActTwoContract.assistantEvidenceChallenge) == .locked)
        precondition(damagedStore.preservedItem(ActTwoContract.warningEvidence) == nil && damagedStore.evidenceRecords().count == 1)
        // A missing replacement cannot partially activate the source event.
        var document = try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as! [String: Any]
        var items = document["items"] as! [[String: Any]]
        let index = items.firstIndex { ($0["id"] as? String) == ActTwoContract.alex }!
        items[index]["versions"] = (items[index]["versions"] as! [[String: Any]]).filter { ($0["version"] as? Int) == 1 }
        document["items"] = items
        let missingStory = StoryProgressionStore(persistence: InMemoryStoryPersistence())
        let missingStore = StoryContentStore(progression: missingStory, catalogue: StoryContentCatalogueLoader.load(data: try JSONSerialization.data(withJSONObject: document), restrictedResourceIDs: ["resource.banana_wall", "resource.act3.mirror.origins", "resource.act3.echo.correspondence", "resource.act3.neural.capabilities", "resource.act3.assistant.mirror", "resource.act3.assistant.influence", "resource.act3.autonomy.actions", "resource.act3.autonomy.maya", "resource.act3.ascension.recording", "resource.act3.ascension.purpose", "resource.act3.energy.transfer", "resource.act3.energy.growth", "resource.act3.assistant.autonomy", "resource.act3.assistant.ascension", "resource.act3.assistant.energy", "resource.act3.daniel.contribution", "resource.act3.daniel.concealment", "resource.act3.maya.guidance", "resource.act3.observer.program", "resource.act3.observer.session", "resource.act3.conclusion.resistance", "resource.act3.assistant.daniel", "resource.act3.assistant.maya", "resource.act3.assistant.observer", "resource.act4.entry", "resource.act4.signal.packet", "resource.act4.vale.authorization", "resource.act4.vale.loss", "resource.act4.deployment.relay", "resource.act4.lantern.protocol", "resource.act4.maya.signature", "resource.act4.assistant.conflict.safety", "resource.act4.assistant.conflict.core", "resource.act4.echo.address", "resource.act5.entry"]))
        enter(missingStory, missingStore); video(missingStore, ActTwoContract.alex)
        let beforeMissing = missingStory.state
        fail(missingStore.activateActTwoChangesAtBoundary(surface: .video), .unknownVersion(ActTwoContract.replacementWarning))
        precondition(missingStory.state == beforeMissing)
        let raw = String(decoding: try JSONEncoder().encode(definitions.items.filter { $0.actAvailable == .somethingIsntRight }), as: UTF8.self).lowercased()
        for lateReveal in ["ascension", "sentient", "harvest", "blackout", "lantern", "observer program", "neural signature", "adrian vale", "the signal"] {
            precondition(!raw.contains(lateReveal), "Premature disclosure: \(lateReveal)")
        }
        // No appearance, preservation-only fact, missing character/research action or skipped synthesis can satisfy handoff.
        for missing in [ActTwoContract.warningViewed, ActTwoContract.replacementViewed, ActTwoContract.symptomsInvestigated,
                        ActTwoContract.officialRead, ActTwoContract.danielFollowed, ActTwoContract.mayaFollowed,
                        ActTwoContract.echoRead, ActTwoContract.diagnosticsRead, "proof", "assistant", "synthesis"] {
            let gated = StoryProgressionStore(persistence: InMemoryStoryPersistence())
            enter(gated, StoryContentStore(progression: gated, catalogue: catalogue))
            var actions: [StoryAction] = []
            for id in [ActTwoContract.warningViewed, ActTwoContract.replacementViewed, ActTwoContract.symptomsInvestigated,
                       ActTwoContract.officialRead, ActTwoContract.danielFollowed, ActTwoContract.mayaFollowed,
                       ActTwoContract.echoRead, ActTwoContract.diagnosticsRead, ActTwoContract.connected] where id != missing {
                actions.append(.recordMilestone(id))
            }
            if missing != "proof" { actions.append(.recordMilestone(ActTwoContract.independentRead)) }
            if missing != "assistant" { actions.append(.recordAssistantFact(ActTwoContract.assistantQuestioned)) }
            action(gated.completeEvent(ActTwoContract.alexReplaced, actions: []), .changed)
            if missing != "synthesis" { action(gated.completeEvent(ActTwoContract.confirmationEvent, actions: []), .changed) }
            action(gated.completeEvent("event.fixture.act2.prerequisites", actions: actions), .changed)
            if case .failure(.prerequisitesNotMet) = gated.advanceAct(to: .theConspiracy) {} else { preconditionFailure("Missing gate: \(missing)") }
        }
        print("PASS: Act 2 entry, explicit original viewing, deterministic same-location replacement, authentic/no-preservation paths, multi-format edits/removal/comparison, conditional Assistant/character leads, ECHO-07, explicit synthesis and guarded Act 3")
    }
    @MainActor static func enter(_ story: StoryProgressionStore, _ store: StoryContentStore) {
        read(store, "content.act1.news.interface"); video(store, "content.act1.promo")
        read(store, FirstAnomalyContract.originalContent)
        result(store.activateFirstAnomalyAtBoundary(), .changed)
        result(store.consumeFirstAnomalyPresentation(), .changed)
        read(store, FirstAnomalyContract.warning); read(store, FirstAnomalyContract.denial); read(store, FirstAnomalyContract.trace)
        action(story.advanceAct(to: .somethingIsntRight), .changed)
    }
    @MainActor static func video(_ store: StoryContentStore, _ id: String) {
        let version = store.currentVersion(for: id)!
        guard case .video(let payload) = version.payload else { preconditionFailure() }
        var panels = StoryPresentationProgress()
        for _ in 1..<(payload.transcript?.count ?? 1) { panels.advance(count: payload.transcript!.count) }
        result(store.completePresentation(id, versionID: version.id, progress: panels), .changed)
    }
    @MainActor static func read(_ store: StoryContentStore, _ id: String) {
        result(store.read(id, versionID: store.currentVersion(for: id)!.id), .changed)
    }
    static func result(_ result: StoryContentDeliveryResult, _ expected: StoryActionOutcome) {
        guard case .success(let outcome) = result, outcome == expected else { preconditionFailure("Unexpected result: \(result)") }
    }
    static func action(_ result: StoryActionResult, _ expected: StoryActionOutcome) {
        guard case .success(let outcome) = result, outcome == expected else { preconditionFailure("Unexpected action: \(result)") }
    }
    static func fail(_ result: StoryContentDeliveryResult, _ expected: StoryContentDeliveryError) {
        guard case .failure(let error) = result, error == expected else { preconditionFailure("Unexpected failure: \(result)") }
    }
}
