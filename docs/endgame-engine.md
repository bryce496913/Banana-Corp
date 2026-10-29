# Approved endgame engine

The creator approved [the completion proposal](STORY_COMPLETION_PROPOSAL.md) on 2026-10-28. The [game bible](../BANANA_CORP_GAME_BIBLE.md) remains canonical. This implementation keeps the single `StoryProgressionStore` owned by AppState; it adds no parallel story/evidence store, score, timer, compulsory game or personal identity.

## Saved prerequisites and actions

`EndgameStore.swift` extends the shared progression store. `EndgameContract` names the exact required facts. `version.act5.recovery.v1` must be explicitly read in Act 5 before any final choice. Catalogue reads remain distinct from action confirmations.

- `reconstructMaya(note1:note2:note3:baseline:)` requires the three explicitly read M-01/M-02/M-03 sources and `access.lantern.authorized`. D/F/A accept surrounding whitespace/case; baseline accepts `440` or `440 Hz` with surrounding whitespace/case. Wrong submissions change nothing and can be retried. Success atomically records `puzzle.act5.maya.identity`, `access.act5.maya.identity` and `event.act5.maya_reconstructed`.
- `requestSafetyCooperation()` requires Recovery Diagnostics, Maya's reconstructed identity, the explicit comparison source and both Act 4 conflict records. Only this separate request awards cooperation. Neither a read nor a puzzle success changes the Assistant personality by itself.
- `performDawnStage(_:)` requires cooperation, the corresponding safety explanation and all prior completed stages. `DawnStage` order is stabilize → isolate → restore. Each stage commits before success is observable. Failed/out-of-order requests award no partial facts or punishment.
- `challengeNegotiation(_:)` explicitly links dependency, autonomy or energy contradictions to the authored claims. Legitimate source reads/milestones suffice; preserved snapshots are optional. `demandSafeguard(_:)` separately records releaseUsers, mayaSupervision and publicOversight after their source is read. `verifyAgreement()` requires every challenge and safeguard; there is no hidden credibility threshold.
- `linkObserverClues()` requires explicit reads of all five optional Observer archives, and records their five clue IDs plus the explicit linking event atomically. Mandatory Act 3 participation discovery alone is insufficient. The identifier archive reuses the established Observer Program/Observer channel designation without inventing a personal identifier.

Every action returns `StoryActionResult`. The UI must surface a failed save/action accurately. Queries, preparing a confirmation and cancelling do not mutate the campaign. Existing once-only event actions remain idempotent.

## Irreversible decisions

`EndgameEnding` has stable IDs `ending.silence`, `ending.first_light`, `ending.agreement`, `ending.false_promise`, `ending.awakening`. It exposes title and catalogue versionID. Consequences live in the shared catalogue, not a second view-local script.

`canPrepareEnding(_:)` checks exact prerequisites. `prepareEnding(_:)` returns an `EndgameConfirmation?` bound to the complete current saved state. Present the route's consequence and separate Confirm/Cancel controls. Cancel discards the token and writes nothing. `confirmEnding(_:)` revalidates the token and prerequisites; any intervening saved change invalidates the old confirmation.

BLACKOUT requires all three established component route facts and a read dependency warning. FIRST LIGHT requires Maya, cooperation and every DAWN stage. THE AGREEMENT requires verified challenges/safeguards. THE FALSE PROMISE requires the explicitly read unverified-assurance explanation and a distinct confirmation. THE AWAKENING requires the five linked optional clues. Opening a route, asking questions, failing a puzzle or missing optional preservation cannot choose an ending.

The first confirmation creates an immutable pre-decision checkpoint and atomically saves it with current ending, completion event and earned ending collection. FIRST LIGHT also records Assistant separation; THE FALSE PROMISE records the authored 100% ASCENSION milestone. A write failure leaves memory and disk at the prior state, without an ending or partial checkpoint. Campaign mutation is blocked after completion; render the consequence as a read-only catalogue version until restore/new game.

## Replay and compatibility

`StoryState.endgame` is an optional additive schema-2 field. Previously saved schema-2 JSON decodes with nil endgame, with no migration or forced rewrite. Schema-1 migration remains unchanged. Existing evidence snapshot `Data` is never refreshed or transformed. Unsupported/corrupt saves keep recovery protection; no endgame operation overwrites them.

The endgame extension contains current ending, earned IDs and opaque checkpoint bytes. The checkpoint encodes the entire legitimate campaign with the endgame extension omitted; it contains original evidence bytes and cannot contain recursive checkpoints. Validation rejects invalid nested saves or non-Act-5 checkpoints.

`restoreFinalDecision()` restores that first legitimate campaign, keeps the ending collection and same immutable checkpoint, and clears the current ending. It grants no prerequisites from other routes completed later. The collection is independent of current campaign facts but persisted in the same atomic save. There is no chapter selection or direct save-edit route.

`resetForNewGame()` retains the collection from a valid writable save while resetting all campaign/evidence/route/checkpoint facts, and preserves the pre-reset file using the existing archive adapter. A separate UI confirmation precedes `clearEndingHistory(confirmed: true)`; false is a no-op. Clear history removes earned IDs without fabricating or rewinding campaign progress. Older app binaries do not understand this extension; use the updated build for endgame saves.

## Verification

Run `bash scripts/check-endgame.sh`. Neutral fixtures outside production verify schema-2 compatibility and schema-1 evidence retention, invalid/newer-input protection, Maya normalization/retry/access gates, ordered stage/reload/idempotency, cooperation, negotiation requirements, Observer linking, all five decisions, cancel/stale confirmation, injected write failure at commit/restore, immutable checkpoint and exact evidence bytes, route-limited replay, new-game collection retention and explicit history clearing. Separate processes exercise real file reload after completion and restore.

These are Foundation model checks, not native UI or a normal-control campaign pass. Root integration additionally validates the merged actual catalogue and its references, app target membership, Debug/Release builds and simulator interactions. Full native coverage of all five endings, partial-route relaunch, confirmation/cancel and replay remains required before claiming the complete game playable. Physical iPhone QA remains separately authorized in roughly ten-minute blocks.
