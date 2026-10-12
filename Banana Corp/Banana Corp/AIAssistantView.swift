import SwiftUI

struct AIAssistantView: View {
    var body: some View {
        PhoneShellView(title: "AI Assistant", subtitle: "BANANA ASSIST") {
            VStack(spacing: 0) {
                AppScreenScroll {
                    AppEmptyState(
                        symbol: "waveform.path.ecg",
                        title: "Connection pending...",
                        message: "System access will become available after device activation."
                    )
                }
                AppMessageComposer(
                    prompt: "Ask Banana Assist",
                    unavailableReason: "System access will become available after device activation.",
                    text: .constant("")
                )
            }
        }
    }
}
