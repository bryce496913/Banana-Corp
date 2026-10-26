import SwiftUI

struct EmailView: View {
    var body: some View {
        PhoneShellView {
            StorySurfaceContent(surface: .email) {
                AppEmptyState(symbol: "envelope", title: "Inbox syncing...",
                              message: "Secure messages will appear after device activation.")
            }
        }
    }
}
