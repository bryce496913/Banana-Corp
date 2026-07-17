import Foundation

struct HomeScreenLayout: Codable, Equatable {
    var gridApps: [PhoneAppRoute]
    var dockApps: [PhoneAppRoute]

    static let defaultDockApps: [PhoneAppRoute] = [
        .email,
        .messager,
        .news,
        .aiAssistant
    ]

    static let defaultLayout = HomeScreenLayout(
        gridApps: PhoneAppRoute.allCases.filter { !defaultDockApps.contains($0) },
        dockApps: defaultDockApps
    )

    var normalized: HomeScreenLayout {
        var seen = Set<PhoneAppRoute>()
        let cleanDock = dockApps.filter { route in
            guard seen.insert(route).inserted else { return false }
            return true
        }.prefix(4)

        let dockArray = Array(cleanDock)
        let cleanGrid = gridApps.filter { route in
            guard !dockArray.contains(route) else { return false }
            return seen.insert(route).inserted
        }

        let missingApps = PhoneAppRoute.allCases.filter { !seen.contains($0) }
        return HomeScreenLayout(gridApps: cleanGrid + missingApps, dockApps: dockArray)
    }
}

enum HomeScreenLayoutStore {
    private static let key = "bananaCorp.homeScreenLayout.v1"

    static func load() -> HomeScreenLayout {
        guard
            let data = UserDefaults.standard.data(forKey: key),
            let layout = try? JSONDecoder().decode(HomeScreenLayout.self, from: data)
        else {
            return HomeScreenLayout.defaultLayout
        }

        return layout.normalized
    }

    static func save(_ layout: HomeScreenLayout) {
        guard let data = try? JSONEncoder().encode(layout.normalized) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
