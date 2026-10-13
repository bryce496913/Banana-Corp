import SwiftUI

struct WebBrowserView: View {
    var body: some View {
        PhoneShellView(title: "Web Browser") {
            StorySurfaceContent(surface: .web) {
                VStack(spacing: 0) {
                    AppScreenScroll {
                        AppTextInput(
                            label: "Address or search",
                            text: .constant(""),
                            symbol: "magnifyingglass",
                            keyboard: .URL,
                            submitLabel: .go
                        )
                        .disabled(true)
                        .accessibilityHint("Connection pending...")
                        AppEmptyState(
                            symbol: "globe",
                            title: "Connection pending...",
                            message: "Corporate browsing is currently routing through a protected relay."
                        )
                    }
                    AppBottomActionArea {
                        HStack {
                            AppNavigationControl(label: "Back", symbol: "chevron.left")
                            AppNavigationControl(label: "Forward", symbol: "chevron.right")
                            Spacer()
                            AppNavigationControl(label: "Reload", symbol: "arrow.clockwise")
                        }
                        .accessibilityHint("Connection pending...")
                    }
                }
            }
        }
    }
}
