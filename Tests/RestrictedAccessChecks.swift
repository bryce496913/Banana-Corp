import Foundation

private final class AccessFailingPersistence: StoryPersistence {
    var data: Data?
    var fail = false
    func read() throws -> Data? { data }
    func write(_ data: Data) throws { if fail { throw StorySaveIssue.ioFailure("fixture failure") }; self.data = data }
    func archiveForReset() throws {}
}

@main struct RestrictedAccessChecks {
    @MainActor static func main() throws {
        let fixtureData = try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1]))
        let contentData = try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[2]))
        let productionData = try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[3]))
        let fixture = RestrictedAccessCatalogueLoader.loadDevelopmentFixture(data: fixtureData)
        let catalogue = try fixture.get()
        let contentCatalogue = StoryContentCatalogueLoader.load(data: contentData, restrictedResourceIDs: Set(catalogue.resources.map(\.id)))
        let puzzleID = "puzzle.fixture.research", resourceID = "resource.fixture.research", memo = "content.fixture.protected_memo"
        if CommandLine.arguments.count == 6 {
            let story = StoryProgressionStore(persistence: StoryFilePersistence(fileURL: URL(fileURLWithPath: CommandLine.arguments[5])))
            let access = RestrictedAccessStore(progression: story, catalogue: fixture)
            let content = StoryContentStore(progression: story, catalogue: contentCatalogue, access: access)
            if CommandLine.arguments[4] == "write" {
                readHint(content)
                precondition(access.submit(puzzleID, fields: ["input.fixture.token":" open "]) == .completed)
                precondition(access.resourceState(resourceID) == .unlocked)
                success(content.read(memo, versionID: "version.fixture.protected_memo.v1"))
                success(content.preserve(memo, versionID: "version.fixture.protected_memo.v1"))
                precondition(access.submit("puzzle.fixture.optional", fields: ["input.fixture.choice":"Inspect"]) == .completed)
            } else {
                precondition(access.resourceState(resourceID) == .unlocked && access.puzzleAvailability(puzzleID) == .completed)
                precondition(content.preservedItem("evidence.fixture.protected_memo.v1") != nil)
                precondition(story.state.observerClueIDs == ["observer.fixture.optional"])
                let before = story.state
                precondition(access.submit(puzzleID, fields: [:]) == .alreadyCompleted)
                precondition(story.state == before && story.state.currentAct == .thePerfectProduct)
            }
            print("PASS: protected access, puzzle completion, independent optional clue and exact evidence \(CommandLine.arguments[4]) in separate process")
            return
        }
        if case .failure = RestrictedAccessCatalogueLoader.load(data: fixtureData) {} else { preconditionFailure("Production loader accepted fixture") }
        let production = try RestrictedAccessCatalogueLoader.load(data: productionData).get()
        precondition(production.puzzlesByID["puzzle.banana_wall.pending_design"]?.rule.kind == .awaitingApproval)
        precondition(production.puzzlesByID["puzzle.banana_wall.review_cross_reference"]?.rule.kind == .exactFields)
        var campaign = StoryState(); campaign.currentAct = .theConspiracy
        campaign.completedMilestoneIDs.insert(ActTwoContract.connected)
        let campaignStory = StoryProgressionStore(persistence: InMemoryStoryPersistence(data: try StorySaveCodec().encode(campaign)))
        let productionAccess = RestrictedAccessStore(progression: campaignStory, catalogue: .success(production))
        let sources = URL(fileURLWithPath: CommandLine.arguments[3]).deletingLastPathComponent().appendingPathComponent("StoryContent.json")
        _ = StoryContentStore(progression: campaignStory, catalogue: StoryContentCatalogueLoader.load(fileURL: sources, restrictedResourceIDs: Set(production.resources.map(\.id))), access: productionAccess)
        precondition(productionAccess.resourceState("resource.banana_wall") == .locked)
        let before = campaignStory.state
        for fields in [[:], ["input.fixture.token":"OPEN"], ["password":"anything"]] {
            precondition(productionAccess.submit("puzzle.banana_wall.pending_design", fields: fields) == .rejected(.awaitingApproval))
        }
        precondition(campaignStory.state == before)
        // Even raw injected historical facts cannot complete an unapproved production design.
        action(campaignStory.completeEvent("event.puzzle.banana_wall.pending_design", actions: [.completePuzzle("puzzle.banana_wall.pending_design"), .grantAccess("access.banana_wall.breached")]))
        precondition(productionAccess.resourceState("resource.banana_wall") == .locked)
        let story = StoryProgressionStore(persistence: InMemoryStoryPersistence())
        let access = RestrictedAccessStore(progression: story, catalogue: fixture)
        precondition(access.resourceState(resourceID) == .unresolved, "Cross-catalogue references must be bound first")
        let content = StoryContentStore(progression: story, catalogue: contentCatalogue, access: access)
        precondition(access.resourceState(resourceID) == .locked)
        precondition(content.currentVersion(for: memo) == nil && content.originalVersion(for: memo) == nil)
        precondition(content.availableItems(for: .web).map(\.id) == ["content.fixture.access_hint"])
        precondition(content.unreadCount(for: .web) == 1)
        failure(content.read(memo, versionID: "version.fixture.protected_memo.v1"))
        failure(content.preserve(memo, versionID: "version.fixture.protected_memo.v1"))
        precondition(access.submit(puzzleID, fields: ["input.fixture.token":"OPEN"]) == .rejected(.inaccessible))
        readHint(content)
        precondition(access.puzzleAvailability(puzzleID) == .ready)
        let ready = story.state
        precondition(access.submit(puzzleID, fields: [:]) == .rejected(.invalidFields))
        precondition(access.submit(puzzleID, fields: ["input.fixture.token":"wrong"]) == .rejected(.incorrectAnswer))
        precondition(access.submit(puzzleID, fields: ["input.fixture.token":String(repeating: "x", count: 257)]) == .rejected(.invalidFields))
        precondition(story.state == ready)
        precondition(access.submit(puzzleID, fields: ["input.fixture.token":"  oPeN\n"]) == .completed)
        precondition(access.resourceState(resourceID) == .unlocked)
        precondition(story.state.completedMilestoneIDs.contains("milestone.fixture.challenge_completed"))
        precondition(story.state.assistant.relationshipFacts.contains("assistant.fixture.evidence_shared"))
        precondition(story.state.assistant.cooperation == .notEstablished && story.state.observerClueIDs.isEmpty)
        let solved = story.state
        precondition(access.submit(puzzleID, fields: ["input.fixture.token":"wrong"]) == .alreadyCompleted)
        precondition(story.state == solved)
        success(content.read(memo, versionID: "version.fixture.protected_memo.v1"))
        success(content.preserve(memo, versionID: "version.fixture.protected_memo.v1"))
        precondition(access.resourceState("resource.fixture.optional") == .hidden)
        precondition(access.submit("puzzle.fixture.optional", fields: ["input.fixture.choice":"Leave"]) == .rejected(.incorrectAnswer))
        precondition(access.submit("puzzle.fixture.optional", fields: ["input.fixture.choice":"Inspect"]) == .completed)
        precondition(access.resourceState("resource.fixture.optional") == .unlocked)
        precondition(story.state.currentAct == .thePerfectProduct && story.state.ascensionMilestone == nil)
        precondition(access.resourceState("resource.fixture.late") == .hidden)
        // A resource with late prerequisites requires each explicit fact, not a computed score.
        var late = story.state; late.currentAct = .theFinalChoice; late.accessMilestoneIDs.insert("access.fixture.late")
        precondition(access.resourceState("resource.fixture.late", state: late) == .locked)
        late.assistant.cooperation = .cooperating
        precondition(access.resourceState("resource.fixture.late", state: late) == .locked)
        late.routePrerequisiteIDs.insert("route.fixture.stabilized")
        precondition(access.resourceState("resource.fixture.late", state: late) == .unlocked)
        // Misbound content revokes all live query routes, while authentic saved evidence remains intact.
        access.validateContentReferences(nil)
        precondition(access.resourceState(resourceID) == .unresolved && content.currentVersion(for: memo) == nil)
        precondition(content.engagedSnapshot(memo, versionID: "version.fixture.protected_memo.v1") == nil)
        precondition(content.preservedItem("evidence.fixture.protected_memo.v1") != nil)
        if case .unavailable(.notAccessible) = try content.comparison(for: "evidence.fixture.protected_memo.v1").get().current {} else { preconditionFailure() }
        let unguarded = StoryContentStore(progression: story, catalogue: contentCatalogue)
        precondition(unguarded.currentVersion(for: memo) == nil)
        if case .failure = StoryContentCatalogueLoader.load(data: contentData) {} else { preconditionFailure("Missing resource references were accepted") }
        let disk = AccessFailingPersistence()
        let failedStory = StoryProgressionStore(persistence: disk)
        let failedAccess = RestrictedAccessStore(progression: failedStory, catalogue: fixture)
        let failedContent = StoryContentStore(progression: failedStory, catalogue: contentCatalogue, access: failedAccess)
        readHint(failedContent); let failedBefore = failedStory.state; let bytes = disk.data; disk.fail = true
        if case .saveFailed(.persistenceFailed) = failedAccess.submit(puzzleID, fields: ["input.fixture.token":"OPEN"]) {} else { preconditionFailure() }
        precondition(failedStory.state == failedBefore && disk.data == bytes && failedAccess.resourceState(resourceID) == .locked)
        disk.fail = false; precondition(failedAccess.submit(puzzleID, fields: ["input.fixture.token":"OPEN"]) == .completed)
        // Existing v1 -> v2 migration retains solved puzzles/access/optional facts without new schema fields.
        var legacy = try JSONSerialization.jsonObject(with: StorySaveCodec().encode(story.state)) as! [String: Any]
        legacy["schemaVersion"] = 1; legacy.removeValue(forKey: "contentDelivery")
        let migrated = StoryProgressionStore(persistence: InMemoryStoryPersistence(data: try JSONSerialization.data(withJSONObject: legacy)))
        precondition(migrated.saveStatus == .migrated(from: 1))
        precondition(migrated.state.solvedPuzzleIDs == story.state.solvedPuzzleIDs && migrated.state.accessMilestoneIDs == story.state.accessMilestoneIDs)
        precondition(migrated.state.observerClueIDs == story.state.observerClueIDs)
        var partial = StoryState(); partial.solvedPuzzleIDs.insert(puzzleID)
        let partialStory = StoryProgressionStore(persistence: InMemoryStoryPersistence(data: try StorySaveCodec().encode(partial)))
        let partialAccess = RestrictedAccessStore(progression: partialStory, catalogue: fixture)
        _ = StoryContentStore(progression: partialStory, catalogue: contentCatalogue, access: partialAccess)
        precondition(partialAccess.resourceState(resourceID) == .locked)
        precondition(partialAccess.submit(puzzleID, fields: ["input.fixture.token":"OPEN"]) == .rejected(.inconsistentCompletion))
        precondition(partialStory.state == partial)
        let corrupt = StoryProgressionStore(persistence: InMemoryStoryPersistence(data: Data("bad save".utf8)))
        let corruptAccess = RestrictedAccessStore(progression: corrupt, catalogue: fixture)
        corruptAccess.validateContentReferences(try contentCatalogue.get())
        precondition(corruptAccess.resourceState(resourceID) == .unresolved)
        if case .saveFailed(.recoveryRequired) = corruptAccess.submit(puzzleID, fields: ["input.fixture.token":"OPEN"]) {} else { preconditionFailure() }
        // Validation rejects unknown keys, effects, duplicate IDs, references and self-producing gates.
        for mutation in 0..<5 {
            var raw = try JSONSerialization.jsonObject(with: fixtureData) as! [String: Any]
            var puzzles = raw["puzzles"] as! [[String: Any]]
            switch mutation {
            case 0: puzzles.append(puzzles[0])
            case 1: puzzles[0]["requirements"] = [["type":"accessGranted","id":"access.fixture.research"]]
            case 2: puzzles[0]["successEffects"] = [["kind":"executeSwift","id":"access.fixture.research"]]
            case 3: puzzles[0]["rule"] = ["kind":"exactFields","expectedFields":["input.fixture.token":"OPEN"],"execute":"ignored"]
            default: puzzles[0]["requirements"] = [["type":"puzzleSolved","id":"puzzle.fixture.missing"]]
            }
            raw["puzzles"] = puzzles
            if case .failure = RestrictedAccessCatalogueLoader.loadDevelopmentFixture(data: try JSONSerialization.data(withJSONObject: raw)) {} else { preconditionFailure("Accepted invalid puzzle definition") }
        }
        print("PASS: locked live queries, prerequisites, explicit typed outcomes, normalization/retry, atomic saved success/idempotency, references, migration, optional Observer independence, late facts and inert retired pending gate")
    }
    @MainActor static func readHint(_ content: StoryContentStore) { success(content.read("content.fixture.access_hint", versionID: "version.fixture.access_hint.v1")) }
    static func success(_ result: StoryContentDeliveryResult) { guard case .success = result else { preconditionFailure("Unexpected delivery: \(result)") } }
    static func failure(_ result: StoryContentDeliveryResult) { guard case .failure(.contentUnavailable) = result else { preconditionFailure("Expected closed resource: \(result)") } }
    static func action(_ result: StoryActionResult) { guard case .success = result else { preconditionFailure("Unexpected action: \(result)") } }
}
