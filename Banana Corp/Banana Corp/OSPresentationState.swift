import Foundation

enum OSVisualMode: String, CaseIterable, Hashable {
    case normal, subtleAnomaly, interference, compromised, critical
}

enum OSPaletteStyle: Equatable {
    case standard, muted, interference, compromised, critical
}

struct OSStatusOverride: Equatable {
    enum Signal: Equatable { case full, weak, unavailable }
    enum WiFi: Equatable { case connected, unavailable }

    var carrier: String?
    var signal: Signal?
    var wifi: WiFi?
    var batteryPercent: Int?

    var sanitized: Self {
        var result = self
        result.carrier = carrier.flatMap { OSVisualText.clean($0, limit: 24) }
        result.batteryPercent = batteryPercent.map { min(100, max(0, $0)) }
        return result
    }

    func overlaying(_ other: Self) -> Self {
        Self(carrier: other.carrier ?? carrier, signal: other.signal ?? signal,
             wifi: other.wifi ?? wifi, batteryPercent: other.batteryPercent ?? batteryPercent)
    }
}

struct OSAppVisualOverride: Equatable {
    var displayName: String?
    var symbol: String?

    var sanitized: Self {
        Self(displayName: displayName.flatMap { OSVisualText.clean($0, limit: 32) },
             symbol: symbol.flatMap { OSVisualText.clean($0, limit: 80) })
    }
}

enum OSVisualTarget: Equatable {
    case carrier, connectivity
    case appIcon(PhoneAppRoute), appName(PhoneAppRoute), screenTitle(PhoneAppRoute)

    var supportsText: Bool {
        switch self {
        case .carrier, .appName, .screenTitle: return true
        case .connectivity, .appIcon: return false
        }
    }
}

struct OSVisualEffect: Equatable {
    enum Kind: Equatable {
        case distortion, opacityPulse
        case textCorruption(String)
    }
    let target: OSVisualTarget
    let kind: Kind

    var sanitized: Self? {
        if case .textCorruption(let replacement) = kind {
            guard target.supportsText, let text = OSVisualText.clean(replacement, limit: 24) else { return nil }
            return Self(target: target, kind: .textCorruption(text))
        }
        return self
    }
}

struct OSInterruption: Equatable {
    enum Kind: Equatable { case notification, systemAlert, assistantMessage }
    let kind: Kind
    let title: String
    let message: String

    var sanitized: Self? {
        guard let title = OSVisualText.clean(title, limit: 60),
              let message = OSVisualText.clean(message, limit: 180) else { return nil }
        return Self(kind: kind, title: title, message: message)
    }
}

struct OSPresentationConfiguration: Equatable {
    var mode: OSVisualMode = .normal
    var palette: OSPaletteStyle = .standard
    var status = OSStatusOverride()
    var apps: [PhoneAppRoute: OSAppVisualOverride] = [:]
    // Only reveal a locked icon; authorization always comes from AppState.unlockedApps.
    var visibleLockedApps: Set<PhoneAppRoute> = []

    var sanitized: Self {
        guard mode != .normal else { return Self() }
        var result = self
        result.status = status.sanitized
        result.apps = apps.mapValues { $0.sanitized }
        return result
    }
}

/// One bounded event may bundle status changes, an effect, and an in-world message.
struct OSPresentationEvent: Equatable {
    var status = OSStatusOverride()
    var apps: [PhoneAppRoute: OSAppVisualOverride] = [:]
    var effect: OSVisualEffect?
    var interruption: OSInterruption?
    var duration: TimeInterval = 2

    var sanitized: Self? {
        guard duration.isFinite else { return nil }
        var result = self
        result.duration = min(4, max(1.2, duration))
        result.status = status.sanitized
        result.apps = apps.mapValues { $0.sanitized }.filter {
            $0.value.displayName != nil || $0.value.symbol != nil
        }
        result.effect = effect?.sanitized
        result.interruption = interruption?.sanitized
        guard result.status != OSStatusOverride() || !result.apps.isEmpty ||
                result.effect != nil || result.interruption != nil else { return nil }
        return result
    }
}

struct OSPresentationState: Equatable {
    struct ActiveEvent: Equatable {
        let id: UUID
        let payload: OSPresentationEvent
        let expiresAt: Date
    }

    static let minimumEventInterval: TimeInterval = 20
    private(set) var configuration = OSPresentationConfiguration()
    private(set) var activeEvent: ActiveEvent?
    private(set) var lastEventStartedAt: Date?
    private(set) var lastEventMonotonicTime: TimeInterval?

    mutating func configure(_ configuration: OSPresentationConfiguration) {
        self.configuration = configuration.sanitized
        activeEvent = nil
        // Mode changes and restoration cannot bypass the disturbance cooldown.
    }

    @discardableResult
    mutating func begin(_ event: OSPresentationEvent, at now: Date, monotonicTime: TimeInterval) -> Bool {
        guard now.timeIntervalSinceReferenceDate.isFinite,
              monotonicTime.isFinite, monotonicTime >= 0, configuration.mode != .normal,
              let payload = event.sanitized else { return false }
        guard self.event(at: now) == nil else { return false }
        if let previous = lastEventMonotonicTime, monotonicTime - previous < Self.minimumEventInterval {
            return false
        }
        activeEvent = ActiveEvent(id: UUID(), payload: payload, expiresAt: now.addingTimeInterval(payload.duration))
        lastEventStartedAt = now
        lastEventMonotonicTime = monotonicTime
        return true
    }

    func event(at now: Date) -> ActiveEvent? {
        guard let activeEvent, now < activeEvent.expiresAt else { return nil }
        return activeEvent
    }

    func resolved(at now: Date) -> OSPresentationConfiguration {
        var result = configuration
        guard let event = event(at: now) else { return result }
        result.status = result.status.overlaying(event.payload.status)
        // Transient overrides replace only supplied fields, not persistent display metadata.
        for (route, override) in event.payload.apps {
            let base = result.apps[route]
            result.apps[route] = OSAppVisualOverride(displayName: override.displayName ?? base?.displayName,
                                                    symbol: override.symbol ?? base?.symbol)
        }
        return result
    }

    @discardableResult
    mutating func endEvent(_ id: UUID) -> Bool {
        guard activeEvent?.id == id else { return false }
        activeEvent = nil
        return true
    }

    mutating func expire(at now: Date) {
        if let event = activeEvent, now >= event.expiresAt { activeEvent = nil }
    }

    mutating func restoreNormal() {
        let previousStart = lastEventStartedAt
        let previousMonotonicTime = lastEventMonotonicTime
        self = Self()
        lastEventStartedAt = previousStart
        lastEventMonotonicTime = previousMonotonicTime
    }
}

enum OSVisualText {
    static func clean(_ text: String, limit: Int) -> String? {
        let cleaned = String(String.UnicodeScalarView(text.unicodeScalars.filter { !CharacterSet.controlCharacters.contains($0) }))
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return nil }
        return String(cleaned.prefix(limit))
    }
}

/// A read-only snapshot of the existing AppState fields, never a second progression store.
struct StoryPresentationContext {
    let currentDay: Int
    let hasOpenedVRApp: Bool
    let hasSeenFirstGlitch: Bool
    let aiCorruptionLevel: Int
}

/// Future callers can supply environmental observations; this type performs no collection.
struct OSEnvironmentContext: Equatable {
    struct Weather: Equatable {
        let summary: String
        let observedAt: Date
    }

    let date: Date
    var timeZoneIdentifier: String = TimeZone.current.identifier
    var weather: Weather?
}


enum OSVisualSafety {
    static let reservedHomeHeight: Double = 64
    static let maximumInterruptionHeight: Double = 160

    static func interruptionHeight(availableHeight: Double) -> Double {
        guard availableHeight.isFinite else { return 0 }
        return min(maximumInterruptionHeight, max(0, availableHeight - reservedHomeHeight))
    }
}
