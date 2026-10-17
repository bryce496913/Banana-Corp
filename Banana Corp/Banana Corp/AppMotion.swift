import SwiftUI

enum AppMotion {
    static let opening = Animation.easeOut(duration: 0.32)
    static let closing = Animation.easeInOut(duration: 0.28)
    static let reduced = Animation.easeOut(duration: 0.12)
    static let press = Animation.easeOut(duration: 0.12)
    static let selection = Animation.easeOut(duration: 0.18)
    static let reorder = Animation.snappy(duration: 0.20, extraBounce: 0)
    static let editWiggle = Animation.easeInOut(duration: 0.18)

    static func appTransition(reduceMotion: Bool) -> AnyTransition {
        if reduceMotion { return .opacity }
        return .asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .top)
        )
    }
}

struct AppPressFeedback: ViewModifier {
    let isPressed: Bool
    var scale: CGFloat = 0.98
    var pressedOpacity: Double = 0.92
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        let pressed = isPressed && isEnabled
        content
            .scaleEffect(pressed && !reduceMotion ? scale : 1)
            .opacity(pressed ? pressedOpacity : 1)
    }
}

/// For actionable cards/rows and icons; passive reading surfaces stay passive.
struct AppContentButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.99
    var pressedOpacity: Double = 0.92

    func makeBody(configuration: Configuration) -> some View {
        configuration.label.modifier(AppPressFeedback(
            isPressed: configuration.isPressed,
            scale: scale,
            pressedOpacity: pressedOpacity
        ))
    }
}

extension ButtonStyle where Self == AppContentButtonStyle {
    static var appContent: AppContentButtonStyle { AppContentButtonStyle() }
    static var appIcon: AppContentButtonStyle { AppContentButtonStyle(scale: 0.96, pressedOpacity: 0.88) }
}

struct AppFeedbackModifier: ViewModifier {
    let event: AppFeedbackEvent?

    func body(content: Content) -> some View {
        content.sensoryFeedback(trigger: event) { _, newEvent in
            guard let newEvent else { return nil }
            switch newEvent.kind {
            case .openedApp: return .impact(weight: .light, intensity: 0.5)
            case .enteredEditing, .completedDrop: return .selection
            case .confirmedAction: return .impact(weight: .light, intensity: 0.6)
            }
        }
    }
}

struct AppConfirmationModifier: ViewModifier {
    let title: String
    let message: String
    let actionTitle: String
    @Binding var isPresented: Bool
    let role: ButtonRole?
    let action: () -> Void
    @State private var feedbackEvent: AppFeedbackEvent?

    func body(content: Content) -> some View {
        content
            .confirmationDialog(title, isPresented: $isPresented, titleVisibility: .visible) {
                Button(actionTitle, role: role) {
                    feedbackEvent = AppFeedbackEvent(kind: .confirmedAction)
                    action()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(message)
            }
            .modifier(AppFeedbackModifier(event: feedbackEvent))
    }
}
