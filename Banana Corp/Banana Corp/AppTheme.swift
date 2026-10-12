import SwiftUI

enum AppTextStyle {
    case screenTitle, sectionTitle, body, caption, systemLabel
    // Compatibility names for existing call sites.
    case h1, h2, h3, paragraph

    var font: Font {
        switch self {
        case .screenTitle, .h1: return .system(.title2, design: .default).weight(.bold)
        case .sectionTitle, .h2: return .system(.headline, design: .default)
        case .body, .paragraph: return .system(.body, design: .default)
        case .caption: return .system(.caption, design: .default)
        case .systemLabel, .h3: return .system(.subheadline, design: .default).weight(.semibold)
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
        static let secondaryText = text.opacity(0.75)
        static let separator = text.opacity(0.10)
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

    enum Layout {
        static let touchTarget: CGFloat = 44
        static let readingWidth: CGFloat = 600
    }
}

struct AppTextModifier: ViewModifier {
    let style: AppTextStyle
    let color: Color

    func body(content: Content) -> some View {
        content.font(style.font).foregroundStyle(color)
    }
}

extension View {
    func appText(_ style: AppTextStyle, color: Color = AppTheme.Colors.text) -> some View {
        modifier(AppTextModifier(style: style, color: color))
    }
}

struct AppPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .appText(.systemLabel)
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.vertical, AppTheme.Spacing.sm)
            .frame(minHeight: AppTheme.Layout.touchTarget)
            .background(
                AppTheme.Colors.accent.opacity(configuration.isPressed ? 0.75 : 1),
                in: RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous)
            )
            .opacity(isEnabled ? 1 : 0.45)
            .modifier(AppPressFeedback(isPressed: configuration.isPressed))
    }
}

struct ModernPhoneButtonStyle: ButtonStyle {
    let prominent: Bool
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .appText(.systemLabel)
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.vertical, AppTheme.Spacing.sm)
            .frame(minHeight: AppTheme.Layout.touchTarget)
            .modernSurface(
                in: RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous),
                tint: prominent ? AppTheme.Colors.accent.opacity(0.25) : AppTheme.Colors.surface.opacity(0.5),
                interactive: true
            )
            .opacity(isEnabled ? 1 : 0.45)
            .modifier(AppPressFeedback(isPressed: configuration.isPressed))
    }
}

extension ButtonStyle where Self == AppPrimaryButtonStyle {
    static var appPrimary: AppPrimaryButtonStyle { AppPrimaryButtonStyle() }
}

extension ButtonStyle where Self == ModernPhoneButtonStyle {
    static var modernPhone: ModernPhoneButtonStyle { ModernPhoneButtonStyle(prominent: false) }
    static var modernPhoneProminent: ModernPhoneButtonStyle { ModernPhoneButtonStyle(prominent: true) }
}
