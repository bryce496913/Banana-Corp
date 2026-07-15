import SwiftUI

struct PhoneHomeIndicator: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(spacing: 6) {
            Capsule()
                .fill(AppTheme.Colors.text.opacity(0.8))
                .frame(width: 110, height: 5)
                .padding(.top, 6)
                .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            appState.goHome()
        }
        .gesture(
            DragGesture(minimumDistance: 16)
                .onEnded { value in
                    if abs(value.translation.height) > 12 {
                        appState.goHome()
                    }
                }
        )
        .accessibilityLabel("Return to Home")
        .accessibilityHint("Tap or swipe on the home indicator to return to the phone home screen.")
    }
}
