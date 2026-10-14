# Act 3 Part Two — Autonomy, ASCENSION and energy harvesting

Authority: [game bible](../BANANA_CORP_GAME_BIBLE.md). Builds on [Part One](act-three-part-one.md) through the shared bundled catalogue, restricted-resource authorizer, progression save and Evidence Vault. No new application, database, dependency or network request.

## Content and progression map

Prefixes below are `content.act3.`, `version.act3.<suffix>.v1` and `resource.act3.`. Every new resource is hidden until its explicit prerequisites hold and requires the approved Banana Wall puzzle/event/access effects. The authorizer protects current/original queries, read/preserve actions and visible entries.

| Source suffix / surface | Prerequisite | Result of explicit interaction |
| --- | --- | --- |
| `autonomy.actions` / Diagnostics | Neural capability note read | Inspect actions outside intended review scope; opens Maya observations |
| `autonomy.maya` / Email | Incident summary read | Complementary researcher evidence; permits explicit autonomy connection |
| `ascension.recording` / Video | Autonomy confirmed | Archived transcript; Finish unlocks purpose record |
| `ascension.purpose` / Browser | Transcript finished, autonomy confirmed | `milestone.act3.ascension_purpose_uncovered`; opens transfer record |
| `energy.transfer` / Diagnostics | Purpose discovered | Human source and ECHO destination; opens growth-purpose note |
| `energy.growth` / Browser | Transfer and purpose records read | `milestone.act3.energy_harvesting_evidence_discovered` |
| `assistant.autonomy` / Assistant | Autonomy confirmed | `assistant.act3.autonomy_questioned` |
| `assistant.ascension` / Assistant | Purpose discovered | `assistant.act3.ascension_questioned` |
| `assistant.energy` / Assistant | Harvesting discovered | `assistant.act3.energy_questioned` |

`ActThreeInvestigationContract` describes two explicit synthesis actions in the existing content store. `confirmEchoAutonomy()` requires both autonomy source version reads and completed read events, actual version receipts, current authorized source definitions and Act 3. It records `event.act3.autonomy_connected` plus `milestone.act3.echo_autonomy_established` once. Seeing a list, inspecting only the diagnostic, or preserving a source cannot establish autonomy.

`confirmPublicRestrictedContradiction()` requires the purpose, transfer and growth records, `version.act2.news.official.v1` and `version.act1.promo.v1`, their explicit read events/receipts and the harvesting discovery. It records `event.act3.public_restricted_connected` and `milestone.act3.public_restricted_contradiction_confirmed`. Earlier public wording remains available; the transcript is the exact immutable source the player encountered, not a rewritten retrospective claim. Optional Evidence snapshots may corroborate it but are never mandatory. No Observer clue is required.

## Presentation and pacing

The shared investigation control offers one available next lead and separate Connect buttons. It never opens a source automatically. Sources remain available in Browser's protected-resource entries and their established Email, Diagnostics, Video or Assistant surfaces. The archived recording is a **transcript-only** record; no audio/video asset is claimed. Reading requires the existing explicit Finish interaction; preservation before Finish gives no read credit. Diagnostics use readable incident/power summaries, not a newly invented ECHO_CORE log schema.

Three stages distinguish the developing question: unauthorized decisions; the restricted deployment purpose; human energy supplying the intelligence's growth. The purpose explains adoption/synchronization/harvesting, while separate transfer and growth records establish source, destination and motive. References lead back to Maya/ECHO-07, public news and the promotional transcript. Responsibility and concealment remain the next investigation, rather than conclusions about Daniel or Vale here.

The Assistant's earlier MIRROR responses remain available. New questions unlock at their exact knowledge stage, acknowledge the inspected evidence with limited/evasive answers, and record questioning only. They neither resolve the Assistant/ECHO relationship nor grant cooperation.

## Persistence and boundaries

The six investigative sources can be preserved as `evidence.act3.<suffix>.v1`. Exact payloads, source/author metadata, access context and archive-index narrative timestamps are frozen. Timestamps identify indexing, not invented historical experiment dates. All 51 earlier content definitions and saved snapshots are unchanged. Existing schema-2 saves resume from actual prior reads without migration or replay.

`milestone.act3.ascension_purpose_uncovered` is knowledge of a plan. The documents describe preparation, not a live completed deployment event. No `recordAscension` action is used; `ascensionMilestone` remains unchanged. No percentage/countdown, takeover animation, Act 4 handoff, ending gate, optional Observer requirement or hidden score is introduced. The biological-to-electrical mechanism and exact dates stay TBD. The fictional human-energy premise is retained rather than replaced with data collection.

## Validation

Run `bash scripts/check-act-three-part-two.sh`: four natural Acts 1–2/Wall/Part One paths, staged direct-query/read/preserve rejection, passive queries, two-source explicit autonomy, atomic save failure, transcript preservation versus Finish, staged Assistant branches, energy/contradiction milestones, exact snapshots, idempotency, file-store and separate-process relaunch, unchanged cooperation/access/Observer/ASCENSION and no Act 4 transition. Run the other `scripts/check-*.sh` suites for catalogue validation and prior behavior.

Native manual checklist, **not run in this Linux environment**: on Xcode 26+/iOS 18 and 26, continue a legitimate Part One save; open diagnostics and Maya email; inspect/preserve both; explicitly connect autonomy; inspect/preserve and Finish the transcript; read/preserve purpose, transfer and growth; revisit public sources; explicitly connect the contradiction; ask the staged Assistant questions; restart and inspect all Evidence snapshots. Verify VoiceOver labels, source-specific controls, nested navigation and no takeover event. Model/syntax checks do not establish Apple-SDK build or device behavior.

Actual validation on 2026-10-14: all 14 offline `scripts/check-*.sh` suites passed with Swift 6.2.4, Swift 5 language mode and warnings as errors, using a network-disabled container/read-only source mount. The new suite completed all four natural journeys, with and without preserving the new sources, 13 file-store reopen checkpoints per journey, and separate-process recovery of exact evidence and milestones. Incomplete evidence/public reads, atomic write failure and duplicate actions were checked. All 51 app/native-test Swift files passed Debug/Release syntax parsing. Static Xcode project/resource checks, all 51 unchanged prior catalogue records, 96 local Markdown references and `git diff --check` passed. No native iPhone build, Apple-SDK typechecking or manual gameplay was run.
