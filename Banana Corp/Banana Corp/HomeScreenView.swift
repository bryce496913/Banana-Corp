import SwiftUI

struct HomeScreenView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)

    var body: some View {
        PhoneShellView(showsHomeIndicator: false) {
            GeometryReader { geometry in
                let width = min(geometry.size.width - 24, 440)
                // Four equal dock cells determine the shared icon size, including small phones.
                let iconSize = min(64, max(44, (width - 48) / 4))
                VStack(spacing: 12) {
                    editHeader
                        .frame(height: AppTheme.Layout.touchTarget)

                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(gridApps) { app in
                                icon(app, size: iconSize)
                                    .dropDestination(for: String.self) { items, _ in
                                        accept(items, in: .grid, before: app.route)
                                    }
                            }
                        }
                        .padding(.top, 4)
                        .padding(.bottom, 20)
                        .frame(maxWidth: .infinity, alignment: .top)
                        .background(outsideTapArea)
                    }
                    .scrollIndicators(.hidden)
                    .background(outsideTapArea)
                    .dropDestination(for: String.self) { items, _ in
                        accept(items, in: .grid)
                    }

                    dock(iconSize: iconSize)
                        .padding(.bottom, 8)
                }
                .frame(width: width)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .background(outsideTapArea)
                .animation(reduceMotion ? nil : AppMotion.reorder, value: appState.homeScreenLayout)
            }
        }
        .onDisappear { appState.finishEditingHomeScreen() }
    }

    private var outsideTapArea: some View {
        Color.clear
            .contentShape(Rectangle())
            .onTapGesture { appState.finishEditingHomeScreen() }
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private var editHeader: some View {
        if appState.isEditingHomeScreen {
            HStack {
                Text("Rearrange apps")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.75))
                Spacer()
                Button("Done") { appState.finishEditingHomeScreen() }
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 16)
                    .frame(minHeight: AppTheme.Layout.touchTarget)
                    .modernSurface(in: Capsule(), tint: AppTheme.Colors.accent.opacity(0.12), interactive: true)
                    .buttonStyle(.appContent)
            }
        }
    }

    private func dock(iconSize: CGFloat) -> some View {
        HStack(alignment: .top, spacing: 8) {
            ForEach(dockApps) { app in
                icon(app, size: iconSize)
                    .dropDestination(for: String.self) { items, _ in
                        accept(items, in: .dock, before: app.route)
                    }
            }
            // Keep dock slots stable and provide an append target even with an empty dock.
            ForEach(0..<(4 - dockApps.count), id: \.self) { _ in
                Color.clear
                    .frame(maxWidth: .infinity)
                    .frame(height: iconSize + 38)
                    .accessibilityHidden(true)
            }
        }
        .padding(12)
        .background(outsideTapArea)
        .modifier(HomeDockSurface())
        .dropDestination(for: String.self) { items, _ in
            accept(items, in: .dock)
        }
        .accessibilityIdentifier("bananaOS.dock")
    }

    @ViewBuilder
    private func icon(_ app: PhoneAppInfo, size: CGFloat) -> some View {
        let icon = BananaAppIcon(
            app: app,
            size: size,
            badgeCount: badgeCount(for: app.route),
            isLocked: !appState.unlockedApps.contains(app.route),
            isEditing: appState.isEditingHomeScreen,
            action: { appState.open(app.route) },
            editAction: appState.beginEditingHomeScreen
        )
        if appState.isEditingHomeScreen {
            icon.draggable(app.route.rawValue) {
                BananaAppIconArtwork(image: app.image, size: size, isLocked: false, appearance: .standard)
            }
        } else {
            icon
        }
    }

    private func accept(_ items: [String], in section: HomeSection, before target: PhoneAppRoute? = nil) -> Bool {
        guard let route = HomeAppDrop.route(from: items) else { return false }
        return appState.moveHomeApp(route, to: section, before: target)
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
}

private struct HomeDockSurface: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    private let shape = RoundedRectangle(cornerRadius: 28, style: .continuous)

    func body(content: Content) -> some View {
        if reduceTransparency {
            content.background(AppTheme.Colors.surface, in: shape)
        } else if #available(iOS 26.0, *) {
            content.glassEffect(.regular.tint(AppTheme.Colors.surface.opacity(0.55)), in: shape)
        } else {
            content
                .background(AppTheme.Colors.surface.opacity(0.78), in: shape)
                .overlay(shape.stroke(.white.opacity(0.09), lineWidth: 1))
                .shadow(color: .black.opacity(0.35), radius: 16, y: 6)
        }
    }
}

#Preview("Compact iPhone") {
    HomeScreenView()
        .environmentObject(AppState())
        .frame(width: 320, height: 568)
}

#Preview("Large iPhone") {
    HomeScreenView()
        .environmentObject(AppState())
        .frame(width: 430, height: 932)
}
