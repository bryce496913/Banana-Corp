import Foundation

@main
struct HomeScreenLayoutChecks {
    static func main() throws {
        let routes = PhoneAppRoute.allCases
        let expectedDock: [PhoneAppRoute] = [.email, .messager, .news, .aiAssistant]
        precondition(HomeScreenLayout.defaultLayout.dockApps == expectedDock)
        checkInvariants(.defaultLayout)

        let oversized = HomeScreenLayout(gridApps: [], dockApps: routes + routes)
        let repaired = oversized.normalized
        precondition(repaired.dockApps == Array(routes.prefix(4)))
        precondition(repaired.gridApps == Array(routes.dropFirst(4)))
        checkInvariants(repaired)
        precondition(repaired.normalized == repaired)

        let customized = HomeScreenLayout(
            gridApps: [.pong, .snake, .pong, .email],
            dockApps: [.email, .email, .news, .messager, .aiAssistant, .xo]
        ).normalized
        precondition(customized.gridApps.prefix(2) == [.pong, .snake])
        precondition(customized.gridApps.contains(.xo))
        checkInvariants(customized)

        var layout = HomeScreenLayout.defaultLayout
        let original = layout
        precondition(!layout.move(.snake, to: .dock, before: .email))
        precondition(layout == original, "Full dock rejection must be atomic")
        precondition(!layout.move(.snake, to: .grid, before: .email))
        precondition(layout == original, "Wrong-section target must be rejected")
        precondition(!layout.move(.snake, to: .grid, before: .snake))
        precondition(layout == original, "Self-drop must not modify the layout")

        // A full dock can reorder its own items, including appending to the end.
        precondition(layout.move(.email, to: .dock))
        precondition(layout.dockApps == [.messager, .news, .aiAssistant, .email])
        precondition(layout.move(.email, to: .dock, before: .messager))
        precondition(layout.dockApps == expectedDock)
        precondition(layout.move(.email, to: .grid, before: .snake))
        precondition(layout.gridApps.firstIndex(of: .email)! + 1 == layout.gridApps.firstIndex(of: .snake)!)
        precondition(layout.move(.snake, to: .dock, before: .news))
        precondition(layout.dockApps == [.messager, .snake, .news, .aiAssistant])
        checkInvariants(layout)

        // An empty dock accepts items without removing any fictional apps.
        var emptyDock = HomeScreenLayout(gridApps: routes, dockApps: [])
        for route in expectedDock {
            precondition(emptyDock.move(route, to: .dock))
        }
        precondition(emptyDock.dockApps == expectedDock)
        checkInvariants(emptyDock)

        // Exercise every source/target pair in both sections, and empty-space drops.
        var successfulMoves = 0
        for source in routes {
            for section in [HomeSection.grid, .dock] {
                for target in routes.map(Optional.some) + [nil] {
                    var candidate = layout
                    let before = candidate
                    if candidate.move(source, to: section, before: target) {
                        successfulMoves += 1
                        checkInvariants(candidate)
                    } else {
                        precondition(candidate == before)
                    }
                }
            }
        }

        // App visibility/unlocks do not participate in saved position normalization.
        precondition(layout.normalized == layout)
        let missingRoute = HomeScreenLayout(
            gridApps: layout.gridApps.filter { $0 != .email },
            dockApps: layout.dockApps
        ).normalized
        precondition(missingRoute.gridApps.dropLast() == layout.gridApps.filter { $0 != .email })
        precondition(missingRoute.gridApps.last == .email)

        precondition(HomeAppDrop.route(from: ["snake"]) == .snake)
        precondition(HomeAppDrop.route(from: []) == nil)
        precondition(HomeAppDrop.route(from: ["snake", "pong"]) == nil)
        precondition(HomeAppDrop.route(from: ["unknown-app"]) == nil)
        precondition(HomeAppDrop.route(from: [""]) == nil)

        let suite = "bananaCorp.layoutChecks." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        precondition(HomeScreenLayoutStore.load(from: defaults) == .defaultLayout)
        HomeScreenLayoutStore.save(layout, to: defaults)
        // New defaults instance simulates reloading stored state, using the existing v1 key.
        let reloaded = UserDefaults(suiteName: suite)!
        precondition(HomeScreenLayoutStore.load(from: reloaded) == layout)
        let storedData = defaults.data(forKey: "bananaCorp.homeScreenLayout.v1")!
        let decoded = try JSONDecoder().decode(HomeScreenLayout.self, from: storedData)
        precondition(decoded == layout)
        defaults.set(Data("invalid".utf8), forKey: "bananaCorp.homeScreenLayout.v1")
        precondition(HomeScreenLayoutStore.load(from: defaults) == .defaultLayout)

        print("PASS: normalization, overflow retention, atomic dock limits, grid/dock reorder, \(successfulMoves) valid moves, invalid payloads, missing routes, and persistent v1 reload")
    }

    static func checkInvariants(_ layout: HomeScreenLayout) {
        let all = layout.gridApps + layout.dockApps
        precondition(layout.dockApps.count <= 4)
        precondition(Set(all) == Set(PhoneAppRoute.allCases))
        precondition(all.count == Set(all).count, "No duplicates or deleted apps")
    }
}
