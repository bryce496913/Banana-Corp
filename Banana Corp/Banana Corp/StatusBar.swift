//
//  StatusBar.swift
//  Banana Corp
//
//  Created by Aditi Abrol on 1/2/24.
//

import SwiftUI

struct StatusBar: View {
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var currentTime = Date()

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("BANANA 5G")
                    .font(.system(size: 18, weight: .semibold))

                Text(currentTime, style: .time)
                    .font(.system(size: 18, weight: .semibold))
                    .monospacedDigit()
            }
            .foregroundColor(AppTheme.Colors.text.opacity(0.94))

            Spacer()

            HStack(spacing: 12) {
                Image(systemName: "cellularbars")
                    .accessibilityLabel("Banana signal: full")
                Image(systemName: "wifi")
                    .accessibilityLabel("Banana Wi-Fi: connected")
                Image(systemName: "battery.75")
                    .accessibilityLabel("Banana battery: 75 percent")
                    .foregroundColor(AppTheme.Colors.highlight)
            }
            .font(.system(size: 18, weight: .semibold))
            .foregroundColor(AppTheme.Colors.text.opacity(0.94))
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.top, AppTheme.Spacing.sm)
        .frame(minHeight: 56)
        .onReceive(timer) { _ in
            currentTime = Date()
        }
    }
}
