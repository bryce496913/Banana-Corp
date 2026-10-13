import Foundation

@main struct EvidenceVaultChecks {
    @MainActor static func main() throws {
        let fixture = try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1]))
        let loaded = StoryContentCatalogueLoader.load(data: fixture)
        _ = try loaded.get()
        if CommandLine.arguments.count == 4 {
            let story = StoryProgressionStore(persistence: StoryFilePersistence(fileURL: URL(fileURLWithPath: CommandLine.arguments[3])))
            let content = StoryContentStore(progression: story, catalogue: loaded)
            if CommandLine.arguments[2] == "write" {
                try preserveSix(content)
                expect(content.read("content.fixture.email", versionID: "version.fixture.email.v1"), .changed)
                expect(content.read("content.fixture.messages", versionID: "version.fixture.messages.v1"), .changed)
                expect(content.recordComparison("evidence.fixture.news.v1"), .changed)
                print("PASS: six source snapshots and comparison facts written before process exit")
                exit(0)
            }
            precondition(content.preservedItems().count == 6)
            precondition(content.currentVersion(for: "content.fixture.news")?.id == "version.fixture.news.v2")
            let news = content.preservedItem("evidence.fixture.news.v1")!
            precondition(news.snapshot.version.id == "version.fixture.news.v1" && news.snapshot.version.timestampLabel == "Fixture morning")
            precondition(story.state.completedMilestoneIDs.contains("milestone.fixture.compared"))
            expect(content.preserve("content.fixture.news", versionID: "version.fixture.news.v1"), .unchanged)
            expect(content.recordComparison("evidence.fixture.news.v1"), .unchanged)
            print("PASS: Vault snapshots, version/source metadata, removal/replacement and authored facts reopened in a new process")
            return
        }
        try checkPreservationAndComparison(loaded, fixture: fixture)
        try checkInvalidRecordsAndFailures(loaded, fixture: fixture)
        try checkHomeLayoutUpgrade()
        print("PASS: six source formats, immutable snapshots/timestamps, metadata, exact-version dedupe, factual comparison, unavailable sources, missing proof, atomic facts/failures and old home layout upgrade")
    }

    @MainActor static func preserveSix(_ content: StoryContentStore) throws {
        for (index, surface) in ["email","news","social","web","video","photos"].enumerated() {
            expect(content.preserve("content.fixture." + surface, versionID: "version.fixture.\(surface).v1", at: Date(timeIntervalSince1970: Double(index + 1))), .changed)
        }
    }

    @MainActor static func checkPreservationAndComparison(_ loaded: Result<StoryContentCatalogue, StoryContentLoadFailure>, fixture: Data) throws {
        let backend = InMemoryStoryPersistence()
        let story = StoryProgressionStore(persistence: backend)
        let content = StoryContentStore(progression: story, catalogue: loaded)
        expect(content.preserve("content.fixture.email", versionID: "version.fixture.email.v1", at: Date(timeIntervalSince1970: 1)), .changed)
        precondition(!story.state.completedMilestoneIDs.contains("milestone.fixture.preserved"), "Unrelated evidence earns no milestone")
        precondition(!story.state.completedMilestoneIDs.contains("milestone.fixture.email_read"), "Preservation does not run read effects")
        for surface in ["news","social","web","video","photos"] {
            expect(content.preserve("content.fixture." + surface, versionID: "version.fixture.\(surface).v1", at: Date(timeIntervalSince1970: 1234)), .changed)
        }
        precondition(content.preservedItems().count == 6 && story.state.readContentIDs.isEmpty)
        precondition(story.state.completedMilestoneIDs.contains("milestone.fixture.preserved") && story.state.observerClueIDs.contains("observer.fixture.secured"))
        precondition(!story.state.completedMilestoneIDs.contains("milestone.fixture.compared"))
        let news = content.preservedItem("evidence.fixture.news.v1")!
        precondition(news.record.capturedAt == Date(timeIntervalSince1970: 1234))
        precondition(news.snapshot.version.narrativeTimestamp == NarrativeTimestamp(day: 1, hour: 10, minute: 20))
        precondition(news.snapshot.appSurface == .news && news.snapshot.version.author == "Development fixture")
        precondition(news.snapshot.version.source == "Local development fixture" && news.snapshot.version.narrativeMetadata?["fixturePurpose"] == "evidence test")
        precondition(news.snapshot.version.evidenceRules?.comparisonMilestoneID == "milestone.fixture.compared")
        let before = story.state
        expect(content.preserve("content.fixture.news", versionID: "version.fixture.news.v1", at: Date(timeIntervalSince1970: 9999)), .unchanged)
        precondition(story.state == before && content.preservedItem(news.id)?.record.snapshot == news.record.snapshot)
        let unchanged = try content.comparison(for: news.id).get()
        precondition(!unchanged.hasVisibleDifferences)
        expect(content.recordComparison(news.id), .changed)
        precondition(!story.state.completedMilestoneIDs.contains("milestone.fixture.compared"))
        expect(content.read("content.fixture.email", versionID: "version.fixture.email.v1"), .changed)
        expect(content.read("content.fixture.messages", versionID: "version.fixture.messages.v1"), .changed)
        let comparison = try content.comparison(for: news.id).get()
        precondition(comparison.hasVisibleDifferences && comparison.differences.contains { $0.id == "title" })
        if case .live(let live) = comparison.current { precondition(live.id == "version.fixture.news.v2") } else { preconditionFailure() }
        precondition(content.preservedItem(news.id)?.snapshot.version.id == "version.fixture.news.v1")
        expect(content.recordComparison(news.id), .changed)
        expect(content.recordComparison(news.id), .unchanged)
        precondition(story.state.completedEventIDs.contains("event.compare." + news.id))
        precondition(story.state.completedEventIDs.contains("event.diff." + news.id))
        precondition(story.state.completedMilestoneIDs.contains("milestone.fixture.compared"))
        let social = try content.comparison(for: "evidence.fixture.social.v1").get()
        if case .unavailable(.removed) = social.current {} else { preconditionFailure() }
        precondition(social.differences.isEmpty && content.preservedItem("evidence.fixture.social.v1") != nil)
        expect(content.recordComparison("evidence.fixture.social.v1"), .changed)
        let reloaded = StoryProgressionStore(persistence: backend)
        let reopened = StoryContentStore(progression: reloaded, catalogue: loaded)
        precondition(reloaded.state == story.state && reopened.preservedItem(news.id)?.record == news.record)
        expectFailure(content.comparison(for: "evidence.fixture.none"), .unknownEvidence("evidence.fixture.none"))
        precondition(!content.isPreservable("content.fixture.messages", versionID: "version.fixture.messages.v1"))
        expect(content.preserve("content.fixture.messages", versionID: "version.fixture.messages.v1"), error: .contentUnavailable)

        // Existing source versions are not guessed when their explicit live definition disappears.
        let missingVersionData = try mutate(fixture) { root in
            var items = root["items"] as! [[String: Any]]
            for index in items.indices {
                if items[index]["appSurface"] as? String == "news" {
                    var versions = items[index]["versions"] as! [[String: Any]]; versions.removeLast(); items[index]["versions"] = versions
                }
                if items[index]["appSurface"] as? String == "messages" {
                    var versions = items[index]["versions"] as! [[String: Any]]; versions[0]["effectsOnRead"] = []; items[index]["versions"] = versions
                }
            }
            root["items"] = items
        }
        let missingVersion = StoryContentStore(progression: story, catalogue: StoryContentCatalogueLoader.load(data: missingVersionData))
        if case .unavailable(.missingVersion) = try missingVersion.comparison(for: news.id).get().current {} else { preconditionFailure() }
        precondition(missingVersion.preservedItem(news.id)?.record.snapshot == news.record.snapshot)
        let empty = StoryContentStore(progression: story, catalogue: StoryContentCatalogueLoader.load(data: Data("{\"schemaVersion\":1,\"facts\":{},\"items\":[]}".utf8)))
        if case .unavailable(.missingSource) = try empty.comparison(for: news.id).get().current {} else { preconditionFailure() }
        expect(empty.recordComparison(news.id), error: .contentUnavailable)
        let unavailable = StoryContentStore(progression: story, catalogue: StoryContentCatalogueLoader.load(fileURL: nil))
        if case .unavailable(.catalogueUnavailable) = try unavailable.comparison(for: news.id).get().current {} else { preconditionFailure() }
        precondition(unavailable.preservedItems().count == 6)

        // A version number/ID change alone is not a visible content edit or a milestone.
        let identical = try mutate(fixture) { root in
            var items = root["items"] as! [[String: Any]]
            let index = items.firstIndex { $0["appSurface"] as? String == "news" }!
            var versions = items[index]["versions"] as! [[String: Any]]
            var copy = versions[0]; copy["id"] = "version.fixture.news.v2"; copy["version"] = 2; copy["preservedEvidenceID"] = "evidence.fixture.news.v2"
            versions[1] = copy; items[index]["versions"] = versions; root["items"] = items
        }
        let isolatedStory = StoryProgressionStore(persistence: InMemoryStoryPersistence())
        let identicalContent = StoryContentStore(progression: isolatedStory, catalogue: StoryContentCatalogueLoader.load(data: identical))
        expect(identicalContent.preserve("content.fixture.news", versionID: "version.fixture.news.v1"), .changed)
        expect(identicalContent.read("content.fixture.email", versionID: "version.fixture.email.v1"), .changed)
        expect(identicalContent.read("content.fixture.messages", versionID: "version.fixture.messages.v1"), .changed)
        let identicalComparison = try identicalContent.comparison(for: "evidence.fixture.news.v1").get()
        precondition(identicalComparison.differences.isEmpty)
        expect(identicalContent.recordComparison("evidence.fixture.news.v1"), .changed)
        precondition(!isolatedStory.state.completedMilestoneIDs.contains("milestone.fixture.compared"))
    }

    @MainActor static func checkInvalidRecordsAndFailures(_ loaded: Result<StoryContentCatalogue, StoryContentLoadFailure>, fixture: Data) throws {
        let backend = FaultEvidencePersistence()
        let story = StoryProgressionStore(persistence: backend)
        let content = StoryContentStore(progression: story, catalogue: loaded)
        let before = story.state; let bytes = backend.data
        backend.fail = true
        if case .failure(.progression(.persistenceFailed)) = content.preserve("content.fixture.news", versionID: "version.fixture.news.v1") {} else { preconditionFailure() }
        precondition(story.state == before && backend.data == bytes)
        backend.fail = false
        expect(content.preserve("content.fixture.news", versionID: "version.fixture.news.v1"), .changed)
        let record = content.preservedItem("evidence.fixture.news.v1")!.record
        let duplicate = PreservedEvidenceRecord(id: "evidence.fixture.duplicate", sourceContentID: record.sourceContentID, sourceVersionID: record.sourceVersionID, capturedAt: record.capturedAt, snapshot: record.snapshot)
        precondition(story.perform(.preserveEvidence(duplicate)) == .failure(.conflictingRecord(duplicate.id)))
        var damaged = story.state
        damaged.preservedEvidence[record.id] = PreservedEvidenceRecord(id: record.id, sourceContentID: record.sourceContentID, sourceVersionID: record.sourceVersionID, capturedAt: record.capturedAt, snapshot: Data("damaged snapshot".utf8))
        let damagedBackend = InMemoryStoryPersistence(data: try StorySaveCodec().encode(damaged))
        let damagedStore = StoryProgressionStore(persistence: damagedBackend)
        let damagedContent = StoryContentStore(progression: damagedStore, catalogue: loaded)
        precondition(damagedContent.evidenceRecords().count == 1 && damagedContent.preservedItem(record.id) == nil)
        expect(damagedContent.preserve(record.sourceContentID, versionID: record.sourceVersionID), error: .invalidSnapshot)
        expectFailure(damagedContent.comparison(for: record.id), .invalidSnapshot)
        precondition(damagedStore.state.preservedEvidence[record.id]?.snapshot == Data("damaged snapshot".utf8))
        // Missing record + an inconsistent completion marker must not report a successful save.
        var inconsistent = StoryState(); inconsistent.completedEventIDs.insert("event.preserve.evidence.fixture.news.v1")
        let bad = StoryProgressionStore(persistence: InMemoryStoryPersistence(data: try StorySaveCodec().encode(inconsistent)))
        let badContent = StoryContentStore(progression: bad, catalogue: loaded)
        expect(badContent.preserve("content.fixture.news", versionID: "version.fixture.news.v1"), error: .invalidSnapshot)
        precondition(bad.state.preservedEvidence.isEmpty)
        precondition(story.perform(.recordEvidenceComparison(evidenceID: "evidence.fixture.none", changed: true)) == .failure(.invalidRecord))
        let invalidRules = try mutate(fixture) { root in
            var items = root["items"] as! [[String: Any]]
            var versions = items[0]["versions"] as! [[String: Any]]
            versions[0]["evidenceRules"] = ["preservationMilestoneID":"milestone.fixture.notdeclared"]
            items[0]["versions"] = versions; root["items"] = items
        }
        if case .failure(let error) = StoryContentCatalogueLoader.load(data: invalidRules) { precondition(error.diagnostics.contains { $0.code == .missingReference }) } else { preconditionFailure() }
        let nonPreservableRules = try mutate(fixture) { root in
            var items = root["items"] as! [[String: Any]]
            let index = items.firstIndex { $0["appSurface"] as? String == "messages" }!
            var versions = items[index]["versions"] as! [[String: Any]]
            versions[0]["evidenceRules"] = ["preservationMilestoneID":"milestone.fixture.preserved"]
            items[index]["versions"] = versions; root["items"] = items
        }
        if case .failure(let error) = StoryContentCatalogueLoader.load(data: nonPreservableRules) { precondition(error.diagnostics.contains { $0.code == .invalidRule }) } else { preconditionFailure() }
        let unknownRule = try mutate(fixture) { root in
            var items = root["items"] as! [[String: Any]]
            var versions = items[0]["versions"] as! [[String: Any]]
            versions[0]["evidenceRules"] = ["unexpectedFormula": "not supported"]
            items[0]["versions"] = versions; root["items"] = items
        }
        if case .failure(let error) = StoryContentCatalogueLoader.load(data: unknownRule) { precondition(error.diagnostics.contains { $0.code == .malformedJSON }) } else { preconditionFailure() }
    }

    static func checkHomeLayoutUpgrade() throws {
        let suite = "bananaCorp.evidenceLayout." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let oldRoutes = PhoneAppRoute.allCases.filter { $0 != .evidence }
        let old = HomeScreenLayout(gridApps: Array(oldRoutes.filter { !HomeScreenLayout.defaultDockApps.contains($0) }.reversed()), dockApps: [.news,.email,.aiAssistant,.messager])
        defaults.set(try JSONEncoder().encode(old), forKey: "bananaCorp.homeScreenLayout.v1")
        var upgraded = HomeScreenLayoutStore.load(from: defaults)
        precondition(upgraded.gridApps.dropLast() == old.gridApps && upgraded.gridApps.last == .evidence && upgraded.dockApps == old.dockApps)
        precondition((upgraded.gridApps + upgraded.dockApps).filter { $0 == .evidence }.count == 1)
        precondition(!upgraded.move(.evidence, to: .dock))
        precondition(upgraded.move(.email, to: .grid) && upgraded.move(.evidence, to: .dock))
        HomeScreenLayoutStore.save(upgraded, to: defaults)
        precondition(HomeScreenLayoutStore.load(from: defaults) == upgraded)
    }

    static func mutate(_ data: Data, _ transform: (inout [String: Any]) -> Void) throws -> Data {
        var object = try JSONSerialization.jsonObject(with: data) as! [String: Any]; transform(&object)
        return try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
    }
    static func expect(_ result: StoryContentDeliveryResult, _ expected: StoryActionOutcome) { precondition(result == .success(expected), "\(result)") }
    static func expect(_ result: StoryContentDeliveryResult, error: StoryContentDeliveryError) { precondition(result == .failure(error), "\(result)") }
    static func expectFailure(_ result: Result<EvidenceComparison, StoryContentDeliveryError>, _ error: StoryContentDeliveryError) {
        if case .failure(let actual) = result { precondition(actual == error) } else { preconditionFailure("Comparison invented a missing copy") }
    }
}

private final class FaultEvidencePersistence: StoryPersistence {
    enum Failure: Error { case write }
    var data: Data?
    var fail = false
    func read() throws -> Data? { data }
    func write(_ data: Data) throws { if fail { throw Failure.write }; self.data = data }
    func archiveForReset() throws {}
}
