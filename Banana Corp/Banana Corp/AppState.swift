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
    @Published private(set) var presentation = OSPresentationState()
    private var presentationExpiryTask: Task<Void, Never>?

    @Published private(set) var feedbackEvent: AppFeedbackEvent?

    var activeApp: PhoneAppRoute? { navigation.activeApp }
    @Published var homeScreenLayout: HomeScreenLayout = HomeScreenLayoutStore.load() {
        didSet { HomeScreenLayoutStore.save(homeScreenLayout) }
    }
    @Published var isEditingHomeScreen = false

    let story: StoryProgressionStore
    let content: StoryContentStore

    // Compatibility queries now read the single saved narrative authority.
    var currentDay: Int { story.state.time.relativeDay }
    var hasOpenedVRApp: Bool { story.state.compatibility.hasOpenedVRApp }
    var hasSeenFirstGlitch: Bool { story.state.compatibility.hasSeenFirstGlitch }
    var unlockedApps: Set<PhoneAppRoute> {
        Set(PhoneAppRoute.allCases.filter { !story.state.lockedAppIDs.contains($0.rawValue) })
    }
    var unreadEmails: Int { content.unreadCount(for: .email) }
    var unreadMessages: Int { content.unreadCount(for: .messages) }
    // Cosmetic legacy input only; not a trust score or narrative progression source.
    @Published var aiCorruptionLevel = 0

    init(story: StoryProgressionStore? = nil,
         catalogue: Result<StoryContentCatalogue, StoryContentLoadFailure>? = nil) {
        self.story = story ?? StoryProgressionStore()
        self.content = StoryContentStore(progression: self.story, catalogue: catalogue ?? StoryContentCatalogueLoader.load())
        self.story.onStateWillChange = { [weak self] in self?.objectWillChange.send() }
        self.story.onStateDidChange = { [weak self] in
            guard let self, let activeApp = self.activeApp, !self.unlockedApps.contains(activeApp) else { return }
            self.goHome()
        }
    }

    var storyTimeContext: StoryTimeContext {
        StoryTimeContext(deviceTime: Date(), timeZoneIdentifier: TimeZone.current.identifier, story: story.state.time)
    }

    @discardableResult
    func resetStoryForNewGame() -> StoryActionResult {
        let result = story.resetForNewGame()
        if case .success = result {
            goHome()
            restoreNormalPresentation()
            aiCorruptionLevel = 0
        }
        return result
    }

    var storyPresentationContext: StoryPresentationContext {
        StoryPresentationContext(currentDay: currentDay, hasOpenedVRApp: hasOpenedVRApp,
                                 hasSeenFirstGlitch: hasSeenFirstGlitch, aiCorruptionLevel: aiCorruptionLevel)
    }

    /// The caller supplies an explicit condition evaluated against the existing story fields.
    @discardableResult
    func configureStoryPresentation(
        _ configuration: OSPresentationConfiguration,
        when condition: (StoryPresentationContext) -> Bool
    ) -> Bool {
        guard condition(storyPresentationContext) else { return false }
        presentationExpiryTask?.cancel()
        presentationExpiryTask = nil
        var next = presentation
        next.configure(configuration)
        presentation = next
        return true
    }

    @discardableResult
    func presentStoryEvent(
        _ event: OSPresentationEvent,
        when condition: (StoryPresentationContext) -> Bool
    ) -> Bool {
        guard condition(storyPresentationContext) else { return false }
        var next = presentation
        guard next.begin(event, at: Date(), monotonicTime: ProcessInfo.processInfo.systemUptime), let active = next.activeEvent else { return false }
        presentation = next
        presentationExpiryTask?.cancel()
        let id = active.id
        let duration = active.payload.duration
        presentationExpiryTask = Task { [weak self] in
            do { try await Task.sleep(for: .seconds(duration)) } catch { return }
            // Monotonic sleep bounds duration even if the real-world clock changes.
            self?.endPresentationEvent(id)
        }
        return true
    }

    func endPresentationEvent(_ id: UUID) {
        var next = presentation
        guard next.endEvent(id) else { return }
        presentation = next
        presentationExpiryTask?.cancel()
        presentationExpiryTask = nil
    }

    func expirePresentationEvents() {
        var next = presentation
        next.expire(at: Date())
        guard next != presentation else { return }
        presentation = next
        presentationExpiryTask?.cancel()
        presentationExpiryTask = nil
    }

    func restoreNormalPresentation() {
        presentationExpiryTask?.cancel()
        presentationExpiryTask = nil
        var next = presentation
        next.restoreNormal()
        presentation = next
    }

    var environmentalContext: OSEnvironmentContext {
        OSEnvironmentContext(date: Date())
    }

    /// Availability commits to the story save; failures do not change access or navigation.
    @discardableResult
    func setStoryAppAvailability(
        _ route: PhoneAppRoute, unlocked: Bool,
        when condition: (StoryPresentationContext) -> Bool
    ) -> Bool {
        guard condition(storyPresentationContext), unlocked || route != .settings else { return false }
        if case .success = story.perform(.setAppAvailability(route, unlocked: unlocked)) { return true }
        return false
    }

    deinit { presentationExpiryTask?.cancel() }

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
