import Foundation

@main
struct BrowserNavigationChecks {
    static func main() {
        let cases: [(String, BrowserAddressIntent)] = [
            ("", .home), ("  /  ", .home), ("banana.example", .home),
            ("https://BANANA.EXAMPLE/", .home), ("www.banana.example/banana-vision", .path("/banana-vision")),
            ("  https://banana.example/banana-vision?ref=mail#details  ", .path("/banana-vision")),
            ("/research/echo-07/summary", .path("/research/echo-07/summary")),
            ("/banana%2Dvision", .path("/banana-vision")),
            ("Banana Vision", .search("Banana Vision")),
            ("https://unavailable.example/banana-vision", .connectionIssue),
            ("https://banana.example.attacker.example/banana-vision", .connectionIssue),
            ("https://user:secret@banana.example/banana-vision", .connectionIssue),
            ("https://banana.example:443/banana-vision", .connectionIssue),
            ("file://banana.example/banana-vision", .connectionIssue),
            ("//banana.example/banana-vision", .connectionIssue),
            (String(repeating: "x", count: 2_049), .connectionIssue)
        ]
        for (input, expected) in cases {
            precondition(BrowserAddressIntent.resolve(input) == expected, "Address resolution mismatch")
        }
        precondition(PhoneEdgeBackIntent.shouldGoBack(horizontal: 90, vertical: 10))
        precondition(PhoneEdgeBackIntent.shouldGoBack(horizontal: 72, vertical: -20))
        precondition(!PhoneEdgeBackIntent.shouldGoBack(horizontal: 71, vertical: 0))
        precondition(!PhoneEdgeBackIntent.shouldGoBack(horizontal: -100, vertical: 0))
        precondition(!PhoneEdgeBackIntent.shouldGoBack(horizontal: 80, vertical: 60))
        precondition(!PhoneEdgeBackIntent.shouldGoBack(horizontal: 80, vertical: 100))
        precondition(BrowserAddressIntent.resolve("https://banana-prizes.example/claim") == .path("/offers/free-headset"))
        precondition(BrowserAddressIntent.resolve("banana-prizes.example") == .path("/offers/free-headset"))
        precondition(BrowserAddressIntent.resolve("https://banana-prizes.example/private") == .connectionIssue)
        print("PASS: fictional Browser address normalization, credential/domain rejection, and directional edge-back intent. Model only; no UI/network execution.")
    }
}
