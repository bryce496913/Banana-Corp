//
//  PhoneView.swift
//  Banana Corp
//

import SwiftUI

struct PhoneView: View {
    var body: some View {
        PhoneShellView(title: "Phone") {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                Text("BANANA PHONE")
                    .appText(.h2, color: AppTheme.Colors.highlight)

                Text("Service limited...")
                    .appText(.paragraph)

                Text("Calls are restricted until the device finishes registration.")
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
