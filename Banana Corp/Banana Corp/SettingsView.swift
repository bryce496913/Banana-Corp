import SwiftUI

struct SettingsView: View {
    var body: some View {
        PhoneShellView(title: "Settings") {
            AppScreenScroll {
                AppSectionHeader("Device")
                AppCard {
                    AppListRow(title: "Banana Corp OS", symbol: "iphone")
                }

                AppSectionHeader("Advanced settings")
                AppEmptyState(
                    symbol: "gearshape",
                    title: "DEVICE SETTINGS",
                    message: "Core device controls are online. Advanced settings remain managed."
                )
            }
        }
    }
}
