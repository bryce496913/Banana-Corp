//
//  SocialXView.swift
//  Banana Corp
//

import SwiftUI

struct SocialXView: View {
    var body: some View {
        PhoneShellView(title: "Social X") {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                Text("SOCIAL X")
                    .appText(.h2, color: AppTheme.Colors.highlight)

                Text("Feed unavailable...")
                    .appText(.paragraph)

                Text("Network identity verification is still in progress.")
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
