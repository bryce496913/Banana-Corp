import XCTest
import UIKit
@testable import Banana_Corp

final class IOSIntegrationTests: XCTestCase {
    private var appBundle: Bundle { Bundle(for: AppState.self) }

    func testProductionCataloguesLoadFromApplicationBundle() throws {
        XCTAssertEqual(appBundle.bundleURL.pathExtension, "app")
        XCTAssertNotNil(appBundle.url(forResource: "StoryContent", withExtension: "json"))
        XCTAssertNotNil(appBundle.url(forResource: "RestrictedAccess", withExtension: "json"))
        let access = try RestrictedAccessCatalogueLoader.load(bundle: appBundle).get()
        let content = try StoryContentCatalogueLoader.load(bundle: appBundle).get()
        XCTAssertFalse(content.items.isEmpty)
        XCTAssertNotNil(content.itemsByID["content.act1.welcome"])
        XCTAssertNotNil(access.resourcesByID["resource.banana_wall"])
        XCTAssertEqual(access.puzzlesByID["puzzle.banana_wall.pending_design"]?.rule.kind, .awaitingApproval)
        XCTAssertEqual(access.puzzlesByID["puzzle.banana_wall.review_cross_reference"]?.rule.kind, .exactFields)
        for item in content.items {
            if let id = item.restrictedResourceID { XCTAssertNotNil(access.resourcesByID[id]) }
        }
        for name in ["story-content-fixtures", "evidence-fixtures", "restricted-access-fixtures", "restricted-content-fixtures"] {
            XCTAssertNil(appBundle.url(forResource: name, withExtension: "json"))
        }
    }

    func testLaunchArtworkAndGeneratedInfoPlist() {
        for asset in AppImageAsset.allCases {
            XCTAssertNotNil(UIImage(named: asset.rawValue, in: appBundle, compatibleWith: nil), "Missing registered artwork: \(asset.rawValue)")
        }
        XCTAssertEqual(appBundle.object(forInfoDictionaryKey: "UIStatusBarHidden") as? Bool, true)
        XCTAssertEqual(appBundle.object(forInfoDictionaryKey: "MinimumOSVersion") as? String, "18.0")
        XCTAssertEqual(appBundle.object(forInfoDictionaryKey: "UIDeviceFamily") as? [Int], [1])
        XCTAssertNotNil(appBundle.object(forInfoDictionaryKey: "UIApplicationSceneManifest"))
    }

    @MainActor
    func testInitialStateAndQueriesArePassive() async {
        let story = StoryProgressionStore(persistence: InMemoryStoryPersistence())
        let app = AppState(story: story)
        XCTAssertTrue(story.isWritable)
        XCTAssertTrue(story.state.isValid)
        XCTAssertEqual(story.state.currentAct, .thePerfectProduct)
        XCTAssertTrue(app.content.loadDiagnostics.isEmpty)
        XCTAssertTrue(app.access.diagnostics.isEmpty)
        let initial = story.state
        XCTAssertGreaterThan(app.unreadEmails, 0)
        _ = app.content.availableItems(for: .news)
        _ = app.access.visibleResources()
        XCTAssertEqual(app.access.resourceState("resource.banana_wall"), .hidden)
        XCTAssertEqual(story.state, initial)
    }

    @MainActor
    func testEveryRegisteredRouteHasArtworkAndCompletesHomeCycle() async {
        let app = AppState(story: StoryProgressionStore(persistence: InMemoryStoryPersistence()))
        let layout = HomeScreenLayout.defaultLayout.normalized
        let routes = layout.gridApps + layout.dockApps
        XCTAssertEqual(Set(routes), Set(PhoneAppRoute.allCases))
        XCTAssertEqual(routes.count, Set(routes).count)
        XCTAssertLessThanOrEqual(layout.dockApps.count, 4)
        for route in PhoneAppRoute.allCases {
            let info = PhoneAppInfo.info(for: route)
            XCTAssertEqual(info?.route, route)
            if case .symbol(let name) = info?.image { XCTAssertNotNil(UIImage(systemName: name), name) }
            app.open(route)
            XCTAssertEqual(app.activeApp, route)
            app.completeNavigationTransition(app.navigation.transitionID)
            app.goHome()
            XCTAssertNil(app.activeApp)
            app.completeNavigationTransition(app.navigation.transitionID)
            XCTAssertTrue(app.navigation.isHomeReady)
        }
    }

    @MainActor
    func testEvidenceSnapshotSurvivesFileSaveAndNewStore() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = StoryFilePersistence(fileURL: directory.appendingPathComponent("story-save.json"))
        let first = AppState(story: StoryProgressionStore(persistence: file))
        let item = try XCTUnwrap(first.content.availableItems(for: .news).first { first.content.isPreservable($0.id, versionID: $0.version.id) })
        _ = try first.content.read(item.id, versionID: item.version.id).get()
        _ = try first.content.preserve(item.id, versionID: item.version.id).get()
        let original = try XCTUnwrap(first.content.preservedItems().first)
        let reopened = AppState(story: StoryProgressionStore(persistence: file))
        XCTAssertTrue(reopened.story.isWritable)
        let saved = try XCTUnwrap(reopened.content.preservedItem(original.record.id))
        XCTAssertEqual(saved.record.snapshot, original.record.snapshot)
        XCTAssertEqual(saved.snapshot.version, original.snapshot.version)
        XCTAssertEqual(reopened.story.state, first.story.state)
        _ = try reopened.content.preserve(item.id, versionID: item.version.id).get()
        XCTAssertEqual(reopened.content.preservedItems().count, 1)
    }

    @MainActor
    func testSavedTakeoverAppearanceIsPassiveAndRestoresAcrossEndingLifecycle() throws {
        // Neutral hosted fixture, not an injected campaign or player-visible shortcut.
        var saved = StoryState()
        saved.currentAct = .theFinalChoice
        saved.completedEventIDs.insert(ActFourContract.takeoverEvent)
        saved.completedMilestoneIDs.insert(ActFourContract.takeoverConnected)
        saved.ascensionMilestone = AscensionMilestone(id: ActFourContract.ascension, percentage: 87)
        saved.routePrerequisiteIDs = EndgameContract.components
        saved.readContentIDs = [EndgameContract.version("recovery"), EndgameContract.version("dependency_warning")]
        saved.discoveredContentIDs = saved.readContentIDs
        let storage = InMemoryStoryPersistence(data: try StorySaveCodec().encode(saved))
        let store = StoryProgressionStore(persistence: storage)
        let app = AppState(story: store)
        XCTAssertEqual(store.state, saved, "Presentation must never award or consume story facts")
        XCTAssertEqual(app.presentation.configuration.mode, .compromised)
        XCTAssertNil(app.presentation.activeEvent, "Rehydrating takeover must not schedule a transient replay")
        app.reconcileSavedStoryPresentation()
        XCTAssertEqual(store.state, saved)
        var preferences = store.phoneLife.preferences; preferences.reduceMotion = true
        _ = try store.updatePhonePreferences(preferences).get()
        XCTAssertEqual(app.presentation.configuration.mode, .compromised)
        XCTAssertNil(app.presentation.activeEvent)
        let reopened = AppState(story: StoryProgressionStore(persistence: storage))
        XCTAssertEqual(reopened.presentation.configuration.mode, .compromised)
        XCTAssertEqual(reopened.story.state, store.state)
        let decision = try XCTUnwrap(store.prepareEnding(.silence))
        _ = try store.confirmEnding(decision).get()
        XCTAssertEqual(app.presentation.configuration.mode, .normal)
        _ = try store.restoreFinalDecision().get()
        XCTAssertEqual(app.presentation.configuration.mode, .compromised)
        XCTAssertTrue(store.phoneLife.preferences.reduceMotion)
        _ = try store.resetForNewGame().get()
        XCTAssertEqual(app.presentation.configuration.mode, .normal)
        XCTAssertTrue(store.phoneLife.preferences.reduceMotion)

        var variants = [saved, saved, saved, saved]
        variants[0].completedEventIDs.remove(ActFourContract.takeoverEvent)
        variants[1].completedMilestoneIDs.remove(ActFourContract.takeoverConnected)
        variants[2].ascensionMilestone = AscensionMilestone(id: ActFourContract.ascension, percentage: 86)
        variants[3].currentAct = .theConspiracy
        for variant in variants {
            let invalidEligibility = AppState(story: StoryProgressionStore(persistence: InMemoryStoryPersistence(data: try StorySaveCodec().encode(variant))))
            XCTAssertEqual(invalidEligibility.presentation.configuration.mode, .normal)
            XCTAssertEqual(invalidEligibility.story.state, variant)
        }
    }

}
