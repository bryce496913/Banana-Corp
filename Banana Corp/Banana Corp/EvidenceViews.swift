import SwiftUI

struct EvidenceBackControl: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        Button { dismiss() } label: { Label("Back", systemImage: "chevron.left").padding(8).frame(minHeight: 44) }
            .buttonStyle(.appContent)
            .accessibilityLabel("Back")
            .accessibilityIdentifier("story.back")
    }
}

struct EvidencePayloadView: View {
    let version: StoryContentVersion
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            if case .video(let video) = version.payload, video.mediaAssetID == nil {
                Text("Text record: source metadata and transcript. No playable video is stored.").appText(.caption, color: AppTheme.Colors.secondaryText)
            }
            ForEach(EvidenceContentFields.fields(for: version).filter { !$0.id.hasSuffix(".position") && !$0.id.hasSuffix(".kind") }) { field in
                VStack(alignment: .leading, spacing: 4) {
                    Text(field.label).appText(.caption, color: AppTheme.Colors.secondaryText)
                    Text(field.displayValue)
                        .appText(field.style == .heading ? .sectionTitle : .body)
                        .textSelection(.enabled)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Shared by lists and detail screens. It never preserves non-preservable versions.
struct PreserveEvidenceButton: View {
    @EnvironmentObject private var appState: AppState
    let contentID: String
    let versionID: String
    @State private var failure = false
    @State private var feedback: AppFeedbackEvent?

    private var isSaved: Bool {
        appState.content.preservedItems().contains { $0.record.sourceContentID == contentID && $0.record.sourceVersionID == versionID }
    }
    var body: some View {
        Button {
            switch appState.content.preserve(contentID, versionID: versionID) {
            case .success(.changed): feedback = AppFeedbackEvent(kind: .confirmedAction)
            case .success(.unchanged): break
            case .failure: failure = true
            }
        } label: {
            Label(isSaved ? "Preserved in Evidence" : "Preserve Evidence", systemImage: isSaved ? "archivebox.fill" : "archivebox")
        }
        .buttonStyle(.modernPhone)
        .accessibilityIdentifier("story.preserve.\(versionID)")
        .disabled(isSaved || !appState.content.isPreservable(contentID, versionID: versionID))
        .accessibilityLabel(isSaved ? "Evidence preserved" : "Preserve Evidence")
        .accessibilityHint(isSaved ? "The saved snapshot is available in Evidence." : "Save this exact version separately from its live source.")
        .modifier(AppFeedbackModifier(event: feedback))
        .alert("Evidence could not be preserved", isPresented: $failure) {
            Button("OK", role: .cancel) {}
        } message: { Text("The source or save is unavailable. Existing saved copies have not been changed.") }
    }
}

struct EvidenceVaultView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selectedEvidence: String?
    var body: some View {
        PhoneShellView(title: "Evidence", subtitle: "Preserved snapshots") {
            AppScreenScroll {
                if case .recoveryRequired = appState.story.saveStatus {
                    AppErrorState(title: "Evidence save unavailable", message: "Your save needs recovery. It has not been reset.", retry: { _ = appState.story.load() })
                }
                let records = appState.content.evidenceRecords()
                if records.isEmpty && appState.story.isWritable {
                    AppEmptyState(symbol: "archivebox", title: "No preserved evidence", message: "Use Preserve Evidence on eligible content to keep an exact snapshot here.")
                } else {
                    ForEach(records, id: \.id) { record in
                        let saved = appState.content.preservedItem(record.id)
                        AppCardButton(label: saved?.snapshot.version.title ?? "Saved snapshot unavailable", action: { selectedEvidence = record.id }) {
                            VStack(alignment: .leading, spacing: 8) {
                                AppListRow(title: saved?.snapshot.version.title ?? "Saved snapshot unavailable", subtitle: saved?.snapshot.appSurface.displayName,
                                           detail: "Preserved snapshot", symbol: saved?.snapshot.appSurface.symbol ?? "exclamationmark.triangle")
                                Text(record.capturedAt, format: .dateTime.year().month().day().hour().minute())
                                    .appText(.caption, color: AppTheme.Colors.secondaryText)
                                    .accessibilityLabel("Preserved \(record.capturedAt.formatted(date: .abbreviated, time: .shortened))")
                            }
                        }
                        .accessibilityIdentifier("story.evidence.\(record.id)")
                        .accessibilityHint("\(saved?.snapshot.appSurface.displayName ?? "Unknown source"), preserved \(record.capturedAt.formatted(date: .abbreviated, time: .shortened)). Opens the saved snapshot.")
                    }
                }
            }
        }
        .navigationDestination(item: $selectedEvidence) { EvidenceDetailView(evidenceID: $0) }
    }
}

struct EvidenceDetailView: View {
    @EnvironmentObject private var appState: AppState
    let evidenceID: String
    @State private var showsComparison = false
    @State private var saveFailure = false
    var body: some View {
        PhoneShellView(title: "Evidence", subtitle: "Preserved snapshot") {
            AppScreenScroll {
                EvidenceBackControl()
                if let saved = appState.content.preservedItem(evidenceID) {
                    AppCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Label(saved.snapshot.appSurface.displayName, systemImage: saved.snapshot.appSurface.symbol).appText(.systemLabel)
                            Text("Preserved version \(saved.snapshot.version.version)").appText(.caption)
                            Text("Preserved \(saved.record.capturedAt.formatted(date: .abbreviated, time: .shortened))").appText(.caption, color: AppTheme.Colors.secondaryText)
                            Text("This is your saved copy, separate from the current source.").appText(.body)
                        }
                    }
                    Button {
                        if case .failure(let error) = appState.content.recordComparison(evidenceID), error != .contentUnavailable { saveFailure = true }
                        showsComparison = true
                    } label: { Label("Compare with live source", systemImage: "rectangle.split.2x1") }
                        .buttonStyle(.appPrimary)
                        .accessibilityIdentifier("story.compare.\(evidenceID)")
                        .accessibilityHint("Compare your preserved copy with the currently available source.")
                    AppCard { EvidencePayloadView(version: saved.snapshot.version) }
                } else {
                    AppErrorState(title: "Saved snapshot unavailable", message: "This snapshot cannot be opened. Any existing record has been retained.")
                }
            }
        }
        .navigationDestination(isPresented: $showsComparison) { EvidenceComparisonView(evidenceID: evidenceID) }
        .alert("Comparison progress could not be saved", isPresented: $saveFailure) { Button("OK", role: .cancel) {} }
            message: { Text("You can still inspect the comparison. Your saved evidence has not changed.") }
    }
}

struct EvidenceComparisonView: View {
    @EnvironmentObject private var appState: AppState
    let evidenceID: String
    var body: some View {
        PhoneShellView(title: "Compare", subtitle: "Preserved and live") {
            AppScreenScroll {
                EvidenceBackControl()
                FirstAnomalyHandoffControl()
                switch appState.content.comparison(for: evidenceID) {
                case .failure:
                    AppErrorState(title: "No usable preserved copy", message: "A comparison needs an existing saved snapshot. No earlier copy has been reconstructed.")
                case .success(let comparison):
                    switch comparison.current {
                    case .unavailable(let reason):
                        AppEmptyState(symbol: "questionmark.circle", title: "Current source unavailable", message: reason.explanation)
                    case .live(let live):
                        if comparison.differences.isEmpty {
                            Text(live.id == comparison.preserved.snapshot.version.id ? "The displayed content matches your preserved copy." : "A different live version is available. Its displayed content matches your preserved copy.")
                                .appText(.body)
                        } else {
                            AppSectionHeader("Visible differences")
                            Text("These are changes in the available source. The comparison does not establish why they changed.").appText(.body, color: AppTheme.Colors.secondaryText)
                            ForEach(comparison.differences) { difference in
                                AppCard {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(difference.label).appText(.sectionTitle)
                                        if difference.isReference {
                                            Text("The linked record differs.").appText(.body)
                                        } else {
                                            Text("Preserved: \(difference.preservedValue ?? "Not present")").appText(.body)
                                            Text("Live: \(difference.liveValue ?? "Not present")").appText(.body, color: AppTheme.Colors.highlight)
                                        }
                                    }
                                    .textSelection(.enabled)
                                }
                            }
                        }
                        AppSectionHeader("Current live version \(live.version)")
                        AppCard { EvidencePayloadView(version: live) }
                    }
                    AppSectionHeader("Preserved version \(comparison.preserved.snapshot.version.version)")
                    AppCard { EvidencePayloadView(version: comparison.preserved.snapshot.version) }
                }
            }
        }
    }
}
