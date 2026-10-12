import SwiftUI

enum AppIconImage {
    case symbol(String)
    case asset(String)
}

/// Presentation can be supplied by future story updates without changing identity or layout.
/// Home currently uses only the standard appearance.
struct AppIconAppearance {
    var surface: Color
    var foreground: Color

    static let standard = AppIconAppearance(
        surface: AppTheme.Colors.surface,
        foreground: .white
    )
}

struct BananaAppIcon: View {
    let app: PhoneAppInfo
    let size: CGFloat
    var badgeCount = 0
    var isLocked = false
    var isEditing = false
    var appearance: AppIconAppearance = .standard
    let action: () -> Void
    let editAction: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .caption) private var labelHeight: CGFloat = 32

    private var wiggleDirection: Double {
        let index = PhoneAppRoute.allCases.firstIndex(of: app.route) ?? 0
        return index.isMultiple(of: 2) ? 1 : -1
    }

    var body: some View {
        Button {
            guard !isEditing, !isLocked else { return }
            action()
        } label: {
            if isEditing && !reduceMotion {
                iconLabel.phaseAnimator([-1.0, 1.0]) { content, phase in
                    content.rotationEffect(.degrees(phase * 1.2 * wiggleDirection))
                } animation: { _ in AppMotion.editWiggle }
            } else {
                iconLabel
            }
        }
        .buttonStyle(.appIcon)
        .simultaneousGesture(LongPressGesture(minimumDuration: 0.4).onEnded { _ in editAction() })
        .accessibilityLabel(app.title)
        .accessibilityValue(accessibilityValue)
        .accessibilityHint(isEditing ? "Drag to rearrange." : "Long press to rearrange apps.")
        .accessibilityAction(named: Text("Rearrange apps")) { editAction() }
        .accessibilityIdentifier("bananaOS.app.\(app.route.rawValue)")
    }

    private var iconLabel: some View {
        VStack(spacing: 7) {
            BananaAppIconArtwork(image: app.image, size: size, isLocked: isLocked, appearance: appearance)
                .overlay(alignment: .topTrailing) {
                    if badgeCount > 0 {
                        AppNotificationBadge(count: badgeCount)
                            .offset(x: 6, y: -5)
                    }
                }
            Text(app.title)
                .font(.caption.weight(.medium))
                .foregroundStyle(.white.opacity(isLocked ? 0.55 : 0.92))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(height: labelHeight, alignment: .top)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
    }

    private var accessibilityValue: String {
        var values: [String] = []
        if isLocked { values.append("Locked") }
        if badgeCount > 0 { values.append("\(badgeCount) unread notifications") }
        if isEditing { values.append("Editing") }
        return values.joined(separator: ", ")
    }
}

struct BananaAppIconArtwork: View {
    let image: AppIconImage
    let size: CGFloat
    let isLocked: Bool
    let appearance: AppIconAppearance

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: size * 0.25, style: .continuous)
        ZStack {
            shape.fill(appearance.surface)
            switch image {
            case .symbol(let name):
                Image(systemName: name)
                    .font(.system(size: size * 0.45, weight: .medium))
                    .foregroundStyle(appearance.foreground)
            case .asset(let name):
                Image(name)
                    .resizable()
                    .scaledToFit()
                    .padding(size * 0.2)
            }
        }
        .frame(width: size, height: size)
        .clipShape(shape)
        .overlay(shape.stroke(.white.opacity(0.1), lineWidth: 1))
        .shadow(color: .black.opacity(0.4), radius: 5, y: 3)
        .opacity(isLocked ? 0.5 : 1)
        .overlay(alignment: .bottomTrailing) {
            if isLocked {
                Image(systemName: "lock.fill")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(5)
                    .background(.black.opacity(0.8), in: Circle())
            }
        }
        .accessibilityHidden(true)
    }
}

// Display metadata is independent of persisted positions and route identity.
struct PhoneAppInfo: Identifiable {
    var id: PhoneAppRoute { route }
    let title: String
    let image: AppIconImage
    let route: PhoneAppRoute

    static func info(for route: PhoneAppRoute) -> PhoneAppInfo? {
        switch route {
        case .email: return PhoneAppInfo(title: "Email", image: .symbol("envelope.fill"), route: .email)
        case .browser: return PhoneAppInfo(title: "Web", image: .symbol("safari.fill"), route: .browser)
        case .social: return PhoneAppInfo(title: "Social X", image: .symbol("bubble.left.and.bubble.right.fill"), route: .social)
        case .watchVideo: return PhoneAppInfo(title: "Video", image: .symbol("play.circle.fill"), route: .watchVideo)
        case .messager: return PhoneAppInfo(title: "Messages", image: .symbol("message.fill"), route: .messager)
        case .photoAlbum: return PhoneAppInfo(title: "Photos", image: .symbol("photo.fill"), route: .photoAlbum)
        case .settings: return PhoneAppInfo(title: "Settings", image: .symbol("gearshape.fill"), route: .settings)
        case .phone: return PhoneAppInfo(title: "Phone", image: .symbol("phone.fill"), route: .phone)
        case .news: return PhoneAppInfo(title: "News", image: .symbol("newspaper.fill"), route: .news)
        case .aiAssistant: return PhoneAppInfo(title: "AI Assistant", image: .symbol("waveform.path.ecg.rectangle.fill"), route: .aiAssistant)
        case .vrExperience: return PhoneAppInfo(title: "VR", image: .symbol("visionpro.fill"), route: .vrExperience)
        case .snake: return PhoneAppInfo(title: "Snake", image: .symbol("gamecontroller.fill"), route: .snake)
        case .pong: return PhoneAppInfo(title: "Pong", image: .symbol("circle.grid.cross.fill"), route: .pong)
        case .xo: return PhoneAppInfo(title: "X / O", image: .symbol("square.grid.3x3.fill"), route: .xo)
        }
    }
}
