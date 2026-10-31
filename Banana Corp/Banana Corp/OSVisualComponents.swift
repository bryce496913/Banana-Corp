import SwiftUI
import UIKit

private struct OSPresentationKey: EnvironmentKey {
    static let defaultValue = OSPresentationState()
}

private struct OSEffectsEnabledKey: EnvironmentKey {
    static let defaultValue = true
}

private struct OSAppRouteKey: EnvironmentKey {
    static let defaultValue: PhoneAppRoute? = nil
}

extension EnvironmentValues {
    var osPresentation: OSPresentationState {
        get { self[OSPresentationKey.self] }
        set { self[OSPresentationKey.self] = newValue }
    }
    var osEffectsEnabled: Bool {
        get { self[OSEffectsEnabledKey.self] }
        set { self[OSEffectsEnabledKey.self] = newValue }
    }
    var osAppRoute: PhoneAppRoute? {
        get { self[OSAppRouteKey.self] }
        set { self[OSAppRouteKey.self] = newValue }
    }
}

struct OSVisualPalette {
    let style: OSPaletteStyle

    var background: Color {
        style == .standard ? AppTheme.Colors.background : AppTheme.Colors.surface.opacity(0.12)
    }
    var surface: Color { AppTheme.Colors.surface }
    var accent: Color {
        switch style {
        case .standard: return AppTheme.Colors.accent
        case .muted: return AppTheme.Colors.accent.opacity(0.8)
        case .interference: return AppTheme.Colors.highlight.opacity(0.75)
        case .compromised: return AppTheme.Colors.accent.opacity(0.65)
        case .critical: return AppTheme.Colors.highlight.opacity(0.72)
        }
    }
}

struct OSStoryText: View {
    let text: String
    var target: OSVisualTarget?
    var displayNameOverride: String?
    @Environment(\.osPresentation) private var presentation
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.deviceReduceMotion) private var phoneReduceMotion
    private var reduceMotion: Bool { systemReduceMotion || phoneReduceMotion }
    @Environment(\.osEffectsEnabled) private var effectsEnabled

    var body: some View {
        Group {
            if displayedText != text {
                // Keep the original intrinsic height so a glyph substitution doesn't resize a game.
                Text(text)
                    .opacity(0)
                    .frame(maxWidth: .infinity, alignment: alignment)
                    .overlay(alignment: alignment) {
                        Text(displayedText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                            .accessibilityHidden(true)
                            .allowsHitTesting(false)
                    }
                    .accessibilityElement(children: .ignore)
            } else {
                Text(text)
            }
        }
        .accessibilityLabel(displayNameOverride ?? text)
        .modifier(OSControlledEffect(target: target))
    }

    private var alignment: Alignment {
        if let target, case .appName = target { return .center }
        return .leading
    }

    private var displayedText: String {
        let readable = displayNameOverride ?? text
        guard effectsEnabled, !reduceMotion, let target,
              let effect = presentation.event(at: Date())?.payload.effect,
              effect.target == target, case .textCorruption(let replacement) = effect.kind else { return readable }
        return replacement
    }
}

/// Apply only to decorative artwork or informational text, never to gesture/hit-test controls.
struct OSControlledEffect: ViewModifier {
    let target: OSVisualTarget?
    @Environment(\.osPresentation) private var presentation
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.deviceReduceMotion) private var phoneReduceMotion
    private var reduceMotion: Bool { systemReduceMotion || phoneReduceMotion }
    @Environment(\.osEffectsEnabled) private var effectsEnabled

    func body(content: Content) -> some View {
        if effectsEnabled, !reduceMotion, let target, let event = presentation.event(at: Date()),
           let effect = event.payload.effect, effect.target == target,
           effect.kind == .distortion || effect.kind == .opacityPulse {
            OSActiveEffect(content: content, kind: effect.kind)
                .id(event.id)
        } else {
            content
        }
    }
}

private struct OSActiveEffect<Content: View>: View {
    let content: Content
    let kind: OSVisualEffect.Kind
    @State private var started = false

    private struct Frame {
        var offset: CGFloat = 0
        var opacity: Double = 1
    }

    var body: some View {
        content.keyframeAnimator(initialValue: Frame(), trigger: started) { content, frame in
            content
                .offset(x: kind == .distortion ? frame.offset : 0)
                .opacity(kind == .opacityPulse ? frame.opacity : 1)
        } keyframes: { _ in
            // One gentle drift or luminance dip, never a rapid/looping flash.
            KeyframeTrack(\.offset) {
                LinearKeyframe(2, duration: 0.4)
                LinearKeyframe(-1, duration: 0.4)
                LinearKeyframe(0, duration: 0.4)
            }
            KeyframeTrack(\.opacity) {
                LinearKeyframe(0.94, duration: 0.6)
                LinearKeyframe(1, duration: 0.6)
            }
        }
        .onAppear { started = true }
    }
}

struct OSInterruptionHost: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.osPresentation) private var presentation

    var body: some View {
        if let event = presentation.event(at: Date()), let interruption = event.payload.interruption {
            AppCard(padding: AppTheme.Spacing.md) {
                HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
                    Image(systemName: symbol(for: interruption.kind)).accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(interruption.title).appText(.systemLabel).lineLimit(1)
                        Text(interruption.message).appText(.caption).lineLimit(2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: 440)
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Banana OS message. \(interruption.title). \(interruption.message)")
            .accessibilityAction(named: Text("Dismiss")) { appState.endPresentationEvent(event.id) }
            // All pointer input passes through. The message also expires automatically.
            .allowsHitTesting(false)
        }
    }

    private func symbol(for kind: OSInterruption.Kind) -> String {
        switch kind {
        case .notification: return "bell"
        case .systemAlert: return "exclamationmark.bubble"
        case .assistantMessage: return "waveform.path.ecg"
        }
    }
}

extension OSPresentationConfiguration {
    var visualPalette: OSVisualPalette { OSVisualPalette(style: palette) }

    func appInfo(for route: PhoneAppRoute) -> PhoneAppInfo? {
        guard let base = PhoneAppInfo.info(for: route) else { return nil }
        let override = apps[route]
        let image: AppIconImage
        if let symbol = override?.symbol, UIImage(systemName: symbol) != nil {
            image = .symbol(symbol)
        } else {
            image = base.image
        }
        return PhoneAppInfo(title: override?.displayName ?? base.title, image: image, route: base.route)
    }
}
