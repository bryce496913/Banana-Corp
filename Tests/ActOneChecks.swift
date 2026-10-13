import Foundation

@main struct ActOneChecks {
    @MainActor static func main() throws {
        let resource = URL(fileURLWithPath: CommandLine.arguments[1])
        let catalogue = StoryContentCatalogueLoader.load(fileURL: resource)
        let definitions = try catalogue.get()
        precondition(definitions.items.filter { $0.actAvailable == .thePerfectProduct }.count == 25)
        precondition(definitions.items.filter { $0.actAvailable == .thePerfectProduct }.allSatisfy { $0.versions.count == 1 })
        precondition(definitions.items.filter { $0.actAvailable == .thePerfectProduct }.allSatisfy { $0.id.hasPrefix("content.act1.") })
        // A restarted executable must resolve exactly the previously saved production versions.
        if CommandLine.arguments.count == 4 {
            let story = StoryProgressionStore(persistence: StoryFilePersistence(fileURL: URL(fileURLWithPath: CommandLine.arguments[3])))
            let store = StoryContentStore(progression: story, catalogue: catalogue)
            if CommandLine.arguments[2] == "write" {
                engage(store, "news.interface")
                engage(store, "promo")
                engage(store, "echo_review")
                expect(store.preserve("content.act1.echo_review", versionID: "version.act1.echo_review.v1"), .changed)
                engage(store, "messages.welcome")
                engage(store, "assistant.vision")
                print("PASS: Act 1 facts, reads and original email snapshot saved immediately")
            } else {
                precondition(story.state.completedMilestoneIDs.contains("milestone.act1.first_suspicious_material"))
                precondition(store.unreadCount(for: .messages) == 0)
                precondition(store.unreadCount(for: .email) == 1)
                let saved = store.preservedItem("evidence.act1.echo_review.v1")!
                precondition(saved.snapshot.version.title == "RE: Project ECHO — Internal Review")
                precondition(saved.record.sourceVersionID == "version.act1.echo_review.v1")
                let before = story.state
                engage(store, "echo_review", outcome: .unchanged)
                expect(store.preserve("content.act1.echo_review", versionID: saved.record.sourceVersionID), .unchanged)
                precondition(story.state == before && store.preservedItems().count == 1)
                precondition(story.state.currentAct.rawValue == 1)
                print("PASS: separate-process relaunch retained exact email, readiness, reads and idempotency")
            }
            return
        }
        let story = StoryProgressionStore(persistence: InMemoryStoryPersistence())
        let store = StoryContentStore(progression: story, catalogue: catalogue)
        let initial = story.state
        for surface in StoryAppSurface.allCases { _ = store.availableItems(for: surface); _ = store.unreadCount(for: surface) }
        precondition(story.state == initial, "List rendering must never read or progress story")
        precondition(store.availableItems(for: .news).count == 3)
        precondition(store.availableItems(for: .social).count == 5)
        precondition(store.availableItems(for: .assistant).count == 6)
        precondition(store.unreadCount(for: .email) == 1 && store.unreadCount(for: .messages) == 1)
        precondition(store.availability(for: "content.act1.echo_review") == .locked)
        expectFailure(store.read("content.act1.echo_review", versionID: "version.act1.echo_review.v1"), .contentUnavailable)
        expectFailure(store.preserve("content.act1.echo_review", versionID: "version.act1.echo_review.v1"), .contentUnavailable)
        engage(store, "product")
        engage(store, "assistant.navigation")
        engage(store, "messages.welcome")
        precondition(store.unreadCount(for: .messages) == 0)
        precondition(store.availability(for: "content.act1.echo_review") == .locked)
        engage(store, "news.launch")
        precondition(story.state.completedMilestoneIDs.contains("milestone.act1.news_context"))
        precondition(store.availability(for: "content.act1.echo_review") == .locked)
        // No media asset or invented playback length. Five inspected panels + explicit Finish.
        let promotion = store.currentVersion(for: "content.act1.promo")!
        guard case .video(let video) = promotion.payload else { preconditionFailure() }
        precondition(video.mediaAssetID == nil && video.durationSeconds == nil)
        let count = video.transcript!.count
        var progress = StoryPresentationProgress()
        expectFailure(store.completePresentation("content.act1.promo", versionID: promotion.id, progress: progress), .presentationIncomplete)
        precondition(!progress.canComplete(count: 0) && !progress.canComplete(count: count))
        for _ in 1..<count { progress.advance(count: count) }
        precondition(progress.canComplete(count: count))
        progress.goBack(); precondition(!progress.canComplete(count: count)); progress.advance(count: count)
        precondition(!story.state.completedMilestoneIDs.contains("milestone.act1.promo_viewed"))
        expect(store.completePresentation("content.act1.promo", versionID: promotion.id, progress: progress), .changed)
        precondition(store.availableItems(for: .email).count == 2)
        precondition(!story.state.completedMilestoneIDs.contains("milestone.act1.first_suspicious_material"))
        let email = store.currentVersion(for: "content.act1.echo_review")!
        guard case .email(let correspondence) = email.payload else { preconditionFailure() }
        precondition(correspondence.blocks.last?.text == "— D.")
        expect(store.preserve("content.act1.echo_review", versionID: email.id), .changed)
        precondition(!story.state.completedMilestoneIDs.contains("milestone.act1.first_suspicious_material"))
        engage(store, "echo_review")
        let after = story.state
        precondition(after.completedMilestoneIDs.contains("milestone.act1.first_suspicious_material"))
        precondition(after.currentAct.rawValue == 1 && after.contentReplacements.isEmpty)
        precondition(after.contentDelivery.unavailableContentIDs.isEmpty && after.contentDelivery.notifications.isEmpty)
        precondition(after.observerClueIDs.isEmpty && after.solvedPuzzleIDs.isEmpty)
        precondition(store.pendingNotifications().isEmpty)
        engage(store, "echo_review", outcome: .unchanged)
        precondition(story.state == after)
        for response in store.availableItems(for: .assistant) {
            guard case .assistant(let data) = response.version.payload else { preconditionFailure() }
            precondition(data.turns.last?.role == .assistant && !data.turns.last!.text.isEmpty)
            precondition(data.turns.count <= 2)
            let expected: StoryActionOutcome = story.state.readContentIDs.contains(response.version.id) ? .unchanged : .changed
            expect(store.read(response.id, versionID: response.version.id), expected)
        }
        engage(store, "vr_preview")
        precondition(story.state.completedEventIDs.contains("event.read.version.act1.vr_preview.v1"))
        precondition(story.state.completedMilestoneIDs.contains("milestone.act1.vr_preview_engaged"))
        precondition(story.state.currentAct.rawValue == 1)
        if case .failure = story.advanceAct(to: StoryAct(rawValue: 2)!) {} else { preconditionFailure("Act 2 must stay gated before the mystery loop") }
        for act in StoryAct.allCases where act.rawValue > 1 {
            if case .failure = story.advanceAct(to: act) {} else { preconditionFailure("No later act unlock") }
        }
        // Any launch-date/calendar or time-zone change must leave availability untouched.
        let dates = [Date(timeIntervalSince1970: 0), Date(timeIntervalSince1970: 2_000_000_000)]
        for date in dates {
            for zone in ["UTC", "Pacific/Kiritimati", "America/Los_Angeles"] {
                let context = StoryTimeContext(deviceTime: date, timeZoneIdentifier: zone, story: initial.time)
                precondition(context.label(for: StoryContentTime.launchDay) == .tomorrow)
                precondition(StoryContentTime.label(for: definitions.versionsByID["version.act1.welcome.v1"]!, context: context) == "Today · 09:41")
            }
        }
        let publicBytes = try JSONEncoder().encode(definitions.items.filter { $0.actAvailable == .thePerfectProduct })
        let text = String(decoding: publicBytes, as: UTF8.self).lowercased()
        for spoiler in ["daniel mercer", "maya chen", "alexrivera", "ascension", "echo_core", "observer", "harvesting", "brainwashing", "sentient", "blackout", "lantern"] {
            precondition(!text.contains(spoiler), "Premature disclosure: \(spoiler)")
        }
        // Alternative ordering works: promo before any article, with no optional-app gate.
        let secondStory = StoryProgressionStore(persistence: InMemoryStoryPersistence())
        let secondStore = StoryContentStore(progression: secondStory, catalogue: catalogue)
        engage(secondStore, "promo")
        precondition(secondStore.availability(for: "content.act1.echo_review") == .locked)
        engage(secondStore, "news.influence")
        precondition(secondStore.availability(for: "content.act1.echo_review") == .availableUnread)
        precondition(secondStory.state.readContentIDs.count == 4)
        print("PASS: production content, passive queries, either-order prerequisites, presentation steps, local links, conversations, offline Assistant, authentic preservation, time independence and spoiler/act boundaries")
    }
    @MainActor static func engage(_ store: StoryContentStore, _ key: String, outcome: StoryActionOutcome = .changed) {
        let contentID = "content.act1." + key
        let versionID = "version.act1." + key + ".v1"
        if key == "promo", case .video(let payload) = store.currentVersion(for: contentID)?.payload {
            var progress = StoryPresentationProgress()
            let count = payload.transcript?.count ?? 0
            for _ in 1..<max(1, count) { progress.advance(count: count) }
            expect(store.completePresentation(contentID, versionID: versionID, progress: progress), outcome)
        } else {
            expect(store.read(contentID, versionID: versionID), outcome)
        }
    }
    static func expect(_ result: StoryContentDeliveryResult, _ expected: StoryActionOutcome) {
        guard case .success(let value) = result, value == expected else { preconditionFailure("Unexpected delivery result: \(result)") }
    }
    static func expectFailure(_ result: StoryContentDeliveryResult, _ expected: StoryContentDeliveryError) {
        guard case .failure(let value) = result, value == expected else { preconditionFailure("Unexpected error: \(result)") }
    }
}
