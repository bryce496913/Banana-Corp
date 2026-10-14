import Foundation

@main struct RestrictedAccessReleaseChecks {
    @MainActor static func main() throws {
        let data = try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1]))
        if case .failure = RestrictedAccessCatalogueLoader.load(data: data) {} else { preconditionFailure("Release accepted development catalogue") }
        let production = try RestrictedAccessCatalogueLoader.load(data: Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[2]))).get()
        precondition(production.puzzlesByID["puzzle.banana_wall.pending_design"]?.rule.kind == .awaitingApproval)
        precondition(production.puzzlesByID["puzzle.banana_wall.review_cross_reference"]?.rule.kind == .exactFields)
        print("PASS: Release production loader rejects fixtures; approved definition exists; retired gate stays inert")
    }
}
