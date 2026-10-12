import Foundation

@main
struct OSNavigationChecks {
    static func main() {
        var state = OSNavigationState()
        precondition(state.isHomeReady && state.activeApp == nil)
        precondition(!state.goHome())
        precondition(!state.completeTransition(state.transitionID))

        var cycles = 0
        for _ in 0..<100 {
            for route in PhoneAppRoute.allCases {
                precondition(state.open(route))
                let opening = state.transitionID
                precondition(state.phase == .opening && state.activeApp == route)
                precondition(!state.isHomeReady)
                let pending = state
                precondition(!state.open(.settings))
                precondition(state == pending, "Double opens must be rejected atomically")
                precondition(!state.completeTransition(opening &- 1))
                precondition(state.phase == .opening)
                precondition(state.completeTransition(opening))
                precondition(state.phase == .active && state.activeApp == route)
                precondition(!state.completeTransition(opening), "Completion must be idempotent")
                precondition(!state.open(route))

                precondition(state.goHome())
                let closing = state.transitionID
                precondition(state.phase == .closing && state.activeApp == nil)
                precondition(!state.isHomeReady, "Home must stay locked through removal")
                let outgoing = state
                precondition(!state.open(route), "A rapid reopen must not overlap removal")
                precondition(!state.goHome())
                precondition(state == outgoing)
                precondition(!state.completeTransition(opening), "Stale opening completion must not unlock home")
                precondition(state.completeTransition(closing))
                precondition(state.isHomeReady && state.activeApp == nil)
                precondition(!state.completeTransition(closing))
                cycles += 1
            }
        }

        // Cancel an opening and then deliver callbacks out of order.
        precondition(state.open(.snake))
        let canceledOpening = state.transitionID
        precondition(state.goHome())
        let canceledClosing = state.transitionID
        precondition(!state.completeTransition(canceledOpening))
        precondition(state.completeTransition(canceledClosing))
        precondition(state.open(.pong))
        let nextOpening = state.transitionID
        precondition(!state.completeTransition(canceledClosing))
        precondition(!state.completeTransition(canceledOpening))
        precondition(state.phase == .opening && state.activeApp == .pong)
        precondition(state.completeTransition(nextOpening))
        precondition(state.goHome())
        // A disappearing/recreated root can settle a pending transition without a timer.
        precondition(state.completeTransition(state.transitionID))
        precondition(state.isHomeReady)

        let swipes: [(CGFloat, CGFloat, Bool)] = [
            (0, -25, true), (10, -40, true), (-20, -80, true),
            (0, -24, false), (0, -16, false), (0, 40, false),
            (50, -40, false), (-50, -40, false), (40, -40, false),
            (80, 0, false), (0, 0, false), (.infinity, -80, false),
            (0, -.infinity, false), (.nan, -80, false)
        ]
        for (x, y, expected) in swipes {
            precondition(HomeSwipeIntent.shouldReturnHome(translation: CGSize(width: x, height: y)) == expected)
        }

        print("PASS: \(cycles) app cycles, rapid reopen/double-open rejection, canceled opening, stale/idempotent completion, root recovery, and \(swipes.count) home-swipe cases")
    }
}
