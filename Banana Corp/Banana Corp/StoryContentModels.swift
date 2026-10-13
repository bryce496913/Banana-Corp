import Foundation

enum StoryAppSurface: String, Codable, CaseIterable, Hashable {
    case email, news, messages, social, video, web, photos, assistant, diagnostics, notifications
}

struct StoryTextBlock: Codable, Equatable {
    enum Kind: String, Codable { case heading, paragraph, quote }
    let kind: Kind
    let text: String
}

struct StoryContentLink: Codable, Equatable {
    let label: String
    let contentID: String
}

struct StoryEmailPayload: Codable, Equatable {
    let sender: String
    let recipients: [String]
    let blocks: [StoryTextBlock]
    let attachments: [StoryContentLink]?
}

struct StoryNewsPayload: Codable, Equatable {
    let publication: String
    let blocks: [StoryTextBlock]
    let relatedContent: [StoryContentLink]?
}

struct StoryMessageRecord: Codable, Equatable {
    enum Direction: String, Codable { case incoming, outgoing }
    let id: String
    let sender: String
    let text: String
    let direction: Direction
    let timestampLabel: String?
}

struct StoryConversationPayload: Codable, Equatable {
    let participants: [String]
    let messages: [StoryMessageRecord]
    let links: [StoryContentLink]?
}

struct StorySocialPayload: Codable, Equatable {
    let handle: String
    let text: String
    let mediaAssetIDs: [String]?
    let replies: [StoryMessageRecord]?
}

struct StoryTranscriptCue: Codable, Equatable {
    let startSeconds: Double
    let text: String
}

struct StoryVideoPayload: Codable, Equatable {
    let creator: String?
    let durationSeconds: Double?
    let mediaAssetID: String?
    let thumbnailAssetID: String?
    /// In-world local source location; never fetched from the internet.
    let sourcePath: String?
    let links: [StoryContentLink]?
    let transcript: [StoryTranscriptCue]?
}

struct StoryWebPayload: Codable, Equatable {
    /// A fictional path within the local catalogue, never a URL to fetch.
    let path: String
    let blocks: [StoryTextBlock]
    let links: [StoryContentLink]?
}

struct StoryPhotoPayload: Codable, Equatable {
    let assetID: String?
    let caption: String?
    let metadata: [String: String]
}

struct StoryAssistantTurn: Codable, Equatable {
    enum Role: String, Codable { case user, assistant, system }
    let id: String
    let role: Role
    let text: String
}

struct StoryAssistantPayload: Codable, Equatable { let turns: [StoryAssistantTurn]; let links: [StoryContentLink]? }

struct StoryDiagnosticEntry: Codable, Equatable {
    enum Level: String, Codable { case info, warning, error }
    let id: String
    let level: Level
    let key: String
    let value: String
    let timestampLabel: String?
}

struct StoryDiagnosticsPayload: Codable, Equatable { let entries: [StoryDiagnosticEntry] }
struct StoryNotificationPayload: Codable, Equatable {
    let message: String
    let targetContentID: String?
}

enum StoryContentPayload: Codable, Equatable {
    case email(StoryEmailPayload), news(StoryNewsPayload), messages(StoryConversationPayload)
    case social(StorySocialPayload), video(StoryVideoPayload), web(StoryWebPayload), photos(StoryPhotoPayload)
    case assistant(StoryAssistantPayload), diagnostics(StoryDiagnosticsPayload), notifications(StoryNotificationPayload)

    var surface: StoryAppSurface {
        switch self {
        case .email: return .email
        case .news: return .news
        case .messages: return .messages
        case .social: return .social
        case .video: return .video
        case .web: return .web
        case .photos: return .photos
        case .assistant: return .assistant
        case .diagnostics: return .diagnostics
        case .notifications: return .notifications
        }
    }

    private enum Keys: String, CodingKey { case type, data }
    init(from decoder: Decoder) throws {
        try StoryJSONKey.requireOnly(["type", "data"], in: decoder)
        let c = try decoder.container(keyedBy: Keys.self)
        switch try c.decode(StoryAppSurface.self, forKey: .type) {
        case .email: self = .email(try c.decode(StoryEmailPayload.self, forKey: .data))
        case .news: self = .news(try c.decode(StoryNewsPayload.self, forKey: .data))
        case .messages: self = .messages(try c.decode(StoryConversationPayload.self, forKey: .data))
        case .social: self = .social(try c.decode(StorySocialPayload.self, forKey: .data))
        case .video: self = .video(try c.decode(StoryVideoPayload.self, forKey: .data))
        case .web: self = .web(try c.decode(StoryWebPayload.self, forKey: .data))
        case .photos: self = .photos(try c.decode(StoryPhotoPayload.self, forKey: .data))
        case .assistant: self = .assistant(try c.decode(StoryAssistantPayload.self, forKey: .data))
        case .diagnostics: self = .diagnostics(try c.decode(StoryDiagnosticsPayload.self, forKey: .data))
        case .notifications: self = .notifications(try c.decode(StoryNotificationPayload.self, forKey: .data))
        }
    }
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: Keys.self)
        try c.encode(surface, forKey: .type)
        switch self {
        case .email(let value): try c.encode(value, forKey: .data)
        case .news(let value): try c.encode(value, forKey: .data)
        case .messages(let value): try c.encode(value, forKey: .data)
        case .social(let value): try c.encode(value, forKey: .data)
        case .video(let value): try c.encode(value, forKey: .data)
        case .web(let value): try c.encode(value, forKey: .data)
        case .photos(let value): try c.encode(value, forKey: .data)
        case .assistant(let value): try c.encode(value, forKey: .data)
        case .diagnostics(let value): try c.encode(value, forKey: .data)
        case .notifications(let value): try c.encode(value, forKey: .data)
        }
    }
}

/// Facts can only be awarded for this exact authored, preservable version.
struct StoryEvidenceRules: Codable, Equatable {
    let securedObserverClueID: String?
    let preservationMilestoneID: String?
    let comparisonMilestoneID: String?

    private enum CodingKeys: String, CodingKey { case securedObserverClueID, preservationMilestoneID, comparisonMilestoneID }
    init(from decoder: Decoder) throws {
        try StoryJSONKey.requireOnly(["securedObserverClueID", "preservationMilestoneID", "comparisonMilestoneID"], in: decoder)
        let fields = try decoder.container(keyedBy: CodingKeys.self)
        securedObserverClueID = try fields.decodeIfPresent(String.self, forKey: .securedObserverClueID)
        preservationMilestoneID = try fields.decodeIfPresent(String.self, forKey: .preservationMilestoneID)
        comparisonMilestoneID = try fields.decodeIfPresent(String.self, forKey: .comparisonMilestoneID)
    }
}

struct StoryContentVersion: Codable, Identifiable, Equatable {
    let id: String
    let version: Int
    let title: String
    let subtitle: String?
    let author: String?
    let source: String?
    let timestampLabel: String?
    let narrativeTimestamp: NarrativeTimestamp?
    let preservedEvidenceID: String?
    let payload: StoryContentPayload
    let effectsOnRead: [StoryEffect]?
    let evidenceRules: StoryEvidenceRules?
    let narrativeMetadata: [String: String]?

    var readEventID: String { "event.read." + id }
}

struct StoryContentItem: Codable, Identifiable, Equatable {
    enum Visibility: String, Codable { case listed, hiddenUntilRevealed }
    let id: String
    let appSurface: StoryAppSurface
    let actAvailable: StoryAct
    let order: Int
    let visibility: Visibility?
    let unlockConditions: [StoryCondition]?
    let initialVersionID: String
    let versions: [StoryContentVersion]
}

struct StoryLocalAsset: Codable, Equatable { let id: String; let fileName: String }
struct StoryContentDocument: Codable {
    let schemaVersion: Int
    /// Explicit external fact declarations, not new story requirements.
    let facts: [String: [String]]
    let assets: [StoryLocalAsset]?
    let items: [StoryContentItem]
}

struct StoryContentSnapshot: Codable, Equatable {
    let schemaVersion: Int
    let contentID: String
    let appSurface: StoryAppSurface
    let version: StoryContentVersion
}

struct StoryJSONKey: CodingKey {
    let stringValue: String
    var intValue: Int? { nil }
    init?(stringValue: String) { self.stringValue = stringValue }
    init?(intValue: Int) { return nil }
    static func requireOnly(_ allowed: Set<String>, in decoder: Decoder) throws {
        let keys = try decoder.container(keyedBy: Self.self).allKeys.map(\.stringValue)
        guard Set(keys).isSubset(of: allowed) else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Unknown rule/payload fields"))
        }
    }
}

/// The launch is narrative day 2, regardless of installation date or time zone.
enum StoryContentTime {
    static let launchDay = NarrativeTimestamp(day: 2, hour: 9, minute: 41)
    static func label(for version: StoryContentVersion, context: StoryTimeContext) -> String? {
        guard let timestamp = version.narrativeTimestamp, let relative = context.label(for: timestamp) else { return version.timestampLabel }
        let day: String
        switch relative {
        case .today: day = "Today"
        case .tomorrow: day = "Tomorrow"
        case .yesterday: day = "Yesterday"
        case .offset: day = "Story day \(timestamp.day)"
        }
        return String(format: "%@ · %02d:%02d", day, timestamp.hour, timestamp.minute)
    }
}
