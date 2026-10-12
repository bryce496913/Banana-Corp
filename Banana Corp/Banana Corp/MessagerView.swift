import SwiftUI

struct MessagerView: View {
    var body: some View {
        PhoneShellView(title: "Messages") {
            VStack(spacing: 0) {
                AppScreenScroll {
                    AppSectionHeader("Conversations")
                    AppEmptyState(
                        symbol: "bubble.left.and.bubble.right",
                        title: "No active conversations...",
                        message: "Encrypted threads are waiting for device activation."
                    )
                }
                AppMessageComposer(
                    prompt: "Message",
                    unavailableReason: "Encrypted threads are waiting for device activation.",
                    text: .constant("")
                )
            }
        }
    }
}
