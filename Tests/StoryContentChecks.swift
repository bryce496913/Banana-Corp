import Foundation

@main struct StoryContentChecks {
    @MainActor static func main() throws {
        let fixtureURL = URL(fileURLWithPath: CommandLine.arguments[1])
        let productionURL = URL(fileURLWithPath: CommandLine.arguments[2])
        let data = try Data(contentsOf: fixtureURL)
        let loaded = StoryContentCatalogueLoader.load(fileURL: fixtureURL)
        let catalogue = try loaded.get()
        precondition(Set(catalogue.items.map(\.appSurface)) == Set(StoryAppSurface.allCases))
        if CommandLine.arguments.count == 5 {
            let story = StoryProgressionStore(persistence: StoryFilePersistence(fileURL: URL(fileURLWithPath: CommandLine.arguments[4])))
            let content = StoryContentStore(progression: story, catalogue: loaded)
            if CommandLine.arguments[3] == "write" {
                expect(content.preserve("content.fixture.news", versionID: "version.fixture.news.v1"), .changed)
                expect(content.read("content.fixture.email", versionID: "version.fixture.email.v1"), .changed)
                expect(content.read("content.fixture.messages", versionID: "version.fixture.messages.v1"), .changed)
                print("PASS: content actions persisted without termination hooks")
                exit(0)
            }
            precondition(content.currentVersion(for: "content.fixture.news")?.id == "version.fixture.news.v2")
            precondition(content.preservedItems().first?.snapshot.version.id == "version.fixture.news.v1")
            precondition(content.pendingNotifications().count == 1)
            let state = story.state
            expect(content.read("content.fixture.email", versionID: "version.fixture.email.v1"), .unchanged)
            precondition(story.state == state)
            print("PASS: content versions, evidence, effects and notification queue survived a new process")
            return
        }
        try validateLoading(data, productionURL: productionURL)
        try validateDelivery(loaded, fixture: data)
        try validateMigrationAndFailures(loaded)
        print("PASS: structured offline formats, validation, ordering, prerequisites, delivery, idempotency, immutable versions/snapshots, resources, queue, migration and atomic failure")
    }

    static func validateLoading(_ fixture: Data, productionURL: URL) throws {
        let production = try StoryContentCatalogueLoader.load(fileURL: productionURL, restrictedResourceIDs: ["resource.banana_wall"]).get()
        precondition(!production.items.isEmpty)
        precondition(production.items.filter { $0.actAvailable.rawValue <= 2 }.count == 45)
        precondition(production.items.filter { $0.actAvailable.rawValue == 3 }.map(\.id) == ["content.act3.banana_wall.scope_record"])
        rejects(StoryContentCatalogueLoader.load(fileURL: nil), .missingResource)
        rejects(StoryContentCatalogueLoader.load(fileURL: URL(string: "https://example.invalid/catalogue.json")), .missingResource)
        rejects(StoryContentCatalogueLoader.load(data: Data("invalid".utf8)), .malformedJSON)
        rejects(StoryContentCatalogueLoader.load(data: try mutate(fixture) { $0["schemaVersion"] = 99 }), .unsupportedSchema)
        rejects(StoryContentCatalogueLoader.load(data: try mutate(fixture) { root in
            var items = root["items"] as! [[String: Any]]; items.append(items[0]); root["items"] = items
        }), .duplicateID)
        rejects(StoryContentCatalogueLoader.load(data: try itemMutation(fixture, "news") { item in
            var versions = item["versions"] as! [[String: Any]]; versions[1]["version"] = 1; item["versions"] = versions
        }), .invalidVersion)
        rejects(StoryContentCatalogueLoader.load(data: try itemMutation(fixture, "email") { $0["unlockConditions"] = [["type":"contentRead", "id":"content.fixture.absent"]] }), .missingReference)
        rejects(StoryContentCatalogueLoader.load(data: try itemMutation(fixture, "email") { $0["unlockConditions"] = [["type":"contentRead", "id":"content.fixture.email"]] }), .invalidRule)
        rejects(StoryContentCatalogueLoader.load(data: try itemMutation(fixture, "email") { $0["unlockConditions"] = [["type":"all", "conditions":[]]] }), .invalidRule)
        rejects(StoryContentCatalogueLoader.load(data: try itemMutation(fixture, "email") { $0["appSurface"] = "news" }), .invalidPayload)
        rejects(StoryContentCatalogueLoader.load(data: try versionMutation(fixture, "email", 0) { $0["effectsOnRead"] = [["type":"executeSwift", "id":"fixture.unsafe"]] }), .malformedJSON)
        rejects(StoryContentCatalogueLoader.load(data: try versionMutation(fixture, "email", 0) { $0["effectsOnRead"] = [["type":"revealContent", "id":"content.fixture.web", "code":"ignored code must be rejected"]] }), .malformedJSON)
        rejects(StoryContentCatalogueLoader.load(data: try versionMutation(fixture, "messages", 0) { $0["effectsOnRead"] = [["type":"changeVersion", "contentID":"content.fixture.news", "versionID":"version.fixture.email.v1"]] }), .missingReference)
        rejects(StoryContentCatalogueLoader.load(data: try versionMutation(fixture, "email", 0) { $0["effectsOnRead"] = [["type":"queueNotification", "id":"content.fixture.news"]] }), .missingReference)
        rejects(StoryContentCatalogueLoader.load(data: try versionMutation(fixture, "news", 1) { $0["effectsOnRead"] = [["type":"revealContent", "id":"content.fixture.messages"]] }), .cycle)
        rejects(StoryContentCatalogueLoader.load(data: try itemMutation(fixture, "email") { $0["unlockConditions"] = [["type":"milestoneCompleted", "id":"milestone.fixture.email_read"]] }), .invalidRule)
        rejects(StoryContentCatalogueLoader.load(data: try mutate(fixture) { $0["assets"] = [["id":"asset.fixture.missing", "fileName":"absent.png"]] }), .missingResource)
        rejects(StoryContentCatalogueLoader.load(data: try versionMutation(fixture, "web", 0) { version in
            var payload = version["payload"] as! [String: Any]; var body = payload["data"] as! [String: Any]
            body["links"] = [["label":"Missing fixture", "contentID":"content.fixture.absent"]]; payload["data"] = body; version["payload"] = payload
        }), .missingReference)
        rejects(StoryContentCatalogueLoader.load(data: try versionMutation(fixture, "video", 0) { version in
            var payload = version["payload"] as! [String: Any]; var body = payload["data"] as! [String: Any]
            body["transcript"] = [["startSeconds":99, "text":"Outside metadata duration"]]; payload["data"] = body; version["payload"] = payload
        }), .invalidPayload)
        let shuffled = try mutate(fixture) { root in root["items"] = (root["items"] as! [[String: Any]]).reversed().map { $0 } }
        let originalItems = try StoryContentCatalogueLoader.load(data: fixture).get().items
        let shuffledItems = try StoryContentCatalogueLoader.load(data: shuffled).get().items
        precondition(originalItems == shuffledItems)
        let tied = try itemMutation(fixture, "news") { $0["order"] = 10 }
        let tiedItems = try StoryContentCatalogueLoader.load(data: tied).get().items
        precondition(tiedItems.prefix(2).map(\.id) == ["content.fixture.email", "content.fixture.news"])

        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".bundle")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        try fixture.write(to: folder.appendingPathComponent("StoryContent.json"))
        let bundle = Bundle(url: folder)!
        let bundled = try StoryContentCatalogueLoader.load(bundle: bundle).get()
        precondition(bundled.items.count == 10)
        rejects(StoryContentCatalogueLoader.load(bundle: bundle, resource: "Absent"), .missingResource)
    }

    @MainActor static func validateDelivery(_ loaded: Result<StoryContentCatalogue, StoryContentLoadFailure>, fixture: Data) throws {
        let backend = InMemoryStoryPersistence()
        let story = StoryProgressionStore(persistence: backend)
        let content = StoryContentStore(progression: story, catalogue: loaded)
        let baseline = story.state
        let bytes = backend.data
        precondition(content.unreadCount(for: .email) == 1 && content.unreadCount(for: .messages) == 0)
        precondition(content.availability(for: "content.fixture.web") == .hidden)
        precondition(content.availability(for: "content.fixture.messages") == .locked)
        precondition(content.availability(for: "content.fixture.video") == .locked)
        precondition(content.availableItems(for: .news).first?.version.id == "version.fixture.news.v1")
        precondition(story.state == baseline && backend.data == bytes, "Queries must never discover/read or save")
        expectFailure(content.read("content.fixture.messages", versionID: "version.fixture.messages.v1"), .contentUnavailable)
        expectFailure(content.read("content.fixture.news", versionID: "version.fixture.news.v2"), .staleVersion)
        expect(content.preserve("content.fixture.news", versionID: "version.fixture.news.v1", at: Date(timeIntervalSince1970: 1)), .changed)
        precondition(!story.state.readContentIDs.contains("content.fixture.news"))
        precondition(content.availableItems(for: .photos).count == 1)
        let evidence = story.state.preservedEvidence["evidence.fixture.news.v1"]!
        _ = story.perform(.setAppAvailability(.vrExperience, unlocked: false))
        expect(content.read("content.fixture.email", versionID: "version.fixture.email.v1"), .changed)
        precondition(content.unreadCount(for: .email) == 0 && content.unreadCount(for: .messages) == 1)
        precondition(content.availability(for: "content.fixture.email") == .read)
        precondition(content.availableItems(for: .web).count == 1 && content.availableItems(for: .diagnostics).count == 1)
        precondition(story.state.completedMilestoneIDs.contains("milestone.fixture.email_read"))
        precondition(story.state.observerClueIDs.contains("observer.fixture.email") && !story.state.lockedAppIDs.contains("vrExperience"))
        precondition(content.pendingNotifications().count == 1 && !story.state.readContentIDs.contains("content.fixture.notifications"))
        precondition(content.availableItems(for: .assistant).isEmpty)
        _ = story.perform(.grantAccess("access.fixture.external"))
        precondition(content.availableItems(for: .assistant).count == 1)
        let after = story.state
        expect(content.read("content.fixture.email", versionID: "version.fixture.email.v1"), .unchanged)
        precondition(story.state == after)
        expect(content.read("content.fixture.messages", versionID: "version.fixture.messages.v1"), .changed)
        precondition(content.currentVersion(for: "content.fixture.news")?.id == "version.fixture.news.v2")
        precondition(content.originalVersion(for: "content.fixture.news")?.id == "version.fixture.news.v1")
        precondition(content.availability(for: "content.fixture.news", versionID: "version.fixture.news.v1") == .replaced(liveVersionID: "version.fixture.news.v2"))
        precondition(content.availability(for: "content.fixture.social") == .removed)
        precondition(content.preservedItems().first?.record == evidence && content.preservedItems().first?.availability == .preserved)
        expect(content.preserve("content.fixture.news", versionID: "version.fixture.news.v1"), .unchanged)
        expect(content.read("content.fixture.news", versionID: "version.fixture.news.v2"), .changed)
        let reload = StoryProgressionStore(persistence: backend)
        let reloadedContent = StoryContentStore(progression: reload, catalogue: loaded)
        precondition(reload.state == story.state && reloadedContent.savedReferenceDiagnostics().isEmpty)
        let notification = reloadedContent.pendingNotifications()[0].record
        expect(reloadedContent.acknowledgeNotification(notification.id), .changed)
        expect(reloadedContent.acknowledgeNotification(notification.id), .unchanged)
        precondition(reloadedContent.pendingNotifications().isEmpty)
        let edited = try versionMutation(fixture, "news", 0) { $0["title"] = "Edited development definition" }
        let changed = StoryContentStore(progression: reload, catalogue: StoryContentCatalogueLoader.load(data: edited))
        precondition(changed.savedReferenceDiagnostics().contains { $0.code == .definitionChanged })
        precondition(changed.originalVersion(for: "content.fixture.news") == nil)
        precondition(changed.preservedItems().first?.record.snapshot == evidence.snapshot)
        expect(changed.preserve("content.fixture.news", versionID: "version.fixture.news.v1"), .unchanged)
        let missing = StoryContentStore(progression: reload, catalogue: StoryContentCatalogueLoader.load(data: Data("{\"schemaVersion\":1,\"facts\":{},\"items\":[]}".utf8)))
        precondition(missing.savedReferenceDiagnostics().contains { $0.code == .savedReference })
        precondition(missing.preservedItems().first?.record.snapshot == evidence.snapshot)
        var futureState = StoryState(); futureState.currentAct = .somethingIsntRight
        precondition(content.availableItems(for: .video, state: futureState).count == 1)
        precondition(story.state.currentAct == .thePerfectProduct, "No fixture query/effect activates a later act")
    }

    @MainActor static func validateMigrationAndFailures(_ loaded: Result<StoryContentCatalogue, StoryContentLoadFailure>) throws {
        var legacy = StoryState()
        legacy.completedMilestoneIDs = ["milestone.fixture.legacy"]
        legacy.discoveredContentIDs = ["content.fixture.legacy"]
        legacy.readContentIDs = legacy.discoveredContentIDs
        legacy.compatibility.hasSeenFirstGlitch = true
        legacy.lockedAppIDs = ["vrExperience"]
        var json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(legacy)) as! [String: Any]
        json["schemaVersion"] = 1; json.removeValue(forKey: "contentDelivery")
        let old = try JSONSerialization.data(withJSONObject: json)
        let migrated = StoryProgressionStore(persistence: InMemoryStoryPersistence(data: old))
        precondition(migrated.state == legacy && migrated.saveStatus == .migrated(from: 1))
        let reformattedStory = StoryProgressionStore(persistence: InMemoryStoryPersistence())
        let initialContent = StoryContentStore(progression: reformattedStory, catalogue: loaded)
        expect(initialContent.read("content.fixture.news", versionID: "version.fixture.news.v1"), .changed)
        var reformattedState = reformattedStory.state
        let originalReceipt = reformattedState.contentDelivery.versionReceipts["version.fixture.news.v1"]!
        let snapshotObject = try JSONSerialization.jsonObject(with: originalReceipt.snapshot)
        let prettySnapshot = try JSONSerialization.data(withJSONObject: snapshotObject, options: [.prettyPrinted])
        reformattedState.contentDelivery.versionReceipts[originalReceipt.versionID] = SavedContentVersion(contentID: originalReceipt.contentID, versionID: originalReceipt.versionID, snapshot: prettySnapshot)
        let encoded = try StorySaveCodec().encode(reformattedState)
        let formatted = StoryProgressionStore(persistence: InMemoryStoryPersistence(data: encoded))
        let formattedContent = StoryContentStore(progression: formatted, catalogue: loaded)
        precondition(formattedContent.savedReferenceDiagnostics().isEmpty)
        expect(formattedContent.preserve("content.fixture.news", versionID: "version.fixture.news.v1"), .changed)
        precondition(formatted.state.preservedEvidence["evidence.fixture.news.v1"]?.snapshot == prettySnapshot)
        let backend = FailingContentPersistence()
        let story = StoryProgressionStore(persistence: backend)
        let content = StoryContentStore(progression: story, catalogue: loaded)
        let state = story.state; let bytes = backend.data
        backend.fail = true
        if case .failure(.progression(.persistenceFailed)) = content.read("content.fixture.email", versionID: "version.fixture.email.v1") {} else { preconditionFailure() }
        precondition(story.state == state && backend.data == bytes && content.pendingNotifications().isEmpty)
        backend.fail = false
        expect(content.read("content.fixture.email", versionID: "version.fixture.email.v1"), .changed)
        let unavailable = StoryContentStore(progression: story, catalogue: StoryContentCatalogueLoader.load(fileURL: nil))
        precondition(!unavailable.loadDiagnostics.isEmpty && unavailable.availableItems(for: .email).isEmpty)
        expectFailure(unavailable.read("content.fixture.email", versionID: "version.fixture.email.v1"), .catalogueUnavailable)
    }

    static func mutate(_ data: Data, _ change: (inout [String: Any]) -> Void) throws -> Data {
        var json = try JSONSerialization.jsonObject(with: data) as! [String: Any]; change(&json)
        return try JSONSerialization.data(withJSONObject: json, options: [.sortedKeys])
    }
    static func itemMutation(_ data: Data, _ surface: String, _ change: (inout [String: Any]) -> Void) throws -> Data {
        try mutate(data) { root in
            var items = root["items"] as! [[String: Any]]
            let index = items.firstIndex { $0["appSurface"] as? String == surface }!
            change(&items[index]); root["items"] = items
        }
    }
    static func versionMutation(_ data: Data, _ surface: String, _ index: Int, _ change: (inout [String: Any]) -> Void) throws -> Data {
        try itemMutation(data, surface) { item in
            var versions = item["versions"] as! [[String: Any]]; change(&versions[index]); item["versions"] = versions
        }
    }
    static func rejects(_ result: Result<StoryContentCatalogue, StoryContentLoadFailure>, _ code: StoryContentDiagnostic.Code) {
        if case .failure(let error) = result { precondition(error.diagnostics.contains { $0.code == code }, "Missing diagnostic \(code): \(error.diagnostics)") }
        else { preconditionFailure("Invalid catalogue loaded: \(code)") }
    }
    static func expect(_ result: StoryContentDeliveryResult, _ outcome: StoryActionOutcome) { precondition(result == .success(outcome), "\(result)") }
    static func expectFailure(_ result: StoryContentDeliveryResult, _ error: StoryContentDeliveryError) { precondition(result == .failure(error), "\(result)") }
}

private final class FailingContentPersistence: StoryPersistence {
    enum Failure: Error { case write }
    var data: Data?
    var fail = false
    func read() throws -> Data? { data }
    func write(_ data: Data) throws { if fail { throw Failure.write }; self.data = data }
    func archiveForReset() throws {}
}
