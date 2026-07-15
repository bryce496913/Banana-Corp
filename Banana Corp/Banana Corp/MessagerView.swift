//
//  MessagerView.swift
//  Banana Corp
//

import SwiftUI

struct MessagerView: View {
    var body: some View {
        PhoneShellView(title: "Messages") {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                Text("BANANA MESSAGES")
                    .appText(.h2, color: AppTheme.Colors.highlight)

                Text("No active conversations...")
                    .appText(.paragraph)

                Text("Encrypted threads are waiting for device activation.")
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
