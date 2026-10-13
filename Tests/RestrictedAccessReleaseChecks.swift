import Foundation

@main struct RestrictedAccessReleaseChecks {
    @MainActor static func main() throws {
        let data = try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1]))
        if case .failure = RestrictedAccessCatalogueLoader.load(data: data) {} else { preconditionFailure("Release accepted development catalogue") }
        let production = try RestrictedAccessCatalogueLoader.load(data: Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[2]))).get()
        precondition(production.puzzles.allSatisfy { $0.rule.kind == .awaitingApproval && $0.successEffects.isEmpty })
        print("PASS: Release production loader rejects fixtures; production has no solution/effect bypass")
    }
}
