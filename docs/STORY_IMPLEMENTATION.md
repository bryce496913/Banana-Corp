# Story implementation conventions

## Canon and scope

The approved [root game bible](../BANANA_CORP_GAME_BIBLE.md) is authoritative for story, narrative, mechanics, progression, puzzles, and endings. It is installed unchanged from the supplied version 1.0 document. [Repository instructions](../AGENTS.md) govern agent work. This pass establishes documentation conventions only; it adds no game content or runtime behavior.

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
| Shared state | AppState.swift owns day, VR/glitch flags, corruption level, unread counts, app availability, OS navigation and presentation | Approved story facts and progression should integrate with this authority; do not create an independent story store |
| Content | Eleven non-game app views contain placeholder presentation, not a narrative content library | Dedicated content models under the app source directory, separate from views; exact types/files and schemas require an implementation task |
| Progression | No five-act engine, puzzle dependency model, or ending evaluator exists | Centralized progression rules under the app source directory, integrated through AppState; exact contracts remain subject to bible approval |
| Visual presentation | OSPresentationState.swift, OSVisualComponents.swift and AppState's explicit predicate APIs | Approved progression callers may request effects; visual modes are not acts or autonomous story triggers |
| Navigation | OSNavigationState.swift and ContentView.swift present routes from PhoneAppRoute.swift | Preserve existing centralized root behavior and per-app nested navigation |
| Persistence | HomeScreenLayout.swift stores customized route placement in UserDefaults | Story save model, schema version, migrations and storage location are not implemented or decided by this pass |
| Regression checks | Tests/ contains standalone Foundation navigation, layout and presentation checks | Add meaningful progression/save checks when those components are implemented |

See [the visual-system contract](story-visual-system.md) for presentation limits and restoration. Its example `hasSeenFirstGlitch` predicate demonstrates the API only; it does not approve a story trigger. Normal/subtleAnomaly/interference/compromised/critical are presentation modes, not a replacement five-stage progression system. Navigation's home/opening/active/closing phases are also unrelated to narrative acts.

## Stable IDs

For future story content, use stable, descriptive, lower-case dotted IDs: a domain, a subject, and a purpose, for example the schematic pattern `content.<subject>.<purpose>` or `puzzle.<subject>.<purpose>`. These are naming templates, not new authored content. Keep display names, localization, act placement, and layout positions separate from identity. Do not derive saved IDs from list indexes, text, timestamps, or mutable presentation state.

Give live content revisions and preserved evidence explicit, distinct identities and retain their source relationship. Once a save references an ID, preserve it or supply an approved, tested migration. Do not rename existing PhoneAppRoute raw values, including `messager`, merely to match new conventions. The existing `bananaCorp.homeScreenLayout.v1` key and route identities are already persistence contracts.

## Persistence validation

Run the existing `scripts/check-home-layout.sh` for current layout serialization/reload, normalization, duplicates, missing routes, and dock limits. Navigation and visual presentation have separate checks in `scripts/check-os-navigation.sh` and `scripts/check-os-presentation.sh`; those transient-state checks do not establish story-save correctness.

When story persistence is implemented, test round-trip/relaunch recovery of approved facts, stable content IDs, preserved evidence versions, earned unlocks, and decisions. Verify idempotent event delivery, prerequisite/reveal order after reopening, corrupt/missing-save handling, and any migration against old save fixtures. Test time-zone/clock/elapsed-event behavior only against approved rules; do not invent schedules, scoring, or replay policy to fill test cases.

## Review and approval

Every future story PR should identify the affected bible sections and acts, approved design changes, reveal boundaries, save compatibility, and applicable validation. Update the bible and its change log in the same PR when approved story, mechanics, puzzle paths, progression contracts, or ending requirements change. An implementation-only refactor with no design change should say so and leave the bible intact. Report contradictions separately instead of treating current code as canon.

Explicit story approval is required before adding hidden morality scoring, trust meters/credibility formulas, alternative endings, new mandatory mini-game gates, new major characters, calendar-specific launch dates, or changing ASCENSION, DAWN, LANTERN, BLACKOUT, or Observer requirements. `[TBD]` and `[PROPOSED]` entries remain unresolved or proposed. The bible's proposed architecture/fairness defaults are not automatically implementation requirements.

## Implementation differences recorded by this pass

These observations do not authorize fixes or new design decisions:

- The live status bar uses the real clock immediately. The bible establishes a 9:41 opening motif and “launch tomorrow”; its relationship to real time/story calendar remains TBD. No fixed clock or launch date was added.
- `currentDay` defaults to 1 and existing flags/corruption values are in-memory scaffolding. They do not implement acts, mandatory elapsed days, trust/morality scoring, or persistent campaign progression. All fourteen routed apps initially appear in `unlockedApps`; no canonical clue gates are implemented.
- App shells describe device activation/registration/calibration limits, but there is no activation progression. Those placeholders must not become new story prerequisites by inference.
- VRExperienceView currently displays “BANANA VR”; the canonical product is Banana Vision. This copy difference is recorded, not changed in this documentation pass. Real headset ownership is not a canon requirement.
- Narrative content, evidence preservation, Banana Wall access, ASCENSION, LANTERN, BLACKOUT, Maya's identity puzzle, DAWN, negotiation, and Observer endings are not implemented. No bible act or ending should be reported complete based on the existing UI.
- Snake, Pong and XO have OS routes. Flap Flap is compiled but unrouted. The bible treats possible story integration as proposed; none is an approved mandatory gate.
- Presentation APIs have explicit caller predicates and bounded effects; they do not establish when story disturbances occur. Environmental context exposes local time/date and optional supplied weather without a weather service or location collection. Approved context triggers remain future work.

No conflicting standalone story outline or existing AGENTS.md was found. The visual-system document now explicitly defers story design to the bible; existing build and UI validation instructions are retained. Runtime sources, launch flow, UI, navigation, persistence, dependencies, and project settings are unchanged.
