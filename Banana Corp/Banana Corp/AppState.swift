//
//  AppState.swift
//  Banana Corp
//
//  Created by Aditi Abrol on 1/2/24.
//

import SwiftUI

final class AppState: ObservableObject {
    @Published var navigationPath: [PhoneAppRoute] = []

    @Published var currentDay: Int = 1
    @Published var hasOpenedVRApp = false
    @Published var hasSeenFirstGlitch = false
    @Published var unlockedApps: Set<PhoneAppRoute> = [
        .email,
        .browser,
        .social,
        .watchVideo,
        .messager,
        .photoAlbum,
        .settings,
        .phone,
        .news,
        .aiAssistant,
        .vrExperience,
        .snake,
        .pong,
        .xo
    ]
    @Published var unreadEmails = 0
    @Published var unreadMessages = 0
    @Published var aiCorruptionLevel = 0

    func open(_ route: PhoneAppRoute) {
        navigationPath.append(route)
    }

    func goHome() {
        navigationPath.removeAll()
    }
}
