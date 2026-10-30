import Foundation

private final class PhoneLifePersistence: StoryPersistence {
    var data: Data?
    var fail = false
    func read() throws -> Data? { data }
    func write(_ bytes: Data) throws {
        if fail { throw StorySaveIssue.ioFailure("phone-life fixture failure") }
        data = bytes
    }
    func archiveForReset() throws {}
}

@main struct PhoneLifeChecks {
    @MainActor static func main() throws {
        let source = URL(fileURLWithPath: CommandLine.arguments[1])
        let resources = RestrictedAccessCatalogueLoader.load(data: try Data(contentsOf: source.appendingPathComponent("RestrictedAccess.json")))
        let catalogue = StoryContentCatalogueLoader.load(fileURL: source.appendingPathComponent("StoryContent.json"), restrictedResourceIDs: Set(try resources.get().resources.map(\.id)))
        _ = try catalogue.get()
        let storage = PhoneLifePersistence()
        let story = StoryProgressionStore(persistence: storage)
        let access = RestrictedAccessStore(progression: story, catalogue: resources)
        let content = StoryContentStore(progression: story, catalogue: catalogue, access: access)
        precondition(story.phoneLife.balance == 100 && story.state.phoneLife == nil)
        let old = try StorySaveCodec().encode(story.state)
        let decodedOld = try StorySaveCodec().decode(old).state
        precondition(decodedOld.phoneLife == nil)
        let before = story.state
        if case .success = story.purchaseHeadset() { preconditionFailure("Purchase without funds") }
        precondition(story.state == before)
        storage.fail = true
        if case .success = story.earnDeviceCredits(task: "orientation") { preconditionFailure("Failed write awarded money") }
        precondition(story.state == before)
        storage.fail = false
        _ = try story.earnDeviceCredits(task: "orientation").get()
        _ = try story.earnDeviceCredits(task: "orientation").get()
        precondition(story.phoneLife.balance == 200)
        _ = try story.earnDeviceCredits(task: "survey").get()
        _ = try story.purchaseHeadset().get()
        _ = try story.purchaseHeadset().get()
        precondition(story.phoneLife.balance == 0 && story.phoneLife.headsetPurchased)
        _ = try story.submitFictionalPrizeProfile().get()
        precondition(story.phoneLife.securityCompromised && story.phoneLife.balance == 0)
        _ = try story.recoverDeviceAccount().get()
        _ = try story.recoverDeviceAccount().get()
        precondition(!story.phoneLife.securityCompromised && story.phoneLife.balance == 0)
        _ = try story.earnDeviceCredits(task: "delivery").get()
        precondition(story.phoneLife.balance == 100)
        _ = try story.submitFictionalPrizeProfile().get()
        precondition(!story.phoneLife.securityCompromised, "Consumed offer cannot repeat a debit")
        var prefs = story.phoneLife.preferences; prefs.reduceMotion = true; prefs.haptics = false
        _ = try story.updatePhonePreferences(prefs).get()
        let available = content.availableItems(for: .assistant)
        precondition(AvailableAssistantMatcher.answerID(for: "what is banana vision?", available: available) == "content.act1.assistant.vision")
        for question in ["ASCENSION", "Maya", "Observer", "Project ECHO", "ECHO-07"] {
            precondition(AvailableAssistantMatcher.answerID(for: question, available: available) == nil)
        }
        let request = DeviceConversationRequest(channel: "assistant", question: "What is Banana Vision?", companyQuestion: false)
        let priorChat = story.state
        storage.fail = true
        if case .success = content.read("content.act1.assistant.vision", versionID: "version.act1.assistant.vision.v1", conversation: request) {
            preconditionFailure("Failed chat write accepted")
        }
        precondition(story.state == priorChat, "Read effect and transcript must save atomically")
        storage.fail = false
        _ = try content.read("content.act1.assistant.vision", versionID: "version.act1.assistant.vision.v1", conversation: request).get()
        precondition(story.phoneLife.conversations.count == 2 && story.state.readContentIDs.contains("version.act1.assistant.vision.v1"))
        _ = try content.read("content.act1.assistant.vision", versionID: "version.act1.assistant.vision.v1", conversation: request).get()
        precondition(story.phoneLife.conversations.count == 4)
        let restored = StoryProgressionStore(persistence: storage)
        precondition(restored.state == story.state && restored.phoneLife.preferences == prefs)
        _ = try story.resetForNewGame().get()
        precondition(story.phoneLife.balance == 100 && story.phoneLife.conversations.isEmpty && !story.phoneLife.headsetPurchased)
        precondition(story.phoneLife.preferences == prefs)
        let scamStore = StoryProgressionStore(persistence: InMemoryStoryPersistence())
        _ = try scamStore.submitFictionalPrizeProfile().get()
        precondition(scamStore.phoneLife.balance == 50 && scamStore.phoneLife.securityCompromised)
        if case .success = scamStore.purchaseHeadset() { preconditionFailure("Compromised purchase accepted") }
        _ = try scamStore.recoverDeviceAccount().get()
        precondition(scamStore.phoneLife.balance == 100 && !scamStore.phoneLife.securityCompromised)
        precondition(scamStore.state.currentAct == .thePerfectProduct && scamStore.state.completedMilestoneIDs.isEmpty)
        print("PASS MODEL ONLY: phone-life legacy saves, atomic currency/chat failure, once-only rewards/purchase/scam/recovery, private local conversations, knowledge-gated matching and preference/reset persistence")
    }
}
