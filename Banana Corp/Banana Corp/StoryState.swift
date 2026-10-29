import Foundation

enum StoryAct: Int, Codable, CaseIterable {
    case thePerfectProduct = 1
    case somethingIsntRight = 2
    case theConspiracy = 3
    case theTakeover = 4
    case theFinalChoice = 5
}

enum StoryID {
    /// Technical IDs are independent of narrative labels such as M-01 or ECHO_CORE.
    static func isValid(_ value: String) -> Bool {
        value.utf8.count <= 128 && value.range(
            of: "\\A[a-z][a-z0-9]*(?:[._-][a-z0-9]+)+\\z", options: .regularExpression
        ) != nil
    }
}

struct PreservedEvidenceRecord: Codable, Equatable {
    let id: String
    let sourceContentID: String
    let sourceVersionID: String
    let capturedAt: Date
    /// Opaque authored content/version snapshot; the future content layer defines its format.
    let snapshot: Data

    var isValid: Bool {
        [id, sourceContentID, sourceVersionID].allSatisfy(StoryID.isValid)
            && id != sourceContentID && id != sourceVersionID
            && capturedAt.timeIntervalSinceReferenceDate.isFinite && !snapshot.isEmpty
    }
}

struct ContentReplacementRecord: Codable, Equatable {
    let id: String
    let contentID: String
    let originalVersionID: String
    let replacementVersionID: String

    var isValid: Bool {
        [id, contentID, originalVersionID, replacementVersionID].allSatisfy(StoryID.isValid)
            && originalVersionID != replacementVersionID
    }
}

enum AssistantCooperation: String, Codable {
    case notEstablished, cooperating, separated
}

struct AssistantStoryFacts: Codable, Equatable {
    var relationshipFacts: Set<String> = []
    var cooperation: AssistantCooperation = .notEstablished
}

struct AscensionMilestone: Codable, Equatable {
    let id: String
    let percentage: Int?
    var isValid: Bool { StoryID.isValid(id) && percentage.map { (0...100).contains($0) } != false }
}

/// Compatibility facts retain existing flags without claiming they are act prerequisites.
struct StoryCompatibilityFacts: Codable, Equatable {
    var hasOpenedVRApp = false
    var hasSeenFirstGlitch = false
}

struct SavedContentVersion: Codable, Equatable {
    let contentID: String
    let versionID: String
    let snapshot: Data
    var isValid: Bool { StoryID.isValid(contentID) && StoryID.isValid(versionID) && contentID != versionID && !snapshot.isEmpty }
}

struct QueuedStoryNotification: Codable, Equatable {
    enum Status: String, Codable { case pending, delivered }
    let id: String
    let contentID: String
    let versionID: String
    let sequence: Int
    var status: Status = .pending
    var isValid: Bool { [id, contentID, versionID].allSatisfy(StoryID.isValid) && sequence >= 0 }
}

struct StoryContentDeliveryState: Codable, Equatable {
    var revealedContentIDs: Set<String> = []
    var unavailableContentIDs: Set<String> = []
    var activeVersionIDs: [String: String] = [:]
    var versionReceipts: [String: SavedContentVersion] = [:]
    var notifications: [String: QueuedStoryNotification] = [:]
    var isValid: Bool {
        revealedContentIDs.allSatisfy(StoryID.isValid) && unavailableContentIDs.allSatisfy(StoryID.isValid)
            && versionReceipts.allSatisfy { $0.key == $0.value.versionID && $0.value.isValid }
            && activeVersionIDs.allSatisfy { StoryID.isValid($0.key) && versionReceipts[$0.value]?.contentID == $0.key }
            && notifications.allSatisfy { $0.key == $0.value.id && $0.value.isValid && versionReceipts[$0.value.versionID]?.contentID == $0.value.contentID }
            && Set(notifications.values.map(\.sequence)).count == notifications.count
    }
}

struct StoryState: Codable, Equatable {
    static let currentSchemaVersion = 2
    var schemaVersion = currentSchemaVersion
    var currentAct: StoryAct = .thePerfectProduct
    var discoveredContentIDs: Set<String> = []
    var readContentIDs: Set<String> = []
    var preservedEvidence: [String: PreservedEvidenceRecord] = [:]
    var contentReplacements: [String: ContentReplacementRecord] = [:]
    var solvedPuzzleIDs: Set<String> = []
    var accessMilestoneIDs: Set<String> = []
    var completedMilestoneIDs: Set<String> = []
    var assistant = AssistantStoryFacts()
    var ascensionMilestone: AscensionMilestone?
    var routePrerequisiteIDs: Set<String> = []
    var observerClueIDs: Set<String> = []
    var completedEventIDs: Set<String> = []
    var time = StoryTimeState()
    var compatibility = StoryCompatibilityFacts()
    // Strings retain future app identities across older builds; existing raw values stay stable.
    var lockedAppIDs: Set<String> = []
    var contentDelivery = StoryContentDeliveryState()
    /// Optional additive schema-2 field; old saves decode without a migration or evidence rewrite.
    var endgame: EndgameProgress?

    var isValid: Bool {
        let groups = [discoveredContentIDs, readContentIDs, solvedPuzzleIDs, accessMilestoneIDs,
                      completedMilestoneIDs, assistant.relationshipFacts, routePrerequisiteIDs,
                      observerClueIDs, completedEventIDs]
        return schemaVersion == Self.currentSchemaVersion
            && groups.allSatisfy { $0.allSatisfy(StoryID.isValid) }
            && readContentIDs.isSubset(of: discoveredContentIDs)
            && preservedEvidence.allSatisfy { key, record in
                key == record.id && record.isValid
                    && discoveredContentIDs.contains(record.sourceContentID)
                    && discoveredContentIDs.contains(record.sourceVersionID)
            }
            && Set(preservedEvidence.values.map { $0.sourceContentID + "\u{0}" + $0.sourceVersionID }).count == preservedEvidence.count
            && contentReplacements.allSatisfy { $0.key == $0.value.id && $0.value.isValid }
            && ascensionMilestone?.isValid != false && time.isValid
            && lockedAppIDs.allSatisfy { !$0.isEmpty && $0.utf8.count <= 128 && $0.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber) } }
            && !lockedAppIDs.contains(PhoneAppRoute.settings.rawValue)
            && contentDelivery.isValid && endgame?.isValid != false
    }
}

/// Stable ending IDs are independent of presentation titles.
enum EndgameEnding: String, Codable, CaseIterable, Identifiable {
    case silence = "ending.silence"
    case firstLight = "ending.first_light"
    case agreement = "ending.agreement"
    case falsePromise = "ending.false_promise"
    case awakening = "ending.awakening"
    var id: String { rawValue }
    var contentKey: String { String(rawValue.dropFirst("ending.".count)) }
    var versionID: String { "version.act5.ending." + contentKey + ".v1" }
    var title: String {
        switch self {
        case .silence: return "THE SILENCE"
        case .firstLight: return "FIRST LIGHT"
        case .agreement: return "THE AGREEMENT"
        case .falsePromise: return "THE FALSE PROMISE"
        case .awakening: return "THE AWAKENING"
        }
    }
}

struct EndgameProgress: Codable, Equatable {
    var currentEnding: EndgameEnding?
    var earnedEndings: Set<EndgameEnding> = []
    /// Encoded legitimate campaign immediately before its first irreversible decision.
    /// The nested save has no endgame field, preventing recursive checkpoints.
    var decisionCheckpoint: Data?
    var isValid: Bool {
        guard currentEnding == nil || decisionCheckpoint != nil else { return false }
        guard let decisionCheckpoint else { return true }
        guard let checkpoint = try? JSONDecoder().decode(StoryState.self, from: decisionCheckpoint),
              checkpoint.endgame == nil, checkpoint.currentAct == .theFinalChoice else { return false }
        return checkpoint.isValid
    }
}
