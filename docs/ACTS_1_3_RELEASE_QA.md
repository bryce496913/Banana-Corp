# Acts 1–3 release QA and Act 4 readiness

Date: 2026-10-14. Authority: [game bible](../BANANA_CORP_GAME_BIBLE.md). Baseline: merged Part Three tree `b50ba8584b384f42fda7d02ddfffd358ae7cf640`. This is an integration/progression pass; the full Act 4 narrative is not implemented.

## Exact completion contract

`ActThreeHandoffContract` is centralized in [StoryPrerequisites.swift](../Banana%20Corp/Banana%20Corp/StoryPrerequisites.swift). Required milestone suffixes (prefix `milestone.act3.` except breach):

| Required fact | Meaning |
| --- | --- |
| `milestone.banana_wall.breached` | Approved Wall success |
| `restricted_research_opened` | First expanded restricted research opened |
| `mirror_origins_discovered` | Original interpretation purpose |
| `mirror_echo_relationship_established` | ECHO lineage connected |
| `neural_influence_evidence_discovered` | Observed capability |
| `echo_autonomy_established` | Explicit two-source autonomy connection |
| `ascension_purpose_uncovered` | Plan knowledge, not takeover state |
| `energy_harvesting_evidence_discovered` | Transfer/growth evidence |
| `public_restricted_contradiction_confirmed` | Explicit comparison against public sources |
| `daniel_involvement_discovered` | Contribution record |
| `daniel_concealment_discovered` | Disclosure record |
| `maya_recorded_guidance_reviewed` | Transcript finished |
| `observer_connection_discovered` | Mandatory participation discovery |
| `investigation_concluded` | Source-linked conclusion explicitly opened |

Also required: solved `puzzle.banana_wall.review_cross_reference`, `access.banana_wall.breached`, Wall success event, `event.act3.autonomy_connected`, `event.act3.public_restricted_connected`, exact Maya guidance/conclusion version reads and their completed read events. Each missing fact is tested independently. Optional preserved evidence, Observer clue IDs, extra apps and late Assistant questions are excluded. No unnecessary ordering is added between independent optional actions.

Eligibility also validates the entry resource against a read-only prospective Act 4 state; missing/revoked references fail closed without changing saved state. Eligibility only offers **Begin the resistance investigation** (`story.advance.act4`). `StoryContentStore.beginActFour()` delegates to the existing consecutive, atomic `advanceAct`. Read-only queries and opening every source never advance the act. Retry after a failed save is safe; repeated entry through the shared API is unchanged. Act 5 remains unconfigured.

## Entry and story coverage

The new `content.act4.entry` / `version.act4.entry.v1`, protected by `resource.act4.entry`, becomes visible only in Act 4 after completion. Its objective is to investigate resistance-capable people/infrastructure, preserve the evidence, and keep Maya's absence distinct from an archived transcript. It gives no ASCENSION progress, takeover animation, countermeasure, DAWN/BLACKOUT/LANTERN access, rescue, cooperation or hidden-ending eligibility.

[Complete Act 3 inventory](act-three-content-inventory.md): 24 immutable records. Earlier approved [Act 1](act-one-content.md), [first anomaly](first-anomaly.md), [Act 2](act-two-content.md), [Wall](banana-wall-implementation.md) and [Parts One](act-three-part-one.md), [Two](act-three-part-two.md), [Three](act-three-part-three.md) remain the narrative contracts. All 69 prior source definitions/snapshot bytes remain unchanged. One minimal Act 4 entry is added. The launch flow, OS navigation, mini-games and UI theme are unchanged.

## Build/device matrix

| Configuration | Device/runtime actually available | Status | Evidence/limitation |
| --- | --- | --- | --- |
| Foundation regression, Swift 5 language mode | Linux x86_64, Swift 6.2.4 | PASS | All 16 offline suites; read-only source/no network |
| Debug/Release syntax and project structure | Linux; no Apple SDK | PASS | Syntax/project checks only; not iPhone builds |
| Debug/Release native app build | No Xcode/Apple SDK | NOT RUN | BLOCKED by platform availability |
| iOS 18 simulator playthrough | No simulator runtime available | NOT RUN | No Apple tooling on this host |
| iOS 26 simulator playthrough | No simulator runtime available | NOT RUN | No Apple tooling on this host |
| Physical iPhone | None connected/authorized | NOT RUN | No device result claimed |
| Native launch/splash, gestures, safe areas, scrolling, media interface, VoiceOver | No Apple device/simulator | NOT RUN | Must be assessed on Apple platforms |
| Instruments/native memory and long-document rendering | No Apple profiler | NOT RUN | Model timing is not device performance |

## Completed model paths and regression coverage

`bash scripts/check-acts-release.sh` runs the full ordinary delivery/progression path from fresh Act 1 to Act 4 entry. No debug replay, injected milestones or app launch bypass is used in primary paths. Negative tests construct partial/legacy states separately and never substitute for campaign coverage.

| Path | Early email/video proof | Later research preservation | Result |
| --- | --- | --- | --- |
| Neither | Neither saved | Skipped new Part Two/Three preservation | PASS (model) |
| Email | Authentic original email | Skipped new Part Two/Three preservation | PASS (model) |
| Video | Authentic Alex original | Research snapshots preserved | PASS (model) |
| Both | Both originals | Research snapshots preserved | PASS (model) |

All pass through introduction, removal/warning/denial, explicit Act 2 entry, Alex replacement, reports/official response, Daniel/Maya/ECHO-07, explicit Act 3 entry, legitimate clue-based Wall solve, MIRROR/ECHO/influence, explicit autonomy, ASCENSION/energy, public contradiction, Daniel concealment, Maya guidance, mandatory Observer connection, conclusion and explicit Act 4 entry. Independent reporting preserves the no-video-proof route. Optional hidden clues may be absent; a separate optional-fact case does not change eligibility. Late Assistant questions are first completed in reverse valid order in a separate deferred-question state; a missing late question does not block handoff. Early content attempts fail without side effects; repeated reads and puzzle submissions do not duplicate awards.

Fifteen exact file-store reopen checkpoints per path (**60 total**), plus a separate executable process, verify state, snapshots, access, puzzle completion, messages/notification count, replacement version, Observer discoveries and Assistant facts. Act 4 entry read and repeated entry survive process restart. Every required handoff milestone/event and conclusion read is independently removed in negative tests; no partial state advances. Failed persistence grants no Act 4 access and retry succeeds.

Schema 2 does not change. A pre-entry saved Act 3 conclusion restores exact facts/snapshots and enters without resetting progress or replaying sources. Earlier journey checkpoints cover pre-research states and the existing schema-1/2 Wall migration checks remain active. No real archived player save corpus was supplied; corpus migration QA is NOT RUN. Optional-clue independence is tested with fixture/retained facts; actual production hidden-clue collection is NOT RUN because no approved playable optional-clue catalogue is implemented. This pass does not invent it.

## Performance finding and repair

The sustained passive query workload exposed repeated full-state/resource validation for unchanged lists. The baseline 1000-cycle workload remained running for minutes and was stopped; no completed baseline timing or ratio is claimed. The shared content store now retains at most one value snapshot and one result per surface, invalidated on state equality changes or the restricted authorizer's content-reference revision. It is a transient query cache, not a saved state store or progression authority. Authority rebinding/revocation and alternative-state queries are regression tested to prevent stale protected results.

Corrected initial runs completed 1000 cycles in approximately **0.23–0.42 seconds** per path. The final run, including fail-closed entry-authorizer validation on each eligibility query, completed in **1.96–2.22 seconds** per path on this Linux host. Each cycle queries ten unread counts, known Observer references and handoff eligibility, without saved-state mutation. This is model timing, not a frame-rate or native memory guarantee.

Static inspection: AppState loads catalogues once at construction and owns one story/content/access set; callbacks use weak references. No new timer, observer, background loop or repeated catalogue load was introduced. Cache retention is bounded. Native allocation growth, Evidence Vault scrolling latency and long-document layout remain NOT RUN; no speculative rewrite was made.

## Native QA preparation and remaining work

The existing [UI journey test](../Banana%20Corp/Banana%20CorpUITests/ActsJourneyTests.swift) now continues through all Act 3 sources, synthesis, transcripts and the explicit Act 4 entry, using normal controls. Its recording helper supports the actual three/five-section transcripts. [The dedicated runner](../scripts/validate-acts-journey.sh) selects the renamed test, creates owned fresh simulators for four paths in Debug/Release, rejects skipped tests, and checks a terminal Act 4 save without ASCENSION, optional clues or route unlocks. This preparation is **NOT RUN** on Apple SDKs; syntax parsing cannot establish native compilation or test reliability.

Run the runner with installed iOS 18 and 26 runtime/device-type IDs on Xcode 26+, retain xcresults/screenshots/save JSON, and manually review navigation/scrolling/safe areas/Home gestures, game controls, modal dismissal, accessibility, transcript identity and Evidence. Do not mark these rows PASS until actually executed.

Known limitations: Apple build/device QA remains BLOCKED; native presentation defects cannot be excluded. No automated progression bug remains known after the final passing run. Open design decisions remain the full Act 4 resistance/takeover sequence, ASCENSION progression timing, LANTERN/BLACKOUT/DAWN puzzle details, rescue, negotiation/Observer eligibility, precise science/chronology, character outcomes and wider-world ontology. Entry does not settle them.

Readiness: **PASS (model)** for the complete Acts 1–3 journey and controlled Act 4 start; **BLOCKED** for claiming an Apple-platform release. The initial objective is ready for subsequent narrative implementation, with Maya still missing and no takeover/countermeasure effects fired.

## Final automated result

**PASS:** all 16 offline suites passed across the final regression runs; the authorized transition set is explicitly asserted as Acts 2, 3 and 4, while Act 5 remains absent. Historical closed-transition assertions were updated to the new approved contract; early-stage rejection and every missing completion requirement remain tested. Catalogue declaration errors and stale pre-handoff test assumptions encountered during development were corrected and retested. **PASS:** 69 immutable earlier definitions, project/resource structure, all 51 Debug/Release Swift source syntax checks, shell syntax, 131 local Markdown links and whitespace checks. **NOT RUN:** native builds/tests, physical devices, Instruments and real archived-save corpus. No Apple-platform completion is inferred from these results.
