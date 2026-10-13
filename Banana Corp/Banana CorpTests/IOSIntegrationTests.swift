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
        for item in content.items {
            if let id = item.restrictedResourceID { XCTAssertNotNil(access.resourcesByID[id]) }
        }
        for name in ["story-content-fixtures", "evidence-fixtures", "restricted-access-fixtures", "restricted-content-fixtures"] {
            XCTAssertNil(appBundle.url(forResource: name, withExtension: "json"))
        }
    }

    func testLaunchArtworkAndGeneratedInfoPlist() {
        XCTAssertNotNil(UIImage(named: "Logo-Black", in: appBundle, compatibleWith: nil))
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
}
