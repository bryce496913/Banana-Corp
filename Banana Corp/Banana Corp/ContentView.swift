//
//  ContentView.swift
//  Banana Corp
//
//  Created by Aditi Abrol on 1/2/24.
//

import SwiftUI

struct LaunchView: View {
    @State private var isLaunchComplete = false

    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()

            if isLaunchComplete {
                BananaOSView()
                    .transition(.opacity)
            } else {
                Image("Logo-Black")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .transition(.opacity)
            }
        }
        .task {
            guard !isLaunchComplete else { return }
            do {
                try await Task.sleep(for: .seconds(4))
                withAnimation(.easeInOut(duration: 0.45)) {
                    isLaunchComplete = true
                }
            } catch {
                // Cancellation keeps a disappeared launch view from completing.
            }
        }
    }
}

struct LaunchView_Previews: PreviewProvider {
    static var previews: some View {
        LaunchView()
            .environmentObject(AppState())
    }
}

// One persistent home beneath a single, disposable app session.
// Individual apps can use their own NavigationStack without changing OS routes.
struct BananaOSView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            HomeScreenView()
                .allowsHitTesting(appState.activeApp == nil)
                .accessibilityHidden(appState.activeApp != nil)

            if let route = appState.activeApp {
                NavigationStack {
                    destinationView(for: route)
                }
                .id(route)
                .statusBarHidden(true)
                .transition(reduceMotion ? .opacity : .asymmetric(
                    insertion: .move(edge: .bottom),
                    removal: .move(edge: .top)
                ))
                .zIndex(1)
            }
        }
        .clipped()
        .statusBarHidden(true)
        .animation(reduceMotion ? .easeOut(duration: 0.15) :
            .spring(response: 0.4, dampingFraction: 0.86), value: appState.activeApp)
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
