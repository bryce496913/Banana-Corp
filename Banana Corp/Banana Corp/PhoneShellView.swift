import SwiftUI

struct PhoneShellView<Content: View>: View {
    @Environment(\.osPresentation) private var presentation
    let title: String?
    let subtitle: String?
    let showsStatusBar: Bool
    let showsHomeIndicator: Bool
    let content: Content

    init(
        title: String? = nil,
        subtitle: String? = nil,
        showsStatusBar: Bool = true,
        showsHomeIndicator: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.showsStatusBar = showsStatusBar
        self.showsHomeIndicator = showsHomeIndicator
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
        .statusBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }
}
