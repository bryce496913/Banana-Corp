import Foundation

private final class EndgameFailingPersistence: StoryPersistence {
    var data: Data?
    var fail = false
    init(_ state: StoryState) throws { data = try StorySaveCodec().encode(state) }
    func read() throws -> Data? { data }
    func write(_ bytes: Data) throws {
        if fail { throw StorySaveIssue.ioFailure("neutral fixture write failure") }
        data = bytes
    }
    func archiveForReset() throws {}
}

/// Neutral state fixtures exercise contracts, not an injected production campaign or native UI.
@main struct EndgameChecks {
    @MainActor static func main() throws {
        if CommandLine.arguments.count == 3 {
            try process(mode: CommandLine.arguments[1], path: CommandLine.arguments[2])
            return
        }
        try compatibility()
        try earlyAndPartialGuards()
        try mayaAndDawn()
        try negotiationAndObserver()
        try decisionsAndReplay()
        print("PASS MODEL ONLY: endgame prerequisites, normalization, ordered resumable DAWN, explicit negotiation/Observer, confirmation/cancel/stale tokens, atomic failure, checkpoint/evidence, collection/reset/history, schema-2 compatibility")
    }
    static func read(_ key: String, into state: inout StoryState) {
        let version = key.hasPrefix("version.") ? key : EndgameContract.version(key)
        state.discoveredContentIDs.insert(version)
        state.readContentIDs.insert(version)
    }
    static func base() -> StoryState {
        var state = StoryState()
        state.currentAct = .theFinalChoice
        read("recovery", into: &state)
        return state
    }
    @MainActor static func store(_ state: StoryState) throws -> StoryProgressionStore {
        StoryProgressionStore(persistence: InMemoryStoryPersistence(data: try StorySaveCodec().encode(state)))
    }
    @MainActor static func compatibility() throws {
        var state = StoryState()
        state.discoveredContentIDs = ["content.fixture.source", "version.fixture.source.v1"]
        let proof = PreservedEvidenceRecord(id: "evidence.fixture.source.v1", sourceContentID: "content.fixture.source", sourceVersionID: "version.fixture.source.v1", capturedAt: Date(timeIntervalSince1970: 123), snapshot: Data([0, 255, 42, 10]))
        state.preservedEvidence[proof.id] = proof
        var object = try JSONSerialization.jsonObject(with: StorySaveCodec().encode(state)) as! [String: Any]
        object.removeValue(forKey: "endgame")
        let old = try JSONSerialization.data(withJSONObject: object)
        let loaded = try StorySaveCodec().decode(old)
        precondition(loaded.migratedFrom == nil && loaded.state == state && loaded.state.preservedEvidence[proof.id] == proof)
        object["schemaVersion"] = 1
        object.removeValue(forKey: "contentDelivery")
        let migrated = try StorySaveCodec().decode(JSONSerialization.data(withJSONObject: object))
        precondition(migrated.migratedFrom == 1 && migrated.state.preservedEvidence[proof.id] == proof)
        for raw in [Data("{broken".utf8), Data("{\"schemaVersion\":999}".utf8)] {
            let persistence = InMemoryStoryPersistence(data: raw)
            let broken = StoryProgressionStore(persistence: persistence)
            precondition(!broken.isWritable && broken.prepareEnding(.silence) == nil)
            precondition((try? broken.clearEndingHistory(confirmed: true).get()) == nil && persistence.data == raw)
        }
    }
    @MainActor static func earlyAndPartialGuards() throws {
        let fresh = try store(StoryState())
        for ending in EndgameEnding.allCases { precondition(!fresh.canPrepareEnding(ending)) }
        precondition((try? fresh.restoreFinalDecision().get()) == nil)
        var fixture = base()
        read("dependency_warning", into: &fixture)
        fixture.routePrerequisiteIDs = EndgameContract.components
        for component in EndgameContract.components {
            var incomplete = fixture
            incomplete.routePrerequisiteIDs.remove(component)
            let route = try store(incomplete)
            precondition(!route.canPrepareEnding(.silence))
        }
        fixture.readContentIDs.remove(EndgameContract.version("recovery"))
        let noWarning = try store(fixture)
        precondition(!noWarning.canPrepareEnding(.silence))
        fixture = base()
        read("maya.m01", into: &fixture); read("maya.m02", into: &fixture)
        fixture.accessMilestoneIDs.insert(EndgameContract.lantern)
        let missingFragment = try store(fixture)
        precondition((try? missingFragment.reconstructMaya(note1: "D", note2: "F", note3: "A", baseline: "440").get()) == nil)
        precondition(missingFragment.state == fixture)
        read("safety_cooperation", into: &fixture)
        fixture.solvedPuzzleIDs.insert(EndgameContract.mayaPuzzle)
        fixture.accessMilestoneIDs.insert(EndgameContract.mayaAccess)
        let missingConflict = try store(fixture)
        precondition((try? missingConflict.requestSafetyCooperation().get()) == nil)
        precondition(missingConflict.state.assistant.cooperation == .notEstablished)
    }
    @MainActor static func mayaAndDawn() throws {
        var fixture = base()
        for key in ["maya.m01", "maya.m02", "maya.m03", "safety_cooperation"] { read(key, into: &fixture) }
        read("version.act4.assistant.conflict.safety.v1", into: &fixture)
        read("version.act4.assistant.conflict.core.v1", into: &fixture)
        var story = try store(fixture)
        let untouched = story.state
        precondition((try? story.reconstructMaya(note1: "D", note2: "F", note3: "A", baseline: "440").get()) == nil)
        precondition(story.state == untouched)
        fixture.accessMilestoneIDs.insert(EndgameContract.lantern)
        story = try store(fixture)
        for invalid in [("E", "F", "A", "440"), ("D", "F", "A", "441"), ("D", "F", "A", "440Hz")] {
            precondition((try? story.reconstructMaya(note1: invalid.0, note2: invalid.1, note3: invalid.2, baseline: invalid.3).get()) == nil)
            precondition(story.state == fixture)
        }
        _ = try story.reconstructMaya(note1: " d\n", note2: "f", note3: " A ", baseline: " 440 hZ ").get()
        precondition(story.state.solvedPuzzleIDs.contains(EndgameContract.mayaPuzzle))
        precondition(story.state.assistant.cooperation == .notEstablished)
        _ = try story.requestSafetyCooperation().get()
        precondition(story.state.assistant.cooperation == .cooperating)
        let before = story.state
        precondition((try? story.performDawnStage(.restore).get()) == nil && story.state == before)
        for stage in DawnStage.allCases {
            _ = try story.perform(.discoverContent(stage.versionID)).get()
            _ = try story.perform(.markContentRead(stage.versionID)).get()
            _ = try story.performDawnStage(stage).get()
            let saved = story.state
            story = try store(saved)
            precondition(story.state == saved)
            _ = try story.performDawnStage(stage).get()
            precondition(story.state == saved)
        }
        precondition(story.canPrepareEnding(.firstLight))
        let token = story.prepareEnding(.firstLight)!
        _ = try story.confirmEnding(token).get()
        precondition(story.state.assistant.cooperation == .separated && story.currentEnding == .firstLight)
        _ = try story.restoreFinalDecision().get()
        precondition(story.state.assistant.cooperation == .cooperating && story.canPrepareEnding(.firstLight))
    }
    @MainActor static func negotiationAndObserver() throws {
        var fixture = base()
        for key in ["negotiation.claims", "negotiation.safeguards", "negotiation.unverified"] { read(key, into: &fixture) }
        let story = try store(fixture)
        precondition(story.canPrepareEnding(.falsePromise) && !story.canPrepareEnding(.agreement))
        precondition((try? story.challengeNegotiation(.autonomy).get()) == nil)
        _ = try story.challengeNegotiation(.dependency).get()
        for id in ["milestone.act3.echo_autonomy_established", "milestone.act3.energy_harvesting_evidence_discovered", "milestone.act3.public_restricted_contradiction_confirmed"] {
            _ = try story.perform(.recordMilestone(id)).get()
        }
        _ = try story.challengeNegotiation(.autonomy).get()
        _ = try story.challengeNegotiation(.energy).get()
        precondition((try? story.verifyAgreement().get()) == nil)
        for safeguard in NegotiationSafeguard.allCases { _ = try story.demandSafeguard(safeguard).get() }
        precondition(!story.canPrepareEnding(.agreement))
        _ = try story.verifyAgreement().get()
        precondition(story.canPrepareEnding(.agreement))
        _ = try story.perform(.recordObserverClue("observer.fixture.unrelated")).get()
        precondition((try? story.linkObserverClues().get()) == nil && !story.canPrepareEnding(.awakening))
        for key in EndgameContract.observerKeys {
            let id = EndgameContract.version("observer." + key)
            _ = try story.perform(.discoverContent(id)).get()
            _ = try story.perform(.markContentRead(id)).get()
        }
        precondition(!story.canPrepareEnding(.awakening))
        _ = try story.linkObserverClues().get()
        precondition(story.canPrepareEnding(.awakening))
    }
    @MainActor static func decisionsAndReplay() throws {
        var fixture = base()
        read("dependency_warning", into: &fixture)
        fixture.routePrerequisiteIDs = EndgameContract.components
        fixture.discoveredContentIDs.formUnion(["content.fixture.proof", "version.fixture.proof.v1"])
        let proof = PreservedEvidenceRecord(id: "evidence.fixture.proof.v1", sourceContentID: "content.fixture.proof", sourceVersionID: "version.fixture.proof.v1", capturedAt: Date(timeIntervalSince1970: 123), snapshot: Data([0, 255, 11]))
        fixture.preservedEvidence[proof.id] = proof
        let disk = try EndgameFailingPersistence(fixture)
        let story = StoryProgressionStore(persistence: disk)
        let token = story.prepareEnding(.silence)!
        precondition(story.state == fixture && story.currentEnding == nil && !story.hasFinalDecisionCheckpoint) // Cancel = discard token.
        disk.fail = true
        let beforeBytes = disk.data
        precondition((try? story.confirmEnding(token).get()) == nil && story.state == fixture && disk.data == beforeBytes)
        disk.fail = false
        _ = try story.perform(.recordMilestone("milestone.fixture.after_confirmation")).get()
        precondition((try? story.confirmEnding(token).get()) == nil) // stale reviewed investigation
        _ = try story.confirmEnding(story.prepareEnding(.silence)!).get()
        precondition(story.currentEnding == .silence && story.earnedEndings == [.silence])
        let checkpoint = story.state.endgame!.decisionCheckpoint!
        let completed = story.state
        disk.fail = true
        precondition((try? story.restoreFinalDecision().get()) == nil && story.state == completed)
        disk.fail = false
        _ = try story.restoreFinalDecision().get()
        precondition(story.currentEnding == nil && story.earnedEndings == [.silence] && story.state.preservedEvidence[proof.id] == proof)
        precondition(story.state.endgame!.decisionCheckpoint == checkpoint && !story.canPrepareEnding(.firstLight))
        _ = try story.confirmEnding(story.prepareEnding(.silence)!).get()
        precondition(story.state.endgame!.decisionCheckpoint == checkpoint)
        _ = try story.resetForNewGame().get()
        precondition(story.state.currentAct == .thePerfectProduct && story.state.preservedEvidence.isEmpty && story.earnedEndings == [.silence])
        let newGame = story.state
        _ = try story.clearEndingHistory(confirmed: false).get()
        precondition(story.state == newGame)
        _ = try story.clearEndingHistory(confirmed: true).get()
        precondition(story.earnedEndings.isEmpty)
        for ending in EndgameEnding.allCases {
            var state = base()
            read("dependency_warning", into: &state)
            read("negotiation.claims", into: &state); read("negotiation.unverified", into: &state)
            read("negotiation.safeguards", into: &state); read("safety_cooperation", into: &state)
            read("version.act4.assistant.conflict.safety.v1", into: &state)
            read("version.act4.assistant.conflict.core.v1", into: &state)
            state.routePrerequisiteIDs = EndgameContract.components
            state.accessMilestoneIDs.insert(EndgameContract.mayaAccess)
            state.solvedPuzzleIDs.insert(EndgameContract.mayaPuzzle)
            state.assistant.cooperation = .cooperating
            state.completedEventIDs.formUnion([EndgameContract.cooperation, EndgameContract.agreementVerified, EndgameContract.observerLinked])
            state.completedEventIDs.formUnion(DawnStage.allCases.map(\.eventID))
            state.completedEventIDs.formUnion(NegotiationChallenge.allCases.map(\.eventID))
            state.completedEventIDs.formUnion(NegotiationSafeguard.allCases.map(\.eventID))
            state.observerClueIDs.formUnion(EndgameContract.observerKeys.map(EndgameContract.clue))
            let route = try store(state)
            precondition(route.canPrepareEnding(ending))
            _ = try route.confirmEnding(route.prepareEnding(ending)!).get()
            precondition(route.currentEnding == ending && route.earnedEndings == [ending])
            if ending == .falsePromise { precondition(route.state.ascensionMilestone?.percentage == 100) }
        }
    }
    @MainActor static func process(mode: String, path: String) throws {
        let file = URL(fileURLWithPath: path)
        let disk = StoryFilePersistence(fileURL: file)
        if mode == "write" {
            var state = base()
            read("dependency_warning", into: &state)
            state.routePrerequisiteIDs = EndgameContract.components
            state.discoveredContentIDs.formUnion(["content.fixture.original", "version.fixture.original.v1"])
            state.preservedEvidence["evidence.fixture.original.v1"] = PreservedEvidenceRecord(id: "evidence.fixture.original.v1", sourceContentID: "content.fixture.original", sourceVersionID: "version.fixture.original.v1", capturedAt: Date(timeIntervalSince1970: 123), snapshot: Data([0, 255, 42]))
            try disk.write(StorySaveCodec().encode(state))
            let story = StoryProgressionStore(persistence: disk)
            _ = try story.confirmEnding(story.prepareEnding(.silence)!).get()
            print("PASS MODEL: completion/checkpoint/evidence written atomically")
        } else if mode == "read" {
            let story = StoryProgressionStore(persistence: disk)
            precondition(story.currentEnding == .silence && story.earnedEndings == [.silence])
            precondition(story.state.preservedEvidence["evidence.fixture.original.v1"]?.snapshot == Data([0, 255, 42]))
            _ = try story.restoreFinalDecision().get()
            precondition(story.canPrepareEnding(.silence) && !story.canPrepareEnding(.firstLight))
            print("PASS MODEL: separate process reloaded ending/checkpoint/exact evidence and restored legitimate route only")
        } else {
            let story = StoryProgressionStore(persistence: disk)
            precondition(story.currentEnding == nil && story.earnedEndings == [.silence] && story.canPrepareEnding(.silence))
            _ = try story.resetForNewGame().get()
            precondition(story.earnedEndings == [.silence] && story.state.currentAct == .thePerfectProduct)
            print("PASS MODEL: separate process reloaded restored checkpoint; new game retained collection")
        }
    }
}
