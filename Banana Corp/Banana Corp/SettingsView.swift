//
//  SettingsView.swift
//  Banana Corp
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        PhoneShellView(title: "Settings") {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                Text("DEVICE SETTINGS")
                    .appText(.h2, color: AppTheme.Colors.highlight)

                Text("Banana Corp OS")
                    .appText(.paragraph)

                Text("Core device controls are online. Advanced settings remain managed.")
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
