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
    var scrollsContent = true
    @ViewBuilder let placeholder: () -> Placeholder
    @State private var selection: StoryContentSelection?
    @State private var readFailure = false
    @State private var query = ""
    @State private var unreadOnly = false
    @State private var refreshNotice: String?
    private var usesAppChrome: Bool { surface == .email || surface == .web }

    var body: some View {
        Group {
            if usesAppChrome {
                VStack(spacing: 0) {
                    if surface == .web {
                        BrowserChrome(address: $query, onHome: { query = ""; refreshNotice = nil },
                                      onRefresh: refreshLocalSources, onGo: openAddress,
                                      notice: refreshNotice)
                    } else {
                        MailChrome(title: "Inbox", onInbox: { query = ""; unreadOnly = false; refreshNotice = nil },
                                   onRefresh: refreshLocalSources, notice: refreshNotice)
                    }
                    AppScreenScroll {
                        if surface == .email {
                            AppSearchField(label: "Search mail", text: $query)
                                .accessibilityIdentifier("mail.search")
                            Toggle("Unread only", isOn: $unreadOnly).tint(AppTheme.Colors.accent)
                                .accessibilityIdentifier("mail.unread")
                        } else {
                            if !appState.access.visibleResources().isEmpty || !appState.access.diagnostics.isEmpty {
                                RestrictedAccessEntries()
                            }
                            AppSectionHeader("Available pages")
                        }
                        sourceContent
                    }
                }
            } else if scrollsContent && showsCatalogueOrRecovery {
                AppScreenScroll { sourceContent }
            } else {
                sourceContent
            }
        }
        .onAppear {
            if surface == .email && selection == nil { appState.reconcileFirstAnomalyAtBoundary() }
            if selection == nil { appState.reconcileActTwoAtBoundary(surface: surface) }
        }
        .onChange(of: selection) { old, new in
            if surface == .email && old?.contentID == FirstAnomalyContract.originalContent && new == nil {
                appState.reconcileFirstAnomalyAtBoundary()
            }
            if old != nil && new == nil { appState.reconcileActTwoAtBoundary(surface: surface) }
        }
        .navigationDestination(item: $selection) { selected in
            StorySourceDetailView(selection: selected)
        }
        .alert("Content could not be opened", isPresented: $readFailure) { Button("OK", role: .cancel) {} }
            message: { Text("The source or save is unavailable. Existing progress has not changed.") }
    }

    private var showsCatalogueOrRecovery: Bool {
        !appState.content.loadDiagnostics.isEmpty || !appState.story.isWritable ||
        appState.content.catalogue?.items.contains(where: { $0.appSurface == surface }) == true
    }

    @ViewBuilder private var sourceContent: some View {
        if !appState.content.loadDiagnostics.isEmpty || !appState.story.isWritable {
            AppErrorState(title: "Content unavailable", message: "The local source or saved progress needs recovery. Your progress has not been reset.", retry: { _ = appState.story.load() })
        } else if appState.content.catalogue?.items.contains(where: { $0.appSurface == surface }) == true {
            let available = appState.content.availableItems(for: surface)
            let items = filtered(available)
            FirstAnomalyHandoffControl()
            if items.isEmpty {
                AppEmptyState(symbol: surface.symbol,
                              title: available.isEmpty ? "No content available" : "No matches",
                              message: available.isEmpty ? "There are no available items in this source right now." : "Try another search or turn off the unread filter.")
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
                            if surface == .email {
                                MailSourceRow(version: item.version, unread: item.availability == .availableUnread,
                                              timestamp: StoryContentTime.label(for: item.version, context: appState.storyTimeContext))
                            } else {
                                AppListRow(title: item.version.title, subtitle: item.version.subtitle, detail: item.version.source,
                                           metadata: StoryContentTime.label(for: item.version, context: appState.storyTimeContext), symbol: surface.symbol, isUnread: item.availability == .availableUnread)
                            }
                        }
                        .buttonStyle(.appContent)
                        .accessibilityIdentifier("story.open.\(item.version.id)")
                        .accessibilityHint(surface == .video ? "Open the presentation. This does not mark it viewed." : "Open this content.")
                        if item.version.preservedEvidenceID != nil { PreserveEvidenceButton(contentID: item.id, versionID: item.version.id) }
                    }
                }
            }
        } else { placeholder() }
    }

    private func refreshLocalSources() {
        _ = appState.content.availableItems(for: surface)
        refreshNotice = surface == .email ? "Local inbox refreshed." : "Local pages refreshed."
    }

    private func filtered(_ items: [DeliveredStoryContent]) -> [DeliveredStoryContent] {
        guard usesAppChrome else { return items }
        let term = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return items.filter { item in
            guard !unreadOnly || item.availability == .availableUnread else { return false }
            var fields = [item.version.title, item.version.subtitle ?? "", item.version.source ?? ""]
            if case .email(let mail) = item.version.payload { fields += [mail.sender] + mail.recipients }
            if case .web(let page) = item.version.payload { fields.append(page.path) }
            return term.isEmpty || fields.contains { $0.localizedCaseInsensitiveContains(term) }
        }
    }

    private func openAddress() {
        let path = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let item = appState.content.availableItems(for: .web).first(where: {
            if case .web(let page) = $0.version.payload { return page.path == path }
            return false
        }) else { refreshNotice = "Search results show available local pages."; return }
        switch appState.content.read(item.id, versionID: item.version.id) {
        case .success:
            selection = StoryContentSelection(contentID: item.id, versionID: item.version.id, surface: .web)
        case .failure: readFailure = true
        }
    }
}

struct StorySourceDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    let selection: StoryContentSelection
    @State private var linkedSelection: StoryContentSelection?
    @State private var failure = false
    @State private var address = ""
    @State private var refreshNotice: String?
    private var usesAppChrome: Bool { selection.surface == .web || selection.surface == .email }

    private var version: StoryContentVersion? {
        if let snapshot = appState.content.engagedSnapshot(selection.contentID, versionID: selection.versionID) { return snapshot.version }
        guard appState.content.availability(for: selection.contentID, versionID: selection.versionID).isAvailable,
              let live = appState.content.currentVersion(for: selection.contentID), live.id == selection.versionID else { return nil }
        return live
    }

    var body: some View {
        PhoneShellView(title: usesAppChrome ? nil : selection.surface.displayName) {
            VStack(spacing: 0) {
                if selection.surface == .web {
                    BrowserChrome(address: $address, homeLabel: appState.activeApp == .browser ? "Browser Home" : (appState.activeApp == .email ? "Inbox" : "App home"),
                                  onBack: { dismiss() }, onHome: returnToRoot,
                                  onRefresh: refreshOpenedSource,
                                  onGo: openAddress, notice: refreshNotice)
                } else if selection.surface == .email {
                    MailChrome(title: "Email", inboxLabel: appState.activeApp == .email ? "Inbox" : (appState.activeApp == .browser ? "Browser Home" : "App home"),
                               onBack: { dismiss() }, onInbox: returnToRoot,
                               onRefresh: refreshOpenedSource, notice: refreshNotice)
                }
                AppScreenScroll {
                if !usesAppChrome { EvidenceBackControl() }
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
                    FirstAnomalyHandoffControl(currentContentID: selection.contentID)
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
        }
        .onAppear {
            if case .web(let page) = version?.payload { address = page.path }
        }
        .onDisappear { appState.reconcileActTwoAtBoundary(surface: selection.surface) }
        .navigationDestination(item: $linkedSelection) { StorySourceDetailView(selection: $0) }
        .alert("Page unavailable", isPresented: $failure) { Button("OK", role: .cancel) {} }
            message: { Text("This source cannot be opened right now. Your progress has not changed.") }
    }

    private func refreshOpenedSource() {
        _ = appState.content.availability(for: selection.contentID, versionID: selection.versionID)
        refreshNotice = "Source availability checked. The opened version is retained."
    }
    private func returnToRoot() {
        guard let route = appState.activeApp else { return }
        appState.requestAppRoot(route)
    }
    private func openAddress() {
        let path = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let item = appState.content.availableItems(for: .web).first(where: {
            if case .web(let page) = $0.version.payload { return page.path == path }
            return false
        }) else { failure = true; return }
        open(item.id)
    }

    private func links(for version: StoryContentVersion) -> [StoryContentLink] {
        switch version.payload {
        case .web(let data): return data.links ?? []
        case .news(let data): return data.relatedContent ?? []
        case .email(let data): return data.attachments ?? []
        case .messages(let data): return data.links ?? []
        case .assistant(let data): return data.links ?? []
        case .video(let data): return data.links ?? []
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
                    Text(payload.creator ?? "Video presentation").appText(.systemLabel)
                    if let location = payload.sourcePath { Text(location).appText(.caption) }
                    Text("Text presentation. No playable video is included; explore the transcript sections below.").appText(.caption, color: AppTheme.Colors.secondaryText)
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
                        .accessibilityIdentifier("story.video.finish.\(version.id)")
                        .accessibilityHint("Records this presentation as viewed.")
                } else {
                    Button("Continue") { progress.advance(count: cues.count) }.buttonStyle(.appPrimary)
                        .accessibilityIdentifier("story.video.next.\(version.id)")
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

/// Explicit progression confirmation; rendering this control never advances an act.
struct FirstAnomalyHandoffControl: View {
    var currentContentID: String? = nil
    @EnvironmentObject private var appState: AppState
    @State private var failure = false
    var body: some View {
        if appState.content.firstAnomalyHandoffAvailable {
            Button("Continue investigation") {
                if case .failure = appState.story.advanceAct(to: .somethingIsntRight) { failure = true }
            }.buttonStyle(.appPrimary)
                .accessibilityIdentifier("story.advance.act2")
                .accessibilityHint("Continue to Something Isn't Right.")
                .alert("Progress could not be saved", isPresented: $failure) { Button("OK", role: .cancel) {} }
                    message: { Text("Your investigation has not advanced. Please try again.") }
        } else if appState.story.state.currentAct == .somethingIsntRight {
            ActTwoInvestigationControl(currentContentID: currentContentID)
        } else if appState.story.state.currentAct == .theConspiracy || appState.story.state.currentAct == .theTakeover {
            ActThreeInvestigationControl(currentContentID: currentContentID)
        }
    }
}

/// Only explicit player actions connect the records and advance. Guidance uses shared-store queries.
struct ActTwoInvestigationControl: View {
    var currentContentID: String? = nil
    @EnvironmentObject private var appState: AppState
    @State private var selection: StoryContentSelection?
    @State private var failure = false
    @State private var feedback: AppFeedbackEvent?
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if appState.content.actThreeHandoffAvailable {
                Button("Investigate beyond the curated sources") {
                    switch appState.story.advanceAct(to: .theConspiracy) {
                    case .success(.changed): feedback = AppFeedbackEvent(kind: .confirmedAction)
                    case .success(.unchanged): break
                    case .failure: failure = true
                    }
                }.buttonStyle(.appPrimary)
                    .accessibilityIdentifier("story.advance.act3")
                    .accessibilityHint("Continue to The Conspiracy.")
            } else if appState.content.actTwoConfirmationAvailable {
                Button("Connect the changed source and research findings") {
                    switch appState.content.confirmActTwoInvestigation() {
                    case .success(.changed): feedback = AppFeedbackEvent(kind: .confirmedAction)
                    case .success(.unchanged): break
                    case .failure: failure = true
                    }
                }.buttonStyle(.appPrimary)
                    .accessibilityIdentifier("story.connect.act2")
                    .accessibilityHint("Connect what you learned from the changed recording and research.")
            }
            if let lead = appState.content.actTwoSuggestedLead, lead.id != currentContentID {
                Button {
                    if lead.surface != .video, case .failure = appState.content.read(lead.id, versionID: lead.version.id) { failure = true; return }
                    selection = .init(contentID: lead.id, versionID: lead.version.id, surface: lead.surface)
                } label: {
                    Label(lead.version.title, systemImage: lead.surface.symbol)
                }.buttonStyle(.modernPhone)
                    .accessibilityIdentifier("story.lead.\(lead.version.id)")
                    .accessibilityHint("Open the next available investigation source. Video requires an explicit Finish action.")
            }
        }
        .navigationDestination(item: $selection) { StorySourceDetailView(selection: $0) }
        .modifier(AppFeedbackModifier(event: feedback))
        .alert("Investigation update unavailable", isPresented: $failure) { Button("OK", role: .cancel) {} }
            message: { Text("The action could not be saved. Your existing records remain intact.") }
    }
}


/// Explicit knowledge confirmation and approved Act 4 entry; never starts ASCENSION.
struct ActThreeInvestigationControl: View {
    var currentContentID: String? = nil
    @EnvironmentObject private var appState: AppState
    @State private var selection: StoryContentSelection?
    @State private var failure = false
    @State private var feedback: AppFeedbackEvent?
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(appState.story.state.currentAct == .theTakeover ? "The Takeover" : "The Conspiracy").appText(.sectionTitle)
            if appState.content.actFourHandoffAvailable {
                Button("Begin the resistance investigation") { confirm(appState.content.beginActFour()) }
                    .buttonStyle(.appPrimary).accessibilityIdentifier("story.advance.act4")
                    .accessibilityHint("Enter The Takeover. This does not start ASCENSION or unlock a countermeasure.")
            }
            if appState.content.autonomyConfirmationAvailable,
               !appState.story.state.completedEventIDs.contains(ActThreeInvestigationContract.autonomyEvent) {
                Button("Connect the authorization record and Maya’s observations") {
                    confirm(appState.content.confirmEchoAutonomy())
                }.buttonStyle(.appPrimary).accessibilityIdentifier("story.connect.act3.autonomy")
                    .accessibilityHint("Record the autonomy finding from both inspected sources.")
            }
            if appState.content.publicRestrictedConfirmationAvailable,
               !appState.story.state.completedEventIDs.contains(ActThreeInvestigationContract.contradictionEvent) {
                Button("Connect the public promises and restricted purpose") {
                    confirm(appState.content.confirmPublicRestrictedContradiction())
                }.buttonStyle(.appPrimary).accessibilityIdentifier("story.connect.act3.contradiction")
                    .accessibilityHint("Confirm the contradiction using the public and restricted records you read.")
            }
            if let lead = (appState.story.state.currentAct == .theTakeover ? appState.content.actFourEntry : appState.content.actThreeSuggestedLead), lead.id != currentContentID {
                Button {
                    if lead.surface != .video, case .failure = appState.content.read(lead.id, versionID: lead.version.id) { failure = true; return }
                    selection = .init(contentID: lead.id, versionID: lead.version.id, surface: lead.surface)
                } label: { Label(lead.version.title, systemImage: lead.surface.symbol) }
                    .buttonStyle(.modernPhone).accessibilityIdentifier("story.lead.\(lead.version.id)")
                    .accessibilityHint("Open the next available source. A transcript requires explicit Finish before it is recorded as read.")
            }
            if ["content.act3.observer.session", "content.act3.conclusion.resistance", "content.act3.assistant.observer"].contains(currentContentID ?? "") {
                if !appState.content.observerKnownSources.isEmpty {
                    Text("Revisit known records").appText(.sectionTitle)
                    Text("These earlier records can be reconsidered in context; they do not identify the cause of every change.").appText(.caption)
                    ForEach(appState.content.observerKnownSources) { source in
                        Button(source.version.title) {
                            if case .failure = appState.content.read(source.id, versionID: source.version.id) { failure = true; return }
                            selection = .init(contentID: source.id, versionID: source.version.id, surface: source.surface)
                        }.buttonStyle(.modernPhone)
                            .accessibilityIdentifier("story.observer.reference.\(source.id)")
                    }
                }
                if appState.content.observerOriginalEvidenceAvailable {
                    NavigationLink("Inspect your preserved original ECHO email") {
                        EvidenceDetailView(evidenceID: FirstAnomalyContract.evidence)
                    }.buttonStyle(.modernPhone).accessibilityIdentifier("story.observer.original_evidence")
                }
            }
        }
        .navigationDestination(item: $selection) { StorySourceDetailView(selection: $0) }
        .modifier(AppFeedbackModifier(event: feedback))
        .alert("Investigation update unavailable", isPresented: $failure) { Button("OK", role: .cancel) {} }
            message: { Text("The action could not be saved. Your existing records remain intact.") }
    }
    private func confirm(_ result: StoryContentDeliveryResult) {
        switch result {
        case .success(.changed): feedback = AppFeedbackEvent(kind: .confirmedAction)
        case .success(.unchanged): break
        case .failure: failure = true
        }
    }
}
