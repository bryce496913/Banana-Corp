import Foundation

enum StoryContentAvailability: Equatable {
    case availableUnread, read, locked, hidden, removed, replaced(liveVersionID: String), preserved, unresolved
    var isAvailable: Bool { self == .availableUnread || self == .read }
}

struct DeliveredStoryContent: Identifiable, Equatable {
    let id: String
    let surface: StoryAppSurface
    let version: StoryContentVersion
    let availability: StoryContentAvailability
}

struct PreservedStoryContent: Identifiable {
    let record: PreservedEvidenceRecord
    let snapshot: StoryContentSnapshot
    var id: String { record.id }
    var availability: StoryContentAvailability { .preserved }
}

enum StoryContentDeliveryError: Error, Equatable {
    case catalogueUnavailable
    case unknownContent(String)
    case unknownVersion(String)
    case contentUnavailable
    case presentationIncomplete
    case staleVersion
    case definitionChanged(String)
    case invalidSnapshot
    case unknownEvidence(String)
    case progression(StoryActionError)
}
typealias StoryContentDeliveryResult = Result<StoryActionOutcome, StoryContentDeliveryError>

/// Immutable catalogue + the existing progression authority. No second saved state or event pump.
@MainActor final class StoryContentStore {
    let catalogue: StoryContentCatalogue?
    let loadDiagnostics: [StoryContentDiagnostic]
    private let progression: StoryProgressionStore
    private let access: RestrictedAccessStore?
    private let versionReceipts: [String: SavedContentVersion]
    private var queryState: StoryState?
    private var queryAuthorityRevision: UInt64?
    private var surfaceQueries: [StoryAppSurface: [DeliveredStoryContent]] = [:]

    init(progression: StoryProgressionStore, catalogue result: Result<StoryContentCatalogue, StoryContentLoadFailure>, access: RestrictedAccessStore? = nil) {
        self.progression = progression
        self.access = access
        switch result {
        case .success(let catalogue): self.catalogue = catalogue; loadDiagnostics = []
        case .failure(let error): catalogue = nil; loadDiagnostics = error.diagnostics
        }
        access?.validateContentReferences(self.catalogue)
        var receipts: [String: SavedContentVersion] = [:]
        let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys]
        for item in self.catalogue?.items ?? [] {
            for version in item.versions {
                if let bytes = try? encoder.encode(StoryContentSnapshot(schemaVersion: 1, contentID: item.id, appSurface: item.appSurface, version: version)) {
                    receipts[version.id] = SavedContentVersion(contentID: item.id, versionID: version.id, snapshot: bytes)
                }
            }
        }
        versionReceipts = receipts
    }

    func availableItems(for surface: StoryAppSurface, state: StoryState? = nil) -> [DeliveredStoryContent] {
        let state = state ?? progression.state
        guard progression.isWritable else { return [] }
        let revision = access?.contentReferenceRevision
        if queryState != state || queryAuthorityRevision != revision {
            queryState = state; queryAuthorityRevision = revision; surfaceQueries.removeAll(keepingCapacity: true)
        }
        if let cached = surfaceQueries[surface] { return cached }
        guard state.isValid else { return [] }
        let result: [DeliveredStoryContent] = (catalogue?.items ?? []).filter { $0.appSurface == surface }.compactMap { item in
            guard let version = currentVersion(for: item.id, state: state) else { return nil }
            let status = availability(for: item.id, versionID: version.id, state: state)
            return status.isAvailable ? DeliveredStoryContent(id: item.id, surface: surface, version: version, availability: status) : nil
        }
        surfaceQueries[surface] = result
        return result
    }

    func unreadCount(for surface: StoryAppSurface, state: StoryState? = nil) -> Int {
        availableItems(for: surface, state: state).filter { $0.availability == .availableUnread }.count
    }

    func currentVersion(for id: String, state: StoryState? = nil) -> StoryContentVersion? {
        guard let item = catalogue?.itemsByID[id], authorized(item, state: state ?? progression.state) else { return nil }
        let state = state ?? progression.state
        return resolvedVersion(item: item, versionID: state.contentDelivery.activeVersionIDs[id] ?? item.initialVersionID, state: state)
    }

    func originalVersion(for id: String, state: StoryState? = nil) -> StoryContentVersion? {
        guard let item = catalogue?.itemsByID[id], authorized(item, state: state ?? progression.state) else { return nil }
        return resolvedVersion(item: item, versionID: item.initialVersionID, state: state ?? progression.state)
    }

    func availability(for id: String, versionID: String? = nil, state: StoryState? = nil) -> StoryContentAvailability {
        let state = state ?? progression.state
        guard progression.isWritable, state.isValid, let item = catalogue?.itemsByID[id] else { return .unresolved }
        guard authorized(item, state: state) else { return .locked }
        let liveID = state.contentDelivery.activeVersionIDs[id] ?? item.initialVersionID
        guard resolvedVersion(item: item, versionID: liveID, state: state) != nil else { return .unresolved }
        if state.contentDelivery.unavailableContentIDs.contains(id) { return .removed }
        if item.visibility == .hiddenUntilRevealed && !state.contentDelivery.revealedContentIDs.contains(id) { return .hidden }
        guard state.currentAct.rawValue >= item.actAvailable.rawValue, (item.unlockConditions ?? []).allSatisfy({ $0.evaluate(in: state) }) else { return .locked }
        let requested = versionID ?? liveID
        guard resolvedVersion(item: item, versionID: requested, state: state) != nil else { return .unresolved }
        if id == FirstAnomalyContract.challenge {
            guard let record = state.preservedEvidence[FirstAnomalyContract.evidence],
                  record.sourceContentID == FirstAnomalyContract.originalContent,
                  record.sourceVersionID == FirstAnomalyContract.originalVersion,
                  validatedEvidence(record) != nil else { return .locked }
        }
        if id == ActTwoContract.assistantEvidenceChallenge {
            guard let record = state.preservedEvidence[ActTwoContract.warningEvidence],
                  record.sourceContentID == ActTwoContract.alex,
                  record.sourceVersionID == ActTwoContract.originalWarning,
                  validatedEvidence(record) != nil else { return .locked }
        }
        if requested != liveID { return .replaced(liveVersionID: liveID) }
        return state.readContentIDs.contains(requested) ? .read : .availableUnread
    }

    /// A local video presentation counts as viewed only after its final panel and explicit confirmation.
    /// Opening its row, preserving it or advancing a panel never emits a read.
    @discardableResult
    func completePresentation(_ id: String, versionID: String, progress: StoryPresentationProgress) -> StoryContentDeliveryResult {
        guard let version = currentVersion(for: id), version.id == versionID else { return .failure(.staleVersion) }
        guard case .video(let payload) = version.payload,
              progress.canComplete(count: payload.transcript?.count ?? 0) else { return .failure(.presentationIncomplete) }
        return read(id, versionID: versionID)
    }

    /// The UI must pass the version actually opened; stale list/detail selections cannot read a newer version.
    @discardableResult
    func read(_ id: String, versionID: String, conversation: DeviceConversationRequest? = nil) -> StoryContentDeliveryResult {
        if let error = recoveryError { return .failure(error) }
        guard let catalogue else { return .failure(.catalogueUnavailable) }
        guard let item = catalogue.itemsByID[id] else { return .failure(.unknownContent(id)) }
        guard catalogue.versionOwners[versionID] == id, let version = catalogue.versionsByID[versionID] else { return .failure(.unknownVersion(versionID)) }
        guard authorized(item, state: progression.state) else { return .failure(.contentUnavailable) }
        func appendConversation(to next: inout StoryState) throws {
            guard let conversation else { return }
            guard case .assistant(let payload) = version.payload else { throw StoryActionError.invalidRecord }
            var answer = payload.turns.filter { $0.role == .assistant }.map(\.text).joined(separator: "\n\n")
            // Repetition may add corporate resistance, never withhold an earned answer/read.
            if conversation.companyQuestion, (next.phoneLife?.companyQuestions ?? 0) >= 3,
               id != "content.device.assistant.pushback",
               let notice = currentVersion(for: "content.device.assistant.pushback"),
               availability(for: "content.device.assistant.pushback").isAvailable,
               case .assistant(let noticePayload) = notice.payload {
                answer += "\n\n" + noticePayload.turns.filter { $0.role == .assistant }.map(\.text).joined(separator: "\n\n")
            }
            try StoryProgressionStore.appendConversation(conversation, answer: answer, versionID: versionID, to: &next)
        }
        if progression.state.completedEventIDs.contains(version.readEventID) {
            guard conversation != nil else { return .success(.unchanged) }
            guard currentVersion(for: id)?.id == versionID, availability(for: id, versionID: versionID).isAvailable else { return .failure(.contentUnavailable) }
            return progression.transact { try appendConversation(to: &$0) }.mapError(StoryContentDeliveryError.progression)
        }
        guard currentVersion(for: id)?.id == versionID else { return .failure(.staleVersion) }
        guard availability(for: id, versionID: versionID).isAvailable else { return .failure(.contentUnavailable) }
        var staged = progression.state
        var actions: [StoryAction] = []
        do {
            func append(_ action: StoryAction) throws {
                try StoryProgressionStore.apply(action, to: &staged)
                actions.append(action)
            }
            try append(.rememberContentVersion(receipt(item: item, version: version, state: staged)))
            for contentID in [id, versionID] { try append(.discoverContent(contentID)); try append(.markContentRead(contentID)) }
            for (index, effect) in (version.effectsOnRead ?? []).enumerated() {
                switch effect {
                case .revealContent(let target): try append(.revealContent(target))
                case .markMilestone(let fact): try append(.recordMilestone(fact))
                case .recordClue(let fact): try append(.recordObserverClue(fact))
                case .recordAssistantFact(let fact): try append(.recordAssistantFact(fact))
                case .unlockRoute(let route): try append(.setAppAvailability(route, unlocked: true))
                case .makeUnavailable(let target): try append(.makeContentUnavailable(target))
                case .queueNotification(let target):
                    guard let targetItem = catalogue.itemsByID[target], targetItem.appSurface == .notifications,
                          let targetVersion = currentVersion(for: target, state: staged) else { throw StoryContentDeliveryError.unknownContent(target) }
                    try append(.rememberContentVersion(receipt(item: targetItem, version: targetVersion, state: staged)))
                    try append(.queueNotification(contentID: target, versionID: targetVersion.id))
                case .changeVersion(let target, let targetID):
                    guard let targetItem = catalogue.itemsByID[target], let old = currentVersion(for: target, state: staged),
                          let next = resolvedVersion(item: targetItem, versionID: targetID, state: staged) else { throw StoryContentDeliveryError.unknownVersion(targetID) }
                    if old.id == next.id { continue }
                    try append(.rememberContentVersion(receipt(item: targetItem, version: old, state: staged)))
                    try append(.rememberContentVersion(receipt(item: targetItem, version: next, state: staged)))
                    try append(.recordReplacement(ContentReplacementRecord(id: "replacement.\(versionID).e\(index)", contentID: target, originalVersionID: old.id, replacementVersionID: next.id)))
                    try append(.activateContentVersion(contentID: target, versionID: next.id))
                }
            }
            if conversation != nil {
                return progression.transact { next in
                    for action in actions { try StoryProgressionStore.apply(action, to: &next) }
                    next.completedEventIDs.insert(version.readEventID)
                    try appendConversation(to: &next)
                }.mapError(StoryContentDeliveryError.progression)
            }
            return progression.completeEvent(version.readEventID, actions: actions).mapError(StoryContentDeliveryError.progression)
        } catch let error as StoryContentDeliveryError { return .failure(error) }
        catch let error as StoryActionError { return .failure(.progression(error)) }
        catch { return .failure(.invalidSnapshot) }
    }

    @discardableResult
    func preserve(_ id: String, versionID: String, at date: Date = Date()) -> StoryContentDeliveryResult {
        if let error = recoveryError { return .failure(error) }
        // A repeated preservation never regenerates evidence from edited catalogue definitions.
        if let existing = progression.state.preservedEvidence.values.first(where: { $0.sourceContentID == id && $0.sourceVersionID == versionID }) {
            return validatedEvidence(existing) != nil ? .success(.unchanged) : .failure(.invalidSnapshot)
        }
        guard let item = catalogue?.itemsByID[id], let version = currentVersion(for: id), version.id == versionID,
              let evidenceID = version.preservedEvidenceID else { return .failure(.contentUnavailable) }
        guard availability(for: id, versionID: versionID).isAvailable else { return .failure(.contentUnavailable) }
        do {
            let receipt = try receipt(item: item, version: version, state: progression.state)
            let record = PreservedEvidenceRecord(id: evidenceID, sourceContentID: id, sourceVersionID: versionID, capturedAt: date, snapshot: receipt.snapshot)
            let eventID = "event.preserve." + evidenceID
            guard !progression.state.completedEventIDs.contains(eventID) else { return .failure(.invalidSnapshot) }
            var actions: [StoryAction] = [
                .rememberContentVersion(receipt), .discoverContent(id), .discoverContent(versionID), .preserveEvidence(record)
            ]
            if let clue = version.evidenceRules?.securedObserverClueID { actions.append(.recordObserverClue(clue)) }
            if let milestone = version.evidenceRules?.preservationMilestoneID { actions.append(.recordMilestone(milestone)) }
            return progression.completeEvent(eventID, actions: actions).mapError(StoryContentDeliveryError.progression)
        } catch { return .failure(.invalidSnapshot) }
    }

    func preservedItems(state: StoryState? = nil) -> [PreservedStoryContent] {
        (state ?? progression.state).preservedEvidence.values.sorted { $0.id < $1.id }.compactMap { record in
            validatedEvidence(record)
        }
    }

    func preservedItem(_ evidenceID: String) -> PreservedStoryContent? {
        progression.state.preservedEvidence[evidenceID].flatMap(validatedEvidence)
    }

    /// Includes unreadable records so the Vault never silently hides damaged evidence.
    func evidenceRecords() -> [PreservedEvidenceRecord] {
        progression.state.preservedEvidence.values.sorted { $0.capturedAt == $1.capturedAt ? $0.id < $1.id : $0.capturedAt > $1.capturedAt }
    }

    func isPreservable(_ id: String, versionID: String) -> Bool {
        guard progression.isWritable, let version = currentVersion(for: id), version.id == versionID,
              version.preservedEvidenceID != nil, availability(for: id, versionID: versionID).isAvailable else { return false }
        return true
    }

    /// The exact engaged version is retained even if its read effects switch/remove the live source.
    func engagedSnapshot(_ id: String, versionID: String) -> StoryContentSnapshot? {
        guard let item = catalogue?.itemsByID[id], authorized(item, state: progression.state) else { return nil }
        guard let record = progression.state.contentDelivery.versionReceipts[versionID], record.contentID == id,
              progression.state.readContentIDs.contains(versionID),
              let snapshot = try? JSONDecoder().decode(StoryContentSnapshot.self, from: record.snapshot), snapshot.schemaVersion == 1,
              snapshot.contentID == id, snapshot.version.id == versionID, snapshot.appSurface == snapshot.version.payload.surface else { return nil }
        return snapshot
    }

    func comparison(for evidenceID: String) -> Result<EvidenceComparison, StoryContentDeliveryError> {
        guard progression.state.preservedEvidence[evidenceID] != nil else { return .failure(.unknownEvidence(evidenceID)) }
        guard let preserved = preservedItem(evidenceID) else { return .failure(.invalidSnapshot) }
        let id = preserved.record.sourceContentID
        func unavailable(_ reason: EvidenceLiveUnavailable) -> Result<EvidenceComparison, StoryContentDeliveryError> {
            .success(EvidenceComparison(preserved: preserved, current: .unavailable(reason), differences: []))
        }
        guard progression.isWritable else { return unavailable(.saveUnavailable) }
        if progression.state.contentDelivery.unavailableContentIDs.contains(id) { return unavailable(.removed) }
        guard let catalogue else { return unavailable(.catalogueUnavailable) }
        guard let item = catalogue.itemsByID[id] else { return unavailable(.missingSource) }
        guard authorized(item, state: progression.state) else { return unavailable(.notAccessible) }
        let liveID = progression.state.contentDelivery.activeVersionIDs[id] ?? item.initialVersionID
        guard catalogue.versionOwners[liveID] == id else { return unavailable(.missingVersion) }
        guard let live = currentVersion(for: id) else { return unavailable(.unverifiedVersion) }
        guard availability(for: id, versionID: liveID).isAvailable else { return unavailable(.notAccessible) }
        return .success(EvidenceComparison(preserved: preserved, current: .live(live), differences: EvidenceComparison.differences(preserved: preserved.snapshot.version, live: live)))
    }

    /// Called by the explicit Compare action, never list rendering/view appearance.
    @discardableResult
    func recordComparison(_ evidenceID: String) -> StoryContentDeliveryResult {
        if let error = recoveryError { return .failure(error) }
        switch comparison(for: evidenceID) {
        case .failure(let error): return .failure(error)
        case .success(let comparison):
            if case .unavailable(let reason) = comparison.current, reason != .removed { return .failure(.contentUnavailable) }
            // A first unchanged comparison does not prevent a later changed comparison from earning its authored fact.
            let performedID = "event.compare." + evidenceID
            let changedID = "event.diff." + evidenceID
            var actions: [StoryAction] = [.recordEvidenceComparison(evidenceID: evidenceID, changed: comparison.hasVisibleDifferences)]
            if evidenceID == FirstAnomalyContract.evidence,
               comparison.preserved.record.sourceContentID == FirstAnomalyContract.originalContent,
               comparison.preserved.record.sourceVersionID == FirstAnomalyContract.originalVersion,
               progression.satisfies(.eventCompleted(FirstAnomalyContract.removalEvent)),
               case .unavailable(.removed) = comparison.current {
                actions.append(.recordMilestone(FirstAnomalyContract.investigated))
            }
            if comparison.hasVisibleDifferences, let milestone = comparison.preserved.snapshot.version.evidenceRules?.comparisonMilestoneID {
                actions.append(.recordMilestone(milestone))
            }
            let investigatesFirstAnomaly = actions.contains { action in
                if case .recordMilestone(let id) = action { return id == FirstAnomalyContract.investigated }
                return false
            }
            let eventID = investigatesFirstAnomaly ? "event.act1.first_anomaly.evidence_compared" : (comparison.hasVisibleDifferences ? changedID : performedID)
            return progression.completeEvent(eventID, actions: actions).mapError(StoryContentDeliveryError.progression)
        }
    }

    private func validatedEvidence(_ record: PreservedEvidenceRecord) -> PreservedStoryContent? {
        guard record.isValid, let snapshot = try? JSONDecoder().decode(StoryContentSnapshot.self, from: record.snapshot), snapshot.schemaVersion == 1,
              snapshot.contentID == record.sourceContentID, snapshot.version.id == record.sourceVersionID,
              snapshot.version.version > 0, !snapshot.version.title.isEmpty, snapshot.version.narrativeTimestamp?.isValid != false,
              snapshot.version.preservedEvidenceID == record.id, snapshot.version.payload.surface == snapshot.appSurface else { return nil }
        if let receipt = progression.state.contentDelivery.versionReceipts[record.sourceVersionID],
           !matches(SavedContentVersion(contentID: record.sourceContentID, versionID: record.sourceVersionID, snapshot: record.snapshot), expected: receipt) { return nil }
        return PreservedStoryContent(record: record, snapshot: snapshot)
    }

    func pendingNotifications(state: StoryState? = nil) -> [(record: QueuedStoryNotification, content: StoryContentVersion)] {
        let state = state ?? progression.state
        return state.contentDelivery.notifications.values.sorted { $0.sequence < $1.sequence }.compactMap { record in
            guard record.status == .pending, let version = currentVersion(for: record.contentID, state: state), version.id == record.versionID,
                  version.payload.surface == .notifications, availability(for: record.contentID, versionID: record.versionID, state: state).isAvailable else { return nil }
            return (record, version)
        }
    }

    @discardableResult
    func acknowledgeNotification(_ id: String) -> StoryContentDeliveryResult {
        progression.perform(.acknowledgeNotification(id)).mapError(StoryContentDeliveryError.progression)
    }

    func savedReferenceDiagnostics(state: StoryState? = nil) -> [StoryContentDiagnostic] {
        let state = state ?? progression.state
        guard let catalogue else { return loadDiagnostics }
        var issues: [StoryContentDiagnostic] = []
        func missing(_ id: String) { issues.append(.init(code: .savedReference, path: id, message: "Saved content reference is absent; progress was retained")) }
        for id in state.discoveredContentIDs.sorted() where catalogue.itemsByID[id] == nil && catalogue.versionsByID[id] == nil { missing(id) }
        for id in state.contentDelivery.revealedContentIDs.union(state.contentDelivery.unavailableContentIDs).sorted() where catalogue.itemsByID[id] == nil { missing(id) }
        for record in state.contentDelivery.versionReceipts.values.sorted(by: { $0.versionID < $1.versionID }) {
            guard catalogue.itemsByID[record.contentID] != nil, let version = catalogue.versionsByID[record.versionID], catalogue.versionOwners[record.versionID] == record.contentID else { missing(record.versionID); continue }
            if !matches(record, expected: versionReceipts[version.id]) { issues.append(.init(code: .definitionChanged, path: record.versionID, message: "Published version was edited; assign a new version ID")) }
        }
        let decodedEvidence = Set(preservedItems(state: state).map(\.id))
        for id in state.preservedEvidence.keys.sorted() where !decodedEvidence.contains(id) { issues.append(.init(code: .savedReference, path: id, message: "Unknown evidence snapshot format; original bytes were retained")) }
        return issues
    }

    private func authorized(_ item: StoryContentItem, state: StoryState) -> Bool {
        guard let resourceID = item.restrictedResourceID else { return true }
        return access?.resourceState(resourceID, state: state) == .unlocked
    }

    private var recoveryError: StoryContentDeliveryError? {
        if case .recoveryRequired(let issue) = progression.saveStatus { return .progression(.recoveryRequired(issue)) }
        return nil
    }

    private func resolvedVersion(item: StoryContentItem, versionID: String, state: StoryState) -> StoryContentVersion? {
        guard catalogue?.versionOwners[versionID] == item.id, let version = catalogue?.versionsByID[versionID] else { return nil }
        if let previous = state.contentDelivery.versionReceipts[versionID], !matches(previous, expected: versionReceipts[versionID]) { return nil }
        return version
    }

    private func receipt(item: StoryContentItem, version: StoryContentVersion, state: StoryState) throws -> SavedContentVersion {
        guard let expected = versionReceipts[version.id], expected.contentID == item.id else { throw StoryContentDeliveryError.invalidSnapshot }
        if let old = state.contentDelivery.versionReceipts[version.id] {
            guard matches(old, expected: expected) else { throw StoryContentDeliveryError.definitionChanged(version.id) }
            return old
        }
        return expected
    }

    private func matches(_ actual: SavedContentVersion, expected: SavedContentVersion?) -> Bool {
        guard let expected, actual.contentID == expected.contentID, actual.versionID == expected.versionID else { return false }
        if actual.snapshot == expected.snapshot { return true }
        // Encoder formatting may vary across SDKs. Compare typed values, retaining original bytes.
        guard let first = try? JSONDecoder().decode(StoryContentSnapshot.self, from: actual.snapshot),
              let second = try? JSONDecoder().decode(StoryContentSnapshot.self, from: expected.snapshot) else { return false }
        return first == second
    }
}

// MARK: - First mystery slice
extension StoryContentStore {
    /// Called only at a real return-to-inbox/Home boundary, never by a timer or a read callback.
    /// Every delivery fact commits together; a read receipt is not a preserved evidence copy.
    @discardableResult
    func activateFirstAnomalyAtBoundary() -> StoryContentDeliveryResult {
        if let error = recoveryError { return .failure(error) }
        if progression.state.completedEventIDs.contains(FirstAnomalyContract.removalEvent) { return .success(.unchanged) }
        guard progression.state.currentAct == .thePerfectProduct,
              progression.satisfies(FirstAnomalyContract.removalPrerequisites) else { return .failure(.progression(.prerequisitesNotMet)) }
        guard let item = catalogue?.itemsByID[FirstAnomalyContract.originalContent],
              let original = currentVersion(for: item.id), original.id == FirstAnomalyContract.originalVersion,
              availability(for: item.id, versionID: original.id).isAvailable else { return .failure(.contentUnavailable) }
        do {
            var actions: [StoryAction] = [.rememberContentVersion(try receipt(item: item, version: original, state: progression.state)),
                                         .makeContentUnavailable(item.id)]
            for id in [FirstAnomalyContract.trace, FirstAnomalyContract.warning, FirstAnomalyContract.notification] {
                guard let target = catalogue?.itemsByID[id], let version = currentVersion(for: id) else { return .failure(.unknownContent(id)) }
                let expectedSurface: StoryAppSurface = id == FirstAnomalyContract.trace ? .email : (id == FirstAnomalyContract.warning ? .messages : .notifications)
                guard version.payload.surface == expectedSurface else { return .failure(.invalidSnapshot) }
                actions.append(.rememberContentVersion(try receipt(item: target, version: version, state: progression.state)))
                actions.append(.revealContent(id))
                if id == FirstAnomalyContract.notification {
                    guard version.payload.surface == .notifications else { return .failure(.invalidSnapshot) }
                    actions.append(.queueNotification(contentID: id, versionID: version.id))
                }
            }
            return progression.completeEvent(FirstAnomalyContract.removalEvent, actions: actions,
                                             when: FirstAnomalyContract.removalPrerequisites).mapError(StoryContentDeliveryError.progression)
        } catch let error as StoryContentDeliveryError { return .failure(error) }
        catch { return .failure(.invalidSnapshot) }
    }

    /// At-most-once cosmetic delivery is consumed durably before drawing; the warning itself remains unread.
    @discardableResult
    func consumeFirstAnomalyPresentation() -> StoryContentDeliveryResult {
        guard let queued = progression.state.contentDelivery.notifications.values.first(where: { $0.contentID == FirstAnomalyContract.notification }) else { return .failure(.contentUnavailable) }
        return progression.completeEvent(FirstAnomalyContract.presentationEvent,
            actions: [.recordFirstGlitch, .acknowledgeNotification(queued.id)],
            when: .eventCompleted(FirstAnomalyContract.removalEvent)).mapError(StoryContentDeliveryError.progression)
    }

    var firstAnomalyHandoffAvailable: Bool {
        progression.state.currentAct == .thePerfectProduct && progression.satisfies(FirstAnomalyContract.handoffPrerequisites)
    }

    #if DEBUG
    /// Replays real catalogue actions after an explicit debug reset, without bypassing prerequisites.
    func debugReplayFirstAnomaly(preserving: Bool) -> StoryContentDeliveryResult {
        let news = "content.act1.news.interface"
        guard let newsVersion = currentVersion(for: news), let promo = currentVersion(for: "content.act1.promo"),
              case .video(let payload) = promo.payload else { return .failure(.contentUnavailable) }
        if case .failure(let error) = read(news, versionID: newsVersion.id) { return .failure(error) }
        var panels = StoryPresentationProgress()
        let count = payload.transcript?.count ?? 0
        for _ in 1..<max(1, count) { panels.advance(count: count) }
        if case .failure(let error) = completePresentation("content.act1.promo", versionID: promo.id, progress: panels) { return .failure(error) }
        if case .failure(let error) = read(FirstAnomalyContract.originalContent, versionID: FirstAnomalyContract.originalVersion) { return .failure(error) }
        if preserving, case .failure(let error) = preserve(FirstAnomalyContract.originalContent, versionID: FirstAnomalyContract.originalVersion) { return .failure(error) }
        return activateFirstAnomalyAtBoundary()
    }
    #endif
}

// MARK: - Act 2 source changes and explicit synthesis
extension StoryContentStore {
    /// Surface-scoped return boundaries preserve the opportunity to inspect/save an original.
    /// Home uses nil scope. Each source change is a separate validated atomic, idempotent event.
    @discardableResult
    func activateActTwoChangesAtBoundary(surface: StoryAppSurface? = nil) -> StoryContentDeliveryResult {
        if let error = recoveryError { return .failure(error) }
        guard progression.state.currentAct == .somethingIsntRight else { return .success(.unchanged) }
        guard let catalogue else { return .failure(.catalogueUnavailable) }
        var changed = false
        for change in ActTwoContract.changes {
            guard !progression.state.completedEventIDs.contains(change.eventID),
                  progression.satisfies(change.prerequisites) else { continue }
            guard let item = catalogue.itemsByID[change.contentID] else { return .failure(.unknownContent(change.contentID)) }
            if let surface, item.appSurface != surface { continue }
            guard (catalogue.declaredFacts["eventCompleted"] ?? []).contains(change.eventID),
                  let original = currentVersion(for: item.id), original.id == change.originalVersionID,
                  availability(for: item.id, versionID: original.id).isAvailable else { return .failure(.contentUnavailable) }
            do {
                var actions: [StoryAction] = [.rememberContentVersion(try receipt(item: item, version: original, state: progression.state))]
                if let replacementID = change.replacementVersionID {
                    guard let replacement = resolvedVersion(item: item, versionID: replacementID, state: progression.state) else { return .failure(.unknownVersion(replacementID)) }
                    actions += [.rememberContentVersion(try receipt(item: item, version: replacement, state: progression.state)),
                                .recordReplacement(.init(id: "replacement." + change.eventID, contentID: item.id,
                                                       originalVersionID: original.id, replacementVersionID: replacement.id)),
                                .activateContentVersion(contentID: item.id, versionID: replacement.id)]
                } else { actions.append(.makeContentUnavailable(item.id)) }
                if let milestone = change.milestoneID {
                    guard (catalogue.declaredFacts["milestoneCompleted"] ?? []).contains(milestone) else { return .failure(.invalidSnapshot) }
                    actions.append(.recordMilestone(milestone))
                }
                // The initial Alex explanation is no longer offered after its source changes.
                if change.contentID == ActTwoContract.alex {
                    guard catalogue.itemsByID["content.act2.assistant.alex_original"] != nil else { return .failure(.unknownContent("content.act2.assistant.alex_original")) }
                    actions.append(.makeContentUnavailable("content.act2.assistant.alex_original"))
                }
                switch progression.completeEvent(change.eventID, actions: actions, when: change.prerequisites) {
                case .success(.changed): changed = true
                case .success(.unchanged): break
                case .failure(let error): return .failure(.progression(error))
                }
            } catch let error as StoryContentDeliveryError { return .failure(error) }
            catch { return .failure(.invalidSnapshot) }
        }
        return .success(changed ? .changed : .unchanged)
    }

    var actTwoConfirmationAvailable: Bool {
        progression.state.currentAct == .somethingIsntRight && progression.satisfies(ActTwoContract.confirmationPrerequisites)
            && currentVersion(for: ActTwoContract.alex)?.id == ActTwoContract.replacementWarning
    }
    var actThreeHandoffAvailable: Bool {
        progression.state.currentAct == .somethingIsntRight && progression.satisfies(ActTwoContract.handoffPrerequisites)
    }
    @discardableResult
    func confirmActTwoInvestigation() -> StoryContentDeliveryResult {
        if let error = recoveryError { return .failure(error) }
        if progression.state.completedEventIDs.contains(ActTwoContract.confirmationEvent) { return .success(.unchanged) }
        guard actTwoConfirmationAvailable else { return .failure(.progression(.prerequisitesNotMet)) }
        guard let item = catalogue?.itemsByID[ActTwoContract.summary], item.appSurface == .web,
              let version = currentVersion(for: item.id),
              (catalogue?.declaredFacts["eventCompleted"] ?? []).contains(ActTwoContract.confirmationEvent),
              (catalogue?.declaredFacts["milestoneCompleted"] ?? []).contains(ActTwoContract.connected) else { return .failure(.contentUnavailable) }
        do {
            return progression.completeEvent(ActTwoContract.confirmationEvent,
                actions: [.rememberContentVersion(try receipt(item: item, version: version, state: progression.state)),
                          .revealContent(item.id), .recordMilestone(ActTwoContract.connected)],
                when: ActTwoContract.confirmationPrerequisites).mapError(StoryContentDeliveryError.progression)
        } catch { return .failure(.invalidSnapshot) }
    }

    var actFourHandoffAvailable: Bool {
        guard progression.state.currentAct == .theConspiracy,
              progression.satisfies(ActThreeHandoffContract.prerequisites),
              let item = catalogue?.itemsByID[ActThreeHandoffContract.entry], item.actAvailable == .theTakeover,
              let resourceID = item.restrictedResourceID else { return false }
        var entryState = progression.state
        entryState.currentAct = .theTakeover
        return access?.resourceState(resourceID, state: entryState) == .unlocked
    }
    @discardableResult
    func beginActFour() -> StoryContentDeliveryResult {
        if let error = recoveryError { return .failure(error) }
        if progression.state.currentAct == .theTakeover { return .success(.unchanged) }
        guard actFourHandoffAvailable else { return .failure(.progression(.prerequisitesNotMet)) }
        return progression.advanceAct(to: .theTakeover).mapError(StoryContentDeliveryError.progression)
    }
    var actFourEntry: DeliveredStoryContent? {
        availableItems(for: .web).first { $0.id == ActThreeHandoffContract.entry }
    }

    var autonomyConfirmationAvailable: Bool {
        researchConfirmationAvailable(ActThreeInvestigationContract.autonomySources)
    }
    var publicRestrictedConfirmationAvailable: Bool {
        progression.state.completedMilestoneIDs.contains("milestone.act3.energy_harvesting_evidence_discovered")
            && researchConfirmationAvailable(ActThreeInvestigationContract.contradictionSources)
    }
    private func researchConfirmationAvailable(_ sources: [String]) -> Bool {
        guard progression.state.currentAct == .theConspiracy,
              progression.satisfies(ActThreeInvestigationContract.prerequisites(for: sources)),
              let catalogue else { return false }
        return sources.allSatisfy { id in
            guard let owner = catalogue.versionOwners[id], let item = catalogue.itemsByID[owner],
                  currentVersion(for: owner)?.id == id,
                  progression.state.contentDelivery.versionReceipts[id] != nil else { return false }
            return authorized(item, state: progression.state)
        }
    }
    @discardableResult
    func confirmEchoAutonomy() -> StoryContentDeliveryResult {
        confirmResearch(event: ActThreeInvestigationContract.autonomyEvent,
                        milestone: ActThreeInvestigationContract.autonomy,
                        sources: ActThreeInvestigationContract.autonomySources,
                        available: autonomyConfirmationAvailable)
    }
    @discardableResult
    func confirmPublicRestrictedContradiction() -> StoryContentDeliveryResult {
        confirmResearch(event: ActThreeInvestigationContract.contradictionEvent,
                        milestone: ActThreeInvestigationContract.contradiction,
                        sources: ActThreeInvestigationContract.contradictionSources,
                        available: publicRestrictedConfirmationAvailable)
    }
    private func confirmResearch(event: String, milestone: String, sources: [String], available: Bool) -> StoryContentDeliveryResult {
        if let error = recoveryError { return .failure(error) }
        guard let catalogue,
              (catalogue.declaredFacts["eventCompleted"] ?? []).contains(event),
              (catalogue.declaredFacts["milestoneCompleted"] ?? []).contains(milestone) else { return .failure(.contentUnavailable) }
        if progression.state.completedEventIDs.contains(event) { return .success(.unchanged) }
        guard available else { return .failure(.progression(.prerequisitesNotMet)) }
        return progression.completeEvent(event, actions: [.recordMilestone(milestone)],
            when: ActThreeInvestigationContract.prerequisites(for: sources)).mapError(StoryContentDeliveryError.progression)
    }

    /// One already-available next question; never opens or reads a source automatically.
    var actThreeSuggestedLead: DeliveredStoryContent? {
        guard progression.state.currentAct == .theConspiracy else { return nil }
        for id in ["content.act3.autonomy.actions", "content.act3.autonomy.maya", "content.act3.ascension.recording",
                   "content.act3.ascension.purpose", "content.act3.energy.transfer", "content.act3.energy.growth",
                   "content.act3.daniel.contribution", "content.act3.daniel.concealment", "content.act3.maya.guidance",
                   "content.act3.observer.program", "content.act3.observer.session", "content.act3.conclusion.resistance"] {
            guard let item = catalogue?.itemsByID[id],
                  let delivered = availableItems(for: item.appSurface).first(where: { $0.id == id }),
                  delivered.availability == .availableUnread else { continue }
            return delivered
        }
        return nil
    }

    /// Mandatory Observer knowledge is a milestone, never a hidden-clue/ending award.
    /// Show only earlier sources supported by actual saved discoveries, not assumed chronology.
    var observerKnownSources: [DeliveredStoryContent] {
        guard progression.state.completedMilestoneIDs.contains("milestone.act3.observer_connection_discovered") else { return [] }
        let references: [(String, StoryCondition)] = [
            (FirstAnomalyContract.trace, .all([.milestoneCompleted(FirstAnomalyContract.suspiciousMaterial),
                                             .eventCompleted(FirstAnomalyContract.removalEvent)])),
            (FirstAnomalyContract.warning, .contentRead(FirstAnomalyContract.warningVersion)),
            ("content.act2.messages.daniel", .milestoneCompleted(ActTwoContract.danielFollowed)),
            ("content.act2.diagnostics.excerpt", .milestoneCompleted(ActTwoContract.diagnosticsRead)),
            ("content.act3.banana_wall.scope_record", .contentRead("version.act3.banana_wall.scope_record.v1"))
        ]
        return references.compactMap { id, condition in
            guard progression.satisfies(condition), let item = catalogue?.itemsByID[id] else { return nil }
            return availableItems(for: item.appSurface).first { $0.id == id }
        }
    }
    var observerOriginalEvidenceAvailable: Bool {
        guard progression.state.completedMilestoneIDs.contains("milestone.act3.observer_connection_discovered"),
              let saved = preservedItem(FirstAnomalyContract.evidence) else { return false }
        return saved.record.sourceContentID == FirstAnomalyContract.originalContent
            && saved.record.sourceVersionID == FirstAnomalyContract.originalVersion
    }

    /// A catalogue-backed next lead is guidance, never an automatic read/unlock.
    var actTwoSuggestedLead: DeliveredStoryContent? {
        guard progression.state.currentAct == .somethingIsntRight else { return nil }
        let state = progression.state
        var id: String?
        if !state.completedMilestoneIDs.contains(ActTwoContract.warningViewed) { id = ActTwoContract.alex }
        else if !state.completedEventIDs.contains(ActTwoContract.alexReplaced) { return nil }
        else if !state.completedMilestoneIDs.contains(ActTwoContract.replacementViewed) { id = ActTwoContract.alex }
        else if !state.completedMilestoneIDs.contains(ActTwoContract.symptomsInvestigated) { id = "content.act2.news.concerns" }
        else if !state.completedMilestoneIDs.contains(ActTwoContract.officialRead) { id = "content.act2.news.official" }
        else if !state.completedMilestoneIDs.contains(ActTwoContract.danielFollowed) { id = "content.act2.messages.daniel" }
        else if !state.completedMilestoneIDs.contains(ActTwoContract.mayaFollowed) { id = "content.act2.email.maya" }
        else if !state.completedMilestoneIDs.contains(ActTwoContract.echoRead) { id = "content.act2.web.echo07" }
        else if !state.completedMilestoneIDs.contains(ActTwoContract.diagnosticsRead) { id = "content.act2.diagnostics.excerpt" }
        else if !state.completedMilestoneIDs.contains(ActTwoContract.savedCompared) && !state.completedMilestoneIDs.contains(ActTwoContract.independentRead) { id = "content.act2.news.corroboration" }
        else if !state.assistant.relationshipFacts.contains(ActTwoContract.assistantQuestioned) { id = "content.act2.assistant.edits" }
        else if state.completedEventIDs.contains(ActTwoContract.confirmationEvent) { id = ActTwoContract.summary }
        guard let id, let item = catalogue?.itemsByID[id] else { return nil }
        return availableItems(for: item.appSurface).first { $0.id == id }
    }
}

// MARK: - Approved Act 4 resistance, fixed takeover and explicit Act 5 handoff
extension StoryContentStore {
    private func actFourSourcesInspected(_ sources: [String]) -> Bool {
        guard progression.state.currentAct == .theTakeover,
              progression.satisfies(ActFourContract.inspected(sources)), let catalogue else { return false }
        return sources.allSatisfy { versionID in
            guard let contentID = catalogue.versionOwners[versionID], let item = catalogue.itemsByID[contentID],
                  currentVersion(for: contentID)?.id == versionID,
                  let remembered = progression.state.contentDelivery.versionReceipts[versionID] else { return false }
            return authorized(item, state: progression.state) && matches(remembered, expected: versionReceipts[versionID])
        }
    }

    private func actFourActionAvailable(_ sources: [String], prerequisites: StoryCondition, event: String) -> Bool {
        !progression.state.completedEventIDs.contains(event) && progression.satisfies(prerequisites)
            && actFourSourcesInspected(sources)
    }

    var valeComparisonAvailable: Bool {
        actFourActionAvailable(ActFourContract.valeSources + ["version.act4.signal.packet.v1"],
            prerequisites: ActFourContract.inspected(ActFourContract.valeSources), event: ActFourContract.valeEvent)
    }
    var rootAuthorizationAvailable: Bool {
        actFourActionAvailable(ActFourContract.valeSources + ["version.act4.signal.packet.v1"],
            prerequisites: ActFourContract.rootPrerequisites, event: ActFourContract.rootEvent)
    }
    var deploymentVerificationAvailable: Bool {
        actFourActionAvailable(["version.act4.signal.packet.v1", "version.act4.deployment.relay.v1"],
            prerequisites: ActFourContract.deploymentPrerequisites, event: ActFourContract.deploymentEvent)
    }
    var lanternAuthorizationAvailable: Bool {
        actFourActionAvailable(["version.act4.signal.packet.v1", "version.act4.lantern.protocol.v1"],
            prerequisites: ActFourContract.lanternPrerequisites, event: ActFourContract.lanternEvent)
    }
    var takeoverConfirmationAvailable: Bool {
        actFourActionAvailable(ActFourContract.takeoverSources,
            prerequisites: ActFourContract.takeoverPrerequisites, event: ActFourContract.takeoverEvent)
    }

    private func commitActFourAction(event: String, prerequisites: StoryCondition, available: Bool,
                                    facts: [(String, String)], completion: StoryCondition,
                                    actions: [StoryAction]) -> StoryContentDeliveryResult {
        if let error = recoveryError { return .failure(error) }
        guard let catalogue, (catalogue.declaredFacts["eventCompleted"] ?? []).contains(event),
              facts.allSatisfy({ (catalogue.declaredFacts[$0.0] ?? []).contains($0.1) }) else { return .failure(.contentUnavailable) }
        if progression.state.completedEventIDs.contains(event) {
            return progression.satisfies(completion) ? .success(.unchanged) : .failure(.invalidSnapshot)
        }
        guard available else { return .failure(.progression(.prerequisitesNotMet)) }
        return progression.completeEvent(event, actions: actions, when: prerequisites).mapError(StoryContentDeliveryError.progression)
    }

    @discardableResult
    func compareValeRecords() -> StoryContentDeliveryResult {
        commitActFourAction(event: ActFourContract.valeEvent,
            prerequisites: ActFourContract.inspected(ActFourContract.valeSources), available: valeComparisonAvailable,
            facts: [("milestoneCompleted", ActFourContract.valeCompared)],
            completion: .milestoneCompleted(ActFourContract.valeCompared),
            actions: [.recordMilestone(ActFourContract.valeCompared)])
    }
    @discardableResult
    func obtainRootAuthorization() -> StoryContentDeliveryResult {
        commitActFourAction(event: ActFourContract.rootEvent, prerequisites: ActFourContract.rootPrerequisites,
            available: rootAuthorizationAvailable, facts: [("routePrerequisite", ActFourContract.rootAuthorization)],
            completion: .routePrerequisite(ActFourContract.rootAuthorization),
            actions: [.recordRoutePrerequisite(ActFourContract.rootAuthorization)])
    }
    @discardableResult
    func verifyDeploymentChannel() -> StoryContentDeliveryResult {
        commitActFourAction(event: ActFourContract.deploymentEvent, prerequisites: ActFourContract.deploymentPrerequisites,
            available: deploymentVerificationAvailable, facts: [("routePrerequisite", ActFourContract.deploymentChannel)],
            completion: .routePrerequisite(ActFourContract.deploymentChannel),
            actions: [.recordRoutePrerequisite(ActFourContract.deploymentChannel)])
    }
    @discardableResult
    func authorizeLanternSafetyAccess() -> StoryContentDeliveryResult {
        commitActFourAction(event: ActFourContract.lanternEvent, prerequisites: ActFourContract.lanternPrerequisites,
            available: lanternAuthorizationAvailable,
            facts: [("accessGranted", ActFourContract.lanternAccess), ("routePrerequisite", ActFourContract.neuralSignature),
                    ("milestoneCompleted", ActFourContract.lanternAuthorized)],
            completion: .all([.accessGranted(ActFourContract.lanternAccess), .routePrerequisite(ActFourContract.neuralSignature),
                              .milestoneCompleted(ActFourContract.lanternAuthorized)]),
            actions: [.grantAccess(ActFourContract.lanternAccess), .recordRoutePrerequisite(ActFourContract.neuralSignature),
                      .recordMilestone(ActFourContract.lanternAuthorized)])
    }
    @discardableResult
    func confirmTakeoverEvidence() -> StoryContentDeliveryResult {
        let result = commitActFourAction(event: ActFourContract.takeoverEvent, prerequisites: ActFourContract.takeoverPrerequisites,
            available: takeoverConfirmationAvailable, facts: [("milestoneCompleted", ActFourContract.takeoverConnected)],
            completion: .milestoneCompleted(ActFourContract.takeoverConnected),
            actions: [.recordAscension(.init(id: ActFourContract.ascension, percentage: 87)),
                      .recordMilestone(ActFourContract.takeoverConnected)])
        if case .success = result, progression.state.ascensionMilestone != AscensionMilestone(id: ActFourContract.ascension, percentage: 87) {
            return .failure(.invalidSnapshot)
        }
        return result
    }

    var actFiveHandoffAvailable: Bool {
        guard progression.state.currentAct == .theTakeover,
              progression.state.ascensionMilestone == AscensionMilestone(id: ActFourContract.ascension, percentage: 87),
              progression.satisfies(ActFourContract.handoffPrerequisites),
              actFourSourcesInspected(ActFourContract.takeoverSources + ["version.act4.echo.address.v1"]),
              let item = catalogue?.itemsByID[ActFourContract.finalEntry], item.actAvailable == .theFinalChoice,
              let resourceID = item.restrictedResourceID else { return false }
        var finalState = progression.state
        finalState.currentAct = .theFinalChoice
        return access?.resourceState(resourceID, state: finalState) == .unlocked
    }
    @discardableResult
    func beginActFive() -> StoryContentDeliveryResult {
        if let error = recoveryError { return .failure(error) }
        if progression.state.currentAct == .theFinalChoice { return .success(.unchanged) }
        guard actFiveHandoffAvailable else { return .failure(.progression(.prerequisitesNotMet)) }
        return progression.advanceAct(to: .theFinalChoice).mapError(StoryContentDeliveryError.progression)
    }

    /// Guidance exposes one actually available unread record; no passive mutation.
    var actFourSuggestedLead: DeliveredStoryContent? {
        guard progression.state.currentAct == .theTakeover else { return nil }
        let ordered = ["content.act4.entry", ActFourContract.signal, "content.act4.vale.authorization", "content.act4.vale.loss",
            "content.act4.deployment.relay", "content.act4.lantern.protocol", "content.act4.maya.signature",
            "content.act4.assistant.conflict.safety", "content.act4.assistant.conflict.core", ActFourContract.echoAddress]
        for id in ordered {
            guard let item = catalogue?.itemsByID[id], let delivered = availableItems(for: item.appSurface).first(where: { $0.id == id }),
                  delivered.availability == .availableUnread else { continue }
            return delivered
        }
        return nil
    }
    var actFiveEntry: DeliveredStoryContent? {
        availableItems(for: .web).first { $0.id == ActFourContract.finalEntry }
    }
}
