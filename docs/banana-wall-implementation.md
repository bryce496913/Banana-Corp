# Banana Wall implementation and validation

**Approved 2026-10-14.** The user explicitly approved the story/design and requested Implementation Pass 4. [Bible v1.8](../BANANA_CORP_GAME_BIBLE.md) records the approval before production edits. The [reviewed specification](BANANA_WALL_PUZZLE_PROPOSAL.md) supplies the exact instructions, fields, hints, feedback and limited reward. Pass 4 additionally requests the factual `milestone.banana_wall.breached`, recorded in the same atomic transaction.

## Delivered behavior

After the existing Act 2 confirmation and explicit Act 3 handoff, Browser → Banana Wall presents the review cross-reference. Four labelled text fields require **neural systems**, **ECHO-07**, **selected preferences**, **recorded cognitive patterns**. Links reopen the stable Daniel conversation, official-response article, Maya correspondence and ECHO-07 through authorized queries. No Act 1–2 text, preservation requirement or earlier gate changed.

RestrictedAccessStore evaluates exact input IDs and ≤256 raw UTF-8 bytes, canonical precomposition, edge-whitespace trimming and case insensitivity. Internal spaces, ASCII hyphen and field mapping remain significant. Missing/empty/oversized fields and incorrect tuples receive the reviewed feedback without writing story state. Supported UITextField controls disable autocorrection/smart punctuation, expose accessible labels, support copy/paste and Done, and scale with Dynamic Type. The copyable `XXXX-00` format illustration does not prefill an answer.

Hints are immediately voluntary, reveal the three approved stages and keep earlier hints visible. Clear input keeps hint visibility. Valid partial input/hints are transiently retained by the existing access coordinator across source/Home navigation; force quit may clear unsolved input, as permitted by the design. Drafts are bounded, filtered by input identity and cleared on completion/new-game reset. They are not another story save or puzzle engine.

Success atomically records these facts once:

- `puzzle.banana_wall.review_cross_reference`
- `event.puzzle.banana_wall.review_cross_reference`
- `access.banana_wall.breached`
- `milestone.banana_wall.breached`

Only `content.act3.banana_wall.scope_record` / `version.act3.banana_wall.scope_record.v1` becomes available through `resource.banana_wall`. Open review record explicitly reads it; success does not silently read it. The exact approved scope-reconciliation draft is a structured local web record, source Internal research review, with ECHO-07/Maya links, no invented author/date and preservation ID `evidence.act3.banana_wall.scope_record.v1`. It establishes the known scope discrepancy, not the wider conspiracy. No Act 4, unrelated document, ending/Observer/ASCENSION fact or Assistant cooperation is unlocked.

PhoneShell, hardware-safe Home/Back, scrollable form/content and existing themed cards/buttons provide the interface; glass remains guarded with iOS 18 fallbacks. Confirmation/haptic state belongs to the resource view so replacing the input panel does not discard it. VoiceOver receives result announcements. No puzzle timer, root gesture, network dependency, permission or mini-game change.

## Catalogue and save contracts

RestrictedAccess.json retains `puzzle.banana_wall.pending_design` **inert**, while the resource now requires the new approved puzzle. Placeholder opening never completes it. Old pending/test/access facts survive loading but cannot substitute for the new solved/event markers and declared success facts. New partial markers fail closed rather than silently repairing success. Duplicate submission is unchanged and does not replay writes/effects.

Save schema remains **2**, with the existing schema 1→2 codec. Existing archives, content version IDs and customized Home layout are retained. All **45** published story definitions remain structurally identical; only the approved scope record and access declaration are added.

Optional model additions are input prompts, clue IDs and typed presentation copy. Loader checks include known keys, complete/nonempty feedback, declared/deduplicated clues and nonempty prompts. Clue references bind to actual content alongside protected links. Strings cannot execute effects. Old fixture definitions still decode; awaitingApproval forbids the new presentation/clue payloads as well as answers, inputs, effects and hints.

## Actual automated validation

Environment: Linux x86_64; official Swift **6.2.4**, language mode **5**, warnings as errors, read-only source and no container network.

- All **12** applicable Foundation/check suites passed. Earlier Act 1–2 separate-process paths, content/evidence persistence, migrations, navigation, layout, presentation and access fixtures remain covered. Earlier catalogue assertions now check immutable Act 1–2 inventory instead of incorrectly prohibiting this approved record.
- `bash scripts/check-banana-wall.sh` passed all four preservation combinations through normal production actions, without debug replay/injected prerequisites. Coverage includes early/locked queries, recoverable clues, hint/draft neutrality, wrong/missing/extra/oversized/whitespace-only fields, wrong punctuation/trial/internal spacing, normalized success, exact fact deltas, explicit reward read/unread, snapshots and duplicate write avoidance.
- Pending/access markers under both schemas cannot unlock the new puzzle. Partial new markers and failed writes grant no access; failed writes can retry. The suite writes all four completed campaigns and starts a **separate executable process** to verify actual Wall access, exact reward/original evidence receipts and repeat-success neutrality after reload. Act 4 remains unconfigured.
- Release production loading still rejects development catalogues; retired pending remains inert. The Release executable scan excludes isolated demo strings. There is no production test-token bypass.
- All **51** app/native-test sources parsed in Debug and Release. The final changed view was reparsed after feedback-layout refinement. This is **not Apple SDK typechecking**.
- Structural project/source/resource membership, iOS 18 settings, approved copy/hint/answer equivalence, unchanged 45 definitions and unchanged launch/Home/gesture/game sources were checked. Markdown references, shell syntax and whitespace are checked before publication.

Native commands attempted:

```sh
xcodebuild -project 'Banana Corp/Banana Corp.xcodeproj' -scheme 'Banana Corp' \
  -configuration Debug -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
xcodebuild -project 'Banana Corp/Banana Corp.xcodeproj' -scheme 'Banana Corp' \
  -configuration Release -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
xcrun simctl list runtimes
```

All returned **command not found / 127**. Xcode, Apple SDKs, simulators and an authorized iPhone are unavailable here. **No manual Apple playthrough, native test compilation/execution, keyboard rendering, VoiceOver, haptic or frame-performance pass is claimed.** Runtime usability acceptance remains pending.

## Native preparation and manual playthrough

ActsJourneyTests now continues from its natural completed Act 2 journey through clue review, a voluntary hint, all four values, leaving/reopening to check the draft, submission, opening the sole reward and termination/relaunch into persistent access. Its Mac runner validates final app-save puzzle/event/access/milestone and reward-read facts instead of the old empty-access assertion. This is prepared coverage, **uncompiled/unrun against Apple SDKs here**.

On a Mac with Xcode 26+, Python 3 and installed iPhone simulators:

```sh
xcrun simctl list runtimes
xcrun simctl list devicetypes
bash scripts/validate-acts-journey.sh INSTALLED_IOS_RUNTIME_ID IPHONE_DEVICE_TYPE_ID
```

Replace placeholders with actual installed IDs. The runner creates its own test simulators for the four preservation paths in Debug/Release, rejects skipped tests and retains xcresult captures/logs/final saves. Complete [native integration validation](IOS_INTEGRATION_VALIDATION.md) and the [device QA matrix](ACTS_1_2_DEVICE_QA.md) on iOS 18 and iOS 26; one runtime is not evidence for the other.

Manual status for **each** step: **NOT RUN — Apple tools unavailable**.

1. Start from a legitimate completed Act 2 save, with and without original preservation. Explicitly advance to Act 3; open Browser → Banana Wall. Check no premature/automatic access and the safe themed layout.
2. Reveal hints before attempts; reread them, inspect all four in-game source links and return by Back. Compare public/research statements without external sites/source code.
3. Enter partial values, leave via Home and reopen. Check retained draft/hints, Clear, wrong/empty/oversized inputs, incorrect hyphen/internal spaces, neutral feedback/invalid-field focus and unchanged progress. Check small/large phones, Dynamic Type, keyboard and Done.
4. Submit the approved tuple, including allowed case/edge whitespace. Check one durable confirmation and Open review record, without wider access, read credit or act changes.
5. Inspect the complete ECHO-07 — Scope reconciliation record and its links; Preserve Evidence if desired. Earlier originals retain exact text/metadata and the new record is its own immutable snapshot.
6. Close/reopen. Browser → Banana Wall shows the completed message and same reward, without editable replay/repeated effects. Inspect the archive; access/milestone are durable and Act 4 stays unavailable.
7. Check VoiceOver result announcements/labels, larger text, Reduce Motion/Transparency, status/Home safe regions, scrolling and real system gestures. Record actual device/runtime, failures and repairs/retests before converting NOT RUN to PASS.

This implements the approved narrow puzzle/reward. Later Act 3 research and unresolved ending puzzles remain outside scope; native execution is the outstanding platform limitation.
