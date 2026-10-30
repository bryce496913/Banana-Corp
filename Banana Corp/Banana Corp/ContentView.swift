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
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var presentedRoute: PhoneAppRoute?
    private var reduceMotion: Bool { systemReduceMotion || appState.phoneLife.preferences.reduceMotion }

    private struct AppContentIdentity: Hashable {
        let route: PhoneAppRoute
        let rootRevision: UInt
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            HomeScreenView()
                .environment(\.osEffectsEnabled, appState.navigation.isHomeReady)
                // Once covered, keep the retained Home at its natural text geometry.
                .scaleEffect(reduceMotion || presentedRoute == nil || appState.navigation.phase == .active ? 1 : 0.99)
                // Keep Home state mounted, but stop rendering its scaled text once
                // the opaque app transition completes. Public audits can otherwise
                // inspect that covered layer despite accessibilityHidden below.
                .opacity(appState.navigation.phase == .active || appState.story.currentEnding != nil ? 0 : (presentedRoute == nil ? 1 : 0.95))
                .allowsHitTesting(appState.navigation.isHomeReady)
                .accessibilityHidden(!appState.navigation.isHomeReady)

            if let route = presentedRoute {
                NavigationStack {
                    destinationView(for: route)
                        .environment(\.osAppRoute, route)
                }
                .id(AppContentIdentity(route: route, rootRevision: appState.navigation.contentRootRevision))
                .statusBarHidden(true)
                .transition(AppMotion.appTransition(reduceMotion: reduceMotion))
                .opacity(appState.story.currentEnding == nil ? 1 : 0)
                .allowsHitTesting(appState.navigation.phase == .active && appState.story.currentEnding == nil)
                .accessibilityHidden(appState.story.currentEnding != nil)
                .zIndex(1)
            }
            if appState.story.currentEnding != nil {
                EndingCompletionView()
                    .background(AppTheme.Colors.background.ignoresSafeArea())
                    .zIndex(2)
            }
        }
        .overlay(alignment: .top) {
            if appState.phoneLife.preferences.banners && appState.presentation.event(at: Date())?.payload.interruption != nil {
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
        .environment(\.deviceHapticsEnabled, appState.phoneLife.preferences.haptics)
        .environment(\.deviceReduceMotion, appState.phoneLife.preferences.reduceMotion)
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
        .alert("Source update unavailable", isPresented: $appState.firstAnomalyDeliveryFailed) {
            Button("Retry") {
                appState.reconcileFirstAnomalyAtBoundary()
                appState.deliverFirstAnomalyPresentationIfNeeded()
                appState.reconcileActTwoAtBoundary()
            }
            Button("Later", role: .cancel) {}
        } message: { Text("The update could not be saved. Existing source records and progress remain intact.") }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                appState.expirePresentationEvents()
                appState.deliverFirstAnomalyPresentationIfNeeded()
            }
        }
        .onAppear {
            appState.expirePresentationEvents()
            appState.deliverFirstAnomalyPresentationIfNeeded()
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
        case .banking: BankingView()
        }
    }
}
