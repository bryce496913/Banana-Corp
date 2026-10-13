import SwiftUI

struct SettingsView: View {
    var body: some View {
        PhoneShellView(title: "Settings") {
            AppScreenScroll {
                AppSectionHeader("Device")
                AppCard {
                    AppListRow(title: "Banana Corp OS", symbol: "iphone")
                }

                #if DEBUG
                NavigationLink("Story slice diagnostics") { FirstAnomalyDebugView() }
                    .buttonStyle(.modernPhone)
                #endif

                AppSectionHeader("Advanced settings")
                AppEmptyState(
                    symbol: "gearshape",
                    title: "DEVICE SETTINGS",
                    message: "Core device controls are online. Advanced settings remain managed."
                )
            }
        }
    }
}

#if DEBUG
private struct FirstAnomalyDebugView: View {
    @EnvironmentObject private var appState: AppState
    @State private var confirm = false
    @State private var action = 0
    @State private var failed = false
    var body: some View {
        PhoneShellView(title: "Story diagnostics", subtitle: "Development only") {
            AppScreenScroll {
                EvidenceBackControl()
                Text("Act: \(appState.story.state.currentAct.rawValue)").appText(.sectionTitle)
                Text("Live definition: \(appState.content.currentVersion(for: FirstAnomalyContract.originalContent)?.id ?? "unresolved")").appText(.caption)
                Text("Source availability: \(String(describing: appState.content.availability(for: FirstAnomalyContract.originalContent)))").appText(.caption)
                Text("Authentic preserved copy: \(appState.content.preservedItem(FirstAnomalyContract.evidence) != nil ? "yes" : "no")").appText(.caption)
                Text("Delivered conversations: \(appState.content.availableItems(for: .messages).count); unread: \(appState.unreadMessages)").appText(.caption)
                Text("Cooperation: \(String(describing: appState.story.state.assistant.cooperation))").appText(.caption)
                AppSectionHeader("Milestones")
                ForEach(appState.story.state.completedMilestoneIDs.sorted(), id: \.self) { Text($0).appText(.caption) }
                AppSectionHeader("Assistant facts")
                ForEach(appState.story.state.assistant.relationshipFacts.sorted(), id: \.self) { Text($0).appText(.caption) }
                AppSectionHeader("Anomaly events")
                ForEach(appState.story.state.completedEventIDs.filter { $0.contains("first_anomaly") }.sorted(), id: \.self) { Text($0).appText(.caption) }
                Button("Reset story slice") { action = 0; confirm = true }.buttonStyle(.modernPhone)
                Button("Replay with preserved email") { action = 1; confirm = true }.buttonStyle(.modernPhone)
                Button("Replay without preserved email") { action = 2; confirm = true }.buttonStyle(.modernPhone)
                Text("Reset archives the existing story save and leaves your Home layout intact. Replay performs the real catalogue actions through the removal boundary.").appText(.caption)
            }
        }
        .confirmationDialog("Reset this development story save?", isPresented: $confirm) {
            Button("Reset and continue", role: .destructive) {
                guard case .success = appState.resetStoryForNewGame() else { failed = true; return }
                if action != 0, case .failure = appState.content.debugReplayFirstAnomaly(preserving: action == 1) { failed = true }
                appState.deliverFirstAnomalyPresentationIfNeeded()
            }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Debug replay failed", isPresented: $failed) { Button("OK", role: .cancel) {} }
            message: { Text("Some actions could not be saved. Inspect the existing state; it was not silently replaced.") }
    }
}
#endif
