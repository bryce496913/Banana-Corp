//
//  VRExperienceView.swift
//  Banana Corp
//

import SwiftUI

struct VRExperienceView: View {
    var body: some View {
        PhoneShellView(title: "VR Experience") {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                Text("BANANA VR")
                    .appText(.h2, color: AppTheme.Colors.highlight)

                Text("Calibration required...")
                    .appText(.paragraph)

                Text("Immersive access is waiting for headset confirmation.")
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
