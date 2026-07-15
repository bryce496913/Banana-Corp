import SwiftUI

struct PhoneShellView<Content: View>: View {
    let title: String?
    let showsStatusBar: Bool
    let showsHomeIndicator: Bool
    let content: Content

    init(
        title: String? = nil,
        showsStatusBar: Bool = true,
        showsHomeIndicator: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.showsStatusBar = showsStatusBar
        self.showsHomeIndicator = showsHomeIndicator
        self.content = content()
    }

    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()

            VStack(spacing: AppTheme.Spacing.sm) {
                if showsStatusBar {
                    StatusBar()
                }

                if let title {
                    Text(title)
                        .appText(.h1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, AppTheme.Spacing.lg)
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
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }
}
