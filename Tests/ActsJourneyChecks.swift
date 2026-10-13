import Foundation

/// Model-level journey only. No debug replay, injected milestones or act shortcuts.
@main struct ActsJourneyChecks {
    @MainActor static func main() throws {
        let source = URL(fileURLWithPath: CommandLine.arguments[1])
        let accessResult = RestrictedAccessCatalogueLoader.load(data: try Data(contentsOf: source.appendingPathComponent("RestrictedAccess.json")))
        let catalogue = StoryContentCatalogueLoader.load(fileURL: source.appendingPathComponent("StoryContent.json"), restrictedResourceIDs: Set(try accessResult.get().resources.map(\.id)))
        for email in [false, true] {
            for video in [false, true] {
                let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
                defer { try? FileManager.default.removeItem(at: directory) }
                let disk = StoryFilePersistence(fileURL: directory.appendingPathComponent("story-save.json"))
                var story = StoryProgressionStore(persistence: disk)
                var access = RestrictedAccessStore(progression: story, catalogue: accessResult)
                var content = StoryContentStore(progression: story, catalogue: catalogue, access: access)
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
                print("PASS MODEL ONLY: email=\(email), video=\(video), \(checkpoints) exact file-store reopen checkpoints, natural catalogue actions to locked Banana Wall; no Apple UI execution")
            }
        }
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
