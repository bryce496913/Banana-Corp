//
//  HomeScreenView.swift
//  Banana Corp
//
//  Created by Aditi Abrol on 1/2/24.
//

import SwiftUI

struct HomeScreenView: View {
    let apps = [
        AppInfo("Email", "envelope.fill", EmailView()),
        AppInfo("Web Browser", "safari.fill", WebBrowserView()),
        AppInfo("Social X", "bubble.left.and.bubble.right.fill", SocialXView()),
        AppInfo("WatchVideo", "play.circle.fill", WatchVideoView()),
        AppInfo("Messager", "message.fill", MessagerView()),
        AppInfo("Photo Album", "photo.fill", PhotoAlbumView()),
        AppInfo("Settings", "gearshape.fill", SettingsView()),
        AppInfo("Phone", "phone.fill", PhoneView()),
        AppInfo("News", "newspaper.fill", NewsView()),
        AppInfo("AI Assistant", "waveform.path.ecg.rectangle.fill", AIAssistantView()),
        AppInfo("Snake", "gamecontroller.fill", SnakeGameView()), //done
        AppInfo("X / O", "gamecontroller.fill", XOGameView()), //done
        AppInfo("VR Experience", "eyeglasses", VRExperienceView()),
        AppInfo("Pong", "flame.fill", PongGameView()) //done
        // Add more apps as needed
    ]

    let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 3)

    var body: some View {
        NavigationView {
            VStack {
                StatusBar()

                ScrollView {
                    LazyVGrid(columns: columns, spacing: 30) {
                        ForEach(apps, id: \.name) { app in
                            NavigationLink(
                                destination: app.destination,
                                label: {
                                    VStack {
                                        Image(systemName: app.icon)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 50, height: 50)
                                            .foregroundColor(.white)

                                        Text(app.name)
                                            .foregroundColor(.white)
                                            .multilineTextAlignment(.center)
                                            .lineLimit(1)
                                    }
                                }
                            )
                        }
                    }
                    .padding()
                }

                HomeButton()
            }
            .background(Color.black)
            .navigationBarHidden(true)
        }
    }
}

struct AppInfo: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let destination: AnyView

    init<T: View>(_ name: String, _ icon: String, _ destination: T) {
        self.name = name
        self.icon = icon
        self.destination = AnyView(destination)
    }
}

struct HomeScreenView_Previews: PreviewProvider {
    static var previews: some View {
        HomeScreenView()
    }
}
