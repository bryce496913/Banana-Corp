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
    private var firstAnomalyVisualID: UUID?
    @Published var firstAnomalyDeliveryFailed = false

    @Published private(set) var feedbackEvent: AppFeedbackEvent?

    var activeApp: PhoneAppRoute? { navigation.activeApp }
    @Published var homeScreenLayout: HomeScreenLayout = HomeScreenLayoutStore.load() {
        didSet { HomeScreenLayoutStore.save(homeScreenLayout) }
    }
    @Published var isEditingHomeScreen = false

    let story: StoryProgressionStore
    let content: StoryContentStore
    let access: RestrictedAccessStore

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
        self.access = RestrictedAccessStore(progression: self.story, catalogue: RestrictedAccessCatalogueLoader.load())
        let contentCatalogue = catalogue ?? StoryContentCatalogueLoader.load(restrictedResourceIDs: Set(self.access.catalogue?.resources.map(\.id) ?? []))
        self.content = StoryContentStore(progression: self.story, catalogue: contentCatalogue, access: self.access)
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
            access.clearDrafts()
            firstAnomalyDeliveryFailed = false
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
        firstAnomalyVisualID = nil
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
        if firstAnomalyVisualID == id {
            next.restoreNormal()
            firstAnomalyVisualID = nil
        }
        presentation = next
        presentationExpiryTask?.cancel()
        presentationExpiryTask = nil
    }

    func expirePresentationEvents() {
        var next = presentation
        next.expire(at: Date())
        if firstAnomalyVisualID != nil && next.activeEvent == nil {
            next.restoreNormal()
            firstAnomalyVisualID = nil
        }
        guard next != presentation else { return }
        presentation = next
        presentationExpiryTask?.cancel()
        presentationExpiryTask = nil
    }

    func restoreNormalPresentation() {
        firstAnomalyVisualID = nil
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
        reconcileFirstAnomalyAtBoundary()
        reconcileActTwoAtBoundary()
    }

    func reconcileActTwoAtBoundary(surface: StoryAppSurface? = nil) {
        if case .failure = content.activateActTwoChangesAtBoundary(surface: surface) { firstAnomalyDeliveryFailed = true }
    }

    /// Home and return-to-inbox are explicit narrative boundaries, separate from read/preserve actions.
    func reconcileFirstAnomalyAtBoundary() {
        guard story.state.currentAct == .thePerfectProduct,
              story.satisfies(FirstAnomalyContract.removalPrerequisites),
              !story.state.completedEventIDs.contains(FirstAnomalyContract.removalEvent) else { return }
        switch content.activateFirstAnomalyAtBoundary() {
        case .success: firstAnomalyDeliveryFailed = false; deliverFirstAnomalyPresentationIfNeeded()
        case .failure: firstAnomalyDeliveryFailed = true
        }
    }

    /// Durable consumption prevents cosmetic replay. The unread message supplies the permanent lead.
    func deliverFirstAnomalyPresentationIfNeeded() {
        guard story.satisfies(.eventCompleted(FirstAnomalyContract.removalEvent)),
              !story.state.completedEventIDs.contains(FirstAnomalyContract.presentationEvent),
              presentation.configuration.mode == .normal else { return }
        let now = Date()
        var next = presentation
        next.configure(OSPresentationConfiguration(mode: .subtleAnomaly))
        let notice = content.pendingNotifications().first(where: { $0.record.contentID == FirstAnomalyContract.notification })
        var event = OSPresentationEvent(status: OSStatusOverride(carrier: "BANANA 5G…"), duration: 2)
        if let notice, case .notifications(let payload) = notice.content.payload {
            event.interruption = OSInterruption(kind: .notification, title: notice.content.title, message: payload.message)
        }
        guard next.begin(event, at: now, monotonicTime: ProcessInfo.processInfo.systemUptime), let active = next.activeEvent else { return }
        guard case .success = content.consumeFirstAnomalyPresentation() else { firstAnomalyDeliveryFailed = true; return }
        firstAnomalyVisualID = active.id
        presentation = next
        presentationExpiryTask?.cancel()
        presentationExpiryTask = Task { [weak self] in
            do { try await Task.sleep(for: .seconds(active.payload.duration)) } catch { return }
            self?.endPresentationEvent(active.id)
        }
    }
}
