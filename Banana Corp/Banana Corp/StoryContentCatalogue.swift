import Foundation

struct StoryContentDiagnostic: Equatable {
    enum Code: String { case missingResource, malformedJSON, unsupportedSchema, duplicateID, invalidID, invalidVersion, missingReference, invalidRule, invalidPayload, cycle, savedReference, definitionChanged }
    let code: Code
    let path: String
    let message: String
}

struct StoryContentLoadFailure: Error { let diagnostics: [StoryContentDiagnostic] }

struct StoryContentCatalogue {
    let items: [StoryContentItem]
    let itemsByID: [String: StoryContentItem]
    let versionsByID: [String: StoryContentVersion]
    let versionOwners: [String: String]
    fileprivate init(_ document: StoryContentDocument) {
        items = document.items.sorted { $0.order == $1.order ? $0.id < $1.id : $0.order < $1.order }
        itemsByID = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })
        versionsByID = Dictionary(uniqueKeysWithValues: items.flatMap { $0.versions.map { ($0.id, $0) } })
        versionOwners = Dictionary(uniqueKeysWithValues: items.flatMap { item in item.versions.map { ($0.id, item.id) } })
    }
}

enum StoryContentCatalogueLoader {
    static func load(bundle: Bundle = .main, resource: String = "StoryContent") -> Result<StoryContentCatalogue, StoryContentLoadFailure> {
        load(fileURL: bundle.url(forResource: resource, withExtension: "json"), assetExists: { name in
            guard let url = bundle.url(forResource: name, withExtension: nil), url.isFileURL else { return false }
            return FileManager.default.fileExists(atPath: url.path)
        })
    }

    static func load(fileURL: URL?, assetExists: (String) -> Bool = { _ in false }) -> Result<StoryContentCatalogue, StoryContentLoadFailure> {
        guard let fileURL, fileURL.isFileURL else {
            return .failure(StoryContentLoadFailure(diagnostics: [.init(code: .missingResource, path: "resource", message: "Local catalogue resource is missing")]))
        }
        do { return load(data: try Data(contentsOf: fileURL), assetExists: assetExists) }
        catch { return .failure(.init(diagnostics: [.init(code: .missingResource, path: fileURL.lastPathComponent, message: String(describing: error))])) }
    }

    static func load(data: Data, assetExists: (String) -> Bool = { _ in false }) -> Result<StoryContentCatalogue, StoryContentLoadFailure> {
        struct Header: Decodable { let schemaVersion: Int }
        do {
            let schema = try JSONDecoder().decode(Header.self, from: data).schemaVersion
            guard schema == 1 else { return .failure(.init(diagnostics: [.init(code: .unsupportedSchema, path: "schemaVersion", message: "Unsupported catalogue schema \(schema)")])) }
            let document = try JSONDecoder().decode(StoryContentDocument.self, from: data)
            let diagnostics = validate(document, assetExists: assetExists)
            if !diagnostics.isEmpty { return .failure(.init(diagnostics: diagnostics)) }
            return .success(StoryContentCatalogue(document))
        } catch {
            return .failure(.init(diagnostics: [.init(code: .malformedJSON, path: "catalogue", message: String(describing: error))]))
        }
    }

    private static func validate(_ document: StoryContentDocument, assetExists: (String) -> Bool) -> [StoryContentDiagnostic] {
        var diagnostics: [StoryContentDiagnostic] = []
        func report(_ code: StoryContentDiagnostic.Code, _ path: String, _ message: String) {
            diagnostics.append(.init(code: code, path: path, message: message))
        }
        var allIDs: Set<String> = []
        func register(_ id: String, at path: String) {
            if !StoryID.isValid(id) { report(.invalidID, path, "Invalid stable ID: \(id)") }
            if !allIDs.insert(id).inserted { report(.duplicateID, path, "Duplicate ID: \(id)") }
        }
        let externalKinds: Set<String> = ["puzzleSolved", "accessGranted", "milestoneCompleted", "assistantFact", "observerClueFound", "routePrerequisite", "eventCompleted"]
        for kind in document.facts.keys.sorted() {
            if !externalKinds.contains(kind) { report(.invalidRule, "facts.\(kind)", "Unknown external fact kind") }
            for id in document.facts[kind] ?? [] { register(id, at: "facts.\(kind)") }
        }
        let itemIDs = Set(document.items.map(\.id))
        let versionIDs = Set(document.items.flatMap { $0.versions.map(\.id) })
        let assetIDs = Set((document.assets ?? []).map(\.id))
        let evidenceIDs = Set(document.items.flatMap { $0.versions.compactMap(\.preservedEvidenceID) })
        let readEvents = Set(document.items.flatMap { $0.versions.flatMap { version in
            [version.readEventID] + (version.preservedEvidenceID.map { ["event.preserve." + $0, "event.compare." + $0, "event.diff." + $0] } ?? [])
        } })
        let items = Dictionary(document.items.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

        for asset in document.assets ?? [] {
            register(asset.id, at: "assets")
            guard !asset.fileName.isEmpty, !asset.fileName.contains(".."), asset.fileName.allSatisfy({ $0.isASCII && ($0.isLetter || $0.isNumber || "._-".contains($0)) }) else {
                report(.invalidPayload, asset.id, "Assets must name bundled local files"); continue
            }
            if !assetExists(asset.fileName) { report(.missingResource, asset.id, "Missing bundled asset: \(asset.fileName)") }
        }
        var effectEdges: [String: Set<String>] = [:]
        for item in document.items {
            register(item.id, at: "items")
            if item.order < 0 { report(.invalidPayload, item.id, "Order must be nonnegative") }
            let numbers = item.versions.map(\.version).sorted()
            if numbers.isEmpty || numbers != Array(1...max(1, numbers.count)) || item.versions.first(where: { $0.version == 1 })?.id != item.initialVersionID {
                report(.invalidVersion, item.id, "Retain contiguous immutable versions starting at 1, with version 1 as initial")
            }
            let conditions = item.unlockConditions ?? []
            for condition in conditions {
                if !condition.isWellFormed() { report(.invalidRule, item.id, "Malformed unlock condition"); continue }
                for reference in condition.allFactReferences {
                    let exists: Bool
                    switch reference.kind {
                    case "contentDiscovered", "contentRead": exists = itemIDs.contains(reference.id) || versionIDs.contains(reference.id)
                    case "evidencePreserved": exists = evidenceIDs.contains(reference.id)
                    case "eventCompleted": exists = readEvents.contains(reference.id) || (document.facts[reference.kind] ?? []).contains(reference.id)
                    default: exists = (document.facts[reference.kind] ?? []).contains(reference.id)
                    }
                    if !exists { report(.missingReference, item.id, "Unknown \(reference.kind) reference: \(reference.id)") }
                    if ["contentRead", "contentDiscovered"].contains(reference.kind), reference.id == item.id || item.versions.contains(where: { $0.id == reference.id }) {
                        report(.invalidRule, item.id, "Content cannot require its own discovery/read to become available")
                    }
                    if reference.kind == "evidencePreserved", item.versions.contains(where: { $0.preservedEvidenceID == reference.id }) {
                        report(.invalidRule, item.id, "Content cannot require its own preserved evidence to become available")
                    }
                    if reference.kind == "eventCompleted", item.versions.contains(where: { version in
                        version.readEventID == reference.id || version.preservedEvidenceID.map { ["event.preserve." + $0, "event.compare." + $0, "event.diff." + $0].contains(reference.id) } == true
                    }) {
                        report(.invalidRule, item.id, "Content cannot require its own read event to become available")
                    }
                }
            }
            for version in item.versions {
                register(version.id, at: item.id)
                register(version.readEventID, at: version.id)
                if item.appSurface == .notifications { register("notification." + version.id, at: version.id) }
                if let evidenceID = version.preservedEvidenceID {
                    register(evidenceID, at: version.id)
                    register("event.preserve." + evidenceID, at: version.id)
                    register("event.compare." + evidenceID, at: version.id)
                    register("event.diff." + evidenceID, at: version.id)
                }
                if let rules = version.evidenceRules {
                    if version.preservedEvidenceID == nil { report(.invalidRule, version.id, "Evidence rules require a preservable version") }
                    let references = [("observerClueFound", rules.securedObserverClueID), ("milestoneCompleted", rules.preservationMilestoneID), ("milestoneCompleted", rules.comparisonMilestoneID)]
                    for (kind, id) in references {
                        guard let id else { continue }
                        if !StoryID.isValid(id) || !(document.facts[kind] ?? []).contains(id) { report(.missingReference, version.id, "Undeclared evidence fact: \(id)") }
                        if conditions.flatMap(\.allFactReferences).contains(where: { $0.kind == kind && $0.id == id }) { report(.invalidRule, version.id, "Evidence cannot produce its own availability prerequisite") }
                    }
                }
                if version.payload.surface != item.appSurface || !nonempty(version.title) || version.narrativeTimestamp?.isValid == false {
                    report(.invalidPayload, version.id, "Surface/title/narrative timestamp mismatch")
                }
                if !validPayload(version.payload) { report(.invalidPayload, version.id, "Invalid structured payload") }
                for ref in payloadReferences(version.payload) {
                    if !(ref.asset ? assetIDs : itemIDs).contains(ref.id) { report(.missingReference, version.id, "Unknown payload reference: \(ref.id)") }
                }
                for (index, effect) in (version.effectsOnRead ?? []).enumerated() {
                    let path = "\(version.id).effectsOnRead[\(index)]"
                    switch effect {
                    case .revealContent(let id), .makeUnavailable(let id):
                        if !itemIDs.contains(id) { report(.missingReference, path, "Unknown content: \(id)") }
                        if case .revealContent = effect, let target = items[id] {
                            effectEdges[version.id, default: []].insert(target.initialVersionID)
                            if id == item.id { report(.invalidRule, path, "Self-reveal is not allowed") }
                        }
                    case .markMilestone(let id), .recordClue(let id), .recordAssistantFact(let id):
                        let kind: String
                        if case .markMilestone = effect { kind = "milestoneCompleted" }
                        else if case .recordAssistantFact = effect { kind = "assistantFact" }
                        else { kind = "observerClueFound" }
                        if !(document.facts[kind] ?? []).contains(id) { report(.missingReference, path, "Undeclared \(kind): \(id)") }
                        if conditions.flatMap(\.allFactReferences).contains(where: { $0.kind == kind && $0.id == id }) {
                            report(.invalidRule, path, "Read effects cannot produce their own unlock prerequisite")
                        }
                    case .unlockRoute: break
                    case .queueNotification(let id):
                        guard let target = items[id], target.appSurface == .notifications else { report(.missingReference, path, "Queue target must be a notification"); continue }
                        effectEdges[version.id, default: []].insert(target.initialVersionID)
                    case .changeVersion(let id, let targetID):
                        guard let target = items[id], target.versions.contains(where: { $0.id == targetID }) else { report(.missingReference, path, "Version does not belong to target content"); continue }
                        effectEdges[version.id, default: []].insert(targetID)
                        if !StoryID.isValid("replacement.\(version.id).e\(index)") { report(.invalidID, path, "Generated replacement ID exceeds the stable-ID limit") }
                    }
                }
            }
        }
        var visiting: Set<String> = [], visited: Set<String> = []
        func hasCycle(_ id: String) -> Bool {
            if visiting.contains(id) { return true }
            if visited.contains(id) { return false }
            visiting.insert(id)
            for next in (effectEdges[id] ?? []).sorted() where hasCycle(next) { return true }
            visiting.remove(id); visited.insert(id)
            return false
        }
        for id in versionIDs.sorted() where hasCycle(id) { report(.cycle, id, "Cyclic content-delivery effects"); break }
        return diagnostics
    }

    private static func nonempty(_ text: String) -> Bool { !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    private static func validMessages(_ messages: [StoryMessageRecord]) -> Bool {
        Set(messages.map(\.id)).count == messages.count && messages.allSatisfy { StoryID.isValid($0.id) && nonempty($0.sender) && nonempty($0.text) }
    }
    private static func validPayload(_ payload: StoryContentPayload) -> Bool {
        func blocks(_ values: [StoryTextBlock]) -> Bool { !values.isEmpty && values.allSatisfy { nonempty($0.text) } }
        switch payload {
        case .email(let p): return nonempty(p.sender) && !p.recipients.isEmpty && p.recipients.allSatisfy(nonempty) && blocks(p.blocks)
        case .news(let p): return nonempty(p.publication) && blocks(p.blocks)
        case .messages(let p): return !p.participants.isEmpty && p.participants.allSatisfy(nonempty) && !p.messages.isEmpty && validMessages(p.messages) && p.messages.allSatisfy { p.participants.contains($0.sender) }
        case .social(let p): return nonempty(p.handle) && nonempty(p.text) && validMessages(p.replies ?? [])
        case .video(let p):
            let cues = p.transcript ?? []
            return p.durationSeconds.map { $0.isFinite && $0 > 0 } != false
                && cues.allSatisfy { cue in cue.startSeconds.isFinite && cue.startSeconds >= 0 && nonempty(cue.text) && p.durationSeconds.map { cue.startSeconds <= $0 } != false }
                && cues.map(\.startSeconds) == cues.map(\.startSeconds).sorted()
        case .web(let p): return p.path.hasPrefix("/") && !p.path.hasPrefix("//") && blocks(p.blocks)
        case .photos(let p): return p.assetID != nil || !p.metadata.isEmpty
        case .assistant(let p): return !p.turns.isEmpty && Set(p.turns.map(\.id)).count == p.turns.count && p.turns.allSatisfy { StoryID.isValid($0.id) && nonempty($0.text) }
        case .diagnostics(let p): return !p.entries.isEmpty && Set(p.entries.map(\.id)).count == p.entries.count && p.entries.allSatisfy { StoryID.isValid($0.id) && nonempty($0.key) }
        case .notifications(let p): return nonempty(p.message)
        }
    }

    private static func payloadReferences(_ payload: StoryContentPayload) -> [(id: String, asset: Bool)] {
        switch payload {
        case .email(let p): return (p.attachments ?? []).map { ($0.contentID, false) }
        case .messages(let p): return (p.links ?? []).map { ($0.contentID, false) }
        case .assistant(let p): return (p.links ?? []).map { ($0.contentID, false) }
        case .news(let p): return (p.relatedContent ?? []).map { ($0.contentID, false) }
        case .social(let p): return (p.mediaAssetIDs ?? []).map { ($0, true) }
        case .video(let p): return [p.mediaAssetID, p.thumbnailAssetID].compactMap { $0 }.map { ($0, true) }
        case .web(let p): return (p.links ?? []).map { ($0.contentID, false) }
        case .photos(let p): return p.assetID.map { [($0, true)] } ?? []
        case .notifications(let p): return p.targetContentID.map { [($0, false)] } ?? []
        default: return []
        }
    }
}
