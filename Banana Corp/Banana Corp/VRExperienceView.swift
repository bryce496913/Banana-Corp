import SwiftUI

struct VRExperienceView: View {
    @EnvironmentObject private var appState: AppState
    @State private var progress = StoryPresentationProgress()
    @State private var failure = false
    @State private var feedback: AppFeedbackEvent?
    var body: some View {
        PhoneShellView(title: "VR Experience", subtitle: "BANANA VISION") {
            AppScreenScroll {
                HeadsetShopCard()
                if let item = appState.content.availableItems(for: .web).first(where: { $0.id == "content.act1.vr_preview" }),
                   case .web(let preview) = item.version.payload {
                    Image(systemName: "visionpro").font(.system(size: 64)).foregroundStyle(AppTheme.Colors.accent).accessibilityHidden(true)
                    Text(item.version.title).appText(.screenTitle)
                    let scenes = preview.blocks.filter { $0.kind == .paragraph }
                    if scenes.indices.contains(progress.index) {
                        AppCard { Text(scenes[progress.index].text).appText(.body) }
                        Text("\(progress.index + 1) of \(scenes.count)").appText(.caption)
                        if progress.canComplete(count: scenes.count) {
                            Button(item.availability == .read ? "Preview explored" : "Finish preview") {
                                switch appState.content.read(item.id, versionID: item.version.id) {
                                case .success(.changed): feedback = AppFeedbackEvent(kind: .confirmedAction)
                                case .success(.unchanged): break
                                case .failure: failure = true
                                }
                            }.buttonStyle(.appPrimary).disabled(item.availability == .read)
                        } else {
                            Button("Explore next") { progress.advance(count: scenes.count) }.buttonStyle(.appPrimary)
                        }
                        if progress.index > 0 { Button("Previous") { progress.goBack() }.buttonStyle(.modernPhone) }
                    }
                    Text("On-phone preview. No physical headset connection is required.").appText(.caption, color: AppTheme.Colors.secondaryText)
                } else {
                    AppErrorState(title: "Preview unavailable", message: "The local product preview could not be loaded.")
                }
            }
        }
        .modifier(AppFeedbackModifier(event: feedback))
        .alert("Progress could not be saved", isPresented: $failure) { Button("OK", role: .cancel) {} }
            message: { Text("The preview has not been recorded. Please try again.") }
    }
}
