import Foundation

enum RestrictedResourceState: Equatable { case hidden, locked, unlocked, unresolved }
enum PuzzleAvailability: Equatable { case hidden, locked, awaitingApproval, ready, completed, unresolved }
enum PuzzleRejection: Equatable { case unknownPuzzle, inaccessible, awaitingApproval, invalidFields, incorrectAnswer, inconsistentCompletion }
enum PuzzleSubmissionResult: Equatable {
    case completed, alreadyCompleted
    case rejected(PuzzleRejection)
    case saveFailed(StoryActionError)
}

/// A stateless authorizer/validator over the single saved progression authority.
@MainActor final class RestrictedAccessStore {
    let catalogue: RestrictedAccessCatalogue?
    private(set) var diagnostics: [String]
    private let progression: StoryProgressionStore
    private var referencesValid = true

    init(progression: StoryProgressionStore, catalogue: Result<RestrictedAccessCatalogue, RestrictedAccessFailure>) {
        self.progression = progression
        switch catalogue {
        case .success(let value):
            self.catalogue = value; diagnostics = []
            referencesValid = value.resources.allSatisfy { $0.linkedContentIDs.isEmpty }
                && (value.declaredFacts["contentRead"] ?? []).isEmpty && (value.declaredFacts["contentDiscovered"] ?? []).isEmpty
        case .failure(let failure): self.catalogue = nil; diagnostics = failure.diagnostics
        }
    }
    /// The two catalogues must agree on every protected link; missing/incorrect references fail closed.
    func validateContentReferences(_ content: StoryContentCatalogue?) {
        guard let catalogue else { return }
        var failures: [String] = []
        for resource in catalogue.resources {
            for id in resource.linkedContentIDs {
                guard let item = content?.itemsByID[id], item.restrictedResourceID == resource.id else { failures.append("Invalid protected content link: " + id); continue }
            }
        }
        for item in content?.items ?? [] {
            if let resourceID = item.restrictedResourceID,
               catalogue.resourcesByID[resourceID]?.linkedContentIDs.contains(item.id) != true { failures.append("Unregistered protected content: " + item.id) }
        }
        for id in (catalogue.declaredFacts["contentRead"] ?? []) + (catalogue.declaredFacts["contentDiscovered"] ?? []) {
            if content?.itemsByID[id] == nil && content?.versionsByID[id] == nil { failures.append("Missing prerequisite content: " + id) }
        }
        referencesValid = failures.isEmpty
        diagnostics = failures.sorted()
    }
    func resourceState(_ id: String, state: StoryState? = nil) -> RestrictedResourceState {
        let state = state ?? progression.state
        guard progression.isWritable, state.isValid, referencesValid, let resource = catalogue?.resourcesByID[id] else { return .unresolved }
        guard state.currentAct.rawValue >= resource.availableAct.rawValue,
              resource.discoveryConditions.allSatisfy({ $0.evaluate(in: state) }) else { return .hidden }
        if let puzzleID = resource.requiredPuzzleID {
            guard let puzzle = catalogue?.puzzlesByID[puzzleID], puzzle.rule.kind != .awaitingApproval,
                  state.solvedPuzzleIDs.contains(puzzleID), state.completedEventIDs.contains(puzzle.successEventID) else { return .locked }
        }
        return state.accessMilestoneIDs.contains(resource.requiredAccessID) && resource.unlockConditions.allSatisfy({ $0.evaluate(in: state) }) ? .unlocked : .locked
    }
    func visibleResources() -> [RestrictedResource] {
        (catalogue?.resources ?? []).filter { resource in
            let status = resourceState(resource.id)
            return status == .unlocked || (status == .locked && resource.visibility == .entry)
        }
    }
    func puzzleAvailability(_ id: String) -> PuzzleAvailability {
        guard progression.isWritable, referencesValid, let puzzle = catalogue?.puzzlesByID[id] else { return .unresolved }
        let state = progression.state
        guard state.currentAct.rawValue >= puzzle.availableAct.rawValue else { return .hidden }
        if puzzle.rule.kind == .awaitingApproval { return .awaitingApproval }
        let solved = state.solvedPuzzleIDs.contains(id), completed = state.completedEventIDs.contains(puzzle.successEventID)
        if solved != completed { return .unresolved }
        if solved { return .completed }
        return puzzle.requirements.allSatisfy { $0.evaluate(in: state) } ? .ready : .locked
    }
    func submit(_ id: String, fields: [String: String]) -> PuzzleSubmissionResult {
        guard let puzzle = catalogue?.puzzlesByID[id] else { return .rejected(.unknownPuzzle) }
        if !progression.isWritable, case .recoveryRequired(let issue) = progression.saveStatus { return .saveFailed(.recoveryRequired(issue)) }
        switch puzzleAvailability(id) {
        case .completed: return .alreadyCompleted
        case .awaitingApproval: return .rejected(.awaitingApproval)
        case .ready: break
        case .unresolved: return .rejected(.inconsistentCompletion)
        default: return .rejected(.inaccessible)
        }
        guard Set(fields.keys) == Set(puzzle.inputs.map(\.id)), fields.values.allSatisfy({ $0.utf8.count <= 256 }) else { return .rejected(.invalidFields) }
        func normalize(_ value: String) -> String {
            var value = value.precomposedStringWithCanonicalMapping
            if puzzle.rule.trimWhitespace == true { value = value.trimmingCharacters(in: .whitespacesAndNewlines) }
            if puzzle.rule.caseInsensitive == true { value = value.lowercased() }
            return value
        }
        guard let expected = puzzle.rule.expectedFields, expected.allSatisfy({ normalize(fields[$0.key] ?? "") == normalize($0.value) }) else { return .rejected(.incorrectAnswer) }
        let actions: [StoryAction] = [.completePuzzle(id)] + puzzle.successEffects.map(\.action)
        let condition = puzzle.requirements.isEmpty ? nil : StoryCondition.all(puzzle.requirements)
        switch progression.completeEvent(puzzle.successEventID, actions: actions, when: condition) {
        case .success(.changed): return .completed
        case .success(.unchanged): return .alreadyCompleted
        case .failure(let failure): return .saveFailed(failure)
        }
    }
}
