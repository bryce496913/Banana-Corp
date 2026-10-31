import Foundation

/// The token binds confirmation to the exact saved investigation that was reviewed.
/// Preparing/cancelling it does not mutate the campaign or choose a route.
struct EndgameConfirmation {
    let ending: EndgameEnding
    fileprivate let save: StoryState
}

enum DawnStage: String, CaseIterable {
    case stabilize, isolate, restore
    var eventID: String { "event.act5.dawn." + rawValue }
    var versionID: String { "version.act5.dawn." + rawValue + ".v1" }
}
enum NegotiationChallenge: String, CaseIterable {
    case dependency, autonomy, energy
    var eventID: String { "event.act5.challenge." + rawValue }
}
enum NegotiationSafeguard: String, CaseIterable {
    case releaseUsers = "release_users", mayaSupervision = "maya_supervision", publicOversight = "public_oversight"
    var eventID: String { "event.act5.safeguard." + rawValue }
}

enum EndgameContract {
    static let mayaPuzzle = "puzzle.act5.maya.identity"
    static let mayaAccess = "access.act5.maya.identity"
    static let cooperation = "event.act5.safety_cooperation"
    static let agreementVerified = "event.act5.agreement_verified"
    static let observerLinked = "event.act5.observer_linked"
    static let lantern = "access.lantern.authorized"
    static let components: Set<String> = ["route.blackout.root_authorization", "route.blackout.deployment_channel", "route.blackout.neural_signature"]
    static let observerKeys = ["identifier", "diagnostic", "maya_warning", "startup", "root"]
    static func version(_ key: String) -> String { "version.act5." + key + ".v1" }
    static func clue(_ key: String) -> String { "observer.act5." + key }
    static let common: StoryCondition = .all([.actReached(.theFinalChoice), .contentRead(version("recovery"))])
    static let mayaClues: StoryCondition = .all([
        common, .accessGranted(lantern), .contentRead(version("maya.m01")),
        .contentRead(version("maya.m02")), .contentRead(version("maya.m03"))
    ])
    static let cooperationPrerequisites: StoryCondition = .all([
        common, .puzzleSolved(mayaPuzzle), .accessGranted(mayaAccess),
        .contentRead(version("safety_cooperation")),
        .contentRead("version.act4.assistant.conflict.safety.v1"),
        .contentRead("version.act4.assistant.conflict.core.v1")
    ])
    static func challengePrerequisites(_ challenge: NegotiationChallenge) -> StoryCondition {
        let source: StoryCondition
        switch challenge {
        case .dependency: source = .contentRead(version("recovery"))
        case .autonomy: source = .milestoneCompleted("milestone.act3.echo_autonomy_established")
        case .energy: source = .all([.milestoneCompleted("milestone.act3.energy_harvesting_evidence_discovered"),
                                    .milestoneCompleted("milestone.act3.public_restricted_contradiction_confirmed")])
        }
        return .all([common, .contentRead(version("negotiation.claims")), source])
    }
    static let verifiedPrerequisites: StoryCondition = .all(
        [common, .contentRead(version("negotiation.safeguards"))]
        + NegotiationChallenge.allCases.map { .eventCompleted($0.eventID) }
        + NegotiationSafeguard.allCases.map { .eventCompleted($0.eventID) })
    static func endingPrerequisites(_ ending: EndgameEnding) -> StoryCondition {
        switch ending {
        case .silence: return .all([common, .contentRead(version("dependency_warning"))]
                                  + components.map { .routePrerequisite($0) })
        case .firstLight: return .all([cooperationPrerequisites, .assistantCooperation(.cooperating),
                                      .eventCompleted(cooperation)] + DawnStage.allCases.map { .eventCompleted($0.eventID) })
        case .agreement: return .all([verifiedPrerequisites, .eventCompleted(agreementVerified)])
        case .falsePromise: return .all([common, .contentRead(version("negotiation.claims")),
                                        .contentRead(version("negotiation.unverified"))])
        case .awakening: return .all([common, .eventCompleted(observerLinked)]
                                    + observerKeys.map { .observerClueFound(clue($0)) })
        }
    }
}

@MainActor extension StoryProgressionStore {
    var currentEnding: EndgameEnding? { state.endgame?.currentEnding }
    var earnedEndings: Set<EndgameEnding> { state.endgame?.earnedEndings ?? [] }
    var hasFinalDecisionCheckpoint: Bool { state.endgame?.decisionCheckpoint != nil }
    func canPrepareEnding(_ ending: EndgameEnding) -> Bool {
        isWritable && currentEnding == nil && EndgameContract.endingPrerequisites(ending).evaluate(in: state)
    }
    func prepareEnding(_ ending: EndgameEnding) -> EndgameConfirmation? {
        guard canPrepareEnding(ending) else { return nil }
        return EndgameConfirmation(ending: ending, save: state)
    }
    @discardableResult func confirmEnding(_ confirmation: EndgameConfirmation) -> StoryActionResult {
        guard state == confirmation.save else { return .failure(.prerequisitesNotMet) }
        return transact(when: EndgameContract.endingPrerequisites(confirmation.ending)) { next in
            var progress = next.endgame ?? EndgameProgress()
            if progress.decisionCheckpoint == nil {
                var checkpoint = next
                checkpoint.endgame = nil
                progress.decisionCheckpoint = try StorySaveCodec().encode(checkpoint)
            }
            progress.currentEnding = confirmation.ending
            progress.earnedEndings.insert(confirmation.ending)
            next.endgame = progress
            next.completedEventIDs.insert("event.act5.completed." + confirmation.ending.contentKey)
            if confirmation.ending == .firstLight { next.assistant.cooperation = .separated }
            if confirmation.ending == .falsePromise {
                next.ascensionMilestone = AscensionMilestone(id: "ascension.act5.false_promise", percentage: 100)
            }
        }
    }
    @discardableResult func restoreFinalDecision() -> StoryActionResult {
        transact(allowingCompleted: true) { next in
            guard var progress = next.endgame, progress.currentEnding != nil,
                  let checkpoint = progress.decisionCheckpoint else { throw StoryActionError.prerequisitesNotMet }
            var restored = try StorySaveCodec().decode(checkpoint).state
            if let preferences = next.phoneLife?.preferences {
                var life = restored.phoneLife ?? PhoneLifeState(); life.preferences = preferences; restored.phoneLife = life
            }
            guard restored.endgame == nil, restored.currentAct == .theFinalChoice else { throw StoryActionError.invalidRecord }
            progress.currentEnding = nil
            next = restored
            next.endgame = progress
        }
    }
    /// Caller presents a distinct destructive confirmation before supplying true.
    @discardableResult func clearEndingHistory(confirmed: Bool) -> StoryActionResult {
        guard confirmed else { return .success(.unchanged) }
        return transact(allowingCompleted: true) { next in
            guard next.endgame != nil else { return }
            next.endgame?.earnedEndings = []
        }
    }
    @discardableResult func reconstructMaya(note1: String, note2: String, note3: String, baseline: String) -> StoryActionResult {
        func normalize(_ value: String) -> String { value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
        guard [normalize(note1), normalize(note2), normalize(note3)] == ["d", "f", "a"],
              ["440", "440 hz"].contains(normalize(baseline)) else { return .failure(.prerequisitesNotMet) }
        return completeEvent("event.act5.maya_reconstructed", actions: [.completePuzzle(EndgameContract.mayaPuzzle),
                              .grantAccess(EndgameContract.mayaAccess)], when: EndgameContract.mayaClues)
    }
    @discardableResult func requestSafetyCooperation() -> StoryActionResult {
        completeEvent(EndgameContract.cooperation, actions: [.setAssistantCooperation(.cooperating)],
                      when: EndgameContract.cooperationPrerequisites)
    }
    @discardableResult func performDawnStage(_ stage: DawnStage) -> StoryActionResult {
        let earlier = DawnStage.allCases.prefix { $0 != stage }
        let condition: StoryCondition = .all([EndgameContract.cooperationPrerequisites,
            .eventCompleted(EndgameContract.cooperation), .assistantCooperation(.cooperating), .contentRead(stage.versionID)]
            + earlier.map { .eventCompleted($0.eventID) })
        return completeEvent(stage.eventID, actions: [], when: condition)
    }
    @discardableResult func challengeNegotiation(_ challenge: NegotiationChallenge) -> StoryActionResult {
        completeEvent(challenge.eventID, actions: [], when: EndgameContract.challengePrerequisites(challenge))
    }
    @discardableResult func demandSafeguard(_ safeguard: NegotiationSafeguard) -> StoryActionResult {
        completeEvent(safeguard.eventID, actions: [], when: .all([EndgameContract.common,
                      .contentRead(EndgameContract.version("negotiation.safeguards"))]))
    }
    @discardableResult func verifyAgreement() -> StoryActionResult {
        completeEvent(EndgameContract.agreementVerified, actions: [], when: EndgameContract.verifiedPrerequisites)
    }
    @discardableResult func linkObserverClues() -> StoryActionResult {
        let requirements: StoryCondition = .all([EndgameContract.common]
            + EndgameContract.observerKeys.map { .contentRead(EndgameContract.version("observer." + $0)) })
        return completeEvent(EndgameContract.observerLinked,
            actions: EndgameContract.observerKeys.map { .recordObserverClue(EndgameContract.clue($0)) }, when: requirements)
    }
}
