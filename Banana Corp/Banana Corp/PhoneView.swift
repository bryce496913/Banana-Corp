import SwiftUI

struct PhoneView: View {
    var body: some View {
        PhoneShellView(title: "Phone") {
            VStack(spacing: 0) {
                AppScreenScroll {
                    AppSectionHeader("Calls")
                    AppEmptyState(
                        symbol: "phone",
                        title: "Service limited...",
                        message: "Calls are restricted until the device finishes registration."
                    )
                }
            }
        }
    }
}
