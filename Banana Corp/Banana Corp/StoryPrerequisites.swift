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
    // Approved consecutive handoffs through Act 4 entry; Act 5 stays closed.
    static let production = StoryProgressionRules(actTransitions: [
        .somethingIsntRight: StoryActTransition(
            requiredMilestoneIDs: [FirstAnomalyContract.investigated, FirstAnomalyContract.suspiciousMaterial],
            condition: FirstAnomalyContract.handoffPrerequisites),
        .theConspiracy: StoryActTransition(requiredMilestoneIDs: [ActTwoContract.connected],
                                          condition: ActTwoContract.handoffPrerequisites),
        .theTakeover: StoryActTransition(requiredMilestoneIDs: ActThreeHandoffContract.requiredMilestones,
                                        condition: ActThreeHandoffContract.prerequisites)
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

struct StorySourceChange {
    let eventID: String
    let contentID: String
    let originalVersionID: String
    let replacementVersionID: String?
    let prerequisites: StoryCondition
    let milestoneID: String?
}

/// Pass 7 authored contracts; all mutable facts remain in StoryProgressionStore.
enum ActTwoContract {
    static let alex = "content.act2.alex_review"
    static let originalWarning = "version.act2.alex_review.v1"
    static let replacementWarning = "version.act2.alex_review.v2"
    static let warningEvidence = "evidence.act2.alex_review.v1"
    static let alexReplaced = "event.act2.alex_review.replaced"
    static let warningViewed = "milestone.act2.warning_viewed"
    static let replacementViewed = "milestone.act2.replacement_inspected"
    static let symptomsInvestigated = "milestone.act2.symptom_reports_investigated"
    static let officialRead = "milestone.act2.official_response_read"
    static let danielFollowed = "milestone.act2.daniel_lead_followed"
    static let mayaFollowed = "milestone.act2.maya_lead_followed"
    static let echoRead = "milestone.act2.echo07_findings_read"
    static let diagnosticsRead = "milestone.act2.diagnostics_examined"
    static let independentRead = "milestone.act2.independent_record_read"
    static let savedCompared = "milestone.act2.saved_warning_compared"
    static let assistantQuestioned = "assistant.act2.edits_questioned"
    static let assistantEvidenceChallenge = "content.act2.assistant.saved_warning"
    static let connected = "milestone.act2.cross_app_confirmation"
    static let confirmationEvent = "event.act2.sources_connected"
    static let summary = "content.act2.connection_summary"
    static let confirmationPrerequisites: StoryCondition = .all([
        .actReached(.somethingIsntRight), .milestoneCompleted(warningViewed),
        .eventCompleted(alexReplaced), .milestoneCompleted(replacementViewed),
        .milestoneCompleted(symptomsInvestigated), .milestoneCompleted(officialRead),
        .milestoneCompleted(danielFollowed), .milestoneCompleted(mayaFollowed),
        .milestoneCompleted(echoRead), .milestoneCompleted(diagnosticsRead),
        .any([.milestoneCompleted(savedCompared), .milestoneCompleted(independentRead)]),
        .assistantFact(assistantQuestioned)
    ])
    static let handoffPrerequisites: StoryCondition = .all([
        confirmationPrerequisites, .eventCompleted(confirmationEvent), .milestoneCompleted(connected)
    ])
    static let changes: [StorySourceChange] = [
        .init(eventID: alexReplaced, contentID: alex, originalVersionID: originalWarning,
              replacementVersionID: replacementWarning, prerequisites: .milestoneCompleted(warningViewed),
              milestoneID: "milestone.act2.warning_replaced"),
        .init(eventID: "event.act2.social.disorientation_edited", contentID: "content.act2.social.disorientation",
              originalVersionID: "version.act2.social.disorientation.v1", replacementVersionID: "version.act2.social.disorientation.v2",
              prerequisites: .all([.eventCompleted(alexReplaced), .contentRead("version.act2.social.disorientation.v1")]), milestoneID: nil),
        .init(eventID: "event.act2.social.memory_removed", contentID: "content.act2.social.memory",
              originalVersionID: "version.act2.social.memory.v1", replacementVersionID: nil,
              prerequisites: .all([.eventCompleted(alexReplaced), .contentRead("version.act2.social.memory.v1")]), milestoneID: nil),
        .init(eventID: "event.act2.news.concerns_edited", contentID: "content.act2.news.concerns",
              originalVersionID: "version.act2.news.concerns.v1", replacementVersionID: "version.act2.news.concerns.v2",
              prerequisites: .all([.eventCompleted(alexReplaced), .contentRead("version.act2.news.concerns.v1")]), milestoneID: nil),
        .init(eventID: "event.act2.web.preview_updated", contentID: "content.act2.web.preview_notes",
              originalVersionID: "version.act2.web.preview_notes.v1", replacementVersionID: "version.act2.web.preview_notes.v2",
              prerequisites: .all([.eventCompleted(alexReplaced), .contentRead("version.act2.web.preview_notes.v1")]), milestoneID: nil)
    ]
}

/// Pass 6 investigation knowledge; deliberately separate from AscensionMilestone/takeover.
enum ActThreeInvestigationContract {
    static let autonomy = "milestone.act3.echo_autonomy_established"
    static let contradiction = "milestone.act3.public_restricted_contradiction_confirmed"
    static let autonomyEvent = "event.act3.autonomy_connected"
    static let contradictionEvent = "event.act3.public_restricted_connected"
    static let autonomySources = ["version.act3.autonomy.actions.v1", "version.act3.autonomy.maya.v1"]
    static let contradictionSources = ["version.act3.ascension.purpose.v1", "version.act3.energy.transfer.v1",
        "version.act3.energy.growth.v1", "version.act2.news.official.v1", "version.act1.promo.v1"]
    static func prerequisites(for sources: [String]) -> StoryCondition {
        .all([.actReached(.theConspiracy), .puzzleSolved("puzzle.banana_wall.review_cross_reference"),
              .accessGranted("access.banana_wall.breached")] + sources.flatMap {
            [.contentRead($0), .eventCompleted("event.read." + $0)]
        })
    }
}

/// Explicit Pass 8 completion. Optional evidence/Observer clues/Assistant questions are independent.
enum ActThreeHandoffContract {
    static let entry = "content.act4.entry"
    static let requiredMilestones: Set<String> = [
        "milestone.banana_wall.breached", "milestone.act3.restricted_research_opened",
        "milestone.act3.mirror_origins_discovered", "milestone.act3.mirror_echo_relationship_established",
        "milestone.act3.neural_influence_evidence_discovered", "milestone.act3.echo_autonomy_established",
        "milestone.act3.ascension_purpose_uncovered", "milestone.act3.energy_harvesting_evidence_discovered",
        "milestone.act3.public_restricted_contradiction_confirmed", "milestone.act3.daniel_involvement_discovered",
        "milestone.act3.daniel_concealment_discovered", "milestone.act3.maya_recorded_guidance_reviewed",
        "milestone.act3.observer_connection_discovered", "milestone.act3.investigation_concluded"
    ]
    static let requiredEvents: Set<String> = [
        "event.puzzle.banana_wall.review_cross_reference", ActThreeInvestigationContract.autonomyEvent,
        ActThreeInvestigationContract.contradictionEvent, "event.read.version.act3.maya.guidance.v1",
        "event.read.version.act3.conclusion.resistance.v1"
    ]
    static let prerequisites: StoryCondition = .all([
        .puzzleSolved("puzzle.banana_wall.review_cross_reference"), .accessGranted("access.banana_wall.breached"),
        .contentRead("version.act3.maya.guidance.v1"), .contentRead("version.act3.conclusion.resistance.v1")
    ] + requiredMilestones.sorted().map(StoryCondition.milestoneCompleted)
      + requiredEvents.sorted().map(StoryCondition.eventCompleted))
}
