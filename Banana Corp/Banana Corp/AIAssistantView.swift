import SwiftUI

struct AIAssistantView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selectedID: String?
    @State private var failure = false
    var body: some View {
        PhoneShellView(title: "AI Assistant", subtitle: "BANANA ASSIST") {
            AppScreenScroll {
                let responses = appState.content.availableItems(for: .assistant)
                if let welcome = responses.first(where: { $0.id == "content.act1.assistant.welcome" }) {
                    StoryReadableContent(version: welcome.version)
                }
                if let selectedID, let response = responses.first(where: { $0.id == selectedID }) {
                    StoryReadableContent(version: response.version)
                }
                FirstAnomalyHandoffControl()
                if !appState.content.availableItems(for: .diagnostics).isEmpty {
                    NavigationLink("Research diagnostic excerpts") {
                        PhoneShellView(title: "Diagnostics") {
                            VStack(alignment: .leading, spacing: 0) {
                                EvidenceBackControl().padding(.horizontal, AppTheme.Spacing.lg)
                                StorySurfaceContent(surface: .diagnostics) {
                                    AppScreenScroll { AppEmptyState(symbol: "waveform.path.ecg", title: "No diagnostic excerpts", message: "Available review attachments will appear here.") }
                                }
                            }
                        }
                    }.buttonStyle(.modernPhone)
                }
                if responses.isEmpty {
                    AppErrorState(title: "Assistant unavailable", message: "The local responses or saved progress could not be loaded.")
                } else {
                    Text("Choose a question").appText(.sectionTitle)
                    Text("Local answers for your phone and Banana Vision.").appText(.caption, color: AppTheme.Colors.secondaryText)
                    ForEach(responses.filter { $0.id != "content.act1.assistant.welcome" }) { response in
                        Button(response.version.title) {
                            switch appState.content.read(response.id, versionID: response.version.id) {
                            case .success: selectedID = response.id
                            case .failure: failure = true
                            }
                        }.buttonStyle(.modernPhone)
                            .accessibilityIdentifier("story.assistant.\(response.version.id)")
                    }
                }
            }
        }
        .alert("Answer unavailable", isPresented: $failure) { Button("OK", role: .cancel) {} }
            message: { Text("The response could not be saved. Your progress has not changed.") }
    }
}
