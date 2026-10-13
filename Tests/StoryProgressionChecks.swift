import Foundation
import Observation

@main
struct StoryProgressionChecks {
    @MainActor static func main() throws {
        // Separate invocations verify the real file adapter, without graceful store shutdown.
        if CommandLine.arguments.count == 3 {
            let disk = StoryFilePersistence(fileURL: URL(fileURLWithPath: CommandLine.arguments[2]))
            let store = StoryProgressionStore(persistence: disk)
            if CommandLine.arguments[1] == "write" {
                expect(store.perform(.discoverContent("content.fixture.saved")), .changed)
                expect(store.perform(.markContentRead("content.fixture.saved")), .changed)
                print("PASS: process wrote narrative facts synchronously")
                exit(0)
            }
            precondition(store.state.readContentIDs == ["content.fixture.saved"])
            precondition(store.isWritable)
            print("PASS: fresh process restored narrative facts")
            return
        }
        try checkDefaultsAndEvents()
        try checkPrerequisitesAndActs()
        try checkEvidenceAndFacts()
        try checkCorruptionAndMigrations()
        try checkDiskAndFailureAtomicity()
        print("PASS: new game, events, prerequisites, act guards, evidence, Assistant, Observer, time, corruption, migrations, reset, file persistence and failure atomicity")
    }

    @MainActor static func checkDefaultsAndEvents() throws {
        let backend = FaultPersistence()
        let store = StoryProgressionStore(persistence: backend)
        precondition(store.state == StoryState() && store.state.currentAct == .thePerfectProduct)
        precondition(store.state.ascensionMilestone == nil && store.state.lockedAppIDs.isEmpty)
        precondition(store.state.assistant.cooperation == .notEstablished && store.state.time.relativeDay == 1)
        precondition(backend.writeCount == 1)
        expect(store.perform(.markContentRead("content.fixture.unseen")), error: .contentNotDiscovered("content.fixture.unseen"))
        expect(store.perform(.discoverContent("not a stable id")), error: .invalidIdentifier("not a stable id"))
        precondition(!StoryID.isValid("content.fixture.one\n"))
        expect(store.perform(.discoverContent("content.fixture.one")), .changed)
        expect(store.perform(.discoverContent("content.fixture.one")), .unchanged)
        let writes = backend.writeCount
        expect(store.perform(.discoverContent("content.fixture.one")), .unchanged)
        precondition(backend.writeCount == writes, "Repeated facts do not rewrite the save")
        expect(store.perform(.markContentRead("content.fixture.one")), .changed)
        expect(store.perform(.markContentRead("content.fixture.one")), .unchanged)
        let before = store.state
        expect(store.completeEvent("event.fixture.bad", actions: [
            .discoverContent("content.fixture.rollback"), .markContentRead("content.fixture.missing")
        ]), error: .contentNotDiscovered("content.fixture.missing"))
        precondition(store.state == before && !store.state.completedEventIDs.contains("event.fixture.bad"))
        expect(store.completeEvent("event.fixture.once", actions: [
            .discoverContent("content.fixture.two"), .markContentRead("content.fixture.two"), .grantAccess("access.fixture.one")
        ]), .changed)
        let after = store.state
        precondition(store.satisfies(.eventCompleted("event.fixture.once")))
        let eventWrites = backend.writeCount
        expect(store.completeEvent("event.fixture.once", actions: [.discoverContent("content.fixture.shouldnotappear")]), .unchanged)
        precondition(store.state == after && backend.writeCount == eventWrites)
        let reloaded = StoryProgressionStore(persistence: backend)
        precondition(reloaded.state == store.state)
        let observations = ObservationProbe()
        withObservationTracking { _ = store.state } onChange: { observations.increment() }
        expect(store.perform(.recordObserverClue("observer.fixture.one")), .changed)
        precondition(observations.count == 1)
        expect(store.save(), .unchanged)
    }

    @MainActor static func checkPrerequisitesAndActs() throws {
        let memory = InMemoryStoryPersistence()
        let store = StoryProgressionStore(persistence: memory)
        let gate = StoryCondition.all([
            .contentRead("content.fixture.one"),
            .any([.accessGranted("access.fixture.one"), .puzzleSolved("puzzle.fixture.one")]),
            .assistantCooperation(.cooperating), .observerClueFound("observer.fixture.one")
        ])
        precondition(!store.satisfies(gate))
        expect(store.perform(.grantAccess("access.fixture.gated"), when: gate), error: .prerequisitesNotMet)
        precondition(!StoryCondition.all([]).evaluate(in: store.state))
        precondition(!StoryCondition.any([]).evaluate(in: store.state))
        precondition(!StoryCondition.any([.actReached(.thePerfectProduct), .contentRead("bad id")]).evaluate(in: store.state))
        var nested = StoryCondition.actReached(.thePerfectProduct)
        for _ in 0..<40 { nested = .all([nested]) }
        precondition(!nested.evaluate(in: store.state))
        expect(store.perform(.recordMilestone("milestone.fixture.invalidgate"), when: .all([])), error: .invalidCondition)
        for action in [StoryAction.discoverContent("content.fixture.one"), .markContentRead("content.fixture.one"),
                       .completePuzzle("puzzle.fixture.one"), .setAssistantCooperation(.cooperating),
                       .recordObserverClue("observer.fixture.one")] {
            expect(store.perform(action), .changed)
        }
        precondition(store.satisfies(gate))
        expect(store.perform(.grantAccess("access.fixture.gated"), when: gate), .changed)
        expect(store.advanceAct(to: .theConspiracy), error: .invalidActTransition)
        expect(store.advanceAct(to: .thePerfectProduct), error: .invalidActTransition)
        expect(store.advanceAct(to: .somethingIsntRight), error: .prerequisitesNotMet)

        // Fixture rules exercise machinery only, never shipped story prerequisites.
        let rules = StoryProgressionRules(actTransitions: Dictionary(uniqueKeysWithValues:
            StoryAct.allCases.dropFirst().map { act in
                (act, StoryActTransition(requiredMilestoneIDs: ["milestone.fixture.act\(act.rawValue)"],
                                         condition: .contentRead("content.fixture.one")))
            }))
        let configured = StoryProgressionStore(persistence: memory, rules: rules)
        expect(configured.advanceAct(to: .somethingIsntRight), error: .prerequisitesNotMet)
        for act in StoryAct.allCases.dropFirst() {
            expect(configured.perform(.recordMilestone("milestone.fixture.act\(act.rawValue)")), .changed)
            expect(configured.advanceAct(to: act), .changed)
            expect(configured.advanceAct(to: act), error: .invalidActTransition)
            precondition(configured.state.currentAct == act)
        }
        expect(configured.advanceAct(to: .thePerfectProduct), error: .invalidActTransition)
        precondition(StoryProgressionStore(persistence: memory).state.currentAct == .theFinalChoice)
        let checks: [(StoryCondition, Bool)] = [
            (.contentDiscovered("content.fixture.one"), true), (.contentRead("content.fixture.one"), true),
            (.puzzleSolved("puzzle.fixture.one"), true), (.accessGranted("access.fixture.gated"), true),
            (.milestoneCompleted("milestone.fixture.act5"), true), (.actReached(.theTakeover), true),
            (.contentRead("content.fixture.unseen"), false), (.milestoneCompleted("milestone.fixture.unearned"), false)
        ]
        for (condition, expected) in checks { precondition(condition.evaluate(in: configured.state) == expected) }
        let invalidRules = StoryProgressionRules(actTransitions: [
            .somethingIsntRight: StoryActTransition(requiredMilestoneIDs: [], condition: .actReached(.thePerfectProduct))
        ])
        let invalid = StoryProgressionStore(persistence: InMemoryStoryPersistence(), rules: invalidRules)
        expect(invalid.advanceAct(to: .somethingIsntRight), error: .invalidTransitionRule)
        let pending = StoryProgressionStore(persistence: InMemoryStoryPersistence(), rules: rules)
        expect(pending.perform(.recordMilestone("milestone.fixture.act2")), .changed)
        expect(pending.advanceAct(to: .somethingIsntRight), error: .prerequisitesNotMet)
        expect(pending.perform(.discoverContent("content.fixture.one")), .changed)
        expect(pending.perform(.markContentRead("content.fixture.one")), .changed)
        expect(pending.advanceAct(to: .somethingIsntRight), .changed)
    }

    @MainActor static func checkEvidenceAndFacts() throws {
        let memory = InMemoryStoryPersistence()
        let store = StoryProgressionStore(persistence: memory)
        let record = PreservedEvidenceRecord(id: "evidence.fixture.copy", sourceContentID: "content.fixture.item",
            sourceVersionID: "content.fixture.original", capturedAt: Date(timeIntervalSince1970: 1234), snapshot: Data("authored fixture".utf8))
        expect(store.perform(.preserveEvidence(record)), error: .contentNotDiscovered(record.sourceContentID))
        expect(store.perform(.discoverContent(record.sourceContentID)), .changed)
        expect(store.perform(.preserveEvidence(record)), error: .contentNotDiscovered(record.sourceVersionID))
        expect(store.perform(.discoverContent(record.sourceVersionID)), .changed)
        expect(store.perform(.preserveEvidence(record)), .changed)
        let collision = PreservedEvidenceRecord(id: record.sourceContentID, sourceContentID: record.sourceContentID,
            sourceVersionID: record.sourceVersionID, capturedAt: record.capturedAt, snapshot: record.snapshot)
        expect(store.perform(.preserveEvidence(collision)), error: .invalidRecord)
        expect(store.perform(.preserveEvidence(record)), .unchanged)
        let conflict = PreservedEvidenceRecord(id: record.id, sourceContentID: record.sourceContentID,
            sourceVersionID: record.sourceVersionID, capturedAt: record.capturedAt, snapshot: Data("changed".utf8))
        expect(store.perform(.preserveEvidence(conflict)), error: .conflictingRecord(record.id))
        let replacement = ContentReplacementRecord(id: "replacement.fixture.one", contentID: record.sourceContentID,
            originalVersionID: record.sourceVersionID, replacementVersionID: "content.fixture.replacement")
        expect(store.perform(.recordReplacement(replacement)), .changed)
        expect(store.perform(.recordReplacement(replacement)), .unchanged)
        precondition(store.state.preservedEvidence[record.id] == record)
        precondition(!store.state.readContentIDs.contains(replacement.replacementVersionID))
        expect(store.perform(.recordAssistantFact("assistant.fixture.agreement")), .changed)
        expect(store.perform(.setAssistantCooperation(.cooperating)), .changed)
        precondition(store.satisfies(.assistantCooperation(.cooperating)))
        expect(store.perform(.setAssistantCooperation(.separated)), .changed)
        precondition(!store.satisfies(.assistantCooperation(.cooperating)))
        expect(store.perform(.recordObserverClue("observer.fixture.link")), .changed)
        expect(store.perform(.recordObserverClue("observer.fixture.link")), .unchanged)
        expect(store.perform(.recordRoutePrerequisite("route.fixture.component")), .changed)
        expect(store.perform(.recordAscension(AscensionMilestone(id: "ascension.fixture.one", percentage: 87))), .changed)
        expect(store.perform(.recordAscension(AscensionMilestone(id: "ascension.fixture.invalid", percentage: 101))), error: .invalidRecord)
        expect(store.perform(.setAppAvailability(.vrExperience, unlocked: false)), .changed)
        expect(store.perform(.setAppAvailability(.settings, unlocked: false)), error: .invalidRecord)
        expect(store.perform(.recordVRAppOpened), .changed)
        expect(store.perform(.recordFirstGlitch), .changed)
        var time = StoryTimeState()
        time.relativeDay = 2
        time.fictionalTime = NarrativeTimestamp(day: 2, hour: 12, minute: 0)
        time.openingClock = .fixed(NarrativeTimestamp(day: 1, hour: 9, minute: 41))
        expect(store.perform(.configureTime(time)), .changed)
        let context = StoryTimeContext(deviceTime: Date(timeIntervalSince1970: 1_000_000), timeZoneIdentifier: "UTC", story: time)
        precondition(context.label(for: NarrativeTimestamp(day: 3, hour: 0, minute: 0)) == .tomorrow)
        precondition(context.label(for: NarrativeTimestamp(day: 2, hour: 0, minute: 0)) == .today)
        precondition(context.label(for: NarrativeTimestamp(day: 1, hour: 0, minute: 0)) == .yesterday)
        precondition(context.label(for: NarrativeTimestamp(day: 5, hour: 0, minute: 0)) == .offset(3))
        precondition(context.label(for: NarrativeTimestamp(day: 3, hour: 24, minute: 0)) == nil)
        time.relativeDay = 0
        expect(store.perform(.configureTime(time)), error: .invalidRecord)
        let restored = StoryProgressionStore(persistence: memory)
        precondition(restored.state == store.state && restored.state.preservedEvidence[record.id] == record)
        precondition(restored.state.currentAct == .thePerfectProduct, "Time, flags, 87% and cooperation cannot advance acts")
        precondition(restored.satisfies(.all([.evidencePreserved(record.id), .assistantFact("assistant.fixture.agreement"),
            .observerClueFound("observer.fixture.link"), .routePrerequisite("route.fixture.component") ])))
    }

    @MainActor static func checkCorruptionAndMigrations() throws {
        let corrupt = Data("invalid save".utf8)
        let memory = InMemoryStoryPersistence(data: corrupt)
        let blocked = StoryProgressionStore(persistence: memory)
        precondition(blocked.saveStatus == .recoveryRequired(.invalidData))
        expect(blocked.perform(.discoverContent("content.fixture.blocked")), error: .recoveryRequired(.invalidData))
        expect(blocked.advanceAct(to: .somethingIsntRight), error: .recoveryRequired(.invalidData))
        expect(blocked.save(), error: .recoveryRequired(.invalidData))
        precondition(!blocked.satisfies(.actReached(.thePerfectProduct)) && memory.data == corrupt)
        expect(blocked.resetForNewGame(), .changed)
        precondition(memory.archives == [corrupt] && blocked.state == StoryState() && blocked.isWritable)
        precondition(StoryProgressionStore(persistence: memory).state == StoryState())

        let codec = StorySaveCodec()
        var fixture = StoryState()
        fixture.discoveredContentIDs = ["content.fixture.migrated"]
        fixture.readContentIDs = fixture.discoveredContentIDs
        let valid = try codec.encode(fixture)
        let future = try versioned(valid, 99)
        let futureMemory = InMemoryStoryPersistence(data: future)
        let futureStore = StoryProgressionStore(persistence: futureMemory)
        precondition(futureStore.saveStatus == .recoveryRequired(.unsupportedSchema(99)) && futureMemory.data == future)
        expect(futureStore.resetForNewGame(), .changed)
        precondition(futureMemory.archives == [future])
        let old = try versioned(valid, 0)
        let oldMemory = InMemoryStoryPersistence(data: old)
        let noMigration = StoryProgressionStore(persistence: oldMemory)
        precondition(noMigration.saveStatus == .recoveryRequired(.migrationRequired(0)) && oldMemory.data == old)
        let migration = StorySaveCodec(migrations: [0: { try versioned($0, 1) }, 1: StorySaveCodec.migrateSchema1])
        let migrated = StoryProgressionStore(persistence: oldMemory, codec: migration)
        precondition(migrated.state == fixture && migrated.saveStatus == .migrated(from: 0))
        precondition(StoryProgressionStore(persistence: oldMemory).state == fixture)
        let badMigrationMemory = InMemoryStoryPersistence(data: old)
        let bad = StoryProgressionStore(persistence: badMigrationMemory, codec: StorySaveCodec(migrations: [0: { $0 }]))
        precondition(bad.saveStatus == .recoveryRequired(.migrationFailed) && badMigrationMemory.data == old)
        var invalid = fixture
        invalid.readContentIDs.insert("content.fixture.unseen")
        let invalidBytes = try JSONEncoder().encode(invalid)
        let malformed = StoryProgressionStore(persistence: InMemoryStoryPersistence(data: invalidBytes))
        precondition(malformed.saveStatus == .recoveryRequired(.invalidData))
        try memory.write(valid)
        expect(blocked.load(), .changed)
        precondition(blocked.state == fixture && blocked.isWritable)
        let vanishedBackend = FaultPersistence()
        let vanished = StoryProgressionStore(persistence: vanishedBackend)
        vanishedBackend.data = nil
        expect(vanished.load(), error: .recoveryRequired(.missingSave))
        precondition(vanishedBackend.data == nil, "Reloading a missing save never silently creates a new campaign")
        expect(vanished.resetForNewGame(), .changed)
    }

    @MainActor static func checkDiskAndFailureAtomicity() throws {
        let backend = FaultPersistence()
        let store = StoryProgressionStore(persistence: backend)
        expect(store.perform(.discoverContent("content.fixture.old")), .changed)
        let before = store.state
        let beforeBytes = backend.data
        backend.failWrite = true
        if case .failure(.persistenceFailed) = store.completeEvent("event.fixture.failed", actions: [.discoverContent("content.fixture.new")]) {} else { preconditionFailure() }
        precondition(store.state == before && backend.data == beforeBytes)
        if case .failure(.persistenceFailed) = store.resetForNewGame() {} else { preconditionFailure() }
        precondition(store.state == before && backend.data == beforeBytes)
        backend.failWrite = false
        expect(store.completeEvent("event.fixture.failed", actions: [.discoverContent("content.fixture.new")]), .changed)
        backend.failArchive = true
        if case .failure(.persistenceFailed) = store.resetForNewGame() {} else { preconditionFailure() }
        precondition(store.state.discoveredContentIDs.contains("content.fixture.new"))
        backend.failArchive = false
        expect(store.resetForNewGame(), .changed)
        precondition(store.state == StoryState() && !backend.archives.isEmpty)

        let migrationBackend = FaultPersistence(data: try versioned(StorySaveCodec().encode(before), 0))
        migrationBackend.failWrite = true
        let migrationBytes = migrationBackend.data
        let migrationStore = StoryProgressionStore(persistence: migrationBackend,
            codec: StorySaveCodec(migrations: [0: { try versioned($0, 1) }, 1: StorySaveCodec.migrateSchema1]))
        precondition(!migrationStore.isWritable && migrationBackend.data == migrationBytes)

        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let disk = StoryFilePersistence(fileURL: directory.appendingPathComponent("story-save.json"))
        let diskStore = StoryProgressionStore(persistence: disk)
        expect(diskStore.perform(.discoverContent("content.fixture.disk")), .changed)
        precondition(StoryProgressionStore(persistence: disk).state == diskStore.state)
        try Data("corrupted disk".utf8).write(to: disk.fileURL!)
        let corruptStore = StoryProgressionStore(persistence: disk)
        let corruptBytes = try disk.read()
        precondition(!corruptStore.isWritable && corruptBytes == Data("corrupted disk".utf8))
        expect(corruptStore.resetForNewGame(), .changed)
        let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        let archive = files.first { $0.lastPathComponent.hasPrefix("story-reset-") }!
        let archivedBytes = try Data(contentsOf: archive)
        precondition(archivedBytes == Data("corrupted disk".utf8))

        // A failing adapter and a directory at the save path cannot be mistaken for no save.
        let unavailable = StoryProgressionStore(persistence: StoryFilePersistence(fileURL: nil))
        precondition(unavailable.saveStatus == .recoveryRequired(.unavailableStorage))
        let directoryAsSave = StoryProgressionStore(persistence: StoryFilePersistence(fileURL: directory))
        precondition(!directoryAsSave.isWritable)

        let suite = "bananaCorp.storyChecks." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        var layout = HomeScreenLayout.defaultLayout
        _ = layout.move(.email, to: .grid)
        HomeScreenLayoutStore.save(layout, to: defaults)
        expect(diskStore.resetForNewGame(), .changed)
        precondition(HomeScreenLayoutStore.load(from: defaults) == layout, "Story reset never touches the home layout store")
    }

    static func versioned(_ data: Data, _ version: Int) throws -> Data {
        var json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        json["schemaVersion"] = version
        return try JSONSerialization.data(withJSONObject: json, options: [.sortedKeys])
    }

    static func expect(_ result: StoryActionResult, _ outcome: StoryActionOutcome, file: StaticString = #file, line: UInt = #line) {
        precondition(result == .success(outcome), "Expected \(outcome), got \(result)", file: file, line: line)
    }
    static func expect(_ result: StoryActionResult, error: StoryActionError, file: StaticString = #file, line: UInt = #line) {
        precondition(result == .failure(error), "Expected \(error), got \(result)", file: file, line: line)
    }
}

private final class ObservationProbe: @unchecked Sendable {
    private let lock = NSLock()
    private var value = 0
    var count: Int { lock.lock(); defer { lock.unlock() }; return value }
    func increment() { lock.lock(); defer { lock.unlock() }; value += 1 }
}

private final class FaultPersistence: StoryPersistence {
    enum Failure: Error { case write, archive }
    var data: Data?
    var archives: [Data] = []
    var writeCount = 0
    var failWrite = false
    var failArchive = false
    init(data: Data? = nil) { self.data = data }
    func read() throws -> Data? { data }
    func write(_ data: Data) throws {
        if failWrite { throw Failure.write }
        self.data = data
        writeCount += 1
    }
    func archiveForReset() throws {
        if failArchive { throw Failure.archive }
        if let data { archives.append(data) }
    }
}
