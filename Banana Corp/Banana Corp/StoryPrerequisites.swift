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
    // No approved milestone lists yet. Production cannot advance beyond Act 1.
    static let production = StoryProgressionRules(actTransitions: [:])
}
