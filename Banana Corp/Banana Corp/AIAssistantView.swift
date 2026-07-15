//
//  AIAssistantView.swift
//  Banana Corp
//

import SwiftUI

struct AIAssistantView: View {
    var body: some View {
        PhoneShellView(title: "AI Assistant") {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                Text("BANANA ASSIST")
                    .appText(.h2, color: AppTheme.Colors.highlight)

                Text("Connection pending...")
                    .appText(.paragraph)

                Text("System access will become available after device activation.")
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
