//
//  StatusBar.swift
//  Banana Corp
//
//  Created by Aditi Abrol on 1/2/24.
//

import SwiftUI

struct StatusBar: View {
    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            StatusBarTimelineContent(currentTime: context.date)
        }
    }
}

private struct StatusBarTimelineContent: View {
    @Environment(\.osPresentation) private var presentation
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let currentTime: Date

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    statusText
                    connectivityIndicators
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                HStack(alignment: .center) {
                    statusText
                    Spacer()
                    connectivityIndicators
                }
            }
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.top, AppTheme.Spacing.sm)
        .frame(minHeight: 56)
    }

    private var statusText: some View {
        VStack(alignment: .leading, spacing: 2) {
            OSStoryText(text: status.carrier ?? "BANANA 5G", target: .carrier)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
                .font(AppTextStyle.body.font)
                .fontWeight(.semibold)

            Text(currentTime, style: .time)
                .font(AppTextStyle.body.font)
                .fontWeight(.semibold)
                .monospacedDigit()
        }
        .fixedSize(horizontal: false, vertical: true)
        .foregroundColor(AppTheme.Colors.text.opacity(0.94))
    }

    private var connectivityIndicators: some View {
        HStack(spacing: 12) {
            signalImage
                .accessibilityLabel(signalLabel)
            Image(systemName: status.wifi == .unavailable ? "wifi.slash" : "wifi")
                .accessibilityLabel(status.wifi == .unavailable ? "Banana Wi-Fi: unavailable" : "Banana Wi-Fi: connected")
            Image(systemName: batterySymbol)
                .accessibilityLabel("Banana battery: \(status.batteryPercent ?? 75) percent")
                .foregroundColor(AppTheme.Colors.highlight)
        }
        .modifier(OSControlledEffect(target: .connectivity))
        .font(AppTextStyle.body.font.weight(.semibold))
        .foregroundColor(AppTheme.Colors.text.opacity(0.94))
    }

    private var status: OSStatusOverride {
        presentation.resolved(at: currentTime).status
    }

    @ViewBuilder
    private var signalImage: some View {
        switch status.signal ?? .full {
        case .full: Image(systemName: "cellularbars")
        case .weak: Image(systemName: "cellularbars", variableValue: 0.25)
        case .unavailable: Image(systemName: "antenna.radiowaves.left.and.right.slash")
        }
    }

    private var signalLabel: String {
        switch status.signal ?? .full {
        case .full: return "Banana signal: full"
        case .weak: return "Banana signal: weak"
        case .unavailable: return "Banana signal: unavailable"
        }
    }

    private var batterySymbol: String {
        switch status.batteryPercent ?? 75 {
        case 88...100: return "battery.100"
        case 63..<88: return "battery.75"
        case 38..<63: return "battery.50"
        case 13..<38: return "battery.25"
        default: return "battery.0"
        }
    }
}
