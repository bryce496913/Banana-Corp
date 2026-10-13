import Foundation

extension StoryAppSurface {
    var displayName: String {
        switch self {
        case .email: return "Email"
        case .news: return "News"
        case .messages: return "Messages"
        case .social: return "Social X"
        case .video: return "Video"
        case .web: return "Web Browser"
        case .photos: return "Photos"
        case .assistant: return "AI Assistant"
        case .diagnostics: return "Assistant Diagnostics"
        case .notifications: return "System Notifications"
        }
    }
    var symbol: String {
        switch self {
        case .email: return "envelope"
        case .news: return "newspaper"
        case .messages: return "message"
        case .social: return "bubble.left.and.bubble.right"
        case .video: return "play.rectangle"
        case .web: return "globe"
        case .photos: return "photo"
        case .assistant, .diagnostics: return "waveform"
        case .notifications: return "bell"
        }
    }
}

struct EvidenceDisplayField: Identifiable, Equatable {
    enum Style: Equatable { case heading, body, metadata }
    let id: String
    let label: String
    let value: String
    let style: Style
    var isReference = false
    var displayValue: String { isReference ? "Local reference" : value }
}

/// The same normalized fields render snapshots and produce factual, deterministic differences.
enum EvidenceContentFields {
    static func fields(for version: StoryContentVersion) -> [EvidenceDisplayField] {
        var fields: [EvidenceDisplayField] = []
        func add(_ id: String, _ label: String, _ value: String?, _ style: EvidenceDisplayField.Style = .metadata, reference: Bool = false) {
            if let value { fields.append(.init(id: id, label: label, value: value, style: style, isReference: reference)) }
        }
        func blocks(_ blocks: [StoryTextBlock]) {
            for (index, block) in blocks.enumerated() {
                add("block.\(index).kind", "Section \(index + 1) format", block.kind.rawValue)
                add("block.\(index).text", "Section \(index + 1)", block.text, block.kind == .heading ? .heading : .body)
            }
        }
        func links(_ links: [StoryContentLink]) {
            for (index, link) in links.enumerated() {
                add("link.\(index).label", "Reference \(index + 1)", link.label)
                add("link.\(index).target", "Linked source \(index + 1)", link.contentID, reference: true)
            }
        }
        func messages(_ messages: [StoryMessageRecord]) {
            for (index, message) in messages.enumerated() {
                add("message.\(message.id).position", "Message position", String(index + 1))
                add("message.\(message.id).sender", "Message \(index + 1) from", message.sender)
                add("message.\(message.id).text", "Message \(index + 1)", message.text, .body)
                add("message.\(message.id).timestamp", "Message \(index + 1) time", message.timestampLabel)
                add("message.\(message.id).direction", "Message \(index + 1) direction", message.direction.rawValue)
            }
        }
        add("title", "Title", version.title, .heading)
        add("subtitle", "Subtitle", version.subtitle)
        add("author", "Author", version.author)
        add("source", "Source", version.source)
        add("original.timestamp", "Original content time", version.timestampLabel)
        if let time = version.narrativeTimestamp {
            add("original.narrativeTime", "Original story timestamp", String(format: "Story day %d · %02d:%02d", time.day, time.hour, time.minute))
        }
        // Authored narrative IDs/rules remain stored, but are not player-facing copy or differences.
        switch version.payload {
        case .email(let p): add("sender", "From", p.sender); add("recipients", "To", p.recipients.joined(separator: ", ")); blocks(p.blocks); links(p.attachments ?? [])
        case .news(let p): add("publication", "Publication", p.publication); blocks(p.blocks); links(p.relatedContent ?? [])
        case .messages(let p): add("participants", "Participants", p.participants.joined(separator: ", ")); messages(p.messages); links(p.links ?? [])
        case .social(let p):
            add("handle", "Account", p.handle); add("post", "Post", p.text, .body); messages(p.replies ?? [])
            add("media", "Media references", p.mediaAssetIDs?.joined(separator: ", "), reference: true)
        case .video(let p):
            add("creator", "Creator", p.creator); add("duration", "Duration", p.durationSeconds.map { "\($0) seconds" })
            add("media", "Media reference", p.mediaAssetID, reference: true); add("thumbnail", "Thumbnail reference", p.thumbnailAssetID, reference: true)
            for (index, cue) in (p.transcript ?? []).enumerated() {
                add("cue.\(index).time", "Transcript \(index + 1) time", "\(cue.startSeconds) seconds")
                add("cue.\(index).text", "Transcript \(index + 1)", cue.text, .body)
            }
        case .web(let p): add("path", "Page", p.path); blocks(p.blocks); links(p.links ?? [])
        case .photos(let p):
            add("caption", "Caption", p.caption, .body); add("media", "Media reference", p.assetID, reference: true)
            for key in p.metadata.keys.sorted() { add("photo." + key, key, p.metadata[key]) }
        case .assistant(let p):
            for (index, turn) in p.turns.enumerated() {
                add("turn.\(turn.id).position", "Turn position", String(index + 1))
                add("turn.\(turn.id).role", "Turn \(index + 1) from", turn.role.rawValue)
                add("turn.\(turn.id).text", "Turn \(index + 1)", turn.text, .body)
            }
            links(p.links ?? [])
        case .diagnostics(let p):
            for (index, entry) in p.entries.enumerated() {
                add("diagnostic.\(entry.id).position", "Entry position", String(index + 1))
                add("diagnostic.\(entry.id).key", "Entry \(index + 1)", entry.key)
                add("diagnostic.\(entry.id).value", entry.key, entry.value, .body)
                add("diagnostic.\(entry.id).level", "Entry \(index + 1) level", entry.level.rawValue)
                add("diagnostic.\(entry.id).timestamp", "Entry \(index + 1) time", entry.timestampLabel)
            }
        case .notifications(let p): add("message", "Notification", p.message, .body); add("target", "Linked source", p.targetContentID, reference: true)
        }
        return fields
    }
}

struct EvidenceDifference: Identifiable, Equatable {
    let id: String
    let label: String
    let preservedValue: String?
    let liveValue: String?
    let isReference: Bool
}

enum EvidenceLiveUnavailable: Equatable {
    case removed, missingSource, missingVersion, notAccessible, catalogueUnavailable, unverifiedVersion, saveUnavailable
    var explanation: String {
        switch self {
        case .removed: return "The source is no longer available in its app. Your preserved snapshot remains."
        case .missingSource: return "The current source could not be found. Your preserved snapshot remains."
        case .missingVersion: return "The current version could not be found. Your preserved snapshot remains."
        case .notAccessible: return "The current source is not accessible. Your preserved snapshot remains."
        case .catalogueUnavailable: return "Current content is unavailable. Your preserved snapshot remains."
        case .unverifiedVersion: return "The current version cannot be verified. Your preserved snapshot remains."
        case .saveUnavailable: return "Live comparison is temporarily unavailable while your save needs recovery."
        }
    }
}

struct EvidenceComparison {
    enum Current { case live(StoryContentVersion), unavailable(EvidenceLiveUnavailable) }
    let preserved: PreservedStoryContent
    let current: Current
    let differences: [EvidenceDifference]
    var hasVisibleDifferences: Bool { !differences.isEmpty }

    static func differences(preserved: StoryContentVersion, live: StoryContentVersion) -> [EvidenceDifference] {
        let before = Dictionary(uniqueKeysWithValues: EvidenceContentFields.fields(for: preserved).map { ($0.id, $0) })
        let after = Dictionary(uniqueKeysWithValues: EvidenceContentFields.fields(for: live).map { ($0.id, $0) })
        return Set(before.keys).union(after.keys).sorted().compactMap { id in
            guard before[id]?.value != after[id]?.value else { return nil }
            return EvidenceDifference(id: id, label: after[id]?.label ?? before[id]!.label, preservedValue: before[id]?.value, liveValue: after[id]?.value, isReference: after[id]?.isReference ?? before[id]!.isReference)
        }
    }
}
