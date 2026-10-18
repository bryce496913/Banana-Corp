# QA test plan

Updated: 2026-10-18. Scope: authorized [Banana Corp repository](https://github.com/bryce496913/Banana-Corp) only. Use [game canon](BANANA_CORP_GAME_BIBLE.md), [roadmap](DEVELOPMENT_ROADMAP.md) and [progress tracking](AGENT_PROGRESS.md).

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

Current Apple matrix: actual Xcode 26.5 Debug/Release builds and integration tests passed on iOS 26.5. Full journey has one diagnostic pass; the clean preservation/configuration matrix remains incomplete. iOS 18 is NOT RUN because its runtime is absent. Physical iPhone, native VoiceOver and Instruments are NOT RUN. See the retained native records below and [current progress](AGENT_PROGRESS.md); the earlier Linux limitation no longer describes this execution environment.

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
