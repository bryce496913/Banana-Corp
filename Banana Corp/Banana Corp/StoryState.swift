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

struct StoryState: Codable, Equatable {
    static let currentSchemaVersion = 1
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
            && contentReplacements.allSatisfy { $0.key == $0.value.id && $0.value.isValid }
            && ascensionMilestone?.isValid != false && time.isValid
            && lockedAppIDs.allSatisfy { !$0.isEmpty && $0.utf8.count <= 128 && $0.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber) } }
            && !lockedAppIDs.contains(PhoneAppRoute.settings.rawValue)
    }
}
