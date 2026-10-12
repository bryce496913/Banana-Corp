import SwiftUI

struct NewsView: View {
    var body: some View {
        PhoneShellView(title: "News") {
            VStack(spacing: 0) {
                AppScreenScroll {
                    AppSectionHeader("Latest")
                    AppEmptyState(
                        symbol: "newspaper",
                        title: "Headlines pending...",
                        message: "Official updates will refresh when the signal stabilizes."
                    )
                }
            }
        }
    }
}
