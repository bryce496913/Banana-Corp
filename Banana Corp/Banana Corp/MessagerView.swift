import SwiftUI

struct MessagerView: View {
    var body: some View {
        PhoneShellView(title: "Messages") {
            AppScreenScroll {
                DeviceConversationPanel(channel: "messages", title: "Service conversation", responder: "Automated service", inputLabel: "Message the service desk")
                AppSectionHeader("Correspondence")
                StorySurfaceContent(surface: .messages, scrollsContent: false) {
                    AppEmptyState(symbol: "bubble.left.and.bubble.right", title: "No correspondence", message: "Incoming conversations will appear here.")
                }
            }
        }
    }
}
