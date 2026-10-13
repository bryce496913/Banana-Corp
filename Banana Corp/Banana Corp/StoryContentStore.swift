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
    private let versionReceipts: [String: SavedContentVersion]

    init(progression: StoryProgressionStore, catalogue result: Result<StoryContentCatalogue, StoryContentLoadFailure>) {
        self.progression = progression
        switch result {
        case .success(let catalogue): self.catalogue = catalogue; loadDiagnostics = []
        case .failure(let error): catalogue = nil; loadDiagnostics = error.diagnostics
        }
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
        guard progression.isWritable, state.isValid else { return [] }
        return (catalogue?.items ?? []).filter { $0.appSurface == surface }.compactMap { item in
            guard let version = currentVersion(for: item.id, state: state) else { return nil }
            let status = availability(for: item.id, versionID: version.id, state: state)
            return status.isAvailable ? DeliveredStoryContent(id: item.id, surface: surface, version: version, availability: status) : nil
        }
    }

    func unreadCount(for surface: StoryAppSurface, state: StoryState? = nil) -> Int {
        availableItems(for: surface, state: state).filter { $0.availability == .availableUnread }.count
    }

    func currentVersion(for id: String, state: StoryState? = nil) -> StoryContentVersion? {
        guard let item = catalogue?.itemsByID[id] else { return nil }
        let state = state ?? progression.state
        return resolvedVersion(item: item, versionID: state.contentDelivery.activeVersionIDs[id] ?? item.initialVersionID, state: state)
    }

    func originalVersion(for id: String, state: StoryState? = nil) -> StoryContentVersion? {
        guard let item = catalogue?.itemsByID[id] else { return nil }
        return resolvedVersion(item: item, versionID: item.initialVersionID, state: state ?? progression.state)
    }

    func availability(for id: String, versionID: String? = nil, state: StoryState? = nil) -> StoryContentAvailability {
        let state = state ?? progression.state
        guard progression.isWritable, state.isValid, let item = catalogue?.itemsByID[id] else { return .unresolved }
        let liveID = state.contentDelivery.activeVersionIDs[id] ?? item.initialVersionID
        guard resolvedVersion(item: item, versionID: liveID, state: state) != nil else { return .unresolved }
        if state.contentDelivery.unavailableContentIDs.contains(id) { return .removed }
        if item.visibility == .hiddenUntilRevealed && !state.contentDelivery.revealedContentIDs.contains(id) { return .hidden }
        guard state.currentAct.rawValue >= item.actAvailable.rawValue, (item.unlockConditions ?? []).allSatisfy({ $0.evaluate(in: state) }) else { return .locked }
        let requested = versionID ?? liveID
        guard resolvedVersion(item: item, versionID: requested, state: state) != nil else { return .unresolved }
        if requested != liveID { return .replaced(liveVersionID: liveID) }
        return state.readContentIDs.contains(requested) ? .read : .availableUnread
    }

    /// The UI must pass the version actually opened; stale list/detail selections cannot read a newer version.
    @discardableResult
    func read(_ id: String, versionID: String) -> StoryContentDeliveryResult {
        if let error = recoveryError { return .failure(error) }
        guard let catalogue else { return .failure(.catalogueUnavailable) }
        guard let item = catalogue.itemsByID[id] else { return .failure(.unknownContent(id)) }
        guard catalogue.versionOwners[versionID] == id, let version = catalogue.versionsByID[versionID] else { return .failure(.unknownVersion(versionID)) }
        if progression.state.completedEventIDs.contains(version.readEventID) { return .success(.unchanged) }
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
            if comparison.hasVisibleDifferences, let milestone = comparison.preserved.snapshot.version.evidenceRules?.comparisonMilestoneID {
                actions.append(.recordMilestone(milestone))
            }
            return progression.completeEvent(comparison.hasVisibleDifferences ? changedID : performedID, actions: actions).mapError(StoryContentDeliveryError.progression)
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
