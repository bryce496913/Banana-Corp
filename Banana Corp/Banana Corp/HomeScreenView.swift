//
//  HomeScreenView.swift
//  Banana Corp
//
//  Created by Aditi Abrol on 1/2/24.
//

import SwiftUI

struct HomeScreenView: View {
    @EnvironmentObject private var appState: AppState

    private let apps = [
        PhoneAppInfo(title: "Email", systemImage: "envelope.fill", route: .email),
        PhoneAppInfo(title: "Web", systemImage: "safari.fill", route: .browser),
        PhoneAppInfo(title: "Social X", systemImage: "bubble.left.and.bubble.right.fill", route: .social),
        PhoneAppInfo(title: "Video", systemImage: "play.circle.fill", route: .watchVideo),
        PhoneAppInfo(title: "Messages", systemImage: "message.fill", route: .messager),
        PhoneAppInfo(title: "Photos", systemImage: "photo.fill", route: .photoAlbum),
        PhoneAppInfo(title: "Settings", systemImage: "gearshape.fill", route: .settings),
        PhoneAppInfo(title: "Phone", systemImage: "phone.fill", route: .phone),
        PhoneAppInfo(title: "Snake", systemImage: "gamecontroller.fill", route: .snake),
        PhoneAppInfo(title: "X / O", systemImage: "square.grid.3x3.fill", route: .xo),
        PhoneAppInfo(title: "VR", systemImage: "visionpro.fill", route: .vrExperience),
        PhoneAppInfo(title: "Pong", systemImage: "circle.grid.cross.fill", route: .pong)
    ]

    private let dockApps = [
        PhoneAppInfo(title: "Email", systemImage: "envelope.fill", route: .email),
        PhoneAppInfo(title: "Messages", systemImage: "message.fill", route: .messager),
        PhoneAppInfo(title: "News", systemImage: "newspaper.fill", route: .news),
        PhoneAppInfo(title: "AI", systemImage: "waveform.path.ecg.rectangle.fill", route: .aiAssistant)
    ]

    private let columns: [GridItem] = Array(repeating: .init(.flexible(), spacing: AppTheme.Spacing.md), count: 4)

    var body: some View {
        NavigationStack(path: $appState.navigationPath) {
            PhoneShellView(title: nil, showsStatusBar: true, showsHomeIndicator: false) {
                VStack(spacing: AppTheme.Spacing.lg) {
                    Spacer(minLength: AppTheme.Spacing.md)

                    appGrid

                    Spacer(minLength: AppTheme.Spacing.md)

                    dock
                }
                .padding(.horizontal, AppTheme.Spacing.md)
            }
            .navigationDestination(for: PhoneAppRoute.self) { route in
                destinationView(for: route)
            }
        }
    }

    private var appGrid: some View {
        LazyVGrid(columns: columns, spacing: AppTheme.Spacing.lg) {
            ForEach(visibleApps) { app in
                appIcon(app)
            }
        }
    }

    private var dock: some View {
        HStack(spacing: AppTheme.Spacing.lg) {
            ForEach(dockApps.filter { appState.unlockedApps.contains($0.route) }) { app in
                appIcon(app, compact: true)
            }
        }
        .padding(.vertical, AppTheme.Spacing.md)
        .padding(.horizontal, AppTheme.Spacing.lg)
        .modernSurface(
            in: RoundedRectangle(cornerRadius: AppTheme.Radius.lg, style: .continuous),
            tint: AppTheme.Colors.highlight.opacity(0.16)
        )
        .padding(.bottom, AppTheme.Spacing.sm)
    }

    private func appIcon(_ app: PhoneAppInfo, compact: Bool = false) -> some View {
        Button {
            appState.open(app.route)
        } label: {
            VStack(spacing: AppTheme.Spacing.xs) {
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: AppTheme.Radius.lg, style: .continuous)
                        .fill(AppTheme.Colors.accent.opacity(0.26))
                        .modernSurface(
                            in: RoundedRectangle(cornerRadius: AppTheme.Radius.lg, style: .continuous),
                            tint: AppTheme.Colors.accent.opacity(0.20),
                            interactive: true
                        )
                        .frame(width: compact ? 44 : 52, height: compact ? 44 : 52)

                    Image(systemName: app.systemImage)
                        .font(.system(size: compact ? 20 : 24, weight: .semibold))
                        .foregroundColor(AppTheme.Colors.text)
                        .frame(width: compact ? 44 : 52, height: compact ? 44 : 52)

                    if badgeCount(for: app.route) > 0 {
                        Text("\(badgeCount(for: app.route))")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(AppTheme.Colors.text)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(AppTheme.Colors.highlight))
                            .offset(x: 5, y: -5)
                    }
                }

                Text(app.title)
                    .appText(.paragraph)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .frame(maxWidth: 72)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(app.title)
    }

    private func badgeCount(for route: PhoneAppRoute) -> Int {
        switch route {
        case .email: return appState.unreadEmails
        case .messager: return appState.unreadMessages
        default: return 0
        }
    }

    private var visibleApps: [PhoneAppInfo] {
        apps.filter { appState.unlockedApps.contains($0.route) }
    }

    @ViewBuilder
    private func destinationView(for route: PhoneAppRoute) -> some View {
        switch route {
        case .email: EmailView()
        case .browser: WebBrowserView()
        case .social: SocialXView()
        case .watchVideo: WatchVideoView()
        case .messager: MessagerView()
        case .photoAlbum: PhotoAlbumView()
        case .settings: SettingsView()
        case .phone: PhoneView()
        case .news: NewsView()
        case .aiAssistant: AIAssistantView()
        case .vrExperience: VRExperienceView()
        case .snake: SnakeGameView()
        case .pong: PongGameView()
        case .xo: XOGameView()
        }
    }
}

struct PhoneAppInfo: Identifiable {
    let id = UUID()
    let title: String
    let systemImage: String
    let route: PhoneAppRoute
}

struct HomeScreenView_Previews: PreviewProvider {
    static var previews: some View {
        HomeScreenView()
            .environmentObject(AppState())
    }
}
