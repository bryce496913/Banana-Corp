import Foundation

struct RestrictedResource: Codable, Identifiable {
    enum Kind: String, Codable { case webPage, researchMemo, technicalReport, email, diagnosticLog, securityNotice, accessRecord, projectArchive }
    enum Visibility: String, Codable { case entry, hiddenUntilUnlocked }
    let id: String
    let kind: Kind
    let displayName: String
    let message: String
    let availableAct: StoryAct
    let visibility: Visibility
    let discoveryConditions: [StoryCondition]
    let requiredAccessID: String
    let requiredPuzzleID: String?
    let unlockConditions: [StoryCondition]
    let linkedContentIDs: [String]
}

struct PuzzleInput: Codable, Identifiable {
    enum Kind: String, Codable { case text, choice }
    let id: String
    let label: String
    let kind: Kind
    let choices: [String]?
}

struct PuzzleRule: Codable {
    enum Kind: String, Codable { case awaitingApproval, exactFields }
    let kind: Kind
    let expectedFields: [String: String]?
    let trimWhitespace: Bool?
    let caseInsensitive: Bool?
}

struct PuzzleSuccessEffect: Codable {
    enum Kind: String, Codable { case grantAccess, recordMilestone, recordAssistantFact, recordObserverClue, recordRoutePrerequisite }
    let kind: Kind
    let id: String
    var action: StoryAction {
        switch kind {
        case .grantAccess: return .grantAccess(id)
        case .recordMilestone: return .recordMilestone(id)
        case .recordAssistantFact: return .recordAssistantFact(id)
        case .recordObserverClue: return .recordObserverClue(id)
        case .recordRoutePrerequisite: return .recordRoutePrerequisite(id)
        }
    }
    var factKind: String {
        switch kind {
        case .grantAccess: return "accessGranted"
        case .recordMilestone: return "milestoneCompleted"
        case .recordAssistantFact: return "assistantFact"
        case .recordObserverClue: return "observerClueFound"
        case .recordRoutePrerequisite: return "routePrerequisite"
        }
    }
}

struct PuzzleDefinition: Codable, Identifiable {
    let id: String
    let title: String
    let instructions: String
    let availableAct: StoryAct
    let requirements: [StoryCondition]
    let inputs: [PuzzleInput]
    let rule: PuzzleRule
    let successEventID: String
    let successEffects: [PuzzleSuccessEffect]
    let hints: [String]
}

struct RestrictedAccessDocument: Codable {
    enum Kind: String, Codable { case production, developmentFixture }
    let schemaVersion: Int
    let kind: Kind
    let facts: [String: [String]]
    let resources: [RestrictedResource]
    let puzzles: [PuzzleDefinition]
}

struct RestrictedAccessFailure: Error { let diagnostics: [String] }
struct RestrictedAccessCatalogue {
    let resources: [RestrictedResource]
    let puzzles: [PuzzleDefinition]
    let resourcesByID: [String: RestrictedResource]
    let puzzlesByID: [String: PuzzleDefinition]
    let declaredFacts: [String: [String]]
    fileprivate init(_ document: RestrictedAccessDocument) {
        declaredFacts = document.facts
        resources = document.resources.sorted { $0.id < $1.id }
        puzzles = document.puzzles.sorted { $0.id < $1.id }
        resourcesByID = Dictionary(uniqueKeysWithValues: resources.map { ($0.id, $0) })
        puzzlesByID = Dictionary(uniqueKeysWithValues: puzzles.map { ($0.id, $0) })
    }
}

enum RestrictedAccessCatalogueLoader {
    static func load(bundle: Bundle = .main) -> Result<RestrictedAccessCatalogue, RestrictedAccessFailure> {
        guard let url = bundle.url(forResource: "RestrictedAccess", withExtension: "json") else { return .failure(.init(diagnostics: ["RestrictedAccess.json is missing"])) }
        do { return load(data: try Data(contentsOf: url)) }
        catch { return .failure(.init(diagnostics: ["Access resource could not be read"])) }
    }
    static func load(data: Data) -> Result<RestrictedAccessCatalogue, RestrictedAccessFailure> { decode(data, allowFixture: false) }
    #if DEBUG
    static func loadDevelopmentFixture(data: Data) -> Result<RestrictedAccessCatalogue, RestrictedAccessFailure> { decode(data, allowFixture: true) }
    #endif
    private static func decode(_ data: Data, allowFixture: Bool) -> Result<RestrictedAccessCatalogue, RestrictedAccessFailure> {
        do {
            let raw = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            func keys(_ value: [String: Any]?, _ allowed: Set<String>) throws {
                guard let value, Set(value.keys).isSubset(of: allowed) else { throw RestrictedAccessFailure(diagnostics: ["Unknown access schema fields"]) }
            }
            try keys(raw, ["schemaVersion", "kind", "facts", "resources", "puzzles"])
            for resource in raw?["resources"] as? [[String: Any]] ?? [] {
                try keys(resource, ["id", "kind", "displayName", "message", "availableAct", "visibility", "discoveryConditions", "requiredAccessID", "requiredPuzzleID", "unlockConditions", "linkedContentIDs"])
            }
            for puzzle in raw?["puzzles"] as? [[String: Any]] ?? [] {
                try keys(puzzle, ["id", "title", "instructions", "availableAct", "requirements", "inputs", "rule", "successEventID", "successEffects", "hints"])
                try keys(puzzle["rule"] as? [String: Any], ["kind", "expectedFields", "trimWhitespace", "caseInsensitive"])
                for input in puzzle["inputs"] as? [[String: Any]] ?? [] { try keys(input, ["id", "label", "kind", "choices"]) }
                for effect in puzzle["successEffects"] as? [[String: Any]] ?? [] { try keys(effect, ["kind", "id"]) }
            }
            let document = try JSONDecoder().decode(RestrictedAccessDocument.self, from: data)
            guard document.schemaVersion == 1 else { throw RestrictedAccessFailure(diagnostics: ["Unsupported access schema"]) }
            guard document.kind == .production || allowFixture else { throw RestrictedAccessFailure(diagnostics: ["Development fixtures are not production resources"]) }
            var errors: [String] = []
            var ids: Set<String> = []
            func register(_ id: String) { if !StoryID.isValid(id) || !ids.insert(id).inserted { errors.append("Invalid/duplicate ID: " + id) } }
            let factKinds: Set<String> = ["contentRead", "contentDiscovered", "accessGranted", "milestoneCompleted", "assistantFact", "observerClueFound", "routePrerequisite", "eventCompleted", "puzzleSolved"]
            for (kind, values) in document.facts {
                if !factKinds.contains(kind) { errors.append("Unknown fact kind: " + kind) }
                for id in values { register(id) }
            }
            for resource in document.resources { register(resource.id) }
            for puzzle in document.puzzles { register(puzzle.id); register(puzzle.successEventID) }
            let puzzles = Dictionary(document.puzzles.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
            let puzzleIDs = Set(puzzles.keys)
            let events = Set(document.puzzles.map(\.successEventID))
            func valid(_ condition: StoryCondition) {
                if !condition.isWellFormed() { errors.append("Malformed prerequisite") }
                for ref in condition.allFactReferences {
                    if (ref.kind == "puzzleSolved" && puzzleIDs.contains(ref.id)) || (ref.kind == "eventCompleted" && events.contains(ref.id)) { continue }
                    if !(document.facts[ref.kind] ?? []).contains(ref.id) { errors.append("Undeclared prerequisite: " + ref.id) }
                }
            }
            for resource in document.resources {
                if resource.displayName.isEmpty || resource.message.isEmpty || !(document.facts["accessGranted"] ?? []).contains(resource.requiredAccessID) { errors.append("Invalid resource: " + resource.id) }
                if let puzzle = resource.requiredPuzzleID, !puzzleIDs.contains(puzzle) { errors.append("Missing resource puzzle: " + puzzle) }
                for condition in resource.discoveryConditions + resource.unlockConditions { valid(condition) }
                if Set(resource.linkedContentIDs).count != resource.linkedContentIDs.count || !resource.linkedContentIDs.allSatisfy(StoryID.isValid) { errors.append("Invalid content references") }
            }
            var edges: [String: Set<String>] = [:]
            for puzzle in document.puzzles {
                if puzzle.title.isEmpty || puzzle.instructions.isEmpty || puzzle.hints.contains(where: { $0.isEmpty }) { errors.append("Invalid puzzle copy") }
                for condition in puzzle.requirements { valid(condition) }
                let references = puzzle.requirements.flatMap(\.allFactReferences)
                edges[puzzle.id] = Set(references.flatMap { ref in
                    document.puzzles.filter { other in
                        (ref.kind == "puzzleSolved" && ref.id == other.id)
                        || (ref.kind == "eventCompleted" && ref.id == other.successEventID)
                        || other.successEffects.contains { $0.factKind == ref.kind && $0.id == ref.id }
                    }.map(\.id)
                })
                if references.contains(where: { ($0.kind == "puzzleSolved" && $0.id == puzzle.id) || ($0.kind == "eventCompleted" && $0.id == puzzle.successEventID) }) { errors.append("Self-triggering puzzle") }
                let fields = Set(puzzle.inputs.map(\.id))
                if fields.count != puzzle.inputs.count || puzzle.inputs.contains(where: { !StoryID.isValid($0.id) || $0.label.isEmpty }) { errors.append("Invalid inputs") }
                for field in puzzle.inputs {
                    if field.kind == .choice && ((field.choices ?? []).isEmpty || Set(field.choices ?? []).count != field.choices?.count) { errors.append("Invalid choices") }
                }
                switch puzzle.rule.kind {
                case .awaitingApproval:
                    if !puzzle.inputs.isEmpty || !puzzle.successEffects.isEmpty || !puzzle.hints.isEmpty || puzzle.rule.expectedFields != nil { errors.append("Unapproved puzzles cannot have a solution/effects/hints") }
                case .exactFields:
                    let answers = puzzle.rule.expectedFields ?? [:]
                    if fields.isEmpty || fields != Set(answers.keys) || answers.values.contains(where: { $0.isEmpty || $0.utf8.count > 256 }) { errors.append("Invalid exact-field rule") }
                    for field in puzzle.inputs where field.kind == .choice {
                        if !(field.choices ?? []).contains(answers[field.id] ?? "") { errors.append("Answer is not a choice") }
                    }
                }
                for effect in puzzle.successEffects {
                    if !(document.facts[effect.factKind] ?? []).contains(effect.id) { errors.append("Undeclared success fact: " + effect.id) }
                    if references.contains(where: { $0.kind == effect.factKind && $0.id == effect.id }) { errors.append("Puzzle produces its own prerequisite") }
                }
            }
            var visiting: Set<String> = [], visited: Set<String> = []
            func cycle(_ id: String) -> Bool {
                if visiting.contains(id) { return true }
                if visited.contains(id) { return false }
                visiting.insert(id)
                for next in edges[id] ?? [] where cycle(next) { return true }
                visiting.remove(id); visited.insert(id); return false
            }
            if puzzleIDs.contains(where: cycle) { errors.append("Cyclic puzzle prerequisites") }
            if !errors.isEmpty { throw RestrictedAccessFailure(diagnostics: errors.sorted()) }
            return .success(RestrictedAccessCatalogue(document))
        } catch let error as RestrictedAccessFailure { return .failure(error) }
        catch { return .failure(.init(diagnostics: ["Malformed access catalogue"])) }
    }
}

#if DEBUG
/// Neutral fixture answers belong in the definition layer, never in a SwiftUI input handler.
enum RestrictedAccessDevelopmentFixture {
    static let data = Data(#"""
    {"schemaVersion":1,"kind":"developmentFixture","facts":{"accessGranted":["access.fixture.demo"]},
     "resources":[{"id":"resource.fixture.demo","kind":"researchMemo","displayName":"Development test resource","message":"Neutral framework test. This is not the Banana Wall challenge.","availableAct":1,"visibility":"entry","discoveryConditions":[],"requiredAccessID":"access.fixture.demo","requiredPuzzleID":"puzzle.fixture.demo","unlockConditions":[],"linkedContentIDs":[]}],
     "puzzles":[{"id":"puzzle.fixture.demo","title":"Development test challenge","instructions":"Enter the neutral test token DEMO. No campaign progress is affected.","availableAct":1,"requirements":[],"inputs":[{"id":"input.fixture.token","label":"Test token","kind":"text"}],"rule":{"kind":"exactFields","expectedFields":{"input.fixture.token":"DEMO"},"trimWhitespace":true,"caseInsensitive":true},"successEventID":"event.puzzle.fixture.demo","successEffects":[{"kind":"grantAccess","id":"access.fixture.demo"}],"hints":["This test accepts the word DEMO."]}]}
    """#.utf8)
}
#endif
