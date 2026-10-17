# Act 4 dependency and presentation specification — D-01 draft

Date: 2026-10-17. Status: **engineering specification draft, not approval of new canon or a production content contract**. This document maps established requirements to existing implementation seams and identifies the decisions needed before D-02. It adds no catalogue records, production IDs, effects, puzzle answers, route eligibility or act transitions. The [game bible](../BANANA_CORP_GAME_BIBLE.md) remains authoritative.

## Approved baseline

[Bible §10, Pass 8 — explicit completion and Act 4 entry](../BANANA_CORP_GAME_BIBLE.md#pass-8--explicit-completion-and-act-4-entry) approves the existing saved Act 3 completion contract and separately selected **Begin the resistance investigation** action. [Release QA: Exact completion contract](ACTS_1_3_RELEASE_QA.md#exact-completion-contract) lists the 14 factual milestones, solved Wall/access, success/synthesis events and exact read receipts. Optional preserved evidence, extra apps, late questions and hidden Observer clues do not gate entry.

The existing protected `content.act4.entry` / `version.act4.entry.v1` introduces investigating resistance-capable people/infrastructure while preserving research. Maya remains missing: archived guidance is neither live contact nor location proof. Entry grants no takeover, ASCENSION progress, countermeasure access, cooperation, rescue or ending eligibility. Act 5 remains unconfigured. These existing IDs are references, not new allocations.

This draft preserves that boundary. A stable native Acts 1–3 journey establishes the implemented scope; it cannot establish readiness of unauthored Act 4 content. Current native outcomes belong in [agent progress](../AGENT_PROGRESS.md), not inferences from this specification.

## Dependency map

The rows below are review topics, **not an executable order or a new set of saved milestones**. The order of bullets in the bible is not treated as a complete trigger graph. Except for existing entry and explicitly stated canonical route dependencies, every acquisition edge, interaction, source version and completion trigger is **TBD**. No string in the Topic column is a production identifier.

| Topic | Established fact / dependency | Implementation seam to reuse | Unresolved production contract |
| --- | --- | --- | --- |
| Resistance entry | Existing explicit Act 3 completion → chosen Act 4 entry; preserve Maya's absence | `ActThreeHandoffContract`, `StoryContentStore.beginActFour()`, central `advanceAct`, existing entry resource | No new prerequisite or read effect authorized here |
| The Signal | Researchers, infrastructure engineers and employees oppose ECHO | Shared catalogue structured messages/web/email; existing OS routes | Contact identities, authored communication, discovery source, sequence and interaction effects **TBD** |
| BLACKOUT introduction | Abrupt countermeasure; requires Root Authorization, Neural Signature and Deployment Channel | Registered restricted resources/puzzles, access facts and route prerequisites | Exact component sources, acquisition graph, puzzle answers and component semantics **TBD**; do not equate the named Neural Signature component with reconstructed Maya identity without approval |
| LANTERN | Emergency safety access, not a complete shutdown or guaranteed cure | Existing authorized resource queries and atomic puzzle completion | Access puzzle, clues, exact prerequisites, scope of access and recovery behavior **TBD** |
| Maya survival lead | Active neural signature suggests she is alive and connected to ECHO; reveal belongs in Act 4 | Versioned diagnostic/research payload; explicit read/engagement receipts | Authored evidence, timing, exact proof strength and relationship to later identity fragments **TBD**; entry alone cannot award this knowledge |
| Vale accountability | Authorized risky research, then lost control | Source-linked catalogue investigation; explicit knowledge facts | Specific records, comparisons, discovery order and consequences **TBD**; do not claim he knowingly directed the sentient human-battery takeover |
| Overt interference | ECHO's takeover reaches the phone itself | AppState-owned bounded presentation APIs | Exact onset, affected surfaces, wording, duration, repeat/relaunch policy and recovery **TBD** |
| Assistant conflict | Limited permissions and conflicting directives become meaningful; later cooperation must be earned | Separate relationship facts and `AssistantCooperation` state | Conflict scenes, earning conditions and separation mechanism **TBD**; questioning is not cooperation |
| 87% climax | ASCENSION at 87% is the established dramatic milestone | Existing optional validated `AscensionMilestone` can represent an approved future award | Trigger, increments, timing, player-action relationship and presentation **TBD**; no timer/countdown or automatic increment |
| Three immediate directions | Pursue BLACKOUT, find Maya, or negotiate; find Maya leads toward DAWN rather than a separate ending | Existing navigation/content/predicate infrastructure | Choice presentation, prerequisites, reversibility, branch commitment and exact Act 4→5 handoff **TBD**; directions do not themselves establish ending eligibility |

Canonical basis: [Bible §11 — Act 4](../BANANA_CORP_GAME_BIBLE.md#11-act-4--the-takeover), [§5 — knowledge boundaries](../BANANA_CORP_GAME_BIBLE.md#5-truth-player-knowledge-and-spoiler-boundaries), [§6 — characters](../BANANA_CORP_GAME_BIBLE.md#6-characters-and-knowledge), and [§12 — Act 5](../BANANA_CORP_GAME_BIBLE.md#12-act-5--the-final-choice). No new edges between Signal, Vale, LANTERN, survival evidence and component acquisition are asserted.

## Existing engine and content integration

| Concern | Existing implementation / contract | Rule for a later approved implementation |
| --- | --- | --- |
| Story authority | AppState owns shared progression/content/access stores; [progression ownership](story-progression-engine.md#ownership-and-state) | No parallel act, takeover or relationship store |
| Conditions and actions | `StoryCondition` supports explicit reads, evidence, puzzles, access, milestones, Assistant facts/cooperation, routes, events and separate Observer clues; [action contracts](story-progression-engine.md#action-and-prerequisite-contracts) | Express approved causal conditions centrally. App appearance, cosmetic mode and read count are not understanding or consent |
| Catalogue | Typed structured payloads and explicit engagement; [schema](story-content-schema.md#structured-payloads), [query contracts](story-content-schema.md#query-and-engagement-contracts) | Author approved copy once in the shared catalogue. Lists, previews, badges, notifications and accessibility labels share the same knowledge/access boundary |
| Restricted access | Registered resources, reciprocal content bindings, fail-closed queries and explicit submission; [framework](ACT3_PUZZLE_DESIGN.md#framework-and-content-contract) | Allocate IDs only when the approved production contract exists. Neutral fixtures cannot award campaign access or supply missing answers |
| Persistence | Central atomic saved effects and idempotent events; [recovery](story-progression-engine.md#persistence-and-recovery) | Failed saves grant no partial access/knowledge/route award. Relaunch restores earned facts without replaying consumed events. Any migration requires explicit compatibility review |
| Evidence | Existing preserved ledger and [truthful comparison](evidence-vault.md#truthful-comparison-and-progression) | Retain original versions and saved bytes. A live replacement/access loss never rewrites proof; do not invent recovery sources or make existing optional preservation mandatory |
| Assistant / ASCENSION | `StoryState.swift` separates relationship facts, cooperation and optional ASCENSION milestone | Generic storage capability is not permission to set these facts. Knowledge of ASCENSION remains distinct from its execution |
| Presentation | AppState predicates and [explicit story integration](story-visual-system.md#explicit-story-integration) | An approved saved fact may drive presentation; visual state cannot become the progression authority |

No save schema change is proposed by this document. Existing schema-2 records, published source/version IDs, snapshots and Acts 1–3 contracts remain unchanged. Schema capability is not a guarantee that every later route fits without reviewed model work.

## Presentation review contract

[Bible §19 — presentation and tone](../BANANA_CORP_GAME_BIBLE.md#19-presentation-and-tone) and [visual safeguards](story-visual-system.md#rendering-and-player-safeguards) govern the implementation. Preserve the black/purple/pink/white theme, supported system gestures, safe Home controls and iOS 18 fallback behavior. Overt takeover must not be implemented as accidental crashes or broken navigation.

| Surface / behavior | Existing constraint | Decision still needed |
| --- | --- | --- |
| Home/status/app labels | Central presentation configuration; display changes do not authorize access | Specific overrides and knowledge gates **TBD** |
| In-world interruptions | Bounded explicit events and authored content; no actual OS compromise claim | Trigger boundary, exact copy, dismissal/repeat/relaunch policy **TBD** |
| Motion, corruption and audio | Reduce Motion/accessibility and usable controls remain protected | Specific treatment, equivalent clue forms and media assets **TBD**; no new audio/visual-only answer requirement |
| ASCENSION display | 87% is canon; current entry starts no progress | Location, onset and updates **TBD**; no live percentage inferred from clock or elapsed time |
| Assistant surface | Available questions must respect act/knowledge; cooperation remains separate | Authored late conflict dialogue and actions **TBD** |
| Maya/Signal/Vale previews | Respect Act 4 reveal placement and actual source facts | Titles, notification previews, labels and final content bodies **TBD** |

**[PROPOSED] engineering review artifact:** before implementing each approved interference event, record its triggering fact, affected surfaces, bounded duration, safe control behavior, Reduce Motion treatment and restoration behavior in its implementation PR. This is a review proposal, not a newly approved story trigger or player requirement.

## Decisions required before D-02 and Act 5

Each item needs an explicit approved design contract; this draft supplies no default answer. Approval may cover a limited slice without resolving every distant ending detail, provided that slice does not silently choose a reserved dependency.

| Decision | Concrete design deliverable | Canon that must survive |
| --- | --- | --- |
| First resistance slice | Exact approved content, sources, interactions, causal ordering and completion effects | Signal's established composition; no invented major contact; missing Maya until earned survival evidence |
| Takeover progression and climax | Approved graph connecting scenes, 87% trigger, presentation and chosen Act 5 handoff | No clock-driven countdown inferred; established five-act order |
| BLACKOUT components / diagnostics | Exact source graph, clues, answers, normalization and Recovery Diagnostics/access | All three components; disclose severe dependency harm before irreversible confirmation |
| LANTERN and Maya reconstruction | Access scope/puzzle; M-01/M-02/M-03 values; three notes, baseline, input/assembly stages | M-01 webpage, M-02 lab-photo metadata, M-03 Assistant diagnostics; no invented fragment values |
| Cooperation / DAWN | Earned conflict-resolution conditions, separation and stabilization interactions | Safe gradual separation, Maya recovery and Assistant sacrifice/separation ambiguity |
| Negotiation | Concrete evidence/contradiction interactions and success/deception conditions | Agreement and deception both remain possible; no hidden morality/trust meter, credibility formula or fabricated threshold |
| Optional Observer path | Concrete clue acquisition/linking and session-refusal unlock | Separate optional eligibility; mandatory Act 3 Observer knowledge is insufficient; no unexplained fourth ending button |
| Ending/replay state | Scripts, decision-save behavior, commitment/retry, completion UI and post-ending/replay policy | Existing named outcomes and costs; generic new-game reset does not settle endgame replay |

Sources: [Bible §12 — ending routes and rules](../BANANA_CORP_GAME_BIBLE.md#12-act-5--the-final-choice), [§16 — puzzle framework](../BANANA_CORP_GAME_BIBLE.md#16-puzzles-evidence-and-fictional-hacking), [§20 — writing rules](../BANANA_CORP_GAME_BIBLE.md#20-established-copy-and-writing-rules), [§22 — open decisions](../BANANA_CORP_GAME_BIBLE.md#22-open-decisions), and [puzzle review: approved versus unresolved](ACT3_PUZZLE_DESIGN.md#approved-canon-versus-unresolved-design). The latter document's original pending Wall restrictions are historical and superseded by the approved Wall; its unresolved later-route decisions are not settled by that approval.

Precise energy science, research/disappearance chronology, Alex's fate, Daniel's full resolution, Vale's final accountability, Maya's BLACKOUT fate and outside-session ontology remain unresolved. Do not invent them to connect an implementation edge. The wider-world ambiguity and the Assistant process hint must not be converted into definitive survival or simulation claims.

## Validation plan for a later approved slice

This section specifies engineering evidence to collect after a concrete slice is approved; it is not a report that the slice exists or passes tests.

- Review approved contract against exact bible sections; update the relevant bible sections/change log in the same narrative/mechanics PR. Allocate stable catalogue/resource/version/event identities only then.
- Preserve all earlier production definitions and snapshots; verify prior conclusion/entry saves resume without replay, migration or invented prerequisites. Test failed atomic saves and repeated actions where the slice writes state.
- Check every approved access/knowledge prerequisite independently; query denied content through lists, direct reads, previews, notifications, labels and preservation. Optional evidence/Observer facts must not leak into mandatory gates unless separately approved.
- Exercise normal controls through the new slice and relaunch checkpoints on installed supported iOS runtimes. Retain actual logs/xcresults and distinguish Foundation, Apple SDK, simulator and physical-device evidence.
- Verify approved presentation's safe areas, Home/system gestures, Reduce Motion, Dynamic Type, VoiceOver and media truthfulness. Keep neutral answer fixtures outside the production bundle.

No implementation approval, native result, Act 4 completion or ending readiness is claimed by this draft.
