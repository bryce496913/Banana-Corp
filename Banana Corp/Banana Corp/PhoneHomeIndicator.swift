import SwiftUI

struct PhoneHomeIndicator: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Button(action: appState.goHome) {
            Capsule()
                .fill(AppTheme.Colors.text.opacity(0.85))
                .frame(width: 110, height: 5)
                .frame(maxWidth: .infinity, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        // This reserved strip is inside the safe area, above the real Home gesture.
        // No OS gesture is attached to app content or game boards.
        .simultaneousGesture(
            DragGesture(minimumDistance: 16)
                .onEnded { value in
                    guard value.translation.height < -24,
                          abs(value.translation.height) > abs(value.translation.width) else { return }
                    appState.goHome()
                }
        )
        .accessibilityLabel("Return to Home")
        .accessibilityHint("Activate to return to Banana OS.")
        .accessibilityIdentifier("bananaOS.home")
    }
}
