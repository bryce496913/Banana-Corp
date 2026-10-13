# Repository instructions

## Story authority

Read [BANANA_CORP_GAME_BIBLE.md](BANANA_CORP_GAME_BIBLE.md) before changing story content, gameplay, app behavior, progression, puzzles, endings, or story presentation. It is the canonical design reference, not a claim that its features are implemented. Inspect the current implementation and relevant tests before editing. Use [docs/STORY_IMPLEMENTATION.md](docs/STORY_IMPLEMENTATION.md) for the implementation inventory and documentation conventions.

- Preserve the five-act chronology and reveal order, including knowledge boundaries on notifications, accessibility labels, and all other player-visible surfaces. The older six-phase outline is superseded; phone interference and breaking the Banana Wall are beats within the five acts.
- Preserve established names, clues, progression rules, puzzle frameworks, and ending requirements. Keep `[TBD]` decisions unresolved and `[PROPOSED]` items unapproved unless explicitly authorized by the user. Do not invent missing story content.
- For approved changes to story, mechanics, puzzle paths, progression contracts, or ending requirements, update the relevant bible sections and its change log in the same PR. Never add story requirements only through code. Implementation-only refactors that leave game design unchanged do not require rewriting the bible.
- Keep content IDs stable once used in persisted saves. Distinguish preserved evidence from live content versions; document and test any approved save migration.
- Report implementation/canon differences; do not silently resolve them or rewrite canon to justify existing code.

Without explicit story approval, do not introduce hidden morality scoring, trust meters or credibility formulas, alternative endings, new mandatory mini-game gates, new major characters, changes to ASCENSION / DAWN / LANTERN / BLACKOUT / Observer requirements, or calendar-specific launch dates. Negotiation's established use of evidence and credibility does not authorize numerical scoring or thresholds.

## Implementation and validation

- Preserve the iOS 18 deployment target. Protect iOS 26 APIs with availability checks and retain iOS 18-compatible fallbacks.
- Preserve the black, purple, pink, and white Banana Corp theme and immersive fictional OS, hardware-safe controls, and supported system gestures.
- Avoid modifying mini-games unless explicitly requested. A story proposal is not authorization to change their mechanics or make them mandatory gates.
- Keep OS navigation and presentation ownership centralized in AppState; consult the current models rather than creating competing state sources.
- The Xcode project is `Banana Corp/Banana Corp.xcodeproj`, scheme `Banana Corp`. Use Xcode 26+ for the existing Liquid Glass symbols; validate supported iOS 18 and iOS 26 runtimes when available.
- Run applicable checks: `bash scripts/check-restricted-access.sh`, `bash scripts/check-act-two.sh`, `bash scripts/check-first-anomaly.sh`, `bash scripts/check-act-one.sh`, `bash scripts/check-evidence-vault.sh`, `bash scripts/check-story-content.sh`, `bash scripts/check-story-progression.sh`, `bash scripts/check-os-navigation.sh`, `bash scripts/check-home-layout.sh`, and `bash scripts/check-os-presentation.sh` on a Swift-equipped machine; run `git diff --check` and check documentation links for documentation changes.
- Author story content through the shared local catalogue described in [docs/story-content-schema.md](docs/story-content-schema.md), not independent view-local copy. Keep published version IDs and asset identities immutable, retain original versions and preserve saved evidence bytes. Neutral test fixtures must stay outside the production content bundle.
- Reuse the canonical Evidence route and existing preserved-evidence ledger; do not create another archive store or overwrite saved snapshots to match live content. Follow [docs/evidence-vault.md](docs/evidence-vault.md) for preservation eligibility, truthful comparison and explicitly authored evidence facts.
- Foundation checks can run on Linux. They do not replace Apple-SDK typechecking or simulator/device validation. Report actual results and unavailable tools accurately.

Existing build details and manual UI validation remain in [docs/banana-os-validation.md](docs/banana-os-validation.md), [docs/home-screen-validation.md](docs/home-screen-validation.md), [docs/ui-modernization-validation.md](docs/ui-modernization-validation.md), [docs/motion-interaction-validation.md](docs/motion-interaction-validation.md), and [docs/story-visual-system.md](docs/story-visual-system.md). These are technical records, subordinate to the bible for story design.

Pass 5 opening content and its approved prerequisites are documented in [docs/act-one-content.md](docs/act-one-content.md). Preserve the ECHO email’s immutable original; its read marks readiness only. Do not deliver the unknown warning, replace/remove sources, enable Assistant denial or configure Act 2 advancement as part of an opening-content refactor.

Pass 6 explicitly authorizes the initial removal/warning/denial and Act 2 handoff described in [docs/first-anomaly.md](docs/first-anomaly.md). Keep that removal at a return-to-inbox/Home boundary, distinguish read receipts from player evidence, validate saved proof before the challenge and preserve both investigation paths. Do not infer understanding from app appearance or repeat the consumed visual event. Later Act 2 scenes/act transitions require separate approval.

Pass 7 authorizes only the Act 2 content, source changes and explicit cross-app confirmation/handoff in [docs/act-two-content.md](docs/act-two-content.md). Keep transcript-only evidence honest, validate saved proof and knowledge-gated questions, and preserve the independent-corroboration route when no original was saved. Never advance Act 3 on content appearance, reveal later motives/Observer purpose, or implement the Banana Wall as a side effect of this pass.

Pass 8's [ACT3_PUZZLE_DESIGN.md](docs/ACT3_PUZZLE_DESIGN.md) distinguishes approved foundations from TBD puzzle/ending design. Keep the production Banana Wall non-completable until its challenge is explicitly approved. Never treat a development fixture as canon or a campaign bypass. Protected content must use registered resource IDs and the shared store's authorized queries; validate links both ways and retain legitimate saved evidence after live access loss.
