import Foundation
import Observation

enum StoryAction {
    case discoverContent(String)
    case markContentRead(String)
    case preserveEvidence(PreservedEvidenceRecord)
    case recordReplacement(ContentReplacementRecord)
    case completePuzzle(String)
    case grantAccess(String)
    case recordMilestone(String)
    case recordAssistantFact(String)
    case setAssistantCooperation(AssistantCooperation)
    case recordAscension(AscensionMilestone)
    case recordRoutePrerequisite(String)
    case recordObserverClue(String)
    case setAppAvailability(PhoneAppRoute, unlocked: Bool)
    case recordVRAppOpened
    case recordFirstGlitch
    case configureTime(StoryTimeState)
    case revealContent(String)
    case makeContentUnavailable(String)
    case rememberContentVersion(SavedContentVersion)
    case activateContentVersion(contentID: String, versionID: String)
    case queueNotification(contentID: String, versionID: String)
    case acknowledgeNotification(String)
    case recordEvidenceComparison(evidenceID: String, changed: Bool)
}

enum StoryActionError: Error, Equatable {
    case invalidIdentifier(String)
    case invalidRecord
    case contentNotDiscovered(String)
    case conflictingRecord(String)
    case prerequisitesNotMet
    case invalidCondition
    case invalidActTransition
    case transitionNotConfigured
    case invalidTransitionRule
    case recoveryRequired(StorySaveIssue)
    case persistenceFailed(String)
}

enum StoryActionOutcome: Equatable { case changed, unchanged }
typealias StoryActionResult = Result<StoryActionOutcome, StoryActionError>

enum StorySaveStatus: Equatable {
    case ready
    case migrated(from: Int)
    /// State is unavailable (defaults only for safe queries); do not treat it as a fresh campaign.
    case recoveryRequired(StorySaveIssue)
}

@MainActor @Observable
final class StoryProgressionStore {
    private(set) var state = StoryState()
    private(set) var saveStatus: StorySaveStatus = .ready
    @ObservationIgnored private let persistence: any StoryPersistence
    @ObservationIgnored private let codec: StorySaveCodec
    @ObservationIgnored private let rules: StoryProgressionRules
    @ObservationIgnored private var hasAttemptedLoad = false
    /// Bridges this store's changes to the existing ObservableObject OS without copying state.
    @ObservationIgnored var onStateWillChange: (@MainActor () -> Void)?
    @ObservationIgnored var onStateDidChange: (@MainActor () -> Void)?

    init(persistence: any StoryPersistence = StoryFilePersistence.applicationDefault,
         rules: StoryProgressionRules = .production, codec: StorySaveCodec = StorySaveCodec()) {
        self.persistence = persistence
        self.rules = rules
        self.codec = codec
        _ = load()
    }

    var isWritable: Bool {
        if case .recoveryRequired = saveStatus { return false }
        return true
    }

    func satisfies(_ condition: StoryCondition) -> Bool {
        isWritable && condition.evaluate(in: state)
    }

    /// Retrying a load is explicit. Invalid saves remain untouched and writes are blocked.
    @discardableResult
    func load() -> StoryActionResult {
        let firstLoad = !hasAttemptedLoad
        hasAttemptedLoad = true
        do {
            if let data = try persistence.read() {
                let loaded = try codec.decode(data)
                if loaded.migratedFrom != nil { try persistence.write(codec.encode(loaded.state)) }
                onStateWillChange?()
                state = loaded.state
                saveStatus = loaded.migratedFrom.map { .migrated(from: $0) } ?? .ready
                onStateDidChange?()
            } else {
                // A missing file after progress was loaded is a recovery problem, not a reset.
                guard firstLoad else { throw StorySaveIssue.missingSave }
                try persistence.write(codec.encode(state))
                onStateWillChange?()
                saveStatus = .ready
            }
            return .success(.changed)
        } catch {
            let issue = (error as? StorySaveIssue) ?? .ioFailure(String(describing: error))
            onStateWillChange?()
            saveStatus = .recoveryRequired(issue)
            return .failure(.recoveryRequired(issue))
        }
    }

    @discardableResult
    func save() -> StoryActionResult {
        if case .recoveryRequired(let issue) = saveStatus { return .failure(.recoveryRequired(issue)) }
        do {
            try persistence.write(codec.encode(state))
            return .success(.unchanged)
        } catch { return .failure(.persistenceFailed(String(describing: error))) }
    }

    /// An explicit new game archives any existing bytes, including corrupt/newer-schema saves.
    @discardableResult
    func resetForNewGame() -> StoryActionResult {
        do {
            let fresh = StoryState()
            let bytes = try codec.encode(fresh)
            try persistence.archiveForReset()
            try persistence.write(bytes)
            onStateWillChange?()
            state = fresh
            saveStatus = .ready
            onStateDidChange?()
            return .success(.changed)
        } catch { return .failure(.persistenceFailed(String(describing: error))) }
    }

    @discardableResult
    func perform(_ action: StoryAction, when condition: StoryCondition? = nil) -> StoryActionResult {
        transact(when: condition) { try Self.apply(action, to: &$0) }
    }

    /// All event effects and the delivery ID commit together; retries never redeliver effects.
    @discardableResult
    func completeEvent(_ id: String, actions: [StoryAction], when condition: StoryCondition? = nil) -> StoryActionResult {
        if !StoryID.isValid(id) { return .failure(.invalidIdentifier(id)) }
        if !isWritable, case .recoveryRequired(let issue) = saveStatus { return .failure(.recoveryRequired(issue)) }
        if state.completedEventIDs.contains(id) { return .success(.unchanged) }
        return transact(when: condition) { next in
            for action in actions { try Self.apply(action, to: &next) }
            next.completedEventIDs.insert(id)
        }
    }

    @discardableResult
    func advanceAct(to act: StoryAct) -> StoryActionResult {
        transact { next in
            guard act.rawValue == next.currentAct.rawValue + 1 else { throw StoryActionError.invalidActTransition }
            guard let rule = rules.actTransitions[act] else { throw StoryActionError.transitionNotConfigured }
            guard rule.isValid else { throw StoryActionError.invalidTransitionRule }
            guard rule.requiredMilestoneIDs.isSubset(of: next.completedMilestoneIDs), rule.condition.evaluate(in: next) else {
                throw StoryActionError.prerequisitesNotMet
            }
            next.currentAct = act
        }
    }

    private func transact(when condition: StoryCondition? = nil, mutation: (inout StoryState) throws -> Void) -> StoryActionResult {
        if case .recoveryRequired(let issue) = saveStatus { return .failure(.recoveryRequired(issue)) }
        if let condition {
            guard condition.isWellFormed() else { return .failure(.invalidCondition) }
            guard condition.evaluate(in: state) else { return .failure(.prerequisitesNotMet) }
        }
        var next = state
        do { try mutation(&next) }
        catch let error as StoryActionError { return .failure(error) }
        catch { return .failure(.invalidRecord) }
        guard next.isValid else { return .failure(.invalidRecord) }
        guard next != state else { return .success(.unchanged) }
        do { try persistence.write(codec.encode(next)) }
        catch { return .failure(.persistenceFailed(String(describing: error))) }
        // Save succeeds before the new facts become observable. Failures leave memory intact.
        onStateWillChange?()
        state = next
        saveStatus = .ready
        onStateDidChange?()
        return .success(.changed)
    }

    private static func requireID(_ id: String) throws {
        guard StoryID.isValid(id) else { throw StoryActionError.invalidIdentifier(id) }
    }

    /// Shared by declarative delivery staging and the final atomic transaction.
    static func apply(_ action: StoryAction, to state: inout StoryState) throws {
        switch action {
        case .discoverContent(let id):
            try requireID(id); state.discoveredContentIDs.insert(id)
        case .markContentRead(let id):
            try requireID(id)
            guard state.discoveredContentIDs.contains(id) else { throw StoryActionError.contentNotDiscovered(id) }
            state.readContentIDs.insert(id)
        case .preserveEvidence(let record):
            guard record.isValid else { throw StoryActionError.invalidRecord }
            for id in [record.sourceContentID, record.sourceVersionID] where !state.discoveredContentIDs.contains(id) {
                throw StoryActionError.contentNotDiscovered(id)
            }
            if let old = state.preservedEvidence.values.first(where: { $0.sourceContentID == record.sourceContentID && $0.sourceVersionID == record.sourceVersionID }), old != record {
                throw StoryActionError.conflictingRecord(record.id)
            }
            if let old = state.preservedEvidence[record.id], old != record { throw StoryActionError.conflictingRecord(record.id) }
            state.preservedEvidence[record.id] = record
        case .recordReplacement(let record):
            guard record.isValid else { throw StoryActionError.invalidRecord }
            if let old = state.contentReplacements[record.id], old != record { throw StoryActionError.conflictingRecord(record.id) }
            state.contentReplacements[record.id] = record
        case .completePuzzle(let id):
            try requireID(id); state.solvedPuzzleIDs.insert(id)
        case .grantAccess(let id):
            try requireID(id); state.accessMilestoneIDs.insert(id)
        case .recordMilestone(let id):
            try requireID(id); state.completedMilestoneIDs.insert(id)
        case .recordAssistantFact(let id):
            try requireID(id); state.assistant.relationshipFacts.insert(id)
        case .setAssistantCooperation(let cooperation): state.assistant.cooperation = cooperation
        case .recordAscension(let milestone):
            guard milestone.isValid else { throw StoryActionError.invalidRecord }
            state.ascensionMilestone = milestone
        case .recordRoutePrerequisite(let id):
            try requireID(id); state.routePrerequisiteIDs.insert(id)
        case .recordObserverClue(let id):
            try requireID(id); state.observerClueIDs.insert(id)
        case .setAppAvailability(let route, let unlocked):
            guard unlocked || route != .settings else { throw StoryActionError.invalidRecord }
            if unlocked { state.lockedAppIDs.remove(route.rawValue) }
            else { state.lockedAppIDs.insert(route.rawValue) }
        case .recordVRAppOpened: state.compatibility.hasOpenedVRApp = true
        case .recordFirstGlitch: state.compatibility.hasSeenFirstGlitch = true
        case .configureTime(let time):
            guard time.isValid else { throw StoryActionError.invalidRecord }
            state.time = time
        case .revealContent(let id):
            try requireID(id); state.contentDelivery.revealedContentIDs.insert(id)
        case .makeContentUnavailable(let id):
            try requireID(id); state.contentDelivery.unavailableContentIDs.insert(id)
        case .rememberContentVersion(let record):
            guard record.isValid else { throw StoryActionError.invalidRecord }
            if let old = state.contentDelivery.versionReceipts[record.versionID], old != record { throw StoryActionError.conflictingRecord(record.versionID) }
            state.contentDelivery.versionReceipts[record.versionID] = record
        case .activateContentVersion(let id, let versionID):
            try requireID(id); try requireID(versionID)
            guard state.contentDelivery.versionReceipts[versionID]?.contentID == id else { throw StoryActionError.invalidRecord }
            state.contentDelivery.activeVersionIDs[id] = versionID
        case .queueNotification(let id, let versionID):
            guard state.contentDelivery.versionReceipts[versionID]?.contentID == id else { throw StoryActionError.invalidRecord }
            let notificationID = "notification." + versionID
            try requireID(notificationID)
            if let old = state.contentDelivery.notifications[notificationID] {
                guard old.contentID == id && old.versionID == versionID else { throw StoryActionError.conflictingRecord(notificationID) }
            } else {
                let last = state.contentDelivery.notifications.values.map(\.sequence).max() ?? -1
                guard last < Int.max else { throw StoryActionError.invalidRecord }
                state.contentDelivery.notifications[notificationID] = QueuedStoryNotification(id: notificationID, contentID: id, versionID: versionID, sequence: last + 1)
            }
            state.contentDelivery.revealedContentIDs.insert(id)
        case .acknowledgeNotification(let id):
            try requireID(id)
            guard state.contentDelivery.notifications[id] != nil else { throw StoryActionError.invalidRecord }
            state.contentDelivery.notifications[id]?.status = .delivered
        case .recordEvidenceComparison(let evidenceID, let changed):
            guard state.preservedEvidence[evidenceID] != nil else { throw StoryActionError.invalidRecord }
            let performedID = "event.compare." + evidenceID
            try requireID(performedID); state.completedEventIDs.insert(performedID)
            if changed {
                let changedID = "event.diff." + evidenceID
                try requireID(changedID); state.completedEventIDs.insert(changedID)
            }
        }
    }
}
