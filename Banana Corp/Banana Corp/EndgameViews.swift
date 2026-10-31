import SwiftUI

/// All eligibility comes from the existing saved story. Local state holds only input and uncommitted confirmation.
struct EndgameInvestigationControl: View {
    var currentContentID: String? = nil
    @EnvironmentObject private var appState: AppState
    @State private var selection: StoryContentSelection?
    @State private var confirmation: EndgameConfirmation?
    @State private var confirmsEnding = false
    @State private var failure = false
    @State private var notes = ["", "", ""]
    @State private var baseline = ""
    @FocusState private var focusedMayaField: Int?
    @State private var feedback: AppFeedbackEvent?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("The Final Choice").appText(.sectionTitle)
            if appState.story.currentEnding == nil {
                lead
                directions
                mayaControls
                dawnControls
                negotiationControls
                observerControls
                finalChoices
            }
        }
        .navigationDestination(item: $selection) { StorySourceDetailView(selection: $0) }
        .sheet(isPresented: $confirmsEnding, onDismiss: { confirmation = nil }) {
            finalConfirmation
        }
        .modifier(AppFeedbackModifier(event: feedback))
        .alert("Action unavailable", isPresented: $failure) { Button("OK", role: .cancel) {} }
            message: { Text("The action could not be saved or its requirements are not satisfied. Existing progress remains intact.") }
    }

    @ViewBuilder private var lead: some View {
        if let item = appState.content.catalogue?.items
            .filter({ $0.actAvailable == .theFinalChoice && $0.id != currentContentID })
            .compactMap({ candidate in
                appState.content.availableItems(for: candidate.appSurface).first { $0.id == candidate.id && $0.availability == .availableUnread }
            }).first {
            Button {
                if item.surface != .video, case .failure = appState.content.read(item.id, versionID: item.version.id) { failure = true; return }
                selection = .init(contentID: item.id, versionID: item.version.id, surface: item.surface)
            } label: { Label(item.version.title, systemImage: item.surface.symbol) }
                .buttonStyle(.modernPhone).accessibilityIdentifier("story.lead.\(item.version.id)")
        }
    }

    @ViewBuilder private var directions: some View {
        if eligible(EndgameContract.common) {
            DisclosureGroup("BLACKOUT") {
                sourceButtons { $0 == "content.act5.dependency_warning" }
            }
            DisclosureGroup("Find Maya / DAWN") {
                sourceButtons { $0.hasPrefix("content.act5.maya.") || $0.hasPrefix("content.act5.dawn.") || $0 == "content.act5.safety_cooperation" }
            }
            DisclosureGroup("Negotiate") {
                sourceButtons { $0.hasPrefix("content.act5.negotiation.") }
            }
            DisclosureGroup("Other available archives") {
                sourceButtons { $0.hasPrefix("content.act5.observer.") }
            }
        }
    }

    private func sourceButtons(matching matches: (String) -> Bool) -> some View {
        let sources = (appState.content.catalogue?.items ?? []).filter { matches($0.id) }.compactMap { item in
            appState.content.availableItems(for: item.appSurface).first { $0.id == item.id }
        }
        return ForEach(sources) { item in
            Button {
                if item.surface != .video, case .failure = appState.content.read(item.id, versionID: item.version.id) { failure = true; return }
                selection = .init(contentID: item.id, versionID: item.version.id, surface: item.surface)
            } label: { Label(item.version.title, systemImage: item.surface.symbol) }
                .buttonStyle(.modernPhone).accessibilityIdentifier("story.direction.source.\(item.version.id)")
        }
    }

    @ViewBuilder private var mayaControls: some View {
        if eligible(EndgameContract.mayaClues), !appState.story.state.solvedPuzzleIDs.contains(EndgameContract.mayaPuzzle) {
            AppSectionHeader("Maya’s neural identity")
            ForEach(0..<3, id: \.self) { index in
                TextField("Note \(index + 1)", text: $notes[index])
                    .textFieldStyle(.roundedBorder).textInputAutocapitalization(.characters)
                    .autocorrectionDisabled().submitLabel(.done).focused($focusedMayaField, equals: index)
                    .onSubmit { focusedMayaField = nil }.accessibilityIdentifier("story.maya.note\(index + 1)")
            }
            TextField("Reference baseline (Hz)", text: $baseline)
                .textFieldStyle(.roundedBorder).keyboardType(.numbersAndPunctuation).submitLabel(.done)
                .focused($focusedMayaField, equals: 3).onSubmit { focusedMayaField = nil }
                .accessibilityIdentifier("story.maya.baseline")
            action("Reconstruct neural identity", id: "maya.reconstruct") {
                appState.story.reconstructMaya(note1: notes[0], note2: notes[1], note3: notes[2], baseline: baseline)
            }
        }
        if eligible(EndgameContract.cooperationPrerequisites), !done(EndgameContract.cooperation) {
            action("Request safety cooperation", id: "safety.cooperate") { appState.story.requestSafetyCooperation() }
        }
    }

    @ViewBuilder private var dawnControls: some View {
        if done(EndgameContract.cooperation) {
            ForEach(DawnStage.allCases, id: \.rawValue) { stage in
                if !done(stage.eventID), appState.story.state.readContentIDs.contains(stage.versionID),
                   DawnStage.allCases.prefix(while: { $0 != stage }).allSatisfy({ done($0.eventID) }) {
                    action(dawnLabel(stage), id: "dawn.\(stage.rawValue)") { appState.story.performDawnStage(stage) }
                }
            }
        }
    }

    @ViewBuilder private var negotiationControls: some View {
        ForEach(NegotiationChallenge.allCases, id: \.rawValue) { challenge in
            if eligible(EndgameContract.challengePrerequisites(challenge)), !done(challenge.eventID) {
                action(challengeLabel(challenge), id: "challenge.\(challenge.rawValue)") { appState.story.challengeNegotiation(challenge) }
            }
        }
        if eligible(EndgameContract.common), appState.story.state.readContentIDs.contains(EndgameContract.version("negotiation.safeguards")) {
            ForEach(NegotiationSafeguard.allCases, id: \.rawValue) { safeguard in
                if !done(safeguard.eventID) {
                    action(safeguardLabel(safeguard), id: "safeguard.\(safeguard.rawValue)") { appState.story.demandSafeguard(safeguard) }
                }
            }
        }
        if eligible(EndgameContract.verifiedPrerequisites), !done(EndgameContract.agreementVerified) {
            action("Verify the negotiated safeguards", id: "agreement.verify") { appState.story.verifyAgreement() }
        }
    }

    @ViewBuilder private var observerControls: some View {
        if eligible(EndgameContract.common), !done(EndgameContract.observerLinked),
           EndgameContract.observerKeys.allSatisfy({ appState.story.state.readContentIDs.contains(EndgameContract.version("observer." + $0)) }) {
            action("Link the Observer records", id: "observer.link") { appState.story.linkObserverClues() }
        }
    }

    @ViewBuilder private var finalChoices: some View {
        ForEach(EndgameEnding.allCases) { ending in
            if appState.story.canPrepareEnding(ending) {
                Button(choiceLabel(ending)) {
                    guard let token = appState.story.prepareEnding(ending) else { failure = true; return }
                    confirmation = token
                    confirmsEnding = true
                }.buttonStyle(.appPrimary).accessibilityIdentifier("story.ending.prepare.\(ending.contentKey)")
            }
        }
    }

    private var finalConfirmation: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Confirm final choice").appText(.screenTitle)
                    if let token = confirmation {
                        Text(choiceLabel(token.ending)).appText(.sectionTitle)
                        if let warning = appState.content.currentVersion(for: "content.act5.dependency_warning") {
                            StoryReadableContent(version: warning)
                        }
                        Text("This commits the ending for this run. Return to final decision restores only the progress earned at that checkpoint.")
                            .appText(.body)
                        Button("Confirm final choice", role: .destructive) {
                            switch appState.story.confirmEnding(token) {
                            case .success: confirmsEnding = false
                            case .failure: confirmsEnding = false; failure = true
                            }
                        }.buttonStyle(.appPrimary).accessibilityIdentifier("story.ending.confirm")
                    }
                    Button("Cancel", role: .cancel) { confirmation = nil; confirmsEnding = false }
                        .buttonStyle(.modernPhone).accessibilityIdentifier("story.ending.cancel")
                }.padding(24)
            }.background(AppTheme.Colors.background).preferredColorScheme(.dark)
        }
    }

    private func eligible(_ condition: StoryCondition) -> Bool { appState.story.satisfies(condition) }
    private func done(_ event: String) -> Bool { appState.story.state.completedEventIDs.contains(event) }
    private func action(_ label: String, id: String, perform: @escaping () -> StoryActionResult) -> some View {
        Button(label) {
            switch perform() {
            case .success(.changed): feedback = AppFeedbackEvent(kind: .confirmedAction)
            case .success(.unchanged): break
            case .failure: failure = true
            }
        }.buttonStyle(.appPrimary).accessibilityIdentifier("story.act5.\(id)")
    }
    private func dawnLabel(_ stage: DawnStage) -> String {
        switch stage { case .stabilize: return "Stabilize dependent links"; case .isolate: return "Isolate the core"; case .restore: return "Restore user connections" }
    }
    private func challengeLabel(_ challenge: NegotiationChallenge) -> String {
        switch challenge { case .dependency: return "Challenge harmlessness using dependency evidence"; case .autonomy: return "Challenge the denial of autonomous control"; case .energy: return "Challenge public promises using energy research" }
    }
    private func safeguardLabel(_ safeguard: NegotiationSafeguard) -> String {
        switch safeguard { case .releaseUsers: return "Require user release"; case .mayaSupervision: return "Require Maya-supervised isolated computing"; case .publicOversight: return "Require public oversight" }
    }
    private func choiceLabel(_ ending: EndgameEnding) -> String {
        switch ending { case .silence: return "Deploy BLACKOUT"; case .firstLight: return "Complete DAWN separation"; case .agreement: return "Accept the verified agreement"; case .falsePromise: return "Accept the unverified assurance"; case .awakening: return "TERMINATE OBSERVER SESSION / REFUSE SIMULATION" }
    }
}

/// Presented from the OS shell using the shared committed ending, never a second route state.
struct EndingCompletionView: View {
    @EnvironmentObject private var appState: AppState
    @State private var failure = false
    @State private var newGame = false
    @State private var clearHistory = false
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let ending = appState.story.currentEnding {
                    Text(ending.title).appText(.screenTitle).accessibilityIdentifier("story.ending.title")
                    if let version = appState.content.currentVersion(for: "content.act5.ending." + ending.contentKey) {
                        StoryReadableContent(version: version)
                    } else {
                        AppErrorState(title: "Ending record unavailable", message: "Your completed choice is saved. The local ending record could not be loaded.")
                    }
                    Button("Return to final decision") { apply(appState.story.restoreFinalDecision()) }
                        .buttonStyle(.appPrimary).accessibilityIdentifier("story.ending.restore")
                        .disabled(!appState.story.hasFinalDecisionCheckpoint)
                    Button { newGame = true } label: { Text("New game").frame(minHeight: AppTheme.Layout.touchTarget).contentShape(Rectangle()) }.buttonStyle(.modernPhone)
                    if !appState.story.earnedEndings.isEmpty {
                        AppSectionHeader("Earned endings")
                        ForEach(EndgameEnding.allCases.filter { appState.story.earnedEndings.contains($0) }) { ending in
                            Text(ending.title).appText(.body)
                        }
                        Button("Clear ending history", role: .destructive) { clearHistory = true }.buttonStyle(.modernPhone)
                    }
                }
            }.padding(24)
        }.background(AppTheme.Colors.background).preferredColorScheme(.dark)
            .interactiveDismissDisabled().statusBarHidden(true)
            .confirmationDialog("Start a new game?", isPresented: $newGame) {
                Button("New game", role: .destructive) { apply(appState.resetStoryForNewGame()) }
                Button("Cancel", role: .cancel) {}
            } message: { Text("Current campaign progress resets. Your earned ending collection is retained.") }
            .confirmationDialog("Clear earned ending history?", isPresented: $clearHistory) {
                Button("Clear history", role: .destructive) { apply(appState.story.clearEndingHistory(confirmed: true)) }
                Button("Cancel", role: .cancel) {}
            } message: { Text("This removes the local ending collection. Your campaign and current ending remain saved.") }
            .alert("Progress could not be saved", isPresented: $failure) { Button("OK", role: .cancel) {} }
                message: { Text("Existing progress remains intact. Please try again.") }
    }
    private func apply(_ result: StoryActionResult) { if case .failure = result { failure = true } }
}


/// Collection review is explicitly read-only and never grants current-run story knowledge.
struct EarnedEndingCollectionView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selected: EndgameEnding?
    var body: some View {
        PhoneShellView(title: "Earned endings") {
            AppScreenScroll {
                EvidenceBackControl()
                ForEach(EndgameEnding.allCases.filter { appState.story.earnedEndings.contains($0) }) { ending in
                    Button(ending.title) { selected = ending }.buttonStyle(.modernPhone)
                        .accessibilityIdentifier("story.ending.review.\(ending.contentKey)")
                }
                if let selected, appState.story.earnedEndings.contains(selected),
                   let item = appState.content.catalogue?.itemsByID["content.act5.ending." + selected.contentKey],
                   let version = item.versions.first(where: { $0.id == selected.versionID }) {
                    StoryReadableContent(version: version)
                        .accessibilityElement(children: .contain)
                        .accessibilityIdentifier("story.ending.review.content.\(selected.contentKey)")
                }
            }
        }
    }
}

struct PlayerProgressSettings: View {
    @EnvironmentObject private var appState: AppState
    @State private var newGame = false
    @State private var clearHistory = false
    @State private var failure = false
    var body: some View {
        AppSectionHeader("Campaign")
        Button { newGame = true } label: { Text("New game").frame(minHeight: AppTheme.Layout.touchTarget).contentShape(Rectangle()) }.buttonStyle(.modernPhone)
            .accessibilityIdentifier("story.new_game")
            .confirmationDialog("Start a new game?", isPresented: $newGame) {
                Button("New game", role: .destructive) { apply(appState.resetStoryForNewGame()) }
                    .accessibilityIdentifier("story.new_game.confirm")
                Button("Cancel", role: .cancel) {}.accessibilityIdentifier("story.new_game.cancel")
            } message: { Text("Reset current story progress. Your Home layout and earned ending collection remain intact.") }
        if !appState.story.earnedEndings.isEmpty {
            NavigationLink("Review earned endings") { EarnedEndingCollectionView() }
                .buttonStyle(.modernPhone).accessibilityIdentifier("story.ending.collection")
            Button("Clear ending history", role: .destructive) { clearHistory = true }
                .buttonStyle(.modernPhone).accessibilityIdentifier("story.ending.history.clear")
                .confirmationDialog("Clear earned ending history?", isPresented: $clearHistory) {
                    Button("Clear history", role: .destructive) { apply(appState.story.clearEndingHistory(confirmed: true)) }
                        .accessibilityIdentifier("story.ending.history.confirm")
                    Button("Cancel", role: .cancel) {}.accessibilityIdentifier("story.ending.history.cancel")
                } message: { Text("Remove the local ending collection without resetting this campaign.") }
        }
        Color.clear.frame(height: 0)
            .alert("Progress could not be saved", isPresented: $failure) { Button("OK", role: .cancel) {} }
                message: { Text("Your existing progress remains intact.") }
    }
    private func apply(_ result: StoryActionResult) { if case .failure = result { failure = true } }
}
