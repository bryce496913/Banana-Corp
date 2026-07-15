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
        PhoneAppInfo(title: "Web Browser", systemImage: "safari.fill", route: .browser),
        PhoneAppInfo(title: "Social X", systemImage: "bubble.left.and.bubble.right.fill", route: .social),
        PhoneAppInfo(title: "WatchVideo", systemImage: "play.circle.fill", route: .watchVideo),
        PhoneAppInfo(title: "Messager", systemImage: "message.fill", route: .messager),
        PhoneAppInfo(title: "Photo Album", systemImage: "photo.fill", route: .photoAlbum),
        PhoneAppInfo(title: "Settings", systemImage: "gearshape.fill", route: .settings),
        PhoneAppInfo(title: "Phone", systemImage: "phone.fill", route: .phone),
        PhoneAppInfo(title: "News", systemImage: "newspaper.fill", route: .news),
        PhoneAppInfo(title: "AI Assistant", systemImage: "waveform.path.ecg.rectangle.fill", route: .aiAssistant),
        PhoneAppInfo(title: "Snake", systemImage: "gamecontroller.fill", route: .snake),
        PhoneAppInfo(title: "X / O", systemImage: "gamecontroller.fill", route: .xo),
        PhoneAppInfo(title: "VR Experience", systemImage: "eyeglasses", route: .vrExperience),
        PhoneAppInfo(title: "Pong", systemImage: "flame.fill", route: .pong)
    ]

    private let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 3)

    var body: some View {
        NavigationStack(path: $appState.navigationPath) {
            VStack {
                StatusBar()

                ScrollView {
                    LazyVGrid(columns: columns, spacing: 30) {
                        ForEach(visibleApps) { app in
                            Button {
                                appState.open(app.route)
                            } label: {
                                VStack {
                                    Image(systemName: app.systemImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 50, height: 50)
                                        .foregroundColor(AppTheme.Colors.text)

                                    Text(app.title)
                                        .appText(.h3)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(1)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding()
                }

                HomeButton()
            }
            .background(AppTheme.Colors.background)
            .navigationBarHidden(true)
            .navigationDestination(for: PhoneAppRoute.self) { route in
                destinationView(for: route)
                    .navigationBarHidden(true)
            }
        }
    }

    private var visibleApps: [PhoneAppInfo] {
        apps.filter { appState.unlockedApps.contains($0.route) }
    }

    @ViewBuilder
    private func destinationView(for route: PhoneAppRoute) -> some View {
        switch route {
        case .email:
            EmailView()
        case .browser:
            WebBrowserView()
        case .social:
            SocialXView()
        case .watchVideo:
            WatchVideoView()
        case .messager:
            MessagerView()
        case .photoAlbum:
            PhotoAlbumView()
        case .settings:
            SettingsView()
        case .phone:
            PhoneView()
        case .news:
            NewsView()
        case .aiAssistant:
            AIAssistantView()
        case .vrExperience:
            VRExperienceView()
        case .snake:
            SnakeGameView()
        case .pong:
            PongGameView()
        case .xo:
            XOGameView()
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
