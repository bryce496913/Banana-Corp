import SwiftUI

struct SocialXView: View {
    var body: some View {
        PhoneShellView(title: "Social X") {
            StorySurfaceContent(surface: .social) {
                VStack(spacing: 0) {
                    AppScreenScroll {
                        AppSectionHeader("Feed")
                        AppEmptyState(
                            symbol: "person.crop.circle",
                            title: "Feed unavailable...",
                            message: "Network identity verification is still in progress."
                        )
                    }
                }
            }
        }
    }
}
