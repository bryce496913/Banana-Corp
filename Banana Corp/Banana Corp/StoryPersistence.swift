import Foundation

enum StorySaveIssue: Error, Equatable {
    case invalidData
    case missingSave
    case unsupportedSchema(Int)
    case migrationRequired(Int)
    case migrationFailed
    case unavailableStorage
    case ioFailure(String)
}

protocol StoryPersistence {
    func read() throws -> Data?
    func write(_ data: Data) throws
    /// Called only for an explicit reset. Must preserve the original before replacement.
    func archiveForReset() throws
}

struct StoryFilePersistence: StoryPersistence {
    let fileURL: URL?

    static var applicationDefault: StoryFilePersistence {
        StoryFilePersistence(fileURL: FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first?.appendingPathComponent("BananaCorp", isDirectory: true)
            .appendingPathComponent("story-save.json"))
    }

    func read() throws -> Data? {
        guard let fileURL else { throw StorySaveIssue.unavailableStorage }
        do { return try Data(contentsOf: fileURL) }
        catch CocoaError.fileReadNoSuchFile { return nil }
        catch { throw error }
    }

    func write(_ data: Data) throws {
        guard let fileURL else { throw StorySaveIssue.unavailableStorage }
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: fileURL, options: .atomic)
    }

    func archiveForReset() throws {
        guard let fileURL else { throw StorySaveIssue.unavailableStorage }
        // read() distinguishes missing files from permission/other failures.
        guard try read() != nil else { return }
        let archive = fileURL.deletingLastPathComponent()
            .appendingPathComponent("story-reset-\(UUID().uuidString).json")
        try FileManager.default.copyItem(at: fileURL, to: archive)
    }
}

/// Schema 1 is the Pass 2 save. Its facts remain intact when delivery state is added.
struct StorySaveCodec {
    typealias Migration = (Data) throws -> Data
    var migrations: [Int: Migration] = [1: migrateSchema1]

    static func migrateSchema1(_ data: Data) throws -> Data {
        guard var object = try JSONSerialization.jsonObject(with: data) as? [String: Any], object["schemaVersion"] as? Int == 1 else {
            throw StorySaveIssue.migrationFailed
        }
        if object["contentDelivery"] == nil {
            object["contentDelivery"] = try JSONSerialization.jsonObject(with: JSONEncoder().encode(StoryContentDeliveryState()))
        }
        object["schemaVersion"] = 2
        return try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
    }

    private struct Header: Decodable { let schemaVersion: Int }

    func encode(_ state: StoryState) throws -> Data {
        guard state.isValid else { throw StorySaveIssue.invalidData }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(state)
    }

    func decode(_ data: Data) throws -> (state: StoryState, migratedFrom: Int?) {
        let initialVersion: Int
        do { initialVersion = try JSONDecoder().decode(Header.self, from: data).schemaVersion }
        catch { throw StorySaveIssue.invalidData }
        guard initialVersion >= 0 else { throw StorySaveIssue.invalidData }
        guard initialVersion <= StoryState.currentSchemaVersion else { throw StorySaveIssue.unsupportedSchema(initialVersion) }
        var bytes = data
        var version = initialVersion
        while version < StoryState.currentSchemaVersion {
            guard let migration = migrations[version] else { throw StorySaveIssue.migrationRequired(version) }
            do {
                bytes = try migration(bytes)
                let next = try JSONDecoder().decode(Header.self, from: bytes).schemaVersion
                guard next == version + 1 else { throw StorySaveIssue.migrationFailed }
                version = next
            } catch { throw StorySaveIssue.migrationFailed }
        }
        let state: StoryState
        do { state = try JSONDecoder().decode(StoryState.self, from: bytes) }
        catch { throw StorySaveIssue.invalidData }
        guard state.isValid else { throw StorySaveIssue.invalidData }
        return (state, initialVersion == version ? nil : initialVersion)
    }
}

/// Previews and tests never write the player's live story save.
final class InMemoryStoryPersistence: StoryPersistence {
    private(set) var data: Data?
    private(set) var archives: [Data] = []
    init(data: Data? = nil) { self.data = data }
    func read() throws -> Data? { data }
    func write(_ data: Data) throws { self.data = data }
    func archiveForReset() throws { if let data { archives.append(data) } }
}
