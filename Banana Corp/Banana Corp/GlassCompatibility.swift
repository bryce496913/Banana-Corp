import SwiftUI

struct ModernSurfaceModifier<S: Shape>: ViewModifier {
    let shape: S
    let tint: Color
    let isInteractive: Bool
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    func body(content: Content) -> some View {
        if reduceTransparency {
            content.background(AppTheme.Colors.surface, in: shape)
        } else if #available(iOS 26.0, *) {
            content
                .background(.clear)
                .glassEffect(
                    .regular
                        .tint(tint)
                        .interactive(isInteractive),
                    in: shape
                )
        } else {
            content
                .background(
                    shape
                        .fill(AppTheme.Colors.surface.opacity(0.88))
                )
                .overlay(
                    shape
                        .stroke(AppTheme.Colors.separator, lineWidth: 1)
                )
        }
    }
}

extension View {
    func modernSurface<S: Shape>(
        in shape: S,
        tint: Color = AppTheme.Colors.accent.opacity(0.18),
        interactive: Bool = false
    ) -> some View {
        modifier(
            ModernSurfaceModifier(
                shape: shape,
                tint: tint,
                isInteractive: interactive
            )
        )
    }
}
