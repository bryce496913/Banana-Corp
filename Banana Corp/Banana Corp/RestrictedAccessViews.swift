import SwiftUI

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
        }.padding(.horizontal, AppTheme.Spacing.lg)
    }
}

struct RestrictedResourceView: View {
    @EnvironmentObject private var appState: AppState
    let resourceID: String
    var accessOverride: RestrictedAccessStore? = nil
    @State private var selection: StoryContentSelection?
    @State private var failed = false
    private var access: RestrictedAccessStore { accessOverride ?? appState.access }
    var body: some View {
        PhoneShellView(title: "Protected access") {
            AppScreenScroll {
                EvidenceBackControl()
                if let resource = access.catalogue?.resourcesByID[resourceID] {
                    switch access.resourceState(resourceID) {
                    case .hidden, .unresolved:
                        AppErrorState(title: "Entry unavailable", message: "No accessible entry is available here.")
                    case .locked:
                        AppCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Label(resource.displayName, systemImage: "lock.shield").appText(.screenTitle)
                                    .accessibilityIdentifier("story.resource.locked.\(resource.id)")
                                Text(resource.message).appText(.body)
                            }
                        }
                        if let puzzleID = resource.requiredPuzzleID { PuzzleInteractionView(puzzleID: puzzleID, access: access) }
                    case .unlocked:
                        Label(resource.displayName, systemImage: "lock.open").appText(.screenTitle)
                        Text("Access granted").appText(.sectionTitle)
                        ForEach(resource.linkedContentIDs, id: \.self) { id in
                            if let definition = appState.content.catalogue?.itemsByID[id],
                               let item = appState.content.availableItems(for: definition.appSurface).first(where: { $0.id == id }) {
                                Button(item.version.title) {
                                    if item.surface != .video, case .failure = appState.content.read(id, versionID: item.version.id) { failed = true; return }
                                    selection = .init(contentID: id, versionID: item.version.id, surface: item.surface)
                                }.buttonStyle(.modernPhone)
                            }
                        }
                    }
                } else { AppErrorState(title: "Entry unavailable", message: "The local access record could not be loaded.") }
            }
        }
        .navigationDestination(item: $selection) { StorySourceDetailView(selection: $0) }
        .alert("Source unavailable", isPresented: $failed) { Button("OK", role: .cancel) {} }
            message: { Text("The source could not be opened. Your records remain intact.") }
    }
}

private struct PuzzleInteractionView: View {
    let puzzleID: String
    let access: RestrictedAccessStore
    @State private var fields: [String: String] = [:]
    @State private var result: PuzzleSubmissionResult?
    @State private var hintIndex = 0
    @State private var feedback: AppFeedbackEvent?
    var body: some View {
        if access.puzzleAvailability(puzzleID) == .hidden || access.puzzleAvailability(puzzleID) == .unresolved {
            Text("Challenge unavailable. No progress has been reset.").appText(.caption)
        } else if access.puzzleAvailability(puzzleID) == .locked {
            Text("Additional access requirements remain.").appText(.caption)
        } else if let puzzle = access.catalogue?.puzzlesByID[puzzleID] {
            VStack(alignment: .leading, spacing: 12) {
                Text(puzzle.title).appText(.sectionTitle)
                Text(puzzle.instructions).appText(.body)
                switch access.puzzleAvailability(puzzleID) {
                case .ready:
                    ForEach(puzzle.inputs) { input in
                        if input.kind == .choice {
                            Picker(input.label, selection: binding(input.id)) {
                                Text("Choose").tag("")
                                ForEach(input.choices ?? [], id: \.self) { Text($0).tag($0) }
                            }.frame(minHeight: AppTheme.Layout.touchTarget)
                        } else {
                            TextField(input.label, text: binding(input.id))
                                .textFieldStyle(.roundedBorder)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .accessibilityLabel(input.label)
                        }
                    }
                    Button("Submit") {
                        result = access.submit(puzzleID, fields: fields)
                        if result == .completed { feedback = AppFeedbackEvent(kind: .confirmedAction) }
                    }.buttonStyle(.appPrimary)
                    Button("Clear input and retry") { fields = [:]; result = nil }.buttonStyle(.modernPhone)
                    if !puzzle.hints.isEmpty {
                        Button("Hint") { hintIndex = min(hintIndex + 1, puzzle.hints.count) }.buttonStyle(.modernPhone)
                        ForEach(Array(puzzle.hints.prefix(hintIndex).enumerated()), id: \.offset) { _, hint in Text(hint).appText(.body) }
                    }
                case .completed: Text("Challenge completed").appText(.sectionTitle)
                case .awaitingApproval: Text("Access challenge unavailable").appText(.caption)
                case .hidden, .locked: Text("Additional access requirements remain.").appText(.caption)
                case .unresolved: Text("Challenge state unavailable. No progress has been reset.").appText(.caption)
                }
                if let result {
                    switch result {
                    case .completed, .alreadyCompleted: Text("Your completion is saved.").appText(.body)
                    case .saveFailed: Text("Completion could not be saved. You can retry; no access has been granted.").appText(.body)
                    case .rejected(.incorrectAnswer), .rejected(.invalidFields): Text("The input did not match the challenge. You can retry.").appText(.body)
                    case .rejected: Text("This challenge cannot accept input right now.").appText(.body)
                    }
                }
            }.modifier(AppFeedbackModifier(event: feedback))
        }
    }
    private func binding(_ id: String) -> Binding<String> { Binding(get: { fields[id] ?? "" }, set: { fields[id] = $0 }) }
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
