import SwiftUI

struct VRExperienceView: View {
    var body: some View {
        PhoneShellView(title: "VR Experience", subtitle: "BANANA VR") {
            VStack(spacing: 0) {
                AppScreenScroll {
                    AppSectionHeader("Headset")
                    AppEmptyState(
                        symbol: "visionpro",
                        title: "Calibration required...",
                        message: "Immersive access is waiting for headset confirmation.",
                        symbolSize: 72
                    )
                }
            }
        }
    }
}
