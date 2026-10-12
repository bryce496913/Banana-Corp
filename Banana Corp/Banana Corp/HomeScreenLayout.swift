import Foundation

enum HomeSection: Equatable {
    case grid
    case dock
}

struct HomeScreenLayout: Codable, Equatable {
    var gridApps: [PhoneAppRoute]
    var dockApps: [PhoneAppRoute]

    static let defaultDockApps: [PhoneAppRoute] = [
        .email, .messager, .news, .aiAssistant
    ]

    static let defaultLayout = HomeScreenLayout(
        gridApps: PhoneAppRoute.allCases.filter { !defaultDockApps.contains($0) },
        dockApps: defaultDockApps
    )

    var normalized: HomeScreenLayout {
        // Only accepted dock items enter 'seen': overflow is preserved in the grid.
        var seen = Set<PhoneAppRoute>()
        var dock: [PhoneAppRoute] = []
        for route in dockApps where dock.count < 4 {
            if seen.insert(route).inserted { dock.append(route) }
        }
        var grid = gridApps.filter { seen.insert($0).inserted }
        for route in dockApps where !seen.contains(route) {
            seen.insert(route)
            grid.append(route)
        }
        // Hidden/locked apps keep positions. Unlocking doesn't reset the arrangement.
        grid += PhoneAppRoute.allCases.filter { seen.insert($0).inserted }
        return HomeScreenLayout(gridApps: grid, dockApps: dock)
    }

    /// Inserts before an icon, or appends when dropping in a section's empty space.
    /// Rejected drops leave the original layout untouched.
    @discardableResult
    mutating func move(_ route: PhoneAppRoute, to section: HomeSection, before target: PhoneAppRoute? = nil) -> Bool {
        guard target != route else { return false }
        var candidate = normalized
        let destination = section == .grid ? candidate.gridApps : candidate.dockApps
        if let target, !destination.contains(target) { return false }

        candidate.gridApps.removeAll { $0 == route }
        candidate.dockApps.removeAll { $0 == route }
        switch section {
        case .grid:
            let index = target.flatMap { candidate.gridApps.firstIndex(of: $0) } ?? candidate.gridApps.endIndex
            candidate.gridApps.insert(route, at: index)
        case .dock:
            guard candidate.dockApps.count < 4 else { return false }
            let index = target.flatMap { candidate.dockApps.firstIndex(of: $0) } ?? candidate.dockApps.endIndex
            candidate.dockApps.insert(route, at: index)
        }
        self = candidate
        return true
    }
}

enum HomeScreenLayoutStore {
    private static let key = "bananaCorp.homeScreenLayout.v1"

    static func load(from defaults: UserDefaults = .standard) -> HomeScreenLayout {
        guard
            let data = defaults.data(forKey: key),
            let layout = try? JSONDecoder().decode(HomeScreenLayout.self, from: data)
        else {
            return .defaultLayout
        }
        return layout.normalized
    }

    static func save(_ layout: HomeScreenLayout, to defaults: UserDefaults = .standard) {
        guard let data = try? JSONEncoder().encode(layout.normalized) else { return }
        defaults.set(data, forKey: key)
    }
}

// Keep native drag payload validation independent of view gestures.
enum HomeAppDrop {
    static func route(from items: [String]) -> PhoneAppRoute? {
        guard items.count == 1, let value = items.first else { return nil }
        return PhoneAppRoute(rawValue: value)
    }
}
