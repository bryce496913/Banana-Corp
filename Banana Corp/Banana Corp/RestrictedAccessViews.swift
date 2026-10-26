import SwiftUI
import UIKit

struct RestrictedAccessEntries: View {
    @EnvironmentObject private var appState: AppState
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(appState.access.visibleResources()) { resource in
                NavigationLink(resource.displayName) { RestrictedResourceView(resourceID: resource.id) }
                    .buttonStyle(.modernPhone)
                    .accessibilityIdentifier("story.resource.\(resource.id)")
            }
            if !appState.access.diagnostics.isEmpty {
                Text("Protected sources are unavailable. Existing investigation records remain intact.").appText(.caption)
            }
        }
    }
}

struct RestrictedResourceView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    let resourceID: String
    var accessOverride: RestrictedAccessStore? = nil
    @State private var selection: StoryContentSelection?
    @State private var failed = false
    @State private var justCompleted = false
    @State private var address = ""
    @State private var refreshNotice: String?
    private var showsBrowserChrome: Bool { appState.activeApp == .browser && accessOverride == nil }
    @State private var feedback: AppFeedbackEvent?
    private var access: RestrictedAccessStore { accessOverride ?? appState.access }
    var body: some View {
        PhoneShellView(title: showsBrowserChrome ? nil : "Protected access") {
            VStack(spacing: 0) {
                if showsBrowserChrome {
                    BrowserChrome(address: $address, onBack: { dismiss() },
                                  onHome: { appState.requestAppRoot(.browser) },
                                  onRefresh: {
                                      _ = access.resourceState(resourceID)
                                      refreshNotice = "Protected access checked."
                                  }, onGo: openAddress, notice: refreshNotice)
                }
                AppScreenScroll {
                if !showsBrowserChrome { EvidenceBackControl() }
                if let resource = access.catalogue?.resourcesByID[resourceID] {
                    switch access.resourceState(resourceID) {
                    case .hidden:
                        AppErrorState(title: "Entry unavailable", message: "No accessible entry is available here.")
                    case .unresolved:
                        AppErrorState(title: "Entry unavailable", message: copy(for: resource)?.unavailable ?? "No accessible entry is available here.")
                    case .locked:
                        AppCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Label(resource.displayName, systemImage: "lock.shield").appText(.screenTitle)
                                    .accessibilityIdentifier("story.resource.locked.\(resource.id)")
                                Text(resource.message).appText(.body)
                            }
                        }
                        if let puzzleID = resource.requiredPuzzleID {
                            PuzzleInteractionView(puzzleID: puzzleID, access: access, openClue: open) {
                                justCompleted = true
                                feedback = AppFeedbackEvent(kind: .confirmedAction)
                                if UIAccessibility.isVoiceOverRunning, let message = copy(for: resource)?.success {
                                    UIAccessibility.post(notification: .announcement, argument: message)
                                }
                            }
                        }
                    case .unlocked:
                        Label(resource.displayName, systemImage: "lock.open").appText(.screenTitle)
                        Text((justCompleted ? copy(for: resource)?.success : copy(for: resource)?.completed) ?? "Access granted")
                            .appText(.sectionTitle)
                            .accessibilityIdentifier("story.resource.unlocked.\(resource.id)")
                        ForEach(resource.linkedContentIDs, id: \.self) { id in
                            if let item = available(id) {
                                AppCard {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text(item.version.title).appText(.sectionTitle)
                                        Button(id == "content.act3.banana_wall.scope_record" ? (copy(for: resource)?.openResource ?? item.version.title) : "Open " + item.version.title) { open(id) }
                                            .buttonStyle(.appPrimary)
                                            .accessibilityIdentifier("story.resource.open.\(id)")
                                    }
                                }
                            }
                        }
                        if resource.id == "resource.banana_wall",
                           access.resourceState("resource.act3.mirror.origins") == .unlocked,
                           let next = access.catalogue?.resourcesByID["resource.act3.mirror.origins"] {
                            NavigationLink(next.displayName) { RestrictedResourceView(resourceID: next.id) }
                                .buttonStyle(.modernPhone)
                                .accessibilityIdentifier("story.research.continue")
                        }
                    }
                } else { AppErrorState(title: "Entry unavailable", message: "The local access record could not be loaded.") }
                }
            }
        }
        .modifier(AppFeedbackModifier(event: feedback))
        .navigationDestination(item: $selection) { StorySourceDetailView(selection: $0) }
        .alert("Source unavailable", isPresented: $failed) { Button("OK", role: .cancel) {} }
            message: { Text("The source could not be opened. Your records remain intact.") }
    }
    private func openAddress() {
        let path = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let item = appState.content.availableItems(for: .web).first(where: {
            if case .web(let page) = $0.version.payload { return page.path == path }
            return false
        }) else { failed = true; return }
        open(item.id)
    }
    private func copy(for resource: RestrictedResource) -> PuzzlePresentationCopy? {
        guard resource.id == "resource.banana_wall" else { return nil }
        return resource.requiredPuzzleID.flatMap { access.catalogue?.puzzlesByID[$0]?.presentation }
    }
    private func available(_ id: String) -> DeliveredStoryContent? {
        guard let item = appState.content.catalogue?.itemsByID[id] else { return nil }
        return appState.content.availableItems(for: item.appSurface).first { $0.id == id }
    }
    private func open(_ id: String) {
        guard let item = available(id) else { failed = true; return }
        if item.surface != .video, case .failure = appState.content.read(id, versionID: item.version.id) { failed = true; return }
        selection = .init(contentID: id, versionID: item.version.id, surface: item.surface)
    }
}

private struct PuzzleInteractionView: View {
    @EnvironmentObject private var appState: AppState
    let puzzleID: String
    let access: RestrictedAccessStore
    let openClue: (String) -> Void
    let onCompletion: () -> Void
    @State private var draft: PuzzleDraft
    @State private var result: PuzzleSubmissionResult?
    @State private var focusedID: String?
    @ScaledMetric(relativeTo: .body) private var inputHeight: CGFloat = 44
    init(puzzleID: String, access: RestrictedAccessStore, openClue: @escaping (String) -> Void, onCompletion: @escaping () -> Void) {
        self.puzzleID = puzzleID; self.access = access; self.openClue = openClue; self.onCompletion = onCompletion
        _draft = State(initialValue: access.draft(for: puzzleID))
    }
    var body: some View {
        let availability = access.puzzleAvailability(puzzleID)
        if availability == .hidden || availability == .unresolved {
            Text("Challenge unavailable. No progress has been reset.").appText(.caption)
        } else if availability == .locked {
            Text("Additional access requirements remain.").appText(.caption)
        } else if let puzzle = access.catalogue?.puzzlesByID[puzzleID] {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                Text(puzzle.title).appText(.sectionTitle)
                Text(puzzle.instructions).appText(.body).textSelection(.enabled)
                if availability == .ready {
                    ForEach(puzzle.inputs) { input in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(input.label).appText(.systemLabel)
                            if let prompt = input.prompt { Text(prompt).appText(.caption, color: AppTheme.Colors.secondaryText) }
                            if input.id == "input.banana_wall.trial" {
                                Text("Reference format: XXXX-00").appText(.caption).monospaced().textSelection(.enabled)
                            }
                            if input.kind == .choice {
                                Picker(input.label, selection: binding(input.id)) {
                                    Text("Choose").tag("")
                                    ForEach(input.choices ?? [], id: \.self) { Text($0).tag($0) }
                                }.frame(minHeight: AppTheme.Layout.touchTarget)
                            } else {
                                PuzzleTextField(id: input.id, label: input.label, text: binding(input.id), focusedID: $focusedID)
                                    .frame(height: inputHeight)
                                    .padding(.horizontal, 12)
                                    .background(AppTheme.Colors.surface, in: RoundedRectangle(cornerRadius: AppTheme.Radius.md))
                                    .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.md).stroke(AppTheme.Colors.separator, lineWidth: 1))
                            }
                        }
                    }
                    Button(puzzle.presentation?.submit ?? "Submit") {
                        focusedID = nil
                        result = access.submit(puzzleID, fields: draft.fields)
                        if result == .completed { onCompletion() }
                        if result == .rejected(.invalidFields) {
                            focusedID = puzzle.inputs.first(where: { (draft.fields[$0.id] ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || (draft.fields[$0.id] ?? "").utf8.count > 256 })?.id
                        }
                    }.buttonStyle(.appPrimary).accessibilityIdentifier("story.puzzle.submit.\(puzzleID)")
                    if let result { Text(message(result, puzzle: puzzle)).appText(.body).accessibilityIdentifier("story.puzzle.feedback.\(puzzleID)") }
                    Button(puzzle.presentation?.clear ?? "Clear input and retry") {
                        draft.fields = [:]; result = nil; focusedID = nil; access.saveDraft(draft, for: puzzleID)
                    }.buttonStyle(.modernPhone).accessibilityIdentifier("story.puzzle.clear.\(puzzleID)")
                    if !puzzle.hints.isEmpty {
                        Button("Hint") { draft.revealHint(total: puzzle.hints.count); access.saveDraft(draft, for: puzzleID) }
                            .buttonStyle(.modernPhone).disabled(draft.hintCount == puzzle.hints.count)
                            .accessibilityHint("Show the next hint. Hints have no penalty.")
                            .accessibilityIdentifier("story.puzzle.hint.\(puzzleID)")
                        if draft.hintCount > 0 {
                            Text("Show previous hints").appText(.sectionTitle)
                            ForEach(Array(puzzle.hints.prefix(draft.hintCount).enumerated()), id: \.offset) { index, hint in
                                Text(hint).appText(.body).textSelection(.enabled)
                                    .accessibilityIdentifier("story.puzzle.hint.\(puzzleID).\(index + 1)")
                            }
                        }
                    }
                    ForEach(puzzle.clueContentIDs ?? [], id: \.self) { id in
                        if let definition = appState.content.catalogue?.itemsByID[id],
                           let item = appState.content.availableItems(for: definition.appSurface).first(where: { $0.id == id }) {
                            Button(item.version.title) { focusedID = nil; openClue(id) }
                                .buttonStyle(.modernPhone).accessibilityIdentifier("story.puzzle.clue.\(id)")
                        }
                    }
                } else {
                    Text(availability == .completed ? (puzzle.presentation?.completed ?? "Challenge completed") : "Access challenge unavailable").appText(.caption)
                }
            }
            .onChange(of: result) { _, value in
                if let value, value != .completed, UIAccessibility.isVoiceOverRunning {
                    UIAccessibility.post(notification: .announcement, argument: message(value, puzzle: puzzle))
                }
            }
        }
    }
    private func binding(_ id: String) -> Binding<String> {
        Binding(get: { draft.fields[id] ?? "" }, set: { draft.fields[id] = $0; result = nil; access.saveDraft(draft, for: puzzleID) })
    }
    private func message(_ result: PuzzleSubmissionResult, puzzle: PuzzleDefinition) -> String {
        switch result {
        case .completed: return puzzle.presentation?.success ?? "Your completion is saved."
        case .alreadyCompleted: return puzzle.presentation?.completed ?? "Your completion is saved."
        case .saveFailed: return puzzle.presentation?.saveFailed ?? "Completion could not be saved. You can retry; no access has been granted."
        case .rejected(.invalidFields): return puzzle.presentation?.invalidFields ?? "The input did not match the challenge. You can retry."
        case .rejected(.incorrectAnswer): return puzzle.presentation?.incorrectAnswer ?? "The input did not match the challenge. You can retry."
        case .rejected: return puzzle.presentation?.unavailable ?? "This challenge cannot accept input right now."
        }
    }
}

/// Supported UIKit input keeps exact-reference punctuation stable; it does not evaluate answers.
private struct PuzzleTextField: UIViewRepresentable {
    let id: String
    let label: String
    @Binding var text: String
    @Binding var focusedID: String?
    func makeUIView(context: Context) -> UITextField {
        let field = UITextField()
        field.font = .preferredFont(forTextStyle: .body)
        field.adjustsFontForContentSizeCategory = true
        field.textColor = .white
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.spellCheckingType = .no
        field.smartDashesType = .no
        field.smartQuotesType = .no
        field.returnKeyType = .done
        field.accessibilityLabel = label
        field.accessibilityIdentifier = "story.puzzle.input.\(id)"
        field.delegate = context.coordinator
        field.addTarget(context.coordinator, action: #selector(Coordinator.changed(_:)), for: .editingChanged)
        field.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return field
    }
    func updateUIView(_ field: UITextField, context: Context) {
        context.coordinator.parent = self
        if field.text != text { field.text = text }
        if focusedID == id, !field.isFirstResponder { field.becomeFirstResponder() }
        else if focusedID != id, field.isFirstResponder { field.resignFirstResponder() }
    }
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: PuzzleTextField
        init(_ parent: PuzzleTextField) { self.parent = parent }
        @objc func changed(_ field: UITextField) { parent.text = field.text ?? "" }
        func textFieldDidBeginEditing(_ field: UITextField) { parent.focusedID = parent.id }
        func textFieldShouldReturn(_ field: UITextField) -> Bool { parent.focusedID = nil; field.resignFirstResponder(); return true }
    }
}

#if DEBUG
/// A neutral local demo owns a fresh in-memory story. It cannot grant access in the campaign.
private struct DevelopmentPuzzleDemo: View {
    @State private var session = DevelopmentAccessSession()
    var body: some View {
        RestrictedResourceView(resourceID: "resource.fixture.demo", accessOverride: session.access)
    }
}
@MainActor private final class DevelopmentAccessSession {
    let story = StoryProgressionStore(persistence: InMemoryStoryPersistence())
    let access: RestrictedAccessStore
    init() { access = RestrictedAccessStore(progression: story, catalogue: RestrictedAccessCatalogueLoader.loadDevelopmentFixture(data: RestrictedAccessDevelopmentFixture.data)) }
}
struct DevelopmentPuzzleEntry: View {
    var body: some View { NavigationLink("Puzzle framework demo (isolated)") { DevelopmentPuzzleDemo() }.buttonStyle(.modernPhone) }
}
#endif
