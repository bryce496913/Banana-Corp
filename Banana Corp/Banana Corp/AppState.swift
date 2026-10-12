//
//  AppState.swift
//  Banana Corp
//
//  Created by Aditi Abrol on 1/2/24.
//

import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published private(set) var activeApp: PhoneAppRoute?
    @Published var homeScreenLayout: HomeScreenLayout = HomeScreenLayoutStore.load() {
        didSet { HomeScreenLayoutStore.save(homeScreenLayout) }
    }
    @Published var isEditingHomeScreen = false

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

    func finishEditingHomeScreen() {
        isEditingHomeScreen = false
    }

    @discardableResult
    func moveHomeApp(_ route: PhoneAppRoute, to section: HomeSection, before target: PhoneAppRoute?) -> Bool {
        guard isEditingHomeScreen, activeApp == nil, unlockedApps.contains(route) else { return false }
        if let target, !unlockedApps.contains(target) { return false }
        var layout = homeScreenLayout
        guard layout.move(route, to: section, before: target) else { return false }
        homeScreenLayout = layout
        return true
    }

    func open(_ route: PhoneAppRoute) {
        guard activeApp == nil, !isEditingHomeScreen, unlockedApps.contains(route) else { return }
        isEditingHomeScreen = false
        activeApp = route
    }

    func goHome() {
        activeApp = nil
        isEditingHomeScreen = false
    }
}
