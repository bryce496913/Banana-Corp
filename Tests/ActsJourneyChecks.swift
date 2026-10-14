import Foundation

private final class WallFailingPersistence: StoryPersistence {
    var data: Data?; var fail = false
    init(data: Data) { self.data = data }
    func read() throws -> Data? { data }
    func write(_ data: Data) throws { if fail { throw StorySaveIssue.ioFailure("test write failure") }; self.data = data }
    func archiveForReset() throws {}
}

/// Model-level journey only. No debug replay, injected milestones or act shortcuts.
@main struct ActsJourneyChecks {
    @MainActor static func main() throws {
        let solvingWall = CommandLine.arguments.count > 2
        let source = URL(fileURLWithPath: CommandLine.arguments[1])
        let accessResult = RestrictedAccessCatalogueLoader.load(data: try Data(contentsOf: source.appendingPathComponent("RestrictedAccess.json")))
        let catalogue = StoryContentCatalogueLoader.load(fileURL: source.appendingPathComponent("StoryContent.json"), restrictedResourceIDs: Set(try accessResult.get().resources.map(\.id)))
        for email in [false, true] {
            for video in [false, true] {
                let external = CommandLine.arguments.count > 3
                let directory = external ? URL(fileURLWithPath: CommandLine.arguments[3]).appendingPathComponent("\(email)-\(video)") : FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
                defer { if !external { try? FileManager.default.removeItem(at: directory) } }
                let disk = StoryFilePersistence(fileURL: directory.appendingPathComponent("story-save.json"))
                var story = StoryProgressionStore(persistence: disk)
                var access = RestrictedAccessStore(progression: story, catalogue: accessResult)
                var content = StoryContentStore(progression: story, catalogue: catalogue, access: access)
                if CommandLine.arguments.count > 2 && CommandLine.arguments[2] == "read-wall" {
                    precondition(story.isWritable && story.state.currentAct == .theConspiracy)
                    precondition(access.resourceState("resource.banana_wall") == .unlocked)
                    precondition(content.preservedItem("evidence.act3.banana_wall.scope_record.v1") != nil)
                    precondition(content.evidenceRecords().count == 1 + (email ? 1 : 0) + (video ? 1 : 0))
                    for record in content.evidenceRecords() {
                        precondition(record.snapshot == story.state.contentDelivery.versionReceipts[record.sourceVersionID]?.snapshot)
                    }
                    let before = story.state
                    precondition(access.submit("puzzle.banana_wall.review_cross_reference", fields: [:]) == .alreadyCompleted)
                    precondition(story.state == before)
                    print("PASS: actual Banana Wall access and exact reward evidence reopened in separate process (email=\(email), video=\(video))")
                    continue
                }
                var checkpoints = 0
                func restart(_ name: String) {
                    let before = story.state
                    let snapshots = content.evidenceRecords().map(\.snapshot)
                    story = StoryProgressionStore(persistence: disk)
                    access = RestrictedAccessStore(progression: story, catalogue: accessResult)
                    content = StoryContentStore(progression: story, catalogue: catalogue, access: access)
                    precondition(story.isWritable && story.state == before, name)
                    precondition(content.evidenceRecords().map(\.snapshot) == snapshots, name)
                    checkpoints += 1
                }
                precondition(story.state.currentAct == .thePerfectProduct)
                precondition(access.resourceState("resource.banana_wall") == .hidden)
                if solvingWall {
                    let early = story.state
                    precondition(access.submit("puzzle.banana_wall.review_cross_reference", fields: [:]) == .rejected(.inaccessible))
                    precondition(content.currentVersion(for: "content.act3.banana_wall.scope_record") == nil && story.state == early)
                }
                precondition(content.availability(for: FirstAnomalyContract.originalContent) == .locked)
                let initial = story.state
                for surface in StoryAppSurface.allCases { _ = content.availableItems(for: surface); _ = content.unreadCount(for: surface) }
                precondition(story.state == initial)
                read(content, "content.act1.news.launch")
                finish(content, "content.act1.promo")
                restart("before original email read")
                precondition(content.availability(for: FirstAnomalyContract.originalContent) == .availableUnread)
                let unreadEmail = content.unreadCount(for: .email)
                read(content, FirstAnomalyContract.originalContent)
                precondition(content.unreadCount(for: .email) == unreadEmail - 1)
                if email { _ = try content.preserve(FirstAnomalyContract.originalContent, versionID: FirstAnomalyContract.originalVersion).get() }
                restart("after original email read")
                restart("before removal")
                _ = try content.activateFirstAnomalyAtBoundary().get()
                let removed = story.state
                let repeatedRemoval = try content.activateFirstAnomalyAtBoundary().get()
                precondition(repeatedRemoval == .unchanged)
                precondition(story.state == removed)
                precondition(content.availability(for: FirstAnomalyContract.originalContent) == .removed)
                precondition(content.availability(for: FirstAnomalyContract.warning) == .availableUnread)
                restart("after removal")
                restart("before warning read")
                let unreadMessages = content.unreadCount(for: .messages)
                read(content, FirstAnomalyContract.warning)
                precondition(content.unreadCount(for: .messages) == unreadMessages - 1)
                _ = try content.consumeFirstAnomalyPresentation().get()
                precondition(content.pendingNotifications().isEmpty)
                _ = try content.consumeFirstAnomalyPresentation().get()
                precondition(story.state.contentDelivery.notifications.count == 1)
                read(content, FirstAnomalyContract.denial)
                restart("after Assistant questioning")
                if email {
                    _ = try content.recordComparison(FirstAnomalyContract.evidence).get()
                    precondition(content.preservedItem(FirstAnomalyContract.evidence)?.snapshot.version.id == FirstAnomalyContract.originalVersion)
                } else {
                    read(content, FirstAnomalyContract.trace)
                    precondition(content.preservedItem(FirstAnomalyContract.evidence) == nil)
                }
                precondition(content.firstAnomalyHandoffAvailable)
                _ = try story.advanceAct(to: .somethingIsntRight).get()
                if video { _ = try content.preserve(ActTwoContract.alex, versionID: ActTwoContract.originalWarning).get() }
                finish(content, ActTwoContract.alex)
                restart("before Alex replacement")
                _ = try content.activateActTwoChangesAtBoundary(surface: .video).get()
                restart("after Alex replacement")
                finish(content, ActTwoContract.alex)
                if video {
                    _ = try content.recordComparison(ActTwoContract.warningEvidence).get()
                    let comparison = try content.comparison(for: ActTwoContract.warningEvidence).get()
                    precondition(comparison.hasVisibleDifferences)
                    guard case .video(let record) = content.preservedItem(ActTwoContract.warningEvidence)!.snapshot.version.payload else { preconditionFailure() }
                    precondition(record.mediaAssetID == nil && record.durationSeconds == nil)
                } else {
                    precondition(content.preservedItem(ActTwoContract.warningEvidence) == nil)
                    read(content, "content.act2.news.corroboration")
                }
                read(content, "content.act2.news.concerns")
                read(content, "content.act2.news.official")
                read(content, "content.act2.messages.daniel")
                read(content, "content.act2.email.maya")
                read(content, "content.act2.web.echo07")
                restart("after ECHO-07 discovery")
                read(content, "content.act2.diagnostics.excerpt")
                read(content, "content.act2.assistant.edits")
                precondition(content.actTwoConfirmationAvailable && !content.actThreeHandoffAvailable)
                _ = try content.confirmActTwoInvestigation().get()
                restart("immediately before Act 3")
                _ = try story.advanceAct(to: .theConspiracy).get()
                precondition(access.resourceState("resource.banana_wall") == .locked)
                precondition(access.visibleResources().map(\.id) == ["resource.banana_wall"])
                restart("locked Banana Wall")
                precondition(access.resourceState("resource.banana_wall") == .locked)
                precondition(access.puzzleAvailability("puzzle.banana_wall.pending_design") == .awaitingApproval)
                precondition(access.submit("puzzle.banana_wall.pending_design", fields: [:]) == .rejected(.awaitingApproval))
                precondition(story.state.solvedPuzzleIDs.isEmpty && story.state.accessMilestoneIDs.isEmpty)
                precondition(story.state.assistant.cooperation == .notEstablished && story.state.observerClueIDs.isEmpty)
                precondition(content.evidenceRecords().count == (email ? 1 : 0) + (video ? 1 : 0))
                let final = story.state
                _ = try content.activateActTwoChangesAtBoundary().get()
                _ = try content.confirmActTwoInvestigation().get()
                precondition(story.state == final)
                if solvingWall { try solveWall(story, access, content, disk: disk) }
                print("PASS MODEL ONLY: email=\(email), video=\(video), \(checkpoints) exact file-store reopen checkpoints, natural catalogue actions to locked Banana Wall; no Apple UI execution")
            }
        }
    }

    @MainActor static func solveWall(_ story: StoryProgressionStore, _ access: RestrictedAccessStore, _ content: StoryContentStore, disk: StoryFilePersistence) throws {
        let id = "puzzle.banana_wall.review_cross_reference"
        let reward = "content.act3.banana_wall.scope_record"
        let version = "version.act3.banana_wall.scope_record.v1"
        let milestone = "milestone.banana_wall.breached"
        let fields = ["input.banana_wall.discipline":"neural systems", "input.banana_wall.trial":"ECHO-07",
                      "input.banana_wall.public_scope":"selected preferences", "input.banana_wall.research_scope":"recorded cognitive patterns"]
        let puzzle = access.catalogue!.puzzlesByID[id]!
        precondition(puzzle.rule.expectedFields == fields && puzzle.hints.count == 3)
        let before = story.state
        precondition(content.currentVersion(for: reward) == nil && !content.availability(for: reward).isAvailable)
        if case .failure = content.read(reward, versionID: version) {} else { preconditionFailure() }
        if case .failure = content.preserve(reward, versionID: version) {} else { preconditionFailure() }
        for clue in puzzle.clueContentIDs! {
            let definition = content.catalogue!.itemsByID[clue]!
            precondition(content.availableItems(for: definition.appSurface).contains { $0.id == clue })
        }
        var draft = PuzzleDraft(fields: ["input.banana_wall.discipline":"neural systems"])
        for _ in 0..<5 { draft.revealHint(total: puzzle.hints.count); access.saveDraft(draft, for: id) }
        precondition(access.draft(for: id) == draft && draft.hintCount == 3 && story.state == before)
        for key in fields.keys {
            var wrong = fields; wrong[key] = "not the clue"
            precondition(access.submit(id, fields: wrong) == .rejected(.incorrectAnswer))
        }
        for value in ["ECHO", "echo07", "ECHO–07", "ECHO_CORE"] {
            var wrong = fields; wrong["input.banana_wall.trial"] = value
            precondition(access.submit(id, fields: wrong) == .rejected(.incorrectAnswer))
        }
        var spaced = fields; spaced["input.banana_wall.discipline"] = "neural  systems"
        precondition(access.submit(id, fields: spaced) == .rejected(.incorrectAnswer))
        var invalid = fields; invalid["input.banana_wall.trial"] = "  "
        precondition(access.submit(id, fields: invalid) == .rejected(.invalidFields))
        invalid["input.banana_wall.trial"] = String(repeating: "x", count: 257)
        precondition(access.submit(id, fields: invalid) == .rejected(.invalidFields))
        precondition(access.submit(id, fields: [:]) == .rejected(.invalidFields))
        invalid = fields; invalid["extra"] = "ECHO-07"
        precondition(access.submit(id, fields: invalid) == .rejected(.invalidFields))
        precondition(story.state == before && access.resourceState("resource.banana_wall") == .locked)
        let normalized = fields.mapValues { " \n" + $0.uppercased() + "\n " }
        precondition(access.submit(id, fields: normalized) == .completed)
        precondition(access.resourceState("resource.banana_wall") == .unlocked && access.draft(for: id) == PuzzleDraft())
        precondition(story.state.solvedPuzzleIDs == [id] && story.state.accessMilestoneIDs == ["access.banana_wall.breached"])
        precondition(story.state.completedMilestoneIDs == before.completedMilestoneIDs.union([milestone]))
        precondition(story.state.completedEventIDs == before.completedEventIDs.union([puzzle.successEventID]))
        precondition(content.availability(for: reward) == .availableUnread)
        precondition(story.state.readContentIDs == before.readContentIDs && story.state.currentAct == .theConspiracy)
        precondition(story.state.assistant == before.assistant && story.state.routePrerequisiteIDs == before.routePrerequisiteIDs && story.state.observerClueIDs == before.observerClueIDs)
        let solved = story.state; let bytes = try disk.read()
        precondition(access.submit(id, fields: ["bad":"wrong"]) == .alreadyCompleted)
        let repeatedBytes = try disk.read()
        precondition(story.state == solved && repeatedBytes == bytes)
        _ = try content.read(reward, versionID: version).get()
        _ = try content.preserve(reward, versionID: version).get()
        let saved = content.preservedItem("evidence.act3.banana_wall.scope_record.v1")!.record
        let reopened = StoryProgressionStore(persistence: disk)
        let reaccess = RestrictedAccessStore(progression: reopened, catalogue: .success(access.catalogue!))
        let restored = StoryContentStore(progression: reopened, catalogue: .success(content.catalogue!), access: reaccess)
        precondition(reaccess.resourceState("resource.banana_wall") == .unlocked)
        precondition(restored.preservedItem(saved.id)?.record.snapshot == saved.snapshot)
        precondition(reaccess.submit(id, fields: [:]) == .alreadyCompleted)
        if case .failure(.transitionNotConfigured) = reopened.advanceAct(to: .theTakeover) {} else { preconditionFailure() }
        // Placeholder/old access/test facts survive; none can substitute for new completion.
        var legacy = before
        legacy.solvedPuzzleIDs.insert("puzzle.banana_wall.pending_design")
        legacy.completedEventIDs.insert("event.puzzle.banana_wall.pending_design")
        legacy.accessMilestoneIDs.insert("access.banana_wall.breached")
        for schema in [1, 2] {
            var raw = try JSONSerialization.jsonObject(with: StorySaveCodec().encode(legacy)) as! [String: Any]
            raw["schemaVersion"] = schema
            if schema == 1 { raw.removeValue(forKey: "contentDelivery") }
            let old = StoryProgressionStore(persistence: InMemoryStoryPersistence(data: try JSONSerialization.data(withJSONObject: raw)))
            let oldAccess = RestrictedAccessStore(progression: old, catalogue: .success(access.catalogue!))
            _ = StoryContentStore(progression: old, catalogue: .success(content.catalogue!), access: oldAccess)
            precondition(oldAccess.resourceState("resource.banana_wall") == .locked)
            precondition(old.state.solvedPuzzleIDs.contains("puzzle.banana_wall.pending_design"))
            precondition(oldAccess.submit(id, fields: fields) == .completed && oldAccess.resourceState("resource.banana_wall") == .unlocked)
        }
        // An incomplete transaction's new markers fail closed rather than repairing access.
        var partial = before; partial.solvedPuzzleIDs.insert(id); partial.completedEventIDs.insert(puzzle.successEventID)
        let partialStore = StoryProgressionStore(persistence: InMemoryStoryPersistence(data: try StorySaveCodec().encode(partial)))
        let partialAccess = RestrictedAccessStore(progression: partialStore, catalogue: .success(access.catalogue!))
        _ = StoryContentStore(progression: partialStore, catalogue: .success(content.catalogue!), access: partialAccess)
        precondition(partialAccess.submit(id, fields: fields) == .rejected(.inconsistentCompletion))
        precondition(partialAccess.resourceState("resource.banana_wall") == .locked && partialStore.state == partial)
        let failing = WallFailingPersistence(data: try StorySaveCodec().encode(before))
        let failureStory = StoryProgressionStore(persistence: failing)
        let failureAccess = RestrictedAccessStore(progression: failureStory, catalogue: .success(access.catalogue!))
        _ = StoryContentStore(progression: failureStory, catalogue: .success(content.catalogue!), access: failureAccess)
        failing.fail = true
        if case .saveFailed(.persistenceFailed) = failureAccess.submit(id, fields: fields) {} else { preconditionFailure() }
        precondition(failureStory.state == before && failureAccess.resourceState("resource.banana_wall") == .locked)
        failing.fail = false; precondition(failureAccess.submit(id, fields: fields) == .completed)
        print("PASS: approved Wall clues, hints/draft neutrality, wrong/normalized answers, atomic scoped success, archives/reload, pending v1/v2 recovery and no Act 4")
    }

    @MainActor static func read(_ content: StoryContentStore, _ id: String) {
        guard let definition = content.catalogue?.itemsByID[id],
              let item = content.availableItems(for: definition.appSurface).first(where: { $0.id == id }) else { preconditionFailure("Unavailable source: " + id) }
        guard case .success(.changed) = content.read(id, versionID: item.version.id) else { preconditionFailure("Read failed: " + id) }
    }
    @MainActor static func finish(_ content: StoryContentStore, _ id: String) {
        guard let item = content.availableItems(for: .video).first(where: { $0.id == id }), case .video(let payload) = item.version.payload,
              let cues = payload.transcript, !cues.isEmpty else { preconditionFailure("Missing presentation") }
        var progress = StoryPresentationProgress()
        for _ in 1..<cues.count { progress.advance(count: cues.count) }
        guard case .success(.changed) = content.completePresentation(id, versionID: item.version.id, progress: progress) else { preconditionFailure("Presentation failed") }
    }
}
