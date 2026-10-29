import Foundation

private final class ActFourPersistence: StoryPersistence {
    var data: Data?
    var fail = false
    init(_ state: StoryState) throws { data = try StorySaveCodec().encode(state) }
    func read() throws -> Data? { data }
    func write(_ bytes: Data) throws {
        if fail { throw StorySaveIssue.ioFailure("Act 4 injected write failure") }
        data = bytes
    }
    func archiveForReset() throws {}
}

/// Seeded model integration of approved Act 4; this is not a native campaign bypass.
@main struct ActFourChecks {
    @MainActor static func main() throws {
        let source = URL(fileURLWithPath: CommandLine.arguments[1])
        let resources = try RestrictedAccessCatalogueLoader.load(data: Data(contentsOf: source.appendingPathComponent("RestrictedAccess.json"))).get()
        let catalogue = try StoryContentCatalogueLoader.load(fileURL: source.appendingPathComponent("StoryContent.json"),
            restrictedResourceIDs: Set(resources.resources.map(\.id))).get()
        if CommandLine.arguments.count > 2, CommandLine.arguments[2] == "reopen" {
            let disk = StoryFilePersistence(fileURL: URL(fileURLWithPath: CommandLine.arguments[3]))
            let story = StoryProgressionStore(persistence: disk)
            let access = RestrictedAccessStore(progression: story, catalogue: .success(resources))
            let content = StoryContentStore(progression: story, catalogue: .success(catalogue), access: access)
            precondition(story.isWritable && story.state.currentAct == .theFinalChoice)
            precondition(story.state.ascensionMilestone == .init(id: ActFourContract.ascension, percentage: 87))
            precondition(story.state.routePrerequisiteIDs == [ActFourContract.rootAuthorization, ActFourContract.deploymentChannel, ActFourContract.neuralSignature])
            let record = try preservedOriginal(catalogue)
            precondition(content.preservedItem(record.id)?.record.snapshot == record.snapshot)
            let before = story.state
            try expect(content.beginActFive(), .unchanged)
            precondition(story.state == before)
            precondition(content.actFiveEntry != nil)
            print("PASS: Act 4 component/87/entry and exact original evidence reopen in separate process")
            return
        }
        let orders = [[0, 1, 2], [0, 2, 1], [1, 0, 2], [1, 2, 0], [2, 0, 1], [2, 1, 0]]
        for order in orders {
            let original = try preservedOriginal(catalogue)
            var seed = StoryState()
            seed.currentAct = .theTakeover
            seed.accessMilestoneIDs = ["access.banana_wall.breached"]
            seed.solvedPuzzleIDs = ["puzzle.banana_wall.review_cross_reference"]
            seed.completedMilestoneIDs = ActThreeHandoffContract.requiredMilestones
            seed.completedEventIDs = ActThreeHandoffContract.requiredEvents
            seed.preservedEvidence = [original.id: original]
            seed.discoveredContentIDs = [original.sourceContentID, original.sourceVersionID]
            seed.readContentIDs = [original.sourceContentID, original.sourceVersionID]
            seed.contentDelivery.versionReceipts = [original.sourceVersionID: .init(contentID: original.sourceContentID, versionID: original.sourceVersionID, snapshot: original.snapshot)]
            let persistence = try ActFourPersistence(seed)
            var story = StoryProgressionStore(persistence: persistence)
            var access = RestrictedAccessStore(progression: story, catalogue: .success(resources))
            var content = StoryContentStore(progression: story, catalogue: .success(catalogue), access: access)
            func reload() {
                let before = story.state
                story = StoryProgressionStore(persistence: persistence)
                access = RestrictedAccessStore(progression: story, catalogue: .success(resources))
                content = StoryContentStore(progression: story, catalogue: .success(catalogue), access: access)
                precondition(story.isWritable && story.state == before)
                precondition(content.preservedItem(original.id)?.record.snapshot == original.snapshot)
            }
            func read(_ id: String) throws {
                let version = try requiredVersion(content, id)
                _ = try content.read(id, versionID: version.id).get()
            }
            func explicit(_ action: () -> StoryContentDeliveryResult) throws {
                let before = story.state
                let bytes = persistence.data
                persistence.fail = true
                if case .success = action() { preconditionFailure("Failed save must not grant Act 4 effects") }
                precondition(story.state == before && persistence.data == bytes)
                persistence.fail = false
                try expect(action(), .changed)
                let completed = story.state
                try expect(action(), .unchanged)
                precondition(story.state == completed)
                reload()
            }
            precondition(story.isWritable, "Act4 seed invalid")
            precondition(access.diagnostics.isEmpty, String(describing: access.diagnostics))
            let initial = story.state
            precondition(content.actFourSuggestedLead?.id == "content.act4.entry")
            precondition(content.currentVersion(for: ActFourContract.signal) == nil)
            precondition(!content.valeComparisonAvailable && !content.rootAuthorizationAvailable && !content.deploymentVerificationAvailable && !content.lanternAuthorizationAvailable)
            if case .success = content.confirmTakeoverEvidence() { preconditionFailure("No appearance-driven takeover") }
            if case .success = content.beginActFive() { preconditionFailure("No premature Act 5") }
            precondition(story.state == initial)
            try read("content.act4.entry")
            try read(ActFourContract.signal)
            precondition(story.state.routePrerequisiteIDs.isEmpty && story.state.ascensionMilestone == nil)
            for investigation in order {
                switch investigation {
                case 0:
                    try read("content.act4.vale.authorization")
                    precondition(!content.valeComparisonAvailable)
                    try read("content.act4.vale.loss")
                    precondition(content.valeComparisonAvailable && !content.rootAuthorizationAvailable)
                    try explicit { content.compareValeRecords() }
                    precondition(content.rootAuthorizationAvailable)
                    try explicit { content.obtainRootAuthorization() }
                case 1:
                    try read("content.act4.deployment.relay")
                    precondition(!story.state.routePrerequisiteIDs.contains(ActFourContract.deploymentChannel))
                    try explicit { content.verifyDeploymentChannel() }
                default:
                    precondition(content.currentVersion(for: "content.act4.maya.signature") == nil)
                    precondition(content.currentVersion(for: "content.act4.assistant.conflict.safety") == nil)
                    try read("content.act4.lantern.protocol")
                    precondition(!story.state.accessMilestoneIDs.contains(ActFourContract.lanternAccess))
                    try explicit { content.authorizeLanternSafetyAccess() }
                    precondition(content.currentVersion(for: "content.act4.maya.signature") != nil)
                    precondition(content.currentVersion(for: "content.act4.assistant.conflict.core") == nil)
                }
                precondition(story.state.ascensionMilestone == nil && story.state.currentAct == .theTakeover)
                precondition(!content.takeoverConfirmationAvailable)
            }
            try read("content.act4.maya.signature")
            try read("content.act4.assistant.conflict.safety")
            precondition(!content.takeoverConfirmationAvailable)
            try read("content.act4.assistant.conflict.core")
            precondition(story.state.assistant.cooperation == .notEstablished)
            precondition(story.state.observerClueIDs.isEmpty && story.state.ascensionMilestone == nil)
            precondition(content.takeoverConfirmationAvailable)
            try explicit { content.confirmTakeoverEvidence() }
            precondition(story.state.ascensionMilestone == .init(id: ActFourContract.ascension, percentage: 87))
            precondition(story.state.currentAct == .theTakeover && !content.actFiveHandoffAvailable)
            try read(ActFourContract.echoAddress)
            precondition(content.actFiveHandoffAvailable && story.state.currentAct == .theTakeover)
            let beforeHandoff = story.state
            persistence.fail = true
            if case .success = content.beginActFive() { preconditionFailure("Failed handoff must not advance") }
            precondition(story.state == beforeHandoff)
            persistence.fail = false
            try expect(content.beginActFive(), .changed)
            reload()
            precondition(story.state.currentAct == .theFinalChoice && content.actFiveEntry != nil)
            precondition(story.state.assistant.cooperation == .notEstablished && story.state.observerClueIDs.isEmpty)
            precondition(content.preservedItem(original.id)?.record.snapshot == original.snapshot)
            if CommandLine.arguments.count > 2, CommandLine.arguments[2] == "write", order == orders[0] {
                let file = StoryFilePersistence(fileURL: URL(fileURLWithPath: CommandLine.arguments[3]))
                try file.write(StorySaveCodec().encode(story.state))
            }
        }
        print("PASS: six Act 4 investigation orders, explicit components/conflict/87/Act 5, failed saves, idempotence and immutable evidence")
    }

    private static func expect(_ result: StoryContentDeliveryResult, _ outcome: StoryActionOutcome) throws {
        let actual = try result.get()
        precondition(actual == outcome)
    }

    @MainActor private static func requiredVersion(_ content: StoryContentStore, _ id: String) throws -> StoryContentVersion {
        guard let version = content.currentVersion(for: id) else { throw StorySaveIssue.ioFailure("Missing authorized Act 4 source: " + id) }
        return version
    }
    private static func preservedOriginal(_ catalogue: StoryContentCatalogue) throws -> PreservedEvidenceRecord {
        let id = FirstAnomalyContract.originalContent
        guard let item = catalogue.itemsByID[id], let version = catalogue.versionsByID[FirstAnomalyContract.originalVersion] else { throw StorySaveIssue.invalidData }
        let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys]
        return .init(id: FirstAnomalyContract.evidence, sourceContentID: id, sourceVersionID: version.id,
                     capturedAt: Date(timeIntervalSinceReferenceDate: 0),
                     snapshot: try encoder.encode(StoryContentSnapshot(schemaVersion: 1, contentID: id, appSurface: item.appSurface, version: version)))
    }
}
