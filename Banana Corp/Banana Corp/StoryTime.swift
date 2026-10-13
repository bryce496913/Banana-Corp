import Foundation

/// Narrative days and timestamps never advance from the real clock on their own.
struct NarrativeTimestamp: Codable, Equatable {
    let day: Int
    let hour: Int
    let minute: Int

    var isValid: Bool { (1...1_000_000).contains(day) && (0...23).contains(hour) && (0...59).contains(minute) }
}

enum StoryClockPresentation: Codable, Equatable {
    case deviceTime
    case fixed(NarrativeTimestamp)
}

struct StoryTimeState: Codable, Equatable {
    var relativeDay = 1
    var fictionalTime: NarrativeTimestamp?
    // A caller may configure 9:41 later; this pass does not decide when to show it.
    var openingClock: StoryClockPresentation = .deviceTime

    var isValid: Bool {
        guard (1...1_000_000).contains(relativeDay), fictionalTime?.isValid != false else { return false }
        if case .fixed(let timestamp) = openingClock { return timestamp.isValid }
        return true
    }
}

struct StoryTimeContext: Equatable {
    enum RelativeDayLabel: Equatable { case today, tomorrow, yesterday, offset(Int) }
    let deviceTime: Date
    let timeZoneIdentifier: String
    let story: StoryTimeState

    func label(for timestamp: NarrativeTimestamp) -> RelativeDayLabel? {
        guard story.isValid, timestamp.isValid else { return nil }
        switch timestamp.day - story.relativeDay {
        case 0: return .today
        case 1: return .tomorrow
        case -1: return .yesterday
        case let difference: return .offset(difference)
        }
    }
}

/// Deliberate, bounded steps; no elapsed-time gate or automatic completion.
struct StoryPresentationProgress: Equatable {
    private(set) var index = 0
    func canComplete(count: Int) -> Bool { count > 0 && index == count - 1 }
    mutating func advance(count: Int) {
        guard count > 0, index < count - 1 else { return }
        index += 1
    }
    mutating func goBack() { index = max(0, index - 1) }
}
