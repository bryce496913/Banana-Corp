import SwiftUI

struct WatchVideoView: View {
    var body: some View {
        PhoneShellView(title: "Watch Video") {
            StorySurfaceContent(surface: .video) {
                VStack(spacing: 0) {
                    AppScreenScroll {
                        AppSectionHeader("Library")
                        AppEmptyState(
                            symbol: "play.rectangle",
                            title: "Library locked...",
                            message: "Approved media will become available after activation."
                        )
                    }
                }
            }
        }
    }
}
