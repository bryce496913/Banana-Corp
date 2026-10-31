import SwiftUI

struct PhoneShellView<Content: View>: View {
    @Environment(\.osPresentation) private var presentation
    @Environment(\.dismiss) private var dismiss
    @Environment(\.isPresented) private var isPresented
    @EnvironmentObject private var appState: AppState
    let title: String?
    let subtitle: String?
    let showsStatusBar: Bool
    let showsHomeIndicator: Bool
    let backAction: (() -> Void)?
    let content: Content

    init(
        title: String? = nil,
        subtitle: String? = nil,
        showsStatusBar: Bool = true,
        showsHomeIndicator: Bool = true,
        backAction: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.showsStatusBar = showsStatusBar
        self.showsHomeIndicator = showsHomeIndicator
        self.backAction = backAction
        self.content = content()
    }

    var body: some View {
        ZStack {
            presentation.resolved(at: Date()).visualPalette.background
                .ignoresSafeArea()

            VStack(spacing: AppTheme.Spacing.sm) {
                if showsStatusBar {
                    StatusBar()
                }

                if let title {
                    AppScreenHeader(title: title, subtitle: subtitle)
                }

                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                if showsHomeIndicator {
                    PhoneHomeIndicator()
                }
            }
            .padding(.horizontal, AppTheme.Spacing.sm)
            .padding(.bottom, AppTheme.Spacing.xs)
        }
        .overlay(alignment: .leading) {
            if permitsEdgeBack {
                // A narrow reserved edge leaves content scrolling, controls and game boards alone.
                Color.clear
                    .frame(width: 20)
                    .contentShape(Rectangle())
                    .gesture(DragGesture(minimumDistance: 24).onEnded { value in
                        guard PhoneEdgeBackIntent.shouldGoBack(horizontal: Double(value.translation.width),
                                                               vertical: Double(value.translation.height)) else { return }
                        if let backAction { backAction() }
                        else if isPresented { dismiss() }
                        else { appState.goHome() }
                    })
                    .accessibilityHidden(true)
            }
        }
        .statusBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var permitsEdgeBack: Bool {
        guard appState.story.state.endgame?.currentEnding == nil else { return false }
        return ![PhoneAppRoute.snake, .pong, .xo].contains(appState.activeApp ?? .phone)
    }
}
