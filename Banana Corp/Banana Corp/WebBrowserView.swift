import SwiftUI

struct WebBrowserView: View {
    var body: some View {
        PhoneShellView {
            StorySurfaceContent(surface: .web) {
                AppEmptyState(symbol: "globe", title: "No pages available",
                              message: "Available in-game pages will appear here.")
            }
        }
    }
}
