import SwiftUI

struct PhotoAlbumView: View {
    var body: some View {
        PhoneShellView(title: "Photo Album") {
            StorySurfaceContent(surface: .photos) {
                VStack(spacing: 0) {
                    AppScreenScroll {
                        AppSectionHeader("Library")
                        AppEmptyState(
                            symbol: "photo.stack",
                            title: "Album indexing...",
                            message: "Recovered media will appear here when access is granted."
                        )
                    }
                }
            }
        }
    }
}
