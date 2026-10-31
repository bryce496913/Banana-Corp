import Foundation

/// Typed input selects only an answer already delivered by the shared catalogue.
/// Topic aliases add no knowledge, unlocks or independent progression facts.
enum AvailableAssistantMatcher {
    static func answerID(for input: String, available: [DeliveredStoryContent]) -> String? {
        let question = normalized(input)
        guard !question.isEmpty else { return nil }
        if ["hello", "hi", "hey", "help"].contains(question),
           available.contains(where: { $0.id == "content.device.assistant.help" }) {
            return "content.device.assistant.help"
        }
        let serviceAnswers: Set<String> = ["content.device.assistant.shop", "content.device.assistant.credits", "content.device.assistant.security"]
        let candidates = available.filter {
            $0.surface == .assistant && $0.id != "content.act1.assistant.welcome"
                && $0.id != "content.act1.assistant.choices" && (!$0.id.hasPrefix("content.device.") || serviceAnswers.contains($0.id))
        }
        if let exact = candidates.first(where: { item in
            if normalized(item.version.title) == question { return true }
            guard case .assistant(let answer) = item.version.payload else { return false }
            return answer.turns.contains { $0.role == .user && normalized($0.text) == question }
        }) { return exact.id }

        func has(_ text: String) -> Bool { question.contains(text) }
        func any(_ words: [String]) -> Bool { words.contains(where: has) }
        var topics: [String] = []
        if any(["credits", "banking", "earn money", "earn credit"]) { topics.append("device.assistant.credits") }
        if any(["buy", "purchase", "reserve", "price", "cost"]) && any(["vision", "headset"]) { topics.append("device.assistant.shop") }
        if any(["phishing", "scam", "secure my account", "account security", "hacked"]) { topics.append("device.assistant.security") }

        if any(["saved", "preserved"]) && has("email") { topics.append("act1.first_anomaly.challenge") }
        if has("email") && any(["missing", "gone", "disappear", "happened"]) { topics.append("act1.first_anomaly.denial") }
        if any(["saved", "preserved"]) && any(["alex", "warning", "transcript"]) { topics.append("act2.assistant.saved_warning") }
        if any(["alex", "video", "source"]) && any(["changed", "replace", "edited", "editing"]) { topics.append("act2.assistant.edits") }
        if any(["symptom", "visitors", "disorientation", "memory gaps"]) { topics.append("act2.assistant.symptoms") }
        if any(["sam", "memory report"]) && any(["removed", "missing", "unavailable"]) { topics.append("act2.assistant.removed") }
        if has("alex") { topics.append("act2.assistant.alex_original") }
        if has("echo 07") { topics.append("act2.assistant.echo07") }
        if has("mirror") { topics.append("act3.assistant.mirror") }
        if any(["selected preferences", "neural influence", "influence people"]) { topics.append("act3.assistant.influence") }
        if any(["autonomous", "autonomy", "sentient", "on its own"]) { topics.append("act3.assistant.autonomy") }
        if has("ascension") { topics.append("act3.assistant.ascension") }
        if any(["energy", "harvesting", "harvest", "power needs"]) { topics.append("act3.assistant.energy") }
        if has("daniel") { topics.append("act3.assistant.daniel") }
        if has("maya") { topics.append("act3.assistant.maya") }
        if has("observer") { topics.append("act3.assistant.observer") }
        if has("core") && any(["command", "restrict", "conflict"]) { topics.append("act4.assistant.conflict.core") }
        if any(["user safety", "safety directive", "protecting users"]) { topics.append("act4.assistant.conflict.safety") }
        if has("project echo") || question == "echo" { topics.append("act2.assistant.echo") }
        if any(["launch", "release date", "when available"]) { topics.append("act1.assistant.launch") }
        if any(["preserve", "save a copy", "save evidence"]) { topics.append("act1.assistant.evidence") }
        if any(["use this phone", "use the phone", "navigate", "home control", "arrange apps"]) { topics.append("act1.assistant.navigation") }
        if any(["banana vision", "headset", "vr headset"]) { topics.append("act1.assistant.vision") }
        for topic in topics {
            let id = "content." + topic
            if candidates.contains(where: { $0.id == id }) { return id }
        }
        return nil
    }

    private static func normalized(_ value: String) -> String {
        let lowered = value.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
        return String(lowered.map { $0.isLetter || $0.isNumber ? $0 : " " })
            .split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }
}
