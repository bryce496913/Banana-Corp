//
//  WatchVideoView.swift
//  Banana Corp
//

import SwiftUI

struct WatchVideoView: View {
    var body: some View {
        PhoneShellView(title: "Watch Video") {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                Text("WATCH VIDEO")
                    .appText(.h2, color: AppTheme.Colors.highlight)

                Text("Library locked...")
                    .appText(.paragraph)

                Text("Approved media will become available after activation.")
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
