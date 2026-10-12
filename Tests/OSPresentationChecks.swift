import Foundation

@main
struct OSPresentationChecks {
    static func main() {
        let start = Date(timeIntervalSince1970: 1_000)
        var state = OSPresentationState()
        let original = OSPresentationConfiguration()
        let event = OSPresentationEvent(
            status: OSStatusOverride(carrier: "Preview carrier", signal: .weak, batteryPercent: 5),
            effect: OSVisualEffect(target: .carrier, kind: .textCorruption("Preview")),
            interruption: OSInterruption(kind: .systemAlert, title: "Preview", message: "Preview only"),
            duration: 2
        )
        precondition(state.configuration == original)
        precondition(state.resolved(at: start) == original)
        precondition(!state.begin(event, at: start, monotonicTime: 100), "Normal play must never activate disturbances")
        state.configure(OSPresentationConfiguration(mode: .normal, palette: .critical,
            status: OSStatusOverride(carrier: "Override"),
            apps: [.settings: OSAppVisualOverride(displayName: "Override")],
            visibleLockedApps: [.settings]))
        precondition(state.configuration == original, "Normal must strip every override")

        for mode in OSVisualMode.allCases where mode != .normal {
            state.configure(OSPresentationConfiguration(mode: mode))
            precondition(state.configuration.mode == mode)
            precondition(state.activeEvent == nil, "A mode alone must not invent a story event")
        }

        state.configure(OSPresentationConfiguration(mode: .subtleAnomaly,
            status: OSStatusOverride(carrier: "Base", batteryPercent: 75),
            apps: [.aiAssistant: OSAppVisualOverride(displayName: "Base name", symbol: "waveform")]))
        precondition(!state.begin(event, at: Date(timeIntervalSinceReferenceDate: .nan), monotonicTime: 100))
        precondition(!state.begin(event, at: start, monotonicTime: .nan))
        precondition(!state.begin(event, at: start, monotonicTime: -1))
        precondition(state.begin(event, at: start, monotonicTime: 100))
        let firstID = state.activeEvent!.id
        precondition(state.resolved(at: start).status.carrier == "Preview carrier")
        precondition(state.resolved(at: start).status.batteryPercent == 5)
        precondition(!state.begin(event, at: start.addingTimeInterval(1), monotonicTime: 100 + 1), "Only one event may be active")
        precondition(state.event(at: start.addingTimeInterval(2)) == nil)
        precondition(state.resolved(at: start.addingTimeInterval(2)).status.carrier == "Base")
        precondition(!state.begin(event, at: start.addingTimeInterval(19), monotonicTime: 100 + 19), "Expired events retain cooldown")
        precondition(!state.begin(event, at: start.addingTimeInterval(10_000), monotonicTime: 102), "Wall-clock jumps must not bypass cooldown")
        precondition(state.begin(event, at: start.addingTimeInterval(20), monotonicTime: 100 + 20))
        let secondID = state.activeEvent!.id
        precondition(!state.endEvent(firstID), "A stale expiry/dismissal cannot end a newer event")
        precondition(state.activeEvent?.id == secondID)
        precondition(state.endEvent(secondID))
        precondition(!state.endEvent(secondID))
        precondition(!state.begin(event, at: start.addingTimeInterval(21), monotonicTime: 100 + 21), "Dismissal doesn't bypass cooldown")

        state.restoreNormal()
        precondition(state.configuration == original && state.activeEvent == nil)
        state.configure(OSPresentationConfiguration(mode: .critical))
        precondition(!state.begin(event, at: start.addingTimeInterval(22), monotonicTime: 100 + 22), "Restore/mode changes don't bypass cooldown")

        let partial = OSPresentationEvent(
            apps: [.aiAssistant: OSAppVisualOverride(symbol: "star")], duration: 100
        )
        state.configure(OSPresentationConfiguration(mode: .compromised,
            apps: [.aiAssistant: OSAppVisualOverride(displayName: "Base name", symbol: "waveform")]))
        precondition(state.begin(partial, at: start.addingTimeInterval(40), monotonicTime: 100 + 40))
        precondition(state.activeEvent!.payload.duration == 4)
        let resolved = state.resolved(at: start.addingTimeInterval(41))
        precondition(resolved.apps[.aiAssistant]?.displayName == "Base name")
        precondition(resolved.apps[.aiAssistant]?.symbol == "star")
        state.expire(at: start.addingTimeInterval(44))
        precondition(state.activeEvent == nil)
        precondition(state.resolved(at: start.addingTimeInterval(44)).apps[.aiAssistant]?.symbol == "waveform")
        let clamped = OSPresentationEvent(status: OSStatusOverride(), duration: -5)
        // Empty payloads and invalid timing cannot allocate an expiry task.
        precondition(clamped.sanitized == nil)
        precondition(OSPresentationEvent(duration: .infinity).sanitized == nil)
        precondition(OSPresentationEvent(apps: [.snake: OSAppVisualOverride(displayName: "  ")]).sanitized == nil)
        precondition(OSPresentationEvent(status: OSStatusOverride(batteryPercent: 80), duration: -1).sanitized?.duration == 1.2)
        precondition(OSStatusOverride(batteryPercent: 200).sanitized.batteryPercent == 100)
        precondition(OSStatusOverride(batteryPercent: -1).sanitized.batteryPercent == 0)
        precondition(OSStatusOverride(carrier: String(repeating: "A", count: 40)).sanitized.carrier?.count == 24)
        precondition(OSVisualText.clean("  \nPreview\u{0000}  ", limit: 24) == "Preview")
        precondition(OSVisualEffect(target: .appIcon(.snake), kind: .textCorruption("Preview")).sanitized == nil)
        precondition(OSVisualEffect(target: .appName(.snake), kind: .textCorruption("  ")).sanitized == nil)

        precondition(OSVisualSafety.interruptionHeight(availableHeight: 50) == 0)
        precondition(OSVisualSafety.interruptionHeight(availableHeight: 120) == 56)
        precondition(OSVisualSafety.interruptionHeight(availableHeight: 1_000) == 160)
        precondition(OSVisualSafety.interruptionHeight(availableHeight: .nan) == 0)

        // Environmental data is explicit input, not a permission/network-backed service.
        let context = OSEnvironmentContext(date: start)
        precondition(context.date == start && context.weather == nil)

        print("PASS: normal identity, explicit modes, one event, expiry/restoration, cooldown, stale dismissal, partial overrides, sanitization, timing/battery bounds, and passive environmental context")
    }
}
