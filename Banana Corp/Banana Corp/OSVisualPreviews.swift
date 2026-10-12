#if DEBUG
import SwiftUI

/// These configurations are never called by launch, navigation, or progression.
enum OSVisualPreviewConfiguration {
    static func make(_ mode: OSVisualMode) -> OSPresentationConfiguration {
        var configuration = OSPresentationConfiguration(mode: mode)
        switch mode {
        case .normal: break
        case .subtleAnomaly:
            configuration.palette = .muted
            configuration.status.signal = .weak
        case .interference:
            configuration.palette = .interference
            configuration.status.carrier = "PREVIEW SIGNAL"
            configuration.status.batteryPercent = 40
        case .compromised:
            configuration.palette = .compromised
            configuration.apps[.aiAssistant] = OSAppVisualOverride(displayName: "Preview Assist", symbol: "waveform")
            configuration.visibleLockedApps = [.vrExperience]
        case .critical:
            configuration.palette = .critical
            configuration.status.carrier = "PREVIEW SYSTEM"
            configuration.status.wifi = .unavailable
            configuration.status.batteryPercent = 10
        }
        return configuration
    }
}

private struct OSVisualPreviewHarness: View {
    @StateObject private var appState = AppState()
    @State private var mode: OSVisualMode = .normal
    let initialMode: OSVisualMode

    var body: some View {
        VStack(spacing: 0) {
            // Developer controls outside the OS are never part of normal play.
            ScrollView(.horizontal) {
                HStack {
                    Picker("Preview visual mode", selection: $mode) {
                        ForEach(OSVisualMode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    Button("Pulse") { demonstrate(.opacityPulse) }
                    Button("Distort") { demonstrate(.distortion) }
                    Button("Text") { demonstrate(.textCorruption("PREVIEW")) }
                    Button("Alert") {
                        appState.presentStoryEvent(
                            OSPresentationEvent(interruption: OSInterruption(
                                kind: .systemAlert, title: "Development preview",
                                message: "Presentation only; no story event.")),
                            when: { _ in true }
                        )
                    }
                    Button("Restore") {
                        appState.restoreNormalPresentation()
                        mode = .normal
                    }
                }
                .buttonStyle(.bordered)
                .padding(8)
            }
            BananaOSView()
        }
        .environmentObject(appState)
        .preferredColorScheme(.dark)
        .onAppear {
            mode = initialMode
            applyMode()
        }
        .onChange(of: mode) { _, _ in applyMode() }
    }

    private func applyMode() {
        appState.configureStoryPresentation(OSVisualPreviewConfiguration.make(mode), when: { _ in true })
        // Only this debug harness can demonstrate locking; restore cosmetics does not undo story locks.
        appState.setStoryAppAvailability(.vrExperience, unlocked: mode != .compromised, when: { _ in true })
    }

    private func demonstrate(_ kind: OSVisualEffect.Kind) {
        appState.presentStoryEvent(
            OSPresentationEvent(
                status: OSStatusOverride(carrier: "PREVIEW CARRIER"),
                effect: OSVisualEffect(target: .carrier, kind: kind)
            ), when: { _ in true }
        )
    }
}

#Preview("Normal visual mode") { OSVisualPreviewHarness(initialMode: .normal) }
#Preview("Subtle anomaly visual mode") { OSVisualPreviewHarness(initialMode: .subtleAnomaly) }
#Preview("Interference visual mode") { OSVisualPreviewHarness(initialMode: .interference) }
#Preview("Compromised visual mode") { OSVisualPreviewHarness(initialMode: .compromised) }
#Preview("Critical visual mode") { OSVisualPreviewHarness(initialMode: .critical) }
#Preview("Critical, Reduce Motion") {
    OSVisualPreviewHarness(initialMode: .critical)
        .environment(\.accessibilityReduceMotion, true)
}
#endif
