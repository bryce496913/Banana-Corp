import Foundation

indirect enum StoryCondition: Equatable {
    case contentDiscovered(String)
    case contentRead(String)
    case evidencePreserved(String)
    case puzzleSolved(String)
    case accessGranted(String)
    case milestoneCompleted(String)
    case actReached(StoryAct)
    case assistantCooperation(AssistantCooperation)
    case assistantFact(String)
    case observerClueFound(String)
    case routePrerequisite(String)
    case eventCompleted(String)
    case all([StoryCondition])
    case any([StoryCondition])

    func isWellFormed(depth: Int = 0) -> Bool {
        guard depth < 32 else { return false }
        switch self {
        case .actReached, .assistantCooperation: return true
        case .contentDiscovered(let id), .contentRead(let id), .evidencePreserved(let id),
             .puzzleSolved(let id), .accessGranted(let id), .milestoneCompleted(let id),
             .assistantFact(let id), .observerClueFound(let id), .routePrerequisite(let id), .eventCompleted(let id):
            return StoryID.isValid(id)
        case .all(let conditions), .any(let conditions):
            return !conditions.isEmpty && conditions.allSatisfy { $0.isWellFormed(depth: depth + 1) }
        }
    }

    func evaluate(in state: StoryState) -> Bool {
        guard isWellFormed() else { return false }
        return evaluateValidated(in: state)
    }

    private func evaluateValidated(in state: StoryState) -> Bool {
        switch self {
        case .contentDiscovered(let id): return state.discoveredContentIDs.contains(id)
        case .contentRead(let id): return state.readContentIDs.contains(id)
        case .evidencePreserved(let id): return state.preservedEvidence[id] != nil
        case .puzzleSolved(let id): return state.solvedPuzzleIDs.contains(id)
        case .accessGranted(let id): return state.accessMilestoneIDs.contains(id)
        case .milestoneCompleted(let id): return state.completedMilestoneIDs.contains(id)
        case .actReached(let act): return state.currentAct.rawValue >= act.rawValue
        case .assistantCooperation(let fact): return state.assistant.cooperation == fact
        case .assistantFact(let id): return state.assistant.relationshipFacts.contains(id)
        case .observerClueFound(let id): return state.observerClueIDs.contains(id)
        case .routePrerequisite(let id): return state.routePrerequisiteIDs.contains(id)
        case .eventCompleted(let id): return state.completedEventIDs.contains(id)
        case .all(let conditions): return conditions.allSatisfy { $0.evaluateValidated(in: state) }
        case .any(let conditions): return conditions.contains { $0.evaluateValidated(in: state) }
        }
    }
}

struct StoryActTransition {
    let requiredMilestoneIDs: Set<String>
    let condition: StoryCondition

    var isValid: Bool {
        !requiredMilestoneIDs.isEmpty && requiredMilestoneIDs.allSatisfy(StoryID.isValid) && condition.isWellFormed()
    }
}

struct StoryProgressionRules {
    let actTransitions: [StoryAct: StoryActTransition]
    // Only the user-approved first mystery handoff is configured; later acts remain closed.
    static let production = StoryProgressionRules(actTransitions: [
        .somethingIsntRight: StoryActTransition(
            requiredMilestoneIDs: [FirstAnomalyContract.investigated, FirstAnomalyContract.suspiciousMaterial],
            condition: FirstAnomalyContract.handoffPrerequisites)
    ])
}

/// Approved Pass 6 IDs and prerequisites. This is a contract, never a second state store.
enum FirstAnomalyContract {
    static let originalContent = "content.act1.echo_review"
    static let originalVersion = "version.act1.echo_review.v1"
    static let evidence = "evidence.act1.echo_review.v1"
    static let trace = "content.act1.first_anomaly.trace"
    static let warning = "content.act1.first_anomaly.warning"
    static let warningVersion = "version.act1.first_anomaly.warning.v1"
    static let denial = "content.act1.first_anomaly.denial"
    static let challenge = "content.act1.first_anomaly.challenge"
    static let notification = "content.act1.first_anomaly.notification"
    static let removalEvent = "event.act1.first_anomaly.email_removed"
    static let presentationEvent = "event.act1.first_anomaly.presentation_consumed"
    static let investigated = "milestone.act1.first_contradiction_investigated"
    static let suspiciousMaterial = "milestone.act1.first_suspicious_material"
    static let assistantQuestioned = "assistant.act1.first_anomaly_questioned"
    static let removalPrerequisites: StoryCondition = .all([
        .actReached(.thePerfectProduct),
        .milestoneCompleted("milestone.act1.news_context"),
        .milestoneCompleted("milestone.act1.promo_viewed"),
        .milestoneCompleted(suspiciousMaterial), .contentRead(originalVersion)
    ])
    static let handoffPrerequisites: StoryCondition = .all([
        removalPrerequisites, .eventCompleted(removalEvent), .contentRead(warningVersion),
        .assistantFact(assistantQuestioned), .milestoneCompleted(investigated)
    ])
}
