import Foundation

/// Browser inputs resolve only inside the fictional phone. This never performs networking.
enum BrowserAddressIntent: Equatable {
    case home
    case path(String)
    case search(String)
    case connectionIssue

    static func resolve(_ input: String) -> BrowserAddressIntent {
        let value = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return .home }
        guard value.utf8.count <= 2_048 else { return .connectionIssue }
        if value == "/" { return .home }
        if value.hasPrefix("/") {
            guard !value.hasPrefix("//"), let components = URLComponents(string: value),
                  components.host == nil, !components.path.isEmpty else { return .connectionIssue }
            return .path(components.path)
        }
        let lower = value.lowercased()
        let looksLikeAddress = value.contains("://") || lower.hasPrefix("www.") ||
            value.split(separator: "/", maxSplits: 1).first?.contains(".") == true
        guard looksLikeAddress else { return .search(value) }
        guard let components = URLComponents(string: value.contains("://") ? value : "https://" + value),
              ["https", "http"].contains(components.scheme?.lowercased() ?? ""),
              ["banana.example", "www.banana.example"].contains(components.host?.lowercased() ?? ""),
              components.user == nil, components.password == nil, components.port == nil else {
            return .connectionIssue
        }
        return components.path.isEmpty || components.path == "/" ? .home : .path(components.path)
    }
}

/// The reserved leading strip cannot treat vertical scrolling or a short nudge as Back.
enum PhoneEdgeBackIntent {
    static func shouldGoBack(horizontal: Double, vertical: Double) -> Bool {
        horizontal >= 72 && abs(vertical) <= 60 && horizontal > abs(vertical) * 1.8
    }
}
