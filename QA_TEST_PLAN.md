# QA test plan

Updated: 2026-10-22. Scope: authorized [Banana Corp repository](https://github.com/bryce496913/Banana-Corp) only. Use [game canon](BANANA_CORP_GAME_BIBLE.md), [roadmap](DEVELOPMENT_ROADMAP.md) and [progress tracking](AGENT_PROGRESS.md).


## Current requested playtest gates

| Gate | Actual status |
| --- | --- |
| Tested physical installation route | PASS: existing-signing Debug iphoneos build, normal signature verification, bundle checks, install/launch/relaunch and eight XCTest cases on iPhone14Pro/iOS27.0.1; zero failures/skips |
| Meaningful save/relaunch/reset | Debug reset/cancel/confirm/relaunch PASS295.828s (1/0/0), archived evidence/source/receipt verification PASS. Full Debug/both campaign save/relaunch passed17checkpoints plus35receipts/7preserved snapshots; remaining matrix stopped on input failure |
| Reliable Acts1–3 progression into minimal Act4 entry | Debug/both PASS1482.638s with exported save/snapshot checks; Debug/email FAIL30.317s at initial Email tap. Matrix stopped; restored-main Release/both subsequently FAIL53.693s at first Email→Home. Other preservation paths remain pending. Reset and Release diagnostics absence passed; no production gameplay change or tap retry introduced |

The StatusBar live-clock experiment passed real Debug/Release builds and one isolated physical Debug/both campaign (1756.072s,1/0/0,17relaunch checkpoints,35receipts/7preserved final snapshots), but failed clean Debug navigation (7passed/1failed/7opt-in-skipped). PR40 is now closed unmerged; canonical49app Swift files exactly match main after restoring StatusBar. That physical campaign is evidence for the retired experimental source; original main's physical build/install/eight-case smoke and earlier simulator journey evidence remain separately recorded. Clean simulator input failure is unresolved. Glass fallback, Home gesture composition and pressed-scale scratch changes did not resolve it; none was adopted. Independent Release XCTest on restored main app sources passed8/0/0, with actual built-bundle/resource verification and unchanged source hashes (`validation/release-integration-20261022/run-main-clock-a/`). Full uninstrumented Release/both then FAILED53.693s on its first Email→Home return (0/1/0), before the first checkpoint; partial save and source hashes retained, owned simulator cleaned. This confirms Release campaign reliability remains open as well.

Current main is `d7949ab132bfe982769abf0f21bc8134b35ae8d1`; PR41 adds only the developer reproducer/progress record, and49app Swift files remain unchanged from8d5ab77. Physical evidence: `validation/device-install-route-20261019/`. Current helper work: [PR #39](https://github.com/bryce496913/Banana-Corp/pull/39). Broader accessibility/VoiceOver/Reduce Motion and absent iOS18 runtime remain explicit limits. The [draft handoff](docs/IPHONE_PLAYTEST_HANDOFF.md) is not yet a playtest invitation.

The corrected neutral trace reproduced Home cancellation before the model callback: item7 remained active after touch-began→cancelled177.806ms, while the preceding same-point Home touch ended normally and navigated. Strict emitted-record validation passed for both app processes (46/158unique records, dropped0, complete lifecycle flushes); source integrity and owned cleanup passed. Evidence: `validation/neutral-shell-trace-20261022/run-trace-debug-b/`. System gesture recognizer state is correlated, not proven cause; this instrumented result does not replace clean acceptance or explain every opening miss. The earlier trace attempt compiled instrumentation out and is a failed capture. Subsequent uninstrumented simultaneous-gesture and raised-Home comparisons both failed initial opens before reaching Home, so neither established a fix. A run-loop trace reproduced initial cancellation but failed required background coverage for that process; retain it as partial capture. The next dispatch trace captured both processes completely and reproduced cancellation with about23ms original forwarding and no recorded>=50ms run-loop gap spanning the failure; a much slower prior Home action succeeded. This does not support a simple forwarding-delay cause. Scoped system logs subsequently distinguished successful ended contacts from a failed contact removed while still active and then cancelled; the cause of the rejected up/path remains unresolved. A0.10-second single-press comparison failed both tests, so its14-site canonical helper proposal was rejected and not applied. Next: compare ordinary Simulator-window pointer input with the same app; Computer Use permission is currently unavailable. Retain all native failures and require clean game campaign/persistence validation before readiness.

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
- Optional clues/evidence/questions remain independent; no hidden scoring. Incomplete facts and failed saves cannot advance. Act 4 entry grants no takeover/countermeasure/cooperation/ending facts; Act 5 remains closed.
- Relaunch at meaningful boundaries; exact acts, evidence, receipts, access, puzzle, replacements, unread counters and nonduplicated notifications/events.
- Query-cache invalidation on story changes, alternative-state queries and authorizer reference changes; passive queries never award reads.
- Native app open/Home/swipe/Back, scrolling/keyboard, modal dismissal, edit/drag/drop persistence, accessibility labels/Dynamic Type/Reduce Motion and mini-game gesture/lifecycle reliability.

Keep content fixtures and fake toolchains outside production resources. Mock tests must use temporary repositories/output and must not reset real saves or manipulate a real simulator. Native testability overrides belong to test invocations; ordinary Release build settings stay unchanged.

## Native build matrix and evidence

Record actual Xcode/SDK, Swift, device model/runtime/UDID, configuration, source commit, command, logs, xcresult, screenshots and failure/retest notes. Run both Debug and normal Release builds, then test invocations with testability enabled. Ensure every enum-registered image resolves in the built app bundle; planned image inventory must not become missing runtime references.

Use dedicated simulators; the full-journey runner owns and cleans up only those it creates. A supplied integration simulator is not owned/deleted by that script. A skipped journey is not a successful journey. Stop on build/test failure while retaining combined stdout/stderr diagnostics.

Current Apple matrix: actual Xcode 26.5 Debug/Release builds and integration tests passed on iOS 26.5. The clean Debug/both full journey passed with17 normal relaunch checkpoints; the remaining preservation/configuration matrix is incomplete after a first Email-tap failure. Scratch instrumented comparisons are excluded from that acceptance result. iOS 18 is NOT RUN because its runtime is absent. Physical iPhone signed build/install/launch and eight hosted/UI XCTest cases passed with zero failures/skips; normal-host signature verification passed. Native VoiceOver remains NOT RUN; Instruments attempts produced no usable capture. See the retained native records below and [current progress](AGENT_PROGRESS.md); the earlier Linux limitation no longer describes this execution environment.

## Playtest/release gate

Before asking the creator to playtest, identify the intended scope, pass available automated checks, resolve critical progression/build blockers, verify saving/relaunch, disclose missing media, and establish a real supported install route. Supply build/version, device/iOS support, test goals and known issues. Do not claim a complete five-act game or full production readiness while Act 4/5 or native validation remain incomplete.

Signing, provisioning, TestFlight/external build distribution, spending and final App Store submission are separate consequential actions requiring approval. PR merges within the authorized repository may proceed after relevant validation and required GitHub checks, without force-push, protection bypass or fabricated native results.


## Historical native checkpoints

The dated records below retain the results and branch states at the time. Current status above supersedes historical NOT RUN and draft-PR references.

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

## Native diagnostic continuation — 2026-10-23

Real UIKit-only XCTest comparisons on iOS26.5 finished1/1/0 on both iPhone17Pro and iPhone16 profiles, with source integrity and owned cleanup passing. The first profile passed60 ordinary loop taps but failed the other case before its swipe; the second passed the real swipe but failed opening item1 in the loop. Retained logs show active-contact removal/cancellation in both. These are diagnostic results, not campaign acceptance: neither SwiftUI views nor the17Pro profile is required for this phenotype, but delivery cause remains unresolved. Details are in [native input findings](docs/NATIVE_INPUT_TRANSPORT_FINDINGS.md), merged to main in PR43. PR39 remains draft.

Next: complete snapshot-only XCTest of stock Settings on a fresh owned simulator, then choose any benign navigation comparison from actual AX evidence. No system setting changes or desktop-input substitute. Computer Use still times out without UI state. Keep the production game and rejected short-press proposal unchanged; require clean Debug/Release progression/persistence and final supported install validation before a human playtest invitation.


## Native readiness continuation — 2026-10-23

Apple Settings provides a separate stock-app input control: snapshot-only and one General-navigation tests each passed (1/0/0). The ten-cycle General/Back test on a fresh owned iOS 26.5 simulator failed on its tenth tap, Cycle 5 Back, after nine verified destination changes (0/1/0, native65, 150.401s). Scoped system logs show an active contact removed while locked to Settings, followed by soft cancellation. Source integrity and owned cleanup passed. Evidence: `validation/stock-settings-loop-20261023/loop-awake-b/`. This reproduces the captured phenotype without custom app code; it does not prove an SDK defect or validate Banana Corp. An earlier launch-only attempt overlapped a retained host sleep transition and is inconclusive for input behavior.

Current-source physical QA (`validation/physical-campaign-qa-20261021/qa-main-20261023/`) completed an actual iPhoneOS Debug build-for-testing, signature/profile/bundle checks and installation under a separate QA identity. The normal campaign preserved initial evidence and reached the third relaunch checkpoint, but CoreDevice/Mercury lost the phone connection during relaunch. The attempt was interrupted without a complete XCTest summary; no campaign pass or verified save/relaunch is claimed. A read-only partial-save export also failed because the developer tunnel was unavailable. Preserve this partial QA installation and its artifacts; do not restart a fresh-journey test on its partial save or reset the original game.

The creator reported enabling developer-tool authorization locally. Subsequent normal-host `DevToolsSecurity -status` still reports disabled; a restricted read cannot inspect its authorization database. Current phone details report developer mode enabled but tunnel unavailable and DDI services unavailable. These are separate states. No credential was entered. Prepare a fresh QA identity using `-collect-test-diagnostics never` to omit verbose failure sysdiagnoses while retaining ordinary XCTest results; this option is not a proven fix for the connection loss.

Computer Use on fresh owned run `run-cua-awake-d` again refused permission before UI state or pointer input. Explicit finish/export and owned cleanup passed; no alternate desktop control ran. A separate explicit one-tap/one-touch public XCTest API comparator is now executing on an owned simulator, with only three neutral test action sites changed and canonical game sources untouched. Its result remains pending. PR39 remains draft and human playtesting is not yet ready. Next: inspect retained comparator results, finish the new isolated physical workflow, recheck device availability, then execute the current-source campaign and save verification before a playtest handoff.

Debugger authorization follow-up — 2026-10-23: after the creator repeated the local enable command, normal-host `/usr/sbin/DevToolsSecurity -status` now confirms enabled. The previous disabled observation remains historical evidence. This resolves the observed debugger authorization setting mismatch; it does not establish a repaired CoreDevice connection or a campaign/save acceptance pass.


Counted-tap comparator outcome — 2026-10-23: the isolated explicit one-tap/one-touch public XCTest API compiled in the real Apple SDK but did not resolve the neutral failure. Actual result: 1 passed, 1 failed, 0 skipped, native65; swipe case passed39.704s, loop failed27.477s. Strict trace/system capture, source integrity and owned simulator shutdown/delete passed, with no runner infrastructure error. Evidence: `validation/neutral-shell-counted-tap-20261023/run-counted-tap-a/`. The three neutral test action sites differ intentionally; canonical game app/tests remain unchanged. No API workaround or campaign acceptance is adopted. Next: restore a usable known-phone developer tunnel, then build/verify/install/test the fresh isolated current-source QA identity and verify exported campaign snapshots.

Physical connection follow-up — 2026-10-23: after USB reconnection, actual known-phone details report wired transport, connected developer tunnel, enabled device developer mode and available DDI services. New isolated current-source qa-no-diag-20261023 build-for-testing started; no new build/test acceptance yet. Prior observations remain historical. Diagnostic records merged in PR44 (`709f228b6dceaf0b6b89d91288ca080df2cce6b8`).

Fresh physical execution — 2026-10-23: qa-no-diag-20261023 actual iPhoneOS Debug build-for-testing passed, followed by both signature/profile/resource/deployment/product checks. Root and independent actual xctestrun review agree on exact QA target mappings/four bundle IDs and empty launch arguments (SHA ba9768bce47f8b4a514ac4b73844e7e6c573e5ee2756713ffebdc37b62212b2f). The new identity was absent; separate QA installation succeeded. Normal-controls full campaign is running with actual recorded `-collect-test-diagnostics never`; no XCTest summary or final save acceptance yet. Original and prior partial QA saves remain untouched. Next after a complete passing result: export and validate official campaign snapshots, then assess the remaining clean simulator matrix and physical playtest handoff requirements.
