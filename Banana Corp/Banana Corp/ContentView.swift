//
//  ContentView.swift
//  Banana Corp
//
//  Created by Aditi Abrol on 1/2/24.
//

import SwiftUI

struct LaunchView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
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
                withAnimation(reduceMotion ? AppMotion.reduced : AppMotion.opening) {
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
    @Environment(\.scenePhase) private var scenePhase
    @State private var presentedRoute: PhoneAppRoute?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            HomeScreenView()
                .environment(\.osEffectsEnabled, appState.navigation.isHomeReady)
                .scaleEffect(reduceMotion || presentedRoute == nil ? 1 : 0.99)
                .opacity(presentedRoute == nil ? 1 : 0.95)
                .allowsHitTesting(appState.navigation.isHomeReady)
                .accessibilityHidden(!appState.navigation.isHomeReady)

            if let route = presentedRoute {
                NavigationStack {
                    destinationView(for: route)
                        .environment(\.osAppRoute, route)
                }
                .id(route)
                .statusBarHidden(true)
                .transition(AppMotion.appTransition(reduceMotion: reduceMotion))
                .allowsHitTesting(appState.navigation.phase == .active)
                .zIndex(1)
            }
        }
        .overlay(alignment: .top) {
            if appState.presentation.event(at: Date())?.payload.interruption != nil {
                GeometryReader { geometry in
                    OSInterruptionHost()
                        // Reserve the Home strip even in short/keyboard-constrained layouts.
                        .frame(
                            maxHeight: CGFloat(OSVisualSafety.interruptionHeight(
                                availableHeight: Double(geometry.size.height)
                            )),
                            alignment: .top
                        )
                        .clipped()
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                }
                .allowsHitTesting(false)
            }
        }
        .environment(\.osPresentation, appState.presentation)
        .tint(appState.presentation.resolved(at: Date()).visualPalette.accent)
        .clipped()
        .statusBarHidden(true)
        .modifier(AppFeedbackModifier(event: appState.feedbackEvent))
        .onChange(of: appState.navigation.transitionID) { _, id in
            let animation = reduceMotion ? AppMotion.reduced :
                (appState.navigation.phase == .closing ? AppMotion.closing : AppMotion.opening)
            withAnimation(animation, completionCriteria: .removed) {
                presentedRoute = appState.activeApp
            } completion: {
                appState.completeNavigationTransition(id)
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { appState.expirePresentationEvents() }
        }
        .onAppear {
            appState.expirePresentationEvents()
            // Synchronize a recreated shell without leaving a transition locked.
            presentedRoute = appState.activeApp
            appState.completeNavigationTransition(appState.navigation.transitionID)
        }
        .onDisappear {
            appState.completeNavigationTransition(appState.navigation.transitionID)
        }
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
        case .evidence: EvidenceVaultView()
        }
    }
}
