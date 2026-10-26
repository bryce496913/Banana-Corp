import Foundation

/// Transient presentation state, independent of layout persistence and story data.
struct OSNavigationState: Equatable {
    enum Phase: Equatable { case home, opening, active, closing }

    private(set) var phase: Phase = .home
    private(set) var activeApp: PhoneAppRoute?
    private(set) var transitionID: UInt = 0
    private(set) var contentRootRevision: UInt = 0

    var isHomeReady: Bool { phase == .home }

    @discardableResult
    mutating func open(_ route: PhoneAppRoute) -> Bool {
        guard isHomeReady else { return false }
        activeApp = route
        phase = .opening
        transitionID &+= 1
        return true
    }

    /// Recreate only the active app's local content stack, without an OS transition.
    @discardableResult
    mutating func requestAppRoot(_ route: PhoneAppRoute) -> Bool {
        guard phase == .active, activeApp == route else { return false }
        contentRootRevision &+= 1
        return true
    }

    @discardableResult
    mutating func goHome() -> Bool {
        guard phase == .opening || phase == .active else { return false }
        // Game update guards stop immediately, before the outgoing view disappears.
        activeApp = nil
        phase = .closing
        transitionID &+= 1
        return true
    }

    @discardableResult
    mutating func completeTransition(_ id: UInt) -> Bool {
        guard id == transitionID else { return false }
        switch phase {
        case .opening: phase = .active
        case .closing: phase = .home
        case .home, .active: return false
        }
        return true
    }
}

enum HomeSwipeIntent {
    static func shouldReturnHome(translation: CGSize) -> Bool {
        guard translation.width.isFinite, translation.height.isFinite else { return false }
        return translation.height < -24 && abs(translation.height) > abs(translation.width)
    }
}

struct AppFeedbackEvent: Equatable {
    enum Kind: Equatable { case openedApp, enteredEditing, completedDrop, confirmedAction }
    let kind: Kind
    let id = UUID()
}
