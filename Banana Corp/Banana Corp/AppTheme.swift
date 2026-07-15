import SwiftUI

enum AppTextStyle {
    case h1
    case h2
    case h3
    case paragraph

    var size: CGFloat {
        switch self {
        case .h1:
            return 16
        case .h2:
            return 14
        case .h3:
            return 12
        case .paragraph:
            return 10
        }
    }

    var weight: Font.Weight {
        switch self {
        case .h1:
            return .bold
        case .h2:
            return .semibold
        case .h3:
            return .medium
        case .paragraph:
            return .regular
        }
    }
}

enum AppTheme {
    enum Colors {
        static let background = Color.black
        static let surface = Color(red: 0.12, green: 0.04, blue: 0.2)
        static let accent = Color(red: 0.72, green: 0.29, blue: 0.95)
        static let highlight = Color(red: 0.98, green: 0.32, blue: 0.67)
        static let text = Color.white
    }

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
    }

    enum Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 18
    }
}

struct AppTextModifier: ViewModifier {
    let style: AppTextStyle
    let color: Color

    func body(content: Content) -> some View {
        content
            .font(.system(size: style.size, weight: style.weight))
            .foregroundColor(color)
    }
}

extension View {
    func appText(
        _ style: AppTextStyle,
        color: Color = AppTheme.Colors.text
    ) -> some View {
        modifier(AppTextModifier(style: style, color: color))
    }
}

struct AppPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .appText(.h3)
            .padding(.vertical, AppTheme.Spacing.sm)
            .padding(.horizontal, AppTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                    .fill(AppTheme.Colors.accent.opacity(configuration.isPressed ? 0.7 : 1))
            )
            .foregroundColor(AppTheme.Colors.text)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
    }
}

extension ButtonStyle where Self == AppPrimaryButtonStyle {
    static var appPrimary: AppPrimaryButtonStyle {
        AppPrimaryButtonStyle()
    }
}


struct ModernPhoneButtonStyle: ButtonStyle {
    let prominent: Bool

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous)

        configuration.label
            .appText(.h3)
            .foregroundColor(AppTheme.Colors.text)
            .padding(.vertical, AppTheme.Spacing.sm)
            .padding(.horizontal, AppTheme.Spacing.md)
            .frame(minHeight: 36)
            .modernSurface(
                in: shape,
                tint: prominent ? AppTheme.Colors.highlight.opacity(0.25) : AppTheme.Colors.accent.opacity(0.18),
                interactive: true
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == ModernPhoneButtonStyle {
    static var modernPhone: ModernPhoneButtonStyle {
        ModernPhoneButtonStyle(prominent: false)
    }

    static var modernPhoneProminent: ModernPhoneButtonStyle {
        ModernPhoneButtonStyle(prominent: true)
    }
}
