import Foundation

extension StoryCondition: Codable {
    private enum Keys: String, CodingKey { case type, id, act, cooperation, conditions }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Keys.self)
        let type = try c.decode(String.self, forKey: .type)
        let field: String
        switch type {
        case "actReached": field = "act"
        case "assistantCooperation": field = "cooperation"
        case "all", "any": field = "conditions"
        default: field = "id"
        }
        try StoryJSONKey.requireOnly(["type", field], in: decoder)
        switch type {
        case "contentDiscovered": self = .contentDiscovered(try c.decode(String.self, forKey: .id))
        case "contentRead": self = .contentRead(try c.decode(String.self, forKey: .id))
        case "evidencePreserved": self = .evidencePreserved(try c.decode(String.self, forKey: .id))
        case "puzzleSolved": self = .puzzleSolved(try c.decode(String.self, forKey: .id))
        case "accessGranted": self = .accessGranted(try c.decode(String.self, forKey: .id))
        case "milestoneCompleted": self = .milestoneCompleted(try c.decode(String.self, forKey: .id))
        case "actReached": self = .actReached(try c.decode(StoryAct.self, forKey: .act))
        case "assistantCooperation": self = .assistantCooperation(try c.decode(AssistantCooperation.self, forKey: .cooperation))
        case "assistantFact": self = .assistantFact(try c.decode(String.self, forKey: .id))
        case "observerClueFound": self = .observerClueFound(try c.decode(String.self, forKey: .id))
        case "routePrerequisite": self = .routePrerequisite(try c.decode(String.self, forKey: .id))
        case "eventCompleted": self = .eventCompleted(try c.decode(String.self, forKey: .id))
        case "all": self = .all(try c.decode([StoryCondition].self, forKey: .conditions))
        case "any": self = .any(try c.decode([StoryCondition].self, forKey: .conditions))
        default: throw DecodingError.dataCorruptedError(forKey: .type, in: c, debugDescription: "Unknown condition: \(type)")
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: Keys.self)
        let reference = factReference
        if let reference { try c.encode(reference.kind, forKey: .type); try c.encode(reference.id, forKey: .id); return }
        switch self {
        case .actReached(let act): try c.encode("actReached", forKey: .type); try c.encode(act, forKey: .act)
        case .assistantCooperation(let fact): try c.encode("assistantCooperation", forKey: .type); try c.encode(fact, forKey: .cooperation)
        case .all(let conditions): try c.encode("all", forKey: .type); try c.encode(conditions, forKey: .conditions)
        case .any(let conditions): try c.encode("any", forKey: .type); try c.encode(conditions, forKey: .conditions)
        default: break
        }
    }

    var factReference: (kind: String, id: String)? {
        switch self {
        case .contentDiscovered(let id): return ("contentDiscovered", id)
        case .contentRead(let id): return ("contentRead", id)
        case .evidencePreserved(let id): return ("evidencePreserved", id)
        case .puzzleSolved(let id): return ("puzzleSolved", id)
        case .accessGranted(let id): return ("accessGranted", id)
        case .milestoneCompleted(let id): return ("milestoneCompleted", id)
        case .assistantFact(let id): return ("assistantFact", id)
        case .observerClueFound(let id): return ("observerClueFound", id)
        case .routePrerequisite(let id): return ("routePrerequisite", id)
        case .eventCompleted(let id): return ("eventCompleted", id)
        default: return nil
        }
    }

    var allFactReferences: [(kind: String, id: String)] {
        if let reference = factReference { return [reference] }
        switch self {
        case .all(let conditions), .any(let conditions): return conditions.flatMap(\.allFactReferences)
        default: return []
        }
    }
}

enum StoryEffect: Codable, Equatable {
    case revealContent(String)
    case markMilestone(String)
    case unlockRoute(PhoneAppRoute)
    case queueNotification(String)
    case changeVersion(contentID: String, versionID: String)
    case makeUnavailable(String)
    case recordClue(String)
    case recordAssistantFact(String)

    private enum Keys: String, CodingKey { case type, id, contentID, versionID, route }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Keys.self)
        let type = try c.decode(String.self, forKey: .type)
        var fields: Set<String> = ["type"]
        switch type {
        case "unlockRoute": fields.insert("route")
        case "changeVersion": fields.formUnion(["contentID", "versionID"])
        default: fields.insert("id")
        }
        try StoryJSONKey.requireOnly(fields, in: decoder)
        switch type {
        case "revealContent": self = .revealContent(try c.decode(String.self, forKey: .id))
        case "markMilestone": self = .markMilestone(try c.decode(String.self, forKey: .id))
        case "unlockRoute": self = .unlockRoute(try c.decode(PhoneAppRoute.self, forKey: .route))
        case "queueNotification": self = .queueNotification(try c.decode(String.self, forKey: .id))
        case "changeVersion": self = .changeVersion(contentID: try c.decode(String.self, forKey: .contentID), versionID: try c.decode(String.self, forKey: .versionID))
        case "makeUnavailable": self = .makeUnavailable(try c.decode(String.self, forKey: .id))
        case "recordClue": self = .recordClue(try c.decode(String.self, forKey: .id))
        case "recordAssistantFact": self = .recordAssistantFact(try c.decode(String.self, forKey: .id))
        default: throw DecodingError.dataCorruptedError(forKey: .type, in: c, debugDescription: "Unknown effect: \(type)")
        }
    }
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: Keys.self)
        switch self {
        case .revealContent(let id): try c.encode("revealContent", forKey: .type); try c.encode(id, forKey: .id)
        case .markMilestone(let id): try c.encode("markMilestone", forKey: .type); try c.encode(id, forKey: .id)
        case .unlockRoute(let route): try c.encode("unlockRoute", forKey: .type); try c.encode(route, forKey: .route)
        case .queueNotification(let id): try c.encode("queueNotification", forKey: .type); try c.encode(id, forKey: .id)
        case .changeVersion(let id, let versionID):
            try c.encode("changeVersion", forKey: .type); try c.encode(id, forKey: .contentID); try c.encode(versionID, forKey: .versionID)
        case .makeUnavailable(let id): try c.encode("makeUnavailable", forKey: .type); try c.encode(id, forKey: .id)
        case .recordClue(let id): try c.encode("recordClue", forKey: .type); try c.encode(id, forKey: .id)
        case .recordAssistantFact(let id): try c.encode("recordAssistantFact", forKey: .type); try c.encode(id, forKey: .id)
        }
    }
}
