//
//  WebBrowserView.swift
//  Banana Corp
//

import SwiftUI

struct WebBrowserView: View {
    var body: some View {
        PhoneShellView(title: "Web Browser") {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                Text("BANANA WEB")
                    .appText(.h2, color: AppTheme.Colors.highlight)

                Text("Connection pending...")
                    .appText(.paragraph)

                Text("Corporate browsing is currently routing through a protected relay.")
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
