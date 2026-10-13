import SwiftUI

struct MessagerView: View {
    var body: some View {
        PhoneShellView(title: "Messages") {
            StorySurfaceContent(surface: .messages) {
                AppScreenScroll {
                    AppEmptyState(symbol: "bubble.left.and.bubble.right", title: "No conversations", message: "Incoming conversations will appear here.")
                }
            }
        }
    }
}
