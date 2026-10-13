import SwiftUI

struct StoryContentSelection: Hashable {
    let contentID: String
    let versionID: String
    let surface: StoryAppSurface
}

/// Queries are passive; selecting a source reads only that exact item.
struct StorySurfaceContent<Placeholder: View>: View {
    @EnvironmentObject private var appState: AppState
    let surface: StoryAppSurface
    @ViewBuilder let placeholder: () -> Placeholder
    @State private var selection: StoryContentSelection?
    @State private var readFailure = false

    var body: some View {
        Group {
            if !appState.content.loadDiagnostics.isEmpty || !appState.story.isWritable {
                AppScreenScroll {
                    AppErrorState(title: "Content unavailable", message: "The local source or saved progress needs recovery. Your progress has not been reset.", retry: { _ = appState.story.load() })
                }
            } else if appState.content.catalogue?.items.contains(where: { $0.appSurface == surface }) == true {
                AppScreenScroll {
                    let items = appState.content.availableItems(for: surface)
                    if items.isEmpty {
                        AppEmptyState(symbol: surface.symbol, title: "No content available", message: "There are no available items in this source right now.")
                    }
                    ForEach(items) { item in
                        AppCard {
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                                Button {
                                    // A promotion is read only after its presentation is completed.
                                    if surface == .video {
                                        selection = StoryContentSelection(contentID: item.id, versionID: item.version.id, surface: surface)
                                    } else {
                                        switch appState.content.read(item.id, versionID: item.version.id) {
                                        case .success: selection = StoryContentSelection(contentID: item.id, versionID: item.version.id, surface: surface)
                                        case .failure: readFailure = true
                                        }
                                    }
                                } label: {
                                    AppListRow(title: item.version.title, subtitle: item.version.subtitle, detail: item.version.source,
                                               metadata: StoryContentTime.label(for: item.version, context: appState.storyTimeContext), symbol: surface.symbol, isUnread: item.availability == .availableUnread)
                                }
                                .buttonStyle(.appContent)
                                .accessibilityHint(surface == .video ? "Open the presentation. This does not mark it viewed." : "Open this content.")
                                if item.version.preservedEvidenceID != nil { PreserveEvidenceButton(contentID: item.id, versionID: item.version.id) }
                            }
                        }
                    }
                }
            } else { placeholder() }
        }
        .navigationDestination(item: $selection) { selected in
            StorySourceDetailView(selection: selected)
        }
        .alert("Content could not be opened", isPresented: $readFailure) { Button("OK", role: .cancel) {} }
            message: { Text("The source or save is unavailable. Existing progress has not changed.") }
    }
}

struct StorySourceDetailView: View {
    @EnvironmentObject private var appState: AppState
    let selection: StoryContentSelection
    @State private var linkedSelection: StoryContentSelection?
    @State private var failure = false

    private var version: StoryContentVersion? {
        if let snapshot = appState.content.engagedSnapshot(selection.contentID, versionID: selection.versionID) { return snapshot.version }
        guard appState.content.availability(for: selection.contentID, versionID: selection.versionID).isAvailable,
              let live = appState.content.currentVersion(for: selection.contentID), live.id == selection.versionID else { return nil }
        return live
    }

    var body: some View {
        PhoneShellView(title: selection.surface.displayName) {
            AppScreenScroll {
                EvidenceBackControl()
                if let version {
                    if case .video(let payload) = version.payload {
                        StoryPromotionView(contentID: selection.contentID, version: version, payload: payload)
                    } else {
                        if version.preservedEvidenceID != nil { PreserveEvidenceButton(contentID: selection.contentID, versionID: selection.versionID) }
                        if !appState.content.availability(for: selection.contentID, versionID: selection.versionID).isAvailable {
                            Text("This opened version is no longer the available live source.").appText(.caption, color: AppTheme.Colors.secondaryText)
                        }
                        StoryReadableContent(version: version)
                    }
                    ForEach(links(for: version), id: \.contentID) { link in
                        Button(link.label) { open(link.contentID) }
                            .buttonStyle(.modernPhone)
                            .disabled(!appState.content.availability(for: link.contentID).isAvailable)
                    }
                } else {
                    AppErrorState(title: "Content unavailable", message: "The opened version could not be restored.")
                }
            }
        }
        .navigationDestination(item: $linkedSelection) { StorySourceDetailView(selection: $0) }
        .alert("Page unavailable", isPresented: $failure) { Button("OK", role: .cancel) {} }
            message: { Text("This source cannot be opened right now. Your progress has not changed.") }
    }

    private func links(for version: StoryContentVersion) -> [StoryContentLink] {
        switch version.payload {
        case .web(let data): return data.links ?? []
        case .news(let data): return data.relatedContent ?? []
        case .email(let data): return data.attachments ?? []
        default: return []
        }
    }
    private func open(_ id: String) {
        guard let item = appState.content.availableItems(for: appState.content.catalogue?.itemsByID[id]?.appSurface ?? .web).first(where: { $0.id == id }) else { failure = true; return }
        if item.surface != .video, case .failure = appState.content.read(item.id, versionID: item.version.id) { failure = true; return }
        linkedSelection = StoryContentSelection(contentID: item.id, versionID: item.version.id, surface: item.surface)
    }
}

/// Source-specific rendering keeps correspondence, conversation and article structures intact.
struct StoryReadableContent: View {
    @EnvironmentObject private var appState: AppState
    let version: StoryContentVersion
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            AppScreenHeader(title: version.title, subtitle: version.subtitle)
            if let time = StoryContentTime.label(for: version, context: appState.storyTimeContext) {
                Text(time).appText(.caption, color: AppTheme.Colors.secondaryText)
            }
            if let source = version.source { Text(source).appText(.caption, color: AppTheme.Colors.secondaryText) }
            switch version.payload {
            case .email(let data):
                AppCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("From: \(data.sender)").appText(.systemLabel)
                        Text("To: \(data.recipients.joined(separator: ", "))").appText(.caption, color: AppTheme.Colors.secondaryText)
                    }
                }
                textBlocks(data.blocks)
            case .news(let data): textBlocks(data.blocks)
            case .web(let data):
                Label("Banana Corp · \(data.path)", systemImage: "globe").appText(.caption)
                textBlocks(data.blocks)
            case .social(let data):
                Text(data.handle).appText(.systemLabel, color: AppTheme.Colors.accent)
                AppCard { Text(data.text).appText(.body).textSelection(.enabled) }
                ForEach(data.replies ?? [], id: \.id) { message in messageCard(message) }
            case .messages(let data):
                ForEach(data.messages, id: \.id) { message in messageCard(message) }
                Text("This is an incoming service thread. Replies are not available.").appText(.caption, color: AppTheme.Colors.secondaryText)
            case .assistant(let data):
                ForEach(data.turns, id: \.id) { turn in
                    AppCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(turn.role == .user ? "You" : "Banana Assist").appText(.systemLabel)
                            Text(turn.text).appText(.body).textSelection(.enabled)
                        }
                    }
                }
            default: AppCard { EvidencePayloadView(version: version) }
            }
        }
    }
    private func textBlocks(_ blocks: [StoryTextBlock]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                Text(block.text).appText(block.kind == .heading ? .sectionTitle : .body).textSelection(.enabled)
                    .accessibilityAddTraits(block.kind == .heading ? .isHeader : [])
            }
        }
    }
    private func messageCard(_ message: StoryMessageRecord) -> some View {
        AppCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(message.sender).appText(.systemLabel)
                Text(message.text).appText(.body).textSelection(.enabled)
                if let timestamp = message.timestampLabel { Text(timestamp).appText(.caption, color: AppTheme.Colors.secondaryText) }
            }
        }
        .padding(message.direction == .incoming ? .trailing : .leading, 12)
    }
}

/// No synthetic video playback, elapsed-duration gate, animation timer or hidden read on appearance.
struct StoryPromotionView: View {
    @EnvironmentObject private var appState: AppState
    let contentID: String
    let version: StoryContentVersion
    let payload: StoryVideoPayload
    @State private var progress = StoryPresentationProgress()
    @State private var failure = false
    @State private var feedback: AppFeedbackEvent?
    private var cues: [StoryTranscriptCue] { payload.transcript ?? [] }
    private var viewed: Bool { appState.story.state.readContentIDs.contains(version.id) }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            AppCard {
                VStack(alignment: .leading, spacing: 16) {
                    Image(systemName: "visionpro").font(.system(size: 64)).foregroundStyle(AppTheme.Colors.accent).accessibilityHidden(true)
                    Text(version.title).appText(.screenTitle)
                    Text("Official product presentation").appText(.systemLabel)
                    Text("The finished promotional video is not included. Explore its on-phone presentation below.").appText(.caption, color: AppTheme.Colors.secondaryText)
                }
            }
            if cues.indices.contains(progress.index) {
                AppCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("\(progress.index + 1) of \(cues.count)").appText(.caption)
                        Text(cues[progress.index].text).appText(.body).textSelection(.enabled)
                    }
                }
                if progress.canComplete(count: cues.count) {
                    Button(viewed ? "Presentation viewed" : "Finish presentation") {
                        switch appState.content.completePresentation(contentID, versionID: version.id, progress: progress) {
                        case .success(.changed): feedback = AppFeedbackEvent(kind: .confirmedAction)
                        case .success(.unchanged): break
                        case .failure: failure = true
                        }
                    }.buttonStyle(.appPrimary).disabled(viewed)
                        .accessibilityHint("Records this presentation as viewed.")
                } else {
                    Button("Continue") { progress.advance(count: cues.count) }.buttonStyle(.appPrimary)
                }
                if progress.index > 0 { Button("Previous") { progress.goBack() }.buttonStyle(.modernPhone) }
            } else {
                AppErrorState(title: "Presentation unavailable", message: "There is no local presentation for this item.")
            }
            if version.preservedEvidenceID != nil { PreserveEvidenceButton(contentID: contentID, versionID: version.id) }
        }
        .modifier(AppFeedbackModifier(event: feedback))
        .alert("Progress could not be saved", isPresented: $failure) { Button("OK", role: .cancel) {} }
            message: { Text("The presentation has not been marked viewed. Please try again.") }
    }
}
