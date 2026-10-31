import SwiftUI

struct SocialXView: View {
    var body: some View {
        PhoneShellView(title: "Social X") {
            AppScreenScroll {
                DeviceConversationPanel(channel: "social", title: "Community channel", responder: "Community auto-reply", inputLabel: "Write a community reply")
                AppSectionHeader("Feed")
                StorySurfaceContent(surface: .social, scrollsContent: false) {
                    AppEmptyState(symbol: "person.crop.circle", title: "Feed unavailable...", message: "Network identity verification is still in progress.")
                }
            }
        }
    }
}
