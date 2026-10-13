# Story implementation conventions

## Canon and scope

The approved [root game bible](../BANANA_CORP_GAME_BIBLE.md) is authoritative for story, narrative, mechanics, progression, puzzles, and endings. Pass 1 installed the supplied version 1.0 unchanged. Versions 1.1–1.3 record the progression, content and evidence mechanics authorized by Passes 2–4 without changing the plot. [Repository instructions](../AGENTS.md) govern agent work. Pass 5/version 1.4 adds the explicitly authorized opening Act 1 catalogue.

The current structure is:

1. The Perfect Product
2. Something Isn't Right
3. The Conspiracy
4. The Takeover
5. The Final Choice

The older six-phase outline is superseded. Phone interference and breaking the Banana Wall belong within the five acts. No older six-phase story document was found in the repository. Existing UI validation reports remain historical technical records and do not establish story requirements.

## Current architecture and planned responsibilities

Source paths below are relative to the repository root; the app source directory is `Banana Corp/Banana Corp/`.

| Responsibility | Current implementation | Future work (planned, not implemented) |
| --- | --- | --- |
| Shared state | AppState.swift owns StoryProgressionStore; day, VR/glitch flags and availability derive from its saved state. OS navigation/presentation remain in AppState | Approved content should integrate with this authority; do not create another story store |
| Content | StoryContentModels/Rules/Catalogue/Store provide typed offline content, validation, availability and explicit delivery. Pass 7 production JSON retains 25 opening/first-anomaly items and adds 20 Act 2 items (four with replacement versions); seven surfaces use shared readers and Assistant/VR use structured catalogue payloads | Opening copy and article/promo-to-leak gates are approved in [act-one-content.md](act-one-content.md); later content is planned and development fixtures remain tests only |
| Evidence | Existing preservedEvidence ledger, EvidenceComparison/EvidenceViews and shared preservation controls provide immutable snapshots and factual comparison | Authored clue rules, source availability and scene-specific timing remain subject to story approval |
| Progression | StoryState.swift, StoryPrerequisites.swift and StoryProgressionStore.swift provide five-act facts, deterministic conditions and guarded actions | Content-specific prerequisites, the first-loop Act 2 and explicit cross-source Act 3 handoffs are approved; later transitions and ending evaluators require story approval |
| Visual presentation | OSPresentationState.swift, OSVisualComponents.swift and AppState's explicit predicate APIs | Approved progression callers may request effects; visual modes are not acts or autonomous story triggers |
| Navigation | OSNavigationState.swift and ContentView.swift present routes from PhoneAppRoute.swift | Preserve existing centralized root behavior and per-app nested navigation |
| Persistence | StoryPersistence.swift atomically writes schema-v2 story JSON in Application Support, separately from HomeScreenLayout.swift's existing UserDefaults layout | The registered v1→v2 migration preserves prior progress; future migrations need retained save fixtures |
| Story time | StoryTime.swift separates device time, fictional timestamps and relative story-day context | Final opening clock/calendar and environmental trigger rules remain TBD |
| Regression checks | Tests/ contains Foundation evidence, content, story, navigation, layout and presentation checks | Extend progression/save fixtures with approved content rules as they are implemented |

See [the visual-system contract](story-visual-system.md) for presentation limits and restoration. Its example `hasSeenFirstGlitch` predicate demonstrates the API only; it does not approve a story trigger. Normal/subtleAnomaly/interference/compromised/critical are presentation modes, not a replacement five-stage progression system. Navigation's home/opening/active/closing phases are also unrelated to narrative acts.

## Stable IDs

For future story content, use stable, descriptive, lower-case dotted IDs: a domain, a subject, and a purpose, for example the schematic pattern `content.<subject>.<purpose>` or `puzzle.<subject>.<purpose>`. These are naming templates, not new authored content. Keep display names, localization, act placement, and layout positions separate from identity. Do not derive saved IDs from list indexes, text, timestamps, or mutable presentation state.

Give live content revisions and preserved evidence explicit, distinct identities and retain their source relationship. Once a save references an ID, preserve it or supply an approved, tested migration. Do not rename existing PhoneAppRoute raw values, including `messager`, merely to match new conventions. The existing `bananaCorp.homeScreenLayout.v1` key and route identities are already persistence contracts.

## Persistence validation

Run the existing `scripts/check-home-layout.sh` for current layout serialization/reload, normalization, duplicates, missing routes, and dock limits. Navigation and visual presentation have separate checks in `scripts/check-os-navigation.sh` and `scripts/check-os-presentation.sh`; those transient-state checks do not establish story-save correctness.

Run `scripts/check-story-progression.sh` for the implemented story contract, including real file writes across separate processes, explicit reset archives, corrupt/newer-schema write blocking, migration fixtures, event atomicity and deterministic prerequisites. See [the engine architecture](story-progression-engine.md) for current tests and limitations. Future approved content must extend these checks for prerequisite/reveal order, earned unlocks and decisions; do not invent schedules, scoring or replay policy to fill test cases.

Run `scripts/check-story-content.sh` for the shared catalogue/delivery contract. See [the content schema](story-content-schema.md) for stable versions, read-only queries, explicit read effects, offline resources and migration rules.

Run `scripts/check-evidence-vault.sh` for six-source preservation, immutable metadata, comparison facts, unavailable-source handling, duplicate prevention, separate-process reload and the added Evidence route. See [the Evidence utility](evidence-vault.md).

## Review and approval

Every future story PR should identify the affected bible sections and acts, approved design changes, reveal boundaries, save compatibility, and applicable validation. Update the bible and its change log in the same PR when approved story, mechanics, puzzle paths, progression contracts, or ending requirements change. An implementation-only refactor with no design change should say so and leave the bible intact. Report contradictions separately instead of treating current code as canon.

Explicit story approval is required before adding hidden morality scoring, trust meters/credibility formulas, alternative endings, new mandatory mini-game gates, new major characters, calendar-specific launch dates, or changing ASCENSION, DAWN, LANTERN, BLACKOUT, or Observer requirements. `[TBD]` and `[PROPOSED]` entries remain unresolved or proposed. The bible's proposed architecture/fairness defaults are not automatically implementation requirements.

## Implementation differences and remaining work

These observations do not authorize fixes or new design decisions:

- The live status bar uses the real clock immediately. The bible establishes a 9:41 opening motif and “launch tomorrow”; Pass 5 uses fictional day-1 welcome timestamps for 9:41 and narrative day 2 for “tomorrow.” A fixed-to-live clock sequence remains TBD; no fixed clock or calendar-specific launch date was added.
- `currentDay` defaults to 1 and derives from saved relative-day context. VR/glitch compatibility facts and app availability are saved, but have no automatic story triggers. Corruption level remains a cosmetic in-memory input. All fifteen routed apps, including the neutral Evidence utility, initially appear in `unlockedApps`; the article/promo content gates are implemented, but there are no app locks or mandatory elapsed days.
- Act 1 supplies ordinary content rather than activation gates. Only one article and the explicitly completed promo are required for the ECHO email; no mini-game, preview or every-app requirement exists.
- Pass 5 replaces the “BANANA VR” placeholder with the canonical Banana Vision optional product preview. Physical headset ownership is not required.
- Persistent evidence/version records, access/puzzle/route facts and an optional ASCENSION milestone now have infrastructure. Shared catalogue delivery and basic preservation/comparison UI now exist, but later narrative rules/content, Banana Wall access, LANTERN, BLACKOUT, Maya's identity puzzle, DAWN, negotiation and Observer endings remain unimplemented. No bible act or ending should be reported complete based on the existing UI or generic engine.
- Snake, Pong and XO have OS routes. Flap Flap is compiled but unrouted. The bible treats possible story integration as proposed; none is an approved mandatory gate.
- Presentation APIs have explicit caller predicates and bounded effects; they do not establish when story disturbances occur. Environmental context exposes local time/date and optional supplied weather without a weather service or location collection. Approved context triggers remain future work.

Pass 1 found no conflicting standalone story outline or prior AGENTS.md and established canon precedence. Passes 2–4 add progression/content infrastructure and Evidence. Pass 5 supplies the opening Act 1 content and shared readers, preserving launch, theme, OS navigation, home arrangement persistence, mini-games, deployment target and dependencies. Readiness does not advance the act; replacement/warning/handoff remain future work.

Run `scripts/check-act-one.sh` for the actual production opening catalogue, explicit engagement gates, reveal boundaries and separate-process story/evidence persistence. See [the inventory and contracts](act-one-content.md).

Pass 6 now implements the explicitly approved initial removal, unknown warning, denial and guarded Act 2 handoff; see [first-anomaly.md](first-anomaly.md). The earlier readiness-only observations describe Pass 5's boundary, not the current first-loop behavior. No full Act 2, later transition, calendar trigger or ending is implemented. Run `scripts/check-first-anomaly.sh` for both preserved/unpreserved paths and separate-process checkpoints.

Pass 7's [playable Act 2 contract](act-two-content.md) now implements Alex's original/replacement, personal reports, source edits/removal, Daniel/Maya/ECHO-07 leads and knowledge-gated questions. A real comparison or independent report, plus explicit synthesis, guards Act 3. Earlier observations about the remaining Act 2 work are historical. No Banana Wall, full Act 3, later handoff or ending is implemented. Run `scripts/check-act-two.sh` for both evidence paths, multi-format comparison and separate-process checkpoints.

Pass 8 adds `RestrictedAccessModels/Store/Views.swift` and the bundled schema-1 `RestrictedAccess.json`; see [the approved/TBD puzzle review](ACT3_PUZZLE_DESIGN.md). AppState owns an authorizer over the existing progression store. Content may declare an optional protected-resource ID and is gated at delivery, not only presentation. The Browser exposes only the approved locked Act 3 entry; no actual breach or research/ending challenge is implemented. Save schema remains 2. Run `scripts/check-restricted-access.sh` for fixtures, references, authorization, completion/reload and Release exclusions.
