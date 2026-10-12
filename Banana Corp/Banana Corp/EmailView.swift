import SwiftUI

struct EmailView: View {
    var body: some View {
        PhoneShellView(title: "Email") {
            VStack(spacing: 0) {
                AppScreenScroll {
                    AppSearchField(label: "Search mail", text: .constant(""))
                        .disabled(true)
                        .accessibilityHint("Secure messages will appear after device activation.")
                    AppSectionHeader("Inbox")
                    AppEmptyState(
                        symbol: "envelope",
                        title: "Inbox syncing...",
                        message: "Secure messages will appear after device activation."
                    )
                }
            }
        }
    }
}
