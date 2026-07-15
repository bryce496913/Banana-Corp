//
//  PhotoAlbumView.swift
//  Banana Corp
//

import SwiftUI

struct PhotoAlbumView: View {
    var body: some View {
        PhoneShellView(title: "Photo Album") {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                Text("BANANA PHOTOS")
                    .appText(.h2, color: AppTheme.Colors.highlight)

                Text("Album indexing...")
                    .appText(.paragraph)

                Text("Recovered media will appear here when access is granted.")
                    .appText(.paragraph)
                    .padding(AppTheme.Spacing.lg)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .modernSurface(
                        in: RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous)
                    )

                Spacer()
            }
            .padding(AppTheme.Spacing.lg)
        }
    }
}
