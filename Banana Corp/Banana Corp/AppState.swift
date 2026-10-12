//
//  AppState.swift
//  Banana Corp
//
//  Created by Aditi Abrol on 1/2/24.
//

import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published private(set) var navigation = OSNavigationState()
    @Published private(set) var feedbackEvent: AppFeedbackEvent?

    var activeApp: PhoneAppRoute? { navigation.activeApp }
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

    func beginEditingHomeScreen() {
        guard navigation.isHomeReady, !isEditingHomeScreen else { return }
        isEditingHomeScreen = true
        feedbackEvent = AppFeedbackEvent(kind: .enteredEditing)
    }

    func completeNavigationTransition(_ id: UInt) {
        var next = navigation
        guard next.completeTransition(id) else { return }
        navigation = next
    }

    func finishEditingHomeScreen() {
        isEditingHomeScreen = false
    }

    @discardableResult
    func moveHomeApp(_ route: PhoneAppRoute, to section: HomeSection, before target: PhoneAppRoute?) -> Bool {
        guard isEditingHomeScreen, navigation.isHomeReady, unlockedApps.contains(route) else { return false }
        if let target, !unlockedApps.contains(target) { return false }
        var layout = homeScreenLayout
        guard layout.move(route, to: section, before: target) else { return false }
        // Accepted no-op drops don't persist, restart layout animation, or buzz.
        guard layout != homeScreenLayout else { return true }
        homeScreenLayout = layout
        feedbackEvent = AppFeedbackEvent(kind: .completedDrop)
        return true
    }

    func open(_ route: PhoneAppRoute) {
        guard !isEditingHomeScreen, unlockedApps.contains(route) else { return }
        var next = navigation
        guard next.open(route) else { return }
        navigation = next
        feedbackEvent = AppFeedbackEvent(kind: .openedApp)
    }

    func goHome() {
        finishEditingHomeScreen()
        var next = navigation
        guard next.goHome() else { return }
        navigation = next
    }
}
