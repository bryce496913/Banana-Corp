//
//  EmailView.swift
//  Banana Corp
//

import SwiftUI

struct EmailView: View {
    var body: some View {
        PhoneShellView(title: "Email") {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                Text("BANANA MAIL")
                    .appText(.h2, color: AppTheme.Colors.highlight)

                Text("Inbox syncing...")
                    .appText(.paragraph)

                Text("Secure messages will appear after device activation.")
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
