# QA test plan

Updated: 2026-10-30. Scope: authorized [Banana Corp repository](https://github.com/bryce496913/Banana-Corp) only. Use [game canon](BANANA_CORP_GAME_BIBLE.md), [roadmap](DEVELOPMENT_ROADMAP.md) and [progress tracking](AGENT_PROGRESS.md).

## Validation tiers and claims

| Tier | Procedure | What a pass establishes |
| --- | --- | --- |
| Static structure | `python3 scripts/check-ios-project.py`, shell syntax, Markdown links, whitespace | Target/resource references and source structure, not Apple compilation |
| Offline story/OS models | Existing `scripts/check-*.sh` Foundation suites on supported Swift | Deterministic progression, delivery, saves, evidence, puzzles, home layout and navigation model behavior |
| Native-runner command contracts | `bash scripts/check-native-runners.sh` (Python 3) | Testability flags, stdout/stderr logs, failure/skip propagation and owned-simulator cleanup using isolated fake tools |
| Apple integration | `bash scripts/validate-ios-integration.sh SIMULATOR_UDID` | Actual Debug/Release builds, bundle checks and XCTest on the selected real runtime, only when executed |
| Apple full journey | `bash scripts/validate-acts-journey.sh INSTALLED_RUNTIME_ID IPHONE_DEVICE_TYPE_ID` | Four normal-control preservation paths through Act 4 entry, owned fresh simulators, recorded native results, only when executed |
| Human/device experience | Authorized iPhone + available iOS 18/26 simulators | Layout, gestures, readability, accessibility, pacing and native performance on the actual recorded configuration |

Always use PASS, FAIL, BLOCKED or NOT RUN with the tier and tool/device evidence. A fake-toolchain pass is neither an iPhone build nor a playable-story pass. Syntax parsing is not SDK typechecking. Preserve failing logs; do not suppress required checks or loosen story conditions to produce a green result.

## Required regression coverage

- Fresh opening, real launch/splash, introduction, exact email disappearance boundary, warning/denial and explicit handoffs.
- Four original-email/video preservation combinations; independent corroboration remains viable without saved originals.
- Genuine original/live version distinctions; exact immutable snapshots, repeated preservation, removed/missing source and truthful comparison.
- Legitimate in-game Banana Wall clues, wrong/normalized answers, hints, saved success/retry, old pending states and no debug bypass.
- MIRROR/ECHO/influence, two-source autonomy, ASCENSION knowledge versus takeover, human-energy records, Daniel accountability, archived Maya guidance, mandatory Observer discovery and conclusion.
- Optional clues/evidence/questions remain independent; no hidden scoring. Incomplete facts and failed saves cannot advance. Act 4 entry alone grants no takeover/countermeasure/cooperation/ending facts; later approved Acts 4–5 actions require their explicit prerequisites.
- Relaunch at meaningful boundaries; exact acts, evidence, receipts, access, puzzle, replacements, unread counters and nonduplicated notifications/events.
- Query-cache invalidation on story changes, alternative-state queries and authorizer reference changes; passive queries never award reads.
- Native app open/Home/swipe/Back, scrolling/keyboard, modal dismissal, edit/drag/drop persistence, accessibility labels/Dynamic Type/Reduce Motion and mini-game gesture/lifecycle reliability.

Keep content fixtures and fake toolchains outside production resources. Mock tests must use temporary repositories/output and must not reset real saves or manipulate a real simulator. Native testability overrides belong to test invocations; ordinary Release build settings stay unchanged.

## Native build matrix and evidence

Record actual Xcode/SDK, Swift, device model/runtime/UDID, configuration, source commit, command, logs, xcresult, screenshots and failure/retest notes. Run both Debug and normal Release builds, then test invocations with testability enabled. Ensure every enum-registered image resolves in the built app bundle; planned image inventory must not become missing runtime references.

Use dedicated simulators; the full-journey runner owns and cleans up only those it creates. A supplied integration simulator is not owned/deleted by that script. A skipped journey is not a successful journey. Stop on build/test failure while retaining combined stdout/stderr diagnostics.

Current Apple matrix (2026-10-30): signed Debug/Release builds pass for the latest complete-story candidate; earlier iOS 26.5 integration and eight physical pre-endgame campaigns are source-qualified historical results. The current full Acts 1–5/ending/replay native journey and full public audit are not accepted. iOS 18 remains NOT RUN because its runtime is absent. Spoken VoiceOver and performance acceptance are outstanding. See [the exhaustive readiness review](docs/FULL_STORY_READINESS_REVIEW.md) and [current progress](AGENT_PROGRESS.md); historical limitations below do not override newer actual evidence.

## Playtest/release gate

Before asking the creator to playtest, identify the intended scope, pass available automated checks, resolve critical progression/build blockers, verify saving/relaunch, disclose missing media, and establish a real supported install route. Supply build/version, device/iOS support, test goals and known issues. Do not claim a complete five-act game or full production readiness while Act 4/5 or native validation remain incomplete.

Signing, provisioning, TestFlight/external build distribution, spending and final App Store submission are separate consequential actions requiring approval. PR merges within the authorized repository may proceed after relevant validation and required GitHub checks, without force-push, protection bypass or fabricated native results.


Native Mac update (2026-10-15): Xcode 26.5 and iOS 26.5 are available. Actual Debug/Release simulator builds and bundle checks passed; five Debug hosted tests passed. Launch UI tests failed and remain under diagnosis; Release XCTest/full native journey are not yet established. iOS 18 runtime is absent. See [current native results and continuation](AGENT_PROGRESS.md#native-mac-execution--2026-10-15). Historical Linux limitations above describe the earlier run.


Isolated confirmation (2026-10-16 continuation): actual Debug/Release builds and bundle checks passed. Five hosted and three UI smoke cases passed in each configuration, including all 15 apps, repeated launch/Home and reserved-strip swipe. Release evidence: `validation/native-fixed-20261015/tests-Release-isolated.xcresult`. Full journey is running separately; its integration skip is not a journey pass. Earlier Release failures are retained. Run one QA simulator at a time and check for owned simulators left booted after interruption. See [current tracking](AGENT_PROGRESS.md).

### Native journey continuation — 2026-10-16

The Browser research list repair passed actual Debug/Release builds, bundle checks and hosted/UI smoke suites in `validation/browser-scroll-clean-20261016/`. Full journey coverage is still incomplete. Earlier failures reached normal Wall solving and scope reload but did not complete all research and Act 4 entry. Repeated Home tap diagnostics remain inconclusive: grid and restored dock runs passed; no permanent touch change was justified. A later retained-simulator journey suffered confirmed host sleep and long event-loop stalls, and is not a clean regression result. The fresh eight-case matrix is retained in `validation/acts-20261016-143324/`; update only after inspecting its actual results and saved-state assertions.

Temporary probes and experimental dock styling were removed and independently reviewed. iOS 18, physical installation, VoiceOver, large text, drag/drop, reset/replay and complete visual validation remain open. Screenshot capture omissions do not establish a visual pass.

First full native diagnostic journey passed (Debug/both,730.285s): normal controls, all Acts1–3 research and Act4 entry, repeated relaunch; exported save passed exact runner assertions (act4,61 read versions,7 preserved records, expected Wall and preservation state). Evidence is under `validation/touch-diagnostic-20261016/event-state-*`. All app diagnostics are now removed. The clean eight-case matrix is running via `validation/journey-final-clean-matrix-20261016.log`; diagnostic success does not replace that gate or resolve earlier intermittent cancellations.

2026-10-17 continuation: clean baseline Debug/both failed its first Email tap (29.648s). The separately isolated Home-background candidate in PR33 passed early Home interactions but failed at preservation (131.263s), with inbox/unread source still present after source-open. PR33 is closed without merge and its production change reverted. Root cause remains open. Minimal debugger state inspection is temporary and excluded from published code; do not count its failure-only pause as a production timeout or a clean journey pass.

2026-10-17 state capture: the later diagnostic journey failed the target-center assertion at Observer session review, after sixteen alternating full-page swipes. LLDB returned navigation phase2/active; this failure does not establish a stalled transition. The helper now moves the target-containing scroll with bounded edge-derived drags; unchanged16-move limit and one final tap. Fresh-simulator diagnostic validation is in progress at `validation/state-cold-20261017.*`. Earlier missed-tap failures remain unresolved. Temporary registry/getter and first-failure pause must be removed before clean validation/publication.

Clean candidate result2026-10-17: PR34 removes only the shared explicit pressed-state animation (unproven cause). Fresh Debug/both journey PASSED827.771s with zero failures/skips and no app probes, bypasses or retries; exported save passed official assertions (act4,61 reads,7 preserved records,both originals,expected Wall and no later ending flags). Evidence `validation/press-animation-b-20261017.*`. This establishes one candidate preservation/configuration path, not the eight-case matrix. Original animation restored for fresh A comparison in `validation/press-animation-a-restored-20261017.*`; inspect outcome before retaining candidate. Other paths/Release integration/press and Reduce Motion/reset/accessibility/physical route remain pending.

Restored A failed59.396s at firstEmail, again with intended point inside its rendered icon. B has been restored for the complete official8-case matrix in `validation/acts-20261017-165809/`, log `validation/press-animation-clean-matrix-20261017.log`; no full matrix outcome yet. App/test/project sources must stay fixed while it runs. The12-checkpoint screenshot review of prior B passed only its bounded visual observations; capture omissions and unpictured states remain open. New native reset/audit tests and enforcing runner are staged outside the workspace, not compiled/executed.

Full B matrix did notpass: firstDebug/bothFAILED105.860s on fourth promoContinue expected5of5; newpostcondition detected it directly. Globalanimation candidate is insufficient alone. Matrixended/ownedsimcleaned, artifacts retained. Next geometry experiment remains unproven; full8-case, Release/integration/accessibility/reset gates stay open.


Native experience coverage (2026-10-18): [dedicated reset/accessibility runner and result boundaries](docs/native-experience-validation.md). First public native audit compiled and FAIL44.940s on Home clock Dynamic Type support; reset/Release absence remain NOT RUN. No accessibility, VoiceOver or Reduce Motion pass is inferred. Original press animation is restored; PR34 closed without merge after its failed matrix.


2026-10-18 repair-branch checkpoint: native Debug/Release builds and bundle checks PASS; hosted5perconfiguration, UI3Debug/4Release PASS (5/4dedicated skips). Release diagnosticsabsence is verified; reset remains NOT RUN pending freshownedcase. Separate optional Home DynamicType audit runs in bothconfigs after the fullaudit's frameworkCode-56 timeout; it does not replace or narrow the default all-types audit. See validation/status-type-integration-20261018/ and the native experience record.

Focused Home Dynamic Type: Debug passed natively (68.027 seconds, one pass/zero failures/skips). Release's first attempt failed before the audit due to invalid AX window geometry; no Release category result. A reviewed readiness guard is being validated on a fresh Release case, followed by reset. Evidence: validation/native-experience-20261018-142814-77365/.

2026-10-18 completed focused/reset pack: guarded Release Home Dynamic Type PASS65.191s, one pass and zero failures/skips. Debug reset FAIL40.459s before Settings: the initial Evidence tap did not produce observable navigation. Reset semantics remain unverified. Results: `validation/native-experience-20261018-142814-77365/`. Investigate missed input with a single scoped profile; no retries or story shortcuts.

2026-10-18: focused status-bar accessibility repair merged to main in PR#38 (`6dccd14d250c2a207c8cd518b99fa9340cbb5994`). Home contrast diagnostic PASS37.204s, exactly1pass/0fail/0skip; hit-region diagnostic is running separately. PR#36 remains draft for incomplete reset and broader QA.

2026-10-19: the Home hit-region attempt ended before audit at launch readiness after a prolonged execution gap (7269.110s test, no audit-start marker). Result exit65 retained in `validation/native-experience-20261018-212232-84526/`; owned simulator cleaned. Hit-region remains untested pending interruption diagnosis.

Power evidence for the interrupted hit-region attempt: Oct18 21:26:39 EDT recorded Clamshell Sleep despite both temporary idle assertions. Brief maintenance wakes align with the delayed failure/result. Filtered evidence retained as `validation/native-experience-20261018-212232-84526/power-window.txt`. This is an environmentally interrupted pre-audit run, not a hit-region finding; no sleep/lock preferences were changed.


## Browser and Email UI update — 2026-10-26

Creator prioritizes UI before further campaign playthroughs. Added Browser address/local-page search/Go, Back/Home/Refresh across catalogue pages and protected panels; Email inbox sender/subject rows, search/unread filter, Back/Inbox/Refresh and retained message headers/preservation/attachments. Shared authorized queries and explicit read actions remain; local refresh does not mutate opened/preserved versions or advance story. Guarded AppState/OSNavigationState app-root revision resets only the current app’s local stack; Email retains the established inbox boundary. Bible1.13 section14/changelog records approved controls without new canon/gates.

Actual final generic iOS Debug/Release SDK builds and actual product/executable/compiled-assets/resource checks passed, deployment18.0. All10 applicable model checks passed, including guarded app-root navigation. Unsigned products establish no installation or new UI interaction/campaign pass. Existing prior campaign evidence remains source-qualified. User requested campaign pause; next focused validation covers Browser address/Back/Home, Email search/unread/Inbox, nested email-to-web return and preservation before source removal, once UI validation resumes.

Cleanup: removed10 targeted inactive task-only compiler/cache/log/temp paths after lsof checks,161.4MiB logical files; free space increased163463168bytes during the cleanup measurement. Final built apps/logs/model evidence/manifests and all prior unresolved diagnostics/signing/simulator environments retained; no uncertain cleanup or approval needed. Ledger validation/browser-mail-ui-20261026/cleanup-report.json. No native process running.


## UI/gameplay continuation and resource checkpoint — 2026-10-27

Current source integrates new controls into all17-checkpoint campaign paths and fixes cross-app Mail root labels/toolbar hit shapes. See docs/BROWSER_EMAIL_GAMEPLAY_QA.md for actual8pass1fail7optinskips UI integration results, three-checkpoint failed first campaign, preserved original, normal-pointer Email-open result after relaunch/unlock and unresolved inactiveHome text audit finding. The ineffective accessibility-group experiment was reverted. No complete campaign/audit pass claimed.

Latest stronger finite/stable-frame readiness source compiled in native-c-20261027. Verification stopped after boot at the2GiB free-space guard before any test; native-b previously stopped at setup space guard. Original partial save and original executor source are preserved. Future export must query current bundle/container and verify exact MCMMetadataIdentifier because XCTest relocated the app sandbox during installation; no app save was edited. Root-reviewed fresh-app matrix uses one retained owned simulator, sharedruntime—not eight cold devices. No current native job is running.

Storage cleanup removed47 exact inactive known-owned compiler/index directories,1367.2MiB logical files; products/symbols/saves/xcresults/logs/source/signing/simulators kept. Read-only old-owned-device audit found no remaining matches to delete. User asked to make df Avail at least8G; full matrix is pending measured space and fresh workflow. Keep main at last verifiede3b6b48 and parent mergecb1622 distinctions; don't merge unvalidated work. No disposable results or simulator deletion authorized.


## Complete-story candidate — 2026-10-28

Bible1.14 approved late-act contracts supersede the historical Act5-closed expectation above. New model suites `check-act-four.sh`, `check-endgame.sh`, and `check-complete-story.sh` cover six Act4 investigation orders, guarded atomic87%/Act5 handoff, old schema2 compatibility, exact Maya normalization/retry, earned cooperation and ordered DAWN, explicit negotiation/Observer eligibility, confirmation cancellation/staleness, five outcomes, immutable checkpoint restore, collection/newgame/history and failed-write recovery. The complete-story suite first creates four legitimate Acts1–3 handoff saves through existing catalogue actions, then tests actual late-act catalogue/actions across all five outcomes (20combinations); no native UI claim.

Actual generic iPhone Debug/Release builds pass for the new51source/102record candidate. The signed physical device journeys throughAct4entry and freshopening checks are PRE-ENDGAME-source evidence. New Act4/5 controls, ending completion layer, production Settings reset/collection review, all five outcome journeys and physical save migration remain NOT RUN natively. The covered-Home opacity candidate has builds/model checks but unsuppressed audit retest remains pending. No failures are suppressed.

Before release: run XCTest plus normal UI journeys for new acts/choices; cancel and stale-confirmation behavior, partial DAWN termination/relaunch, wrong Maya input, source-based negotiation, optional Observer independence, every ending/restore/newgame/collection, unchanged old evidence bytes after app update and Reduce Motion/VoiceOver/layout. Keep daily-driver tests to explicitly authorized roughly ten-minute blocks; close the QA app before each check-in.


## Current complete-story acceptance — 2026-10-30

- PASS: signed Debug/Release Apple SDK app/XCTest builds; strict QA bundle/profile/resource/mapping checks; applicable Foundation checks including Act4/endgame. Model coverage remains separate from UI interactions.
- FAIL: latest completed shared-control public audit, Browser contrast after Home/Mail completed; QA app termination confirmed. Screenshot identifies address placeholder despite mismatched XCTest node label.
- BLOCKED: compiled explicit Browser prompt repair awaits connected developer tunnel, before installation/test. All failures remain unsuppressed.
- NOT RUN: complete current-source ordered opening→Act4→Act5 native campaign, five endings through earned final-decision replay, and corresponding final save/evidence checks. Older-source campaigns do not establish this pass.

Next native sequence: live strict verification, QA-only update with exact save equality, full public audit, contiguous original17checkpoints, then eight late-story phases. Use ordinary controls, no app launch bypasses or save injection. Verify cancellation, reconstruction retry, partial DAWN relaunch, negotiation/Observer prerequisites, immutable earlier evidence, restore/newgame/collection behavior and UI gestures. Public audits do not establish spoken VoiceOver quality.

Creator authorizes continued daily-driver testing through the next large milestone and will message before disconnecting. This supersedes older ten-minute check-ins for this session. Keep commands bounded, use only the separate QA identity and pause promptly on notice. Preserve all unresolved diagnostics; clean only verified-unused task artifacts.
