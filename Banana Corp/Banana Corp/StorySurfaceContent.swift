import SwiftUI

private struct StoryContentSelection: Hashable {
    let contentID: String
    let versionID: String
}

/// Existing app shells keep their original empty layouts until their catalogue is authored.
struct StorySurfaceContent<Placeholder: View>: View {
    @EnvironmentObject private var appState: AppState
    let surface: StoryAppSurface
    @ViewBuilder let placeholder: () -> Placeholder
    @State private var selection: StoryContentSelection?
    @State private var readFailure = false

    var body: some View {
        Group {
            if appState.content.catalogue?.items.contains(where: { $0.appSurface == surface }) == true {
                AppScreenScroll {
                    let items = appState.content.availableItems(for: surface)
                    if items.isEmpty {
                        AppEmptyState(symbol: surface.symbol, title: "No content available", message: "There are no available items in this source right now.")
                    }
                    ForEach(items) { item in
                        AppCard {
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                                Button {
                                    switch appState.content.read(item.id, versionID: item.version.id) {
                                    case .success: selection = StoryContentSelection(contentID: item.id, versionID: item.version.id)
                                    case .failure: readFailure = true
                                    }
                                } label: {
                                    AppListRow(title: item.version.title, subtitle: item.version.subtitle, metadata: item.version.timestampLabel,
                                               symbol: surface.symbol, isUnread: item.availability == .availableUnread)
                                }
                                .buttonStyle(.appContent)
                                .accessibilityHint("Open this content.")
                                if item.version.preservedEvidenceID != nil { PreserveEvidenceButton(contentID: item.id, versionID: item.version.id) }
                            }
                        }
                    }
                }
            } else { placeholder() }
        }
        .navigationDestination(item: $selection) { selected in
            StorySourceDetailView(contentID: selected.contentID, versionID: selected.versionID, surface: surface)
        }
        .alert("Content could not be opened", isPresented: $readFailure) { Button("OK", role: .cancel) {} }
            message: { Text("The source or save is unavailable. Existing progress has not changed.") }
    }
}

private struct StorySourceDetailView: View {
    @EnvironmentObject private var appState: AppState
    let contentID: String
    let versionID: String
    let surface: StoryAppSurface
    var body: some View {
        PhoneShellView(title: surface.displayName) {
            AppScreenScroll {
                EvidenceBackControl()
                if let snapshot = appState.content.engagedSnapshot(contentID, versionID: versionID) {
                    if snapshot.version.preservedEvidenceID != nil { PreserveEvidenceButton(contentID: contentID, versionID: versionID) }
                    if !appState.content.availability(for: contentID, versionID: versionID).isAvailable {
                        Text("This opened version is no longer the available live source.").appText(.caption, color: AppTheme.Colors.secondaryText)
                    }
                    AppCard { EvidencePayloadView(version: snapshot.version) }
                } else {
                    AppErrorState(title: "Content unavailable", message: "The opened version could not be restored.")
                }
            }
        }
    }
}
