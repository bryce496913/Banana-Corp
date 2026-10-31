import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var failed = false
    @State private var resetLayout = false
    @State private var clearChats = false
    var body: some View {
        PhoneShellView(title: "Settings") {
            AppScreenScroll {
                AppSectionHeader("Device")
                AppCard {
                    AppListRow(title: "Banana Corp OS", subtitle: "Local device owner • BNC-DEMO", symbol: "iphone")
                    Toggle("Reduce in-game motion", isOn: preference(\.reduceMotion))
                        .accessibilityIdentifier("settings.motion")
                    Toggle("Haptic feedback", isOn: preference(\.haptics)).accessibilityIdentifier("settings.haptics")
                    Toggle("In-game notification banners", isOn: preference(\.banners)).accessibilityIdentifier("settings.banners")
                    Text("Text size and spoken accessibility follow your iPhone settings. In-game controls do not change the real phone's settings.").appText(.caption)
                }
                NavigationLink { PhoneShellView(title: "Account security") {
                    AppScreenScroll { DeviceSecurityCard(); DeviceCatalogueCopy(contentID: "content.device.web.security") }
                } } label: { AppListRow(title: "Account security", subtitle: appState.phoneLife.securityCompromised ? "Action needed" : "Protected", symbol: "lock.shield") }
                    .buttonStyle(.appContent).accessibilityIdentifier("settings.security")
                NavigationLink { BankingView() } label: { AppListRow(title: "Banking", subtitle: appState.story.isWritable ? "\(appState.phoneLife.balance) Banana Credits" : "Saved account unavailable", symbol: "building.columns") }
                    .buttonStyle(.appContent)
                AppSectionHeader("Personalization and privacy")
                Button("Restore default Home arrangement") { resetLayout = true }.buttonStyle(.modernPhone)
                Button("Clear local conversation history") { clearChats = true }.buttonStyle(.modernPhone)
                Text("Messages you type are stored only in this game save. Clearing these optional conversations does not remove story records or preserved evidence.").appText(.caption)
                PlayerProgressSettings()
                AppSectionHeader("About")
                AppCard {
                    Text("Banana Corp • \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")").appText(.body)
                    Text("Fictional phone services. Credits, orders and account incidents stay inside the game.").appText(.caption)
                }
                #if DEBUG
                DevelopmentPuzzleEntry()
                NavigationLink { FirstAnomalyDebugView() } label: {
                    Text("Story slice diagnostics").frame(minHeight: AppTheme.Layout.touchTarget).contentShape(Rectangle())
                }.buttonStyle(.modernPhone)
                #endif
            }
        }
        .confirmationDialog("Restore Home arrangement?", isPresented: $resetLayout, titleVisibility: .visible) {
            Button("Restore arrangement", role: .destructive) { appState.homeScreenLayout = .defaultLayout }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog("Clear optional conversations?", isPresented: $clearChats, titleVisibility: .visible) {
            Button("Clear conversations", role: .destructive) {
                if case .failure = appState.story.clearDeviceConversations() { failed = true }
            }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Settings could not be saved", isPresented: $failed) { Button("OK", role: .cancel) {} }
    }
    private func preference(_ key: WritableKeyPath<PhoneLifePreferences, Bool>) -> Binding<Bool> {
        Binding(get: { appState.phoneLife.preferences[keyPath: key] }, set: { value in
            var preferences = appState.phoneLife.preferences; preferences[keyPath: key] = value
            if case .failure = appState.story.updatePhonePreferences(preferences) { failed = true }
        })
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
