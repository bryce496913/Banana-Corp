# Act 3 puzzle and restricted-access foundation

**2026-10-14 update:** the user explicitly approved the Banana Wall cross-reference and scoped reward. Bible v1.8 and [banana-wall-implementation.md](banana-wall-implementation.md) supersede the historical non-completable production entry described below. The retired pending descriptor remains inert; later research and ending puzzles remain TBD.

The [root game bible](../BANANA_CORP_GAME_BIBLE.md) is canonical. Pass 8 authorizes infrastructure and the initial locked Banana Wall entry, **not its solution or the full Act 3 revelations**. Acts 1–2 already have the [opening](act-one-content.md), [first anomaly](first-anomaly.md) and [Act 2](act-two-content.md) contract tests. Apple-SDK/simulator validation remains unavailable on this Linux workspace; that limitation is not evidence of runtime acceptance.

## Approved canon versus unresolved design

| Established canon | What remains TBD / awaiting story approval |
| --- | --- |
| Act 3 reaches beyond the Banana Wall and investigates restricted research | Exact breach challenge, inputs, credentials, ciphers, steps, clue ordering and success conditions |
| Research connects MIRROR, Project ECHO, neural influence and autonomous behavior | Full research documents, access graph, scripts and concrete puzzle paths |
| Maya's recording leads to ASCENSION; Daniel's complicity and Observer context emerge in Act 3 | Recording delivery, exact research access requirements and full scene timing |
| LANTERN is emergency safety access, not a guaranteed shutdown/cure | Its access puzzle and precise milestone prerequisites |
| BLACKOUT requires Root Authorization, Neural Signature, Deployment Channel and dependency-warning confirmation | Individual puzzle solutions, recovery/access details and Maya's exact BLACKOUT outcome |
| DAWN uses Maya's baseline/three-note identity, LANTERN, Assistant cooperation/separation and stabilization | Notes/baseline values, answer format, cooperation/separation conditions and stabilization puzzle |
| M-01: archived personal webpage; M-02: lab-photo metadata; M-03: Assistant diagnostic log | Fragment values and concrete acquisition/assembly rules |
| ASCENSION is adoption/synchronization/harvesting; 87% is Act 4's dramatic milestone | Increments, timing and triggers; no real-time countdown is approved |
| Observer clues and session refusal form an optional secret path | Missing clue definitions, concrete unlock chain and wider simulation implications |
| Negotiation has successful/deceptive outcomes; evidence/credibility matter | Branch conditions, challenges and thresholds; no trust/morality/credibility formula is approved |

None of these open decisions is resolved by neutral test fixtures. Ending requirements and character chronology remain unchanged.

## Production entry authorized by this pass

The existing Browser is a canonical research surface and is selected for the entry presentation. After the approved Act 2 handoff, `resource.banana_wall` appears only in Act 3 with the saved cross-app confirmation. Opening it shows a themed corporate barrier, Access required, an honest unavailable-challenge message, native Back and the existing fictional Home control.

Its descriptor references `puzzle.banana_wall.pending_design`. That **non-canonical pending-design placeholder** has an awaitingApproval rule, no inputs, answer, hints or success effects. Production cannot submit or complete it. Even injected historical solved/access facts cannot unlock a resource requiring an unapproved puzzle. This prepares future unlocked rendering without pretending a test token is the Banana Wall solution. The exact approved challenge should get its own deliberate design/ID review before replacing the pending definition.

The only production descriptor is the Banana Wall. No LANTERN, BLACKOUT, DAWN, ASCENSION or Observer challenge/resource is authored or automatically achievable. No major Act 3 content, new clue, password, hidden ending detail or restricted research scene is introduced.

## Framework and content contract

- `RestrictedAccessModels.swift` defines typed resource kinds (web page, memo, technical report, email, diagnostics, security notice, access record, project archive), visibility, act, discovery/unlock conditions, required access/puzzle and linked content IDs. Lock state is computed, never another saved Boolean.
- The bundled `RestrictedAccess.json` is schema 1. Loader validation rejects unknown schema fields/kinds, duplicate/invalid IDs, undeclared references, invalid input/choice/rule definitions, self-producing/cyclic puzzle prerequisites and executable/unknown effects. Unapproved rules cannot have answers, inputs, hints or success effects.
- A puzzle has stable ID, title/instructions, available act, declarative requirements, typed inputs, validation rule, named success event, closed success effects and optional hints. Exact-field matching supports explicit trim/case normalization and bounded input. It is sufficient for neutral tests and future approved simple challenges; additional rules/formats require review, not view-local code.
- `RestrictedAccessStore` delegates all narrative facts to the existing `StoryProgressionStore`. It validates linked sources bidirectionally before access. It does not load a second story save, advance acts, run timers, perform real authentication or contact a network.
- Story content may declare optional `restrictedResourceID`. The content loader validates the registry; content/resource links must agree. Available lists, unread counts, live/original version lookup, read, preservation and engaged receipts all enforce authorization. Missing authorizers, references or resources fail closed. Raw catalogue definitions are implementation data, not an authorized player query API.
- Research formats reuse the existing structured email/web-block/diagnostic payloads, timestamps, source metadata and immutable versions. Resource kinds classify the protected material without reducing every document to one body string. Only neutral research-format fixtures are added in this pass.
- Legitimately preserved snapshots remain independent of later live access. When a current resource becomes inaccessible, comparison says so; it never reconstructs or refreshes a saved copy.

## Inputs, success, failure and recovery

`PuzzleSubmissionResult` distinguishes completed, alreadyCompleted, rejected (unknown, inaccessible, awaiting approval, invalid fields, wrong answer, inconsistent completion) and saveFailed. The solver checks act/requirements, input identities/bounds and declared rules, then atomically commits puzzle completion, the named success event and explicitly authored access/milestone/Assistant/Observer/route facts.

Repeat success does not write or replay effects. A partial completion marker or unresolved references fail closed rather than repairing an unknown save. Write failure leaves all facts unchanged for retry. Incorrect inputs never mutate progress, accumulate a hidden score, lock the player out or reset other puzzles. Clear/retry and hint-display position are transient UI state; reset does not erase earned completion. Existing explicit new-game reset still archives the prior campaign.

Save schema remains 2. The existing v1→v2 migration preserves solved puzzles, access, milestones, Assistant facts/cooperation, route prerequisites, Observer clues and events. No new persistence store or migration is required for this pass; approved future ID/contract changes still need save review.

## Later prerequisites and independence

Existing facts can represent Banana Wall breach/research access through access and milestone IDs; LANTERN/BLACKOUT through explicitly approved future facts; DAWN through route facts plus named interactions/evidence and explicit cooperation; ASCENSION through its existing validated optional milestone; Observer clues through their separate optional set. This capability does not award or finalize any of those facts.

Assistant cooperation remains notEstablished/cooperating/separated, earned through approved explicit conditions. A puzzle can record a named interaction, but no test or production definition here establishes late-game cooperation or activates DAWN. Hidden resource visibility and independent Observer storage keep optional clues outside mandatory Act 1–3 conditions. No new Observer clue is invented for the campaign.

## Development fixtures and release boundary

The DEBUG-only isolated Settings demo decodes a clearly labeled neutral definition from the model layer and owns a fresh in-memory progression store. Its token is not stored in view code and is not the Banana Wall answer. Success cannot grant campaign access. A Release build contains neither the demo entry/view/factory nor the development loader API.

`Tests/Fixtures/restricted-access-fixtures.json` and `restricted-content-fixtures.json` are unbundled neutral tests: a public instruction, protected memo, exact-field/choice inputs, optional clue and late synthetic resource. Production loading rejects developmentFixture catalogues even in Debug. Release compilation also checks rejection and absence of demo strings. This is fictional game access control, not cryptographic protection against inspecting/modifying a local app bundle.

## Proposed next design review (not implemented)

- **Proposed surfaces:** Browser barrier/research index, Settings system access and Assistant review/hint interactions. Browser entry is approved now; the other puzzle roles remain proposals until explicitly chosen.
- **Expected future actions:** Find the approved cross-app clues, inspect their real versions, enter the approved inputs, deliberately submit, receive factual feedback and read the newly authorized resource. Do not infer understanding from a list appearing.
- **Proposed fairness:** Reachable clue references, recoverable missed evidence, accessible text equivalents of audio/visual clues, optional escalating hints and no mandatory mini-game mastery. The bible marks these fairness defaults proposed; this framework does not silently make them story requirements.
- **Approval required:** Exact Banana Wall puzzle/clues/solution, resource graph and unlock ordering; later research scripts/reveals; passwords/ciphers/music values; LANTERN/BLACKOUT/DAWN/ASCENSION/Observer conditions; Assistant cooperation/separation; negotiation and endings. Update the bible and affected content/contracts/tests in the same approved story PR.

## Automated and manual validation

Run `bash scripts/check-restricted-access.sh` plus the nine existing checks. The new checks cover locked/direct source access, declarations and prerequisites, wrong/missing/oversized input, normalized retry, atomic/idempotent success, access propagation, saved protected evidence, separate-process reload, v1 migration, corrupt/write-failed saves, late/optional independence and non-completable production/release fixture rejection.

On an Apple-SDK machine, build with Xcode 26+ and test iPhone simulators on iOS 18 and iOS 26:

- [ ] Acts 1–2 play normally; no Banana Wall or hidden late/Observer titles appear early.
- [ ] After explicit Act 3 handoff, Browser shows Banana Wall. Entry has clear unavailable-challenge messaging, no guessable/editable password or production submit bypass, and working Back/Home.
- [ ] Debug isolated demo: wrong input, hint, clear/retry, correct submit and repeated success work; return to the campaign and verify its access is unchanged.
- [ ] Release has no debug entry or fixture; the production gate stays locked.
- [ ] Relaunch, repeated navigation, preserved evidence, customized Home, mini-games, Reduce Motion, Dynamic Type, VoiceOver and hardware gesture regions remain usable.
- [ ] Future approved protected content stays absent from list previews, badges and direct detail entry until authorization; archives remain authentic after live access loss.

### Actual results — 2026-10-13

All ten Foundation suites passed with official Swift 6.2, language mode 5 and warnings as errors in a network-disabled container with read-only source access. The access suite also passed after the final inconsistent-completion guard test and corrected Release binary scan: default/Release loading rejected development catalogues, and isolated demo strings were absent from the Release executable. New puzzle/access/optional-clue/evidence state reopened in a separate process; existing Act 1–2, content, evidence and progression relaunch checks passed. The v1 migration, wrong-input retry, atomic failure and non-completable production tests passed. Navigation covered 1,500 cycles/14 swipe cases; layout covered 185 moves; presentation checks passed.

All 48 app Swift files parsed in Debug and Release. Project references/unique IDs and fixture exclusion were checked; all 49 local Markdown links resolved. All 45 existing story items remain unchanged, as do mini-game sources, Home layout/routes, launch/splash, iOS 18 deployment target and save schema. Whitespace and shell syntax checks passed.

`xcodebuild` and `xcrun` are unavailable. No Apple-SDK build/typecheck or iPhone simulator rendering, VoiceOver, haptic or native gesture validation was possible. Syntax parsing and Foundation checks do not establish those results; the manual checklist above remains outstanding.
