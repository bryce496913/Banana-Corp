//
//  NewsView.swift
//  Banana Corp
//

import SwiftUI

struct NewsView: View {
    var body: some View {
        PhoneShellView(title: "News") {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                Text("BANANA NEWS")
                    .appText(.h2, color: AppTheme.Colors.highlight)

                Text("Headlines pending...")
                    .appText(.paragraph)

                Text("Official updates will refresh when the signal stabilizes.")
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
