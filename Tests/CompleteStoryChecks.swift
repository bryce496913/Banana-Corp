import Foundation

/// Actual-catalogue model integration. Starting saves are produced by the existing
/// four-path ActsJourneyChecks through ordinary content/actions, never seeded here.
@MainActor private final class CompleteStoryContext {
    let file: URL
    let catalogue: Result<StoryContentCatalogue, StoryContentLoadFailure>
    let resources: Result<RestrictedAccessCatalogue, RestrictedAccessFailure>
    var story: StoryProgressionStore
    var access: RestrictedAccessStore
    var content: StoryContentStore
    init(file: URL, catalogue: Result<StoryContentCatalogue, StoryContentLoadFailure>,
         resources: Result<RestrictedAccessCatalogue, RestrictedAccessFailure>) {
        self.file = file; self.catalogue = catalogue; self.resources = resources
        story = StoryProgressionStore(persistence: StoryFilePersistence(fileURL: file))
        access = RestrictedAccessStore(progression: story, catalogue: resources)
        content = StoryContentStore(progression: story, catalogue: catalogue, access: access)
        precondition(story.isWritable && content.loadDiagnostics.isEmpty)
    }
    func reopen() {
        let before = story.state
        story = StoryProgressionStore(persistence: StoryFilePersistence(fileURL: file))
        access = RestrictedAccessStore(progression: story, catalogue: resources)
        content = StoryContentStore(progression: story, catalogue: catalogue, access: access)
        precondition(story.isWritable && story.state == before && content.loadDiagnostics.isEmpty)
    }
    func read(_ key: String) throws {
        let id = key.hasPrefix("content.") ? key : "content.act5." + key
        guard let version = content.currentVersion(for: id) else {
            throw NSError(domain: "CompleteStoryChecks.unavailable", code: 1, userInfo: [NSLocalizedDescriptionKey: id])
        }
        do { _ = try content.read(id, versionID: version.id).get() }
        catch { print("READ FAILURE: \(id): \(error)"); throw error }
        precondition(story.state.readContentIDs.contains(version.id))
        precondition(story.state.completedEventIDs.contains(version.readEventID))
    }
    func preserve(_ key: String) throws {
        let id = "content.act5." + key
        guard let version = content.currentVersion(for: id) else { preconditionFailure("Missing preservable \(id)") }
        _ = try content.preserve(id, versionID: version.id).get()
    }
}

@main struct CompleteStoryChecks {
    @MainActor static func main() throws {
        let source = URL(fileURLWithPath: CommandLine.arguments[1])
        let root = URL(fileURLWithPath: CommandLine.arguments[2])
        let resources = RestrictedAccessCatalogueLoader.load(data: try Data(contentsOf: source.appendingPathComponent("RestrictedAccess.json")))
        let resourceIDs = Set(try resources.get().resources.map(\.id))
        let catalogue = StoryContentCatalogueLoader.load(fileURL: source.appendingPathComponent("StoryContent.json"), restrictedResourceIDs: resourceIDs)
        if case .failure(let failure) = catalogue { for item in failure.diagnostics { print(item) } }
        let loaded = try catalogue.get()
        precondition(EndgameEnding.allCases.allSatisfy { loaded.versionsByID[$0.versionID] != nil })
        for email in [false, true] {
            for video in [false, true] {
                let path = root.appendingPathComponent("\(email)-\(video)")
                let context = CompleteStoryContext(file: path.appendingPathComponent("story-save.json"), catalogue: catalogue, resources: resources)
                precondition(context.story.state.currentAct == .theTakeover)
                let originalProof = context.story.state.preservedEvidence
                let originalReceipts = context.story.state.contentDelivery.versionReceipts
                let before = context.story.state
                for surface in StoryAppSurface.allCases { _ = context.content.availableItems(for: surface) }
                precondition(context.story.state == before)
                precondition(context.content.availability(for: "content.act5.recovery") == .locked)
                precondition(context.story.prepareEnding(.silence) == nil)
                try actFour(context)
                try context.read("content.act5.entry")
                try context.read("recovery")
                context.reopen()
                let earnedBaseBytes = try Data(contentsOf: context.file)
                for ending in EndgameEnding.allCases {
                    // Exact byte copies of a legitimately played save; no JSON edits/seed facts.
                    let branch = path.appendingPathComponent(ending.contentKey, isDirectory: true)
                    try FileManager.default.createDirectory(at: branch, withIntermediateDirectories: true)
                    let file = branch.appendingPathComponent("story-save.json")
                    try earnedBaseBytes.write(to: file, options: .atomic)
                    let route = CompleteStoryContext(file: file, catalogue: catalogue, resources: resources)
                    precondition(route.story.currentEnding == nil && route.story.earnedEndings.isEmpty)
                    try investigate(ending, context: route)
                    for (id, record) in originalProof { precondition(route.story.state.preservedEvidence[id] == record) }
                    for (id, receipt) in originalReceipts { precondition(route.story.state.contentDelivery.versionReceipts[id] == receipt) }
                    guard let token = route.story.prepareEnding(ending) else { preconditionFailure("Natural route not eligible: \(ending)") }
                    let cancelState = route.story.state
                    precondition(route.story.currentEnding == nil && !route.story.hasFinalDecisionCheckpoint)
                    // Cancellation discards this local token and has no saved effect.
                    precondition(route.story.state == cancelState)
                    _ = try route.story.confirmEnding(token).get()
                    precondition(route.story.currentEnding == ending && route.story.earnedEndings == [ending])
                    let checkpoint = route.story.state.endgame!.decisionCheckpoint!
                    let outcomeID = "content.act5.ending." + ending.contentKey
                    precondition(route.content.currentVersion(for: outcomeID)?.id == ending.versionID)
                    precondition(route.content.currentVersion(for: outcomeID)?.title == ending.title)
                    route.reopen()
                    precondition(route.story.currentEnding == ending && route.story.earnedEndings == [ending])
                    precondition(route.story.state.endgame?.decisionCheckpoint == checkpoint)
                    _ = try route.story.restoreFinalDecision().get()
                    precondition(route.story.currentEnding == nil && route.story.canPrepareEnding(ending))
                    if ending == .silence {
                        precondition(!route.story.canPrepareEnding(.firstLight) && !route.story.canPrepareEnding(.agreement)
                                     && !route.story.canPrepareEnding(.awakening))
                    }
                    var expectedCollection: Set<EndgameEnding> = [ending]
                    if ending == .firstLight {
                        // Earn a second ending through real remaining content after restore.
                        try route.read("dependency_warning")
                        _ = try route.story.confirmEnding(route.story.prepareEnding(.silence)!).get()
                        expectedCollection.insert(.silence)
                        precondition(route.story.earnedEndings == expectedCollection)
                        precondition(route.story.state.endgame?.decisionCheckpoint == checkpoint)
                        _ = try route.story.restoreFinalDecision().get()
                        precondition(!route.story.canPrepareEnding(.silence)) // warning was earned after immutable checkpoint
                    }
                    route.reopen()
                    precondition(route.story.state.endgame?.decisionCheckpoint == checkpoint)
                    _ = try route.story.confirmEnding(route.story.prepareEnding(ending)!).get()
                    precondition(route.story.state.endgame?.decisionCheckpoint == checkpoint)
                    _ = try route.story.resetForNewGame().get()
                    route.reopen()
                    precondition(route.story.state.currentAct == .thePerfectProduct && route.story.earnedEndings == expectedCollection)
                    precondition(route.story.state.preservedEvidence.isEmpty && !route.story.hasFinalDecisionCheckpoint)
                    precondition(route.content.availability(for: outcomeID) == .locked)
                    _ = try route.story.clearEndingHistory(confirmed: false).get()
                    precondition(route.story.earnedEndings == expectedCollection)
                    _ = try route.story.clearEndingHistory(confirmed: true).get()
                    route.reopen()
                    precondition(route.story.earnedEndings.isEmpty)
                    print("PASS MODEL actual catalogue: email=\(email) video=\(video) \(ending.title), persisted checkpoint/replay/collection; prior evidence unchanged")
                }
            }
        }
        print("PASS MODEL ONLY: four natural Acts 1–3 preservation paths → actual Act 4/5 sources/actions → all five endings and reload/replay; no simulator/device/UI validation")
    }
    @MainActor private static func actFour(_ context: CompleteStoryContext) throws {
        let content = context.content
        try context.read("content.act4.entry")
        precondition((try? content.beginActFive().get()) == nil)
        try context.read("content.act4.signal.packet")
        try context.read("content.act4.vale.authorization")
        try context.read("content.act4.vale.loss")
        _ = try content.compareValeRecords().get()
        _ = try content.obtainRootAuthorization().get()
        try context.read("content.act4.deployment.relay")
        _ = try content.verifyDeploymentChannel().get()
        try context.read("content.act4.lantern.protocol")
        _ = try content.authorizeLanternSafetyAccess().get()
        context.reopen()
        try context.read("content.act4.maya.signature")
        try context.read("content.act4.assistant.conflict.safety")
        try context.read("content.act4.assistant.conflict.core")
        _ = try context.content.confirmTakeoverEvidence().get()
        precondition(context.story.state.currentAct == .theTakeover && context.story.state.ascensionMilestone?.percentage == 87)
        try context.read("content.act4.echo.address")
        _ = try context.content.beginActFive().get()
        precondition(context.story.state.currentAct == .theFinalChoice)
        context.reopen()
    }
    @MainActor private static func investigate(_ ending: EndgameEnding, context: CompleteStoryContext) throws {
        switch ending {
        case .silence:
            precondition(!context.story.canPrepareEnding(.silence))
            try context.read("dependency_warning")
        case .firstLight:
            for key in ["maya.m01", "maya.m02", "maya.m03"] { try context.read(key) }
            try context.preserve("maya.m02")
            let before = context.story.state
            precondition((try? context.story.reconstructMaya(note1: "D", note2: "A", note3: "F", baseline: "440").get()) == nil)
            precondition(context.story.state == before)
            _ = try context.story.reconstructMaya(note1: " d ", note2: "f", note3: " A\n", baseline: "440 hZ").get()
            context.reopen()
            try context.read("safety_cooperation")
            _ = try context.story.requestSafetyCooperation().get()
            let beforeOrder = context.story.state
            precondition((try? context.story.performDawnStage(.restore).get()) == nil && context.story.state == beforeOrder)
            for stage in DawnStage.allCases {
                try context.read("dawn." + stage.rawValue)
                _ = try context.story.performDawnStage(stage).get()
                context.reopen()
            }
        case .agreement:
            try context.read("negotiation.claims")
            for challenge in NegotiationChallenge.allCases { _ = try context.story.challengeNegotiation(challenge).get() }
            precondition((try? context.story.verifyAgreement().get()) == nil)
            try context.read("negotiation.safeguards")
            for safeguard in NegotiationSafeguard.allCases { _ = try context.story.demandSafeguard(safeguard).get() }
            context.reopen()
            _ = try context.story.verifyAgreement().get()
        case .falsePromise:
            try context.read("negotiation.claims")
            precondition(!context.story.canPrepareEnding(.falsePromise))
            try context.read("negotiation.unverified")
            precondition(context.story.state.ascensionMilestone?.percentage == 87)
        case .awakening:
            precondition(!context.story.canPrepareEnding(.awakening))
            for key in EndgameContract.observerKeys { try context.read("observer." + key) }
            precondition(!context.story.canPrepareEnding(.awakening))
            _ = try context.story.linkObserverClues().get()
            context.reopen()
        }
        precondition(context.story.canPrepareEnding(ending))
    }
}
