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
        HStack(spacing: AppTheme.Spacing.sm) {
            Text("BANANA 5G")
                .lineLimit(1)

            Text(currentTime, style: .time)
                .monospacedDigit()

            Spacer()

            HStack(spacing: 7) {
                Image(systemName: "cellularbars")
                Image(systemName: "wifi")
                Image(systemName: "battery.100")
                    .foregroundColor(AppTheme.Colors.highlight)
            }
            .imageScale(.small)
        }
        .appText(.paragraph, color: AppTheme.Colors.text.opacity(0.92))
        .padding(.horizontal, AppTheme.Spacing.md)
        .frame(height: 24)
        .onReceive(timer) { _ in
            currentTime = Date()
        }
    }
}
