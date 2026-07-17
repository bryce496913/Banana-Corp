//
//  HomeScreenView.swift
//  Banana Corp
//
//  Created by Aditi Abrol on 1/2/24.
//

import SwiftUI

struct HomeScreenView: View {
    @EnvironmentObject private var appState: AppState

    private let columns: [GridItem] = Array(repeating: .init(.flexible(), spacing: AppTheme.Spacing.md), count: 4)

    var body: some View {
        ZStack {
            PhoneShellView(title: nil, showsStatusBar: true, showsHomeIndicator: false) {
                GeometryReader { proxy in
                    VStack(spacing: AppTheme.Spacing.lg) {
                        editHeader

                        ScrollView {
                            appGrid
                                .padding(.top, AppTheme.Spacing.md)
                                .padding(.horizontal, AppTheme.Spacing.sm)
                        }
                        .dropDestination(for: String.self) { items, _ in
                            guard let route = route(from: items.first) else { return false }
                            move(route, to: .grid, before: nil)
                            return true
                        }

                        dock
                            .padding(.bottom, max(proxy.safeAreaInsets.bottom, AppTheme.Spacing.sm))
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if appState.isEditingHomeScreen { stopEditing() }
                    }
                }
            }

            if let activeApp = appState.activeApp {
                destinationView(for: activeApp)
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .bottom),
                            removal: .move(edge: .top)
                        )
                    )
                    .zIndex(1)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.86), value: appState.activeApp)
    }

    @ViewBuilder
    private var editHeader: some View {
        if appState.isEditingHomeScreen {
            HStack {
                Text("Rearrange Banana OS")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.text.opacity(0.82))

                Spacer()

                Button("Done") { stopEditing() }
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppTheme.Colors.text)
                    .padding(.vertical, 7)
                    .padding(.horizontal, 14)
                    .modernSurface(
                        in: Capsule(),
                        tint: AppTheme.Colors.highlight.opacity(0.22),
                        interactive: true
                    )
            }
            .padding(.horizontal, AppTheme.Spacing.lg)
        }
    }

    private var appGrid: some View {
        LazyVGrid(columns: columns, spacing: AppTheme.Spacing.xl) {
            ForEach(gridApps) { app in
                appIcon(app)
                    .dropDestination(for: String.self) { items, _ in
                        guard let route = route(from: items.first), route != app.route else { return false }
                        move(route, to: .grid, before: app.route)
                        return true
                    }
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private var dock: some View {
        HStack(spacing: AppTheme.Spacing.lg) {
            ForEach(dockApps) { app in
                appIcon(app)
                    .dropDestination(for: String.self) { items, _ in
                        guard let route = route(from: items.first), route != app.route else { return false }
                        move(route, to: .dock, before: app.route)
                        return true
                    }
            }
        }
        .frame(minHeight: 92)
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.md)
        .padding(.horizontal, AppTheme.Spacing.lg)
        .modernSurface(
            in: RoundedRectangle(cornerRadius: AppTheme.Radius.lg, style: .continuous),
            tint: AppTheme.Colors.highlight.opacity(0.16)
        )
        .dropDestination(for: String.self) { items, _ in
            guard let route = route(from: items.first) else { return false }
            return move(route, to: .dock, before: nil)
        }
        .padding(.horizontal, AppTheme.Spacing.md)
    }

    private func appIcon(_ app: PhoneAppInfo) -> some View {
        Button {
            guard !appState.isEditingHomeScreen, appState.draggedApp == nil else { return }
            appState.open(app.route)
        } label: {
            VStack(spacing: 6) {
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(AppTheme.Colors.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(AppTheme.Colors.accent.opacity(0.45), lineWidth: 1)
                        )
                        .frame(width: 60, height: 60)

                    Image(systemName: app.systemImage)
                        .font(.system(size: 27, weight: .medium))
                        .foregroundColor(AppTheme.Colors.text)
                        .frame(width: 60, height: 60)

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
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(AppTheme.Colors.text)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .frame(maxWidth: 76)
            }
            .rotationEffect(appState.isEditingHomeScreen ? .degrees(app.route.hashValue.isMultiple(of: 2) ? 1.4 : -1.4) : .zero)
            .animation(appState.isEditingHomeScreen ? .easeInOut(duration: 0.16).repeatForever(autoreverses: true) : .default, value: appState.isEditingHomeScreen)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(LongPressGesture(minimumDuration: 0.35).onEnded { _ in startEditing() })
        .draggable(app.route.rawValue) {
            appIconPreview(app)
                .onAppear {
                    startEditing()
                    appState.draggedApp = app.route
                }
        }
        .accessibilityLabel(app.title)
    }

    private func appIconPreview(_ app: PhoneAppInfo) -> some View {
        Image(systemName: app.systemImage)
            .font(.system(size: 27, weight: .medium))
            .foregroundStyle(AppTheme.Colors.text)
            .frame(width: 60, height: 60)
            .background(AppTheme.Colors.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func startEditing() {
        appState.isEditingHomeScreen = true
    }

    private func stopEditing() {
        appState.isEditingHomeScreen = false
        appState.draggedApp = nil
    }

    @discardableResult
    private func move(_ route: PhoneAppRoute, to destination: HomeSection, before target: PhoneAppRoute?) -> Bool {
        guard appState.unlockedApps.contains(route) else { return false }
        var layout = appState.homeScreenLayout.normalized
        layout.gridApps.removeAll { $0 == route }
        layout.dockApps.removeAll { $0 == route }

        switch destination {
        case .grid:
            insert(route, before: target, in: &layout.gridApps)
        case .dock:
            guard target != nil || layout.dockApps.count < 4 else { return false }
            guard target != nil || !layout.dockApps.contains(route) else { return false }
            if let target, let index = layout.dockApps.firstIndex(of: target) {
                layout.dockApps.insert(route, at: index)
            } else if layout.dockApps.count < 4 {
                layout.dockApps.append(route)
            }
            if layout.dockApps.count > 4 { return false }
        }

        appState.homeScreenLayout = layout.normalized
        appState.draggedApp = nil
        return true
    }

    private func insert(_ route: PhoneAppRoute, before target: PhoneAppRoute?, in routes: inout [PhoneAppRoute]) {
        if let target, let index = routes.firstIndex(of: target) {
            routes.insert(route, at: index)
        } else {
            routes.append(route)
        }
    }

    private func route(from value: String?) -> PhoneAppRoute? {
        value.flatMap(PhoneAppRoute.init(rawValue:))
    }

    private func badgeCount(for route: PhoneAppRoute) -> Int {
        switch route {
        case .email: return appState.unreadEmails
        case .messager: return appState.unreadMessages
        default: return 0
        }
    }

    private var gridApps: [PhoneAppInfo] {
        appState.homeScreenLayout.normalized.gridApps
            .filter { appState.unlockedApps.contains($0) }
            .compactMap(PhoneAppInfo.info(for:))
    }

    private var dockApps: [PhoneAppInfo] {
        appState.homeScreenLayout.normalized.dockApps
            .filter { appState.unlockedApps.contains($0) }
            .compactMap(PhoneAppInfo.info(for:))
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

private enum HomeSection {
    case grid
    case dock
}

struct PhoneAppInfo: Identifiable {
    var id: PhoneAppRoute { route }
    let title: String
    let systemImage: String
    let route: PhoneAppRoute

    static func info(for route: PhoneAppRoute) -> PhoneAppInfo? {
        switch route {
        case .email: return PhoneAppInfo(title: "Email", systemImage: "envelope.fill", route: .email)
        case .browser: return PhoneAppInfo(title: "Web", systemImage: "safari.fill", route: .browser)
        case .social: return PhoneAppInfo(title: "Social X", systemImage: "bubble.left.and.bubble.right.fill", route: .social)
        case .watchVideo: return PhoneAppInfo(title: "Video", systemImage: "play.circle.fill", route: .watchVideo)
        case .messager: return PhoneAppInfo(title: "Messages", systemImage: "message.fill", route: .messager)
        case .photoAlbum: return PhoneAppInfo(title: "Photos", systemImage: "photo.fill", route: .photoAlbum)
        case .settings: return PhoneAppInfo(title: "Settings", systemImage: "gearshape.fill", route: .settings)
        case .phone: return PhoneAppInfo(title: "Phone", systemImage: "phone.fill", route: .phone)
        case .news: return PhoneAppInfo(title: "News", systemImage: "newspaper.fill", route: .news)
        case .aiAssistant: return PhoneAppInfo(title: "AI", systemImage: "waveform.path.ecg.rectangle.fill", route: .aiAssistant)
        case .vrExperience: return PhoneAppInfo(title: "VR", systemImage: "visionpro.fill", route: .vrExperience)
        case .snake: return PhoneAppInfo(title: "Snake", systemImage: "gamecontroller.fill", route: .snake)
        case .pong: return PhoneAppInfo(title: "Pong", systemImage: "circle.grid.cross.fill", route: .pong)
        case .xo: return PhoneAppInfo(title: "X / O", systemImage: "square.grid.3x3.fill", route: .xo)
        }
    }
}

struct HomeScreenView_Previews: PreviewProvider {
    static var previews: some View {
        HomeScreenView()
            .environmentObject(AppState())
    }
}
