# Acts 1–2 device QA

**2026-10-14 extension:** the approved Banana Wall is now implemented. The native journey runner additionally reviews clue links, retains a draft through Home, solves the puzzle, opens its sole scoped reward and relaunches into persistent access. See [banana-wall-implementation.md](banana-wall-implementation.md); the historical NOT RUN device results below are not upgraded to passes by this extension.

Date: **2026-10-13**. Baseline: merged Xcode integration PR #20, tree `2e46ae0edddbe9e3bd0bca3ac0478a86e26d99fd`.

**The requested Apple-platform completion criterion remains unmet.** PR #20 supplied integration repairs and native coverage, but did not establish a successful Xcode build. This workspace still runs Linux without Xcode, Apple SDKs, simulator tooling or an authorized iPhone. No primary player/UI playthrough, simulator execution or physical-device validation is claimed here.

## Scope and findings

Reviewed the canonical [bible](../BANANA_CORP_GAME_BIBLE.md), repository instructions, bundled story/access catalogues, progression rules, existing Act 1/anomaly/Act 2/evidence checks, app/source/Assistant/Evidence/Browser views, navigation owner and [integration report](IOS_INTEGRATION_VALIDATION.md).

No progression blocker was reproduced in the executed **model** journeys. Accordingly, this pass does not change story requirements, content, read effects, progression logic, persistence, navigation, launch, games or visual design. No puzzle solution or Act 3 research was added. Native presentation/accessibility defects cannot be ruled out without Apple execution.

Added stable accessibility **identifiers** to existing source, presentation, evidence, Assistant, handoff and locked-resource controls. Spoken labels and story text remain unchanged; IDs derive from existing content/version/evidence identities and do not reveal locked content. They add no player action, state bypass, permission or persistence field.

Added:

- [ActsJourneyChecks.swift](../Tests/ActsJourneyChecks.swift) / [check-acts-journey.sh](../scripts/check-acts-journey.sh): four independent email/video preservation combinations, production catalogues and normal delivery/progression actions, eleven exact file-store reopen checkpoints per path, unread-count changes, one notification, immutable archive retention and the still-locked Banana Wall. No debug replay or injected milestones/acts.
- [ActsJourneyTests.swift](../Banana%20Corp/Banana%20CorpUITests/ActsJourneyTests.swift): native UI preparation for the full journey using existing Home/app/source/Finish/Preserve/Compare/Assistant/Connect/advance controls. Includes ordinary splash, real application termination/relaunch and retained checkpoint screenshots. **Apple SDK compilation and execution are outstanding.**
- [validate-acts-journey.sh](../scripts/validate-acts-journey.sh): on a Mac with Xcode 26+, creates a fresh dedicated iPhone simulator for each preservation/configuration case. Runs only the journey test, retains xcresult/logs/screenshots and final real app-save JSON, and rejects skipped/failed tests or an incorrect final save. It deletes only simulators it created; existing player devices/saves are never reset.

The native runner's `BANANA_QA_PATH` selects preservation choices **in XCTest only**. No QA launch argument or app branch changes progression. Without a runner path the journey test explicitly skips; ordinary integration test success must not be reported as a full Acts 1–2 playthrough. The dedicated script requires one passed test and zero skipped/failed tests, so failure to forward the runner environment cannot masquerade as QA success.

## Executed model matrix

“PASS (model)” below is deliberately separate from player/device QA. Device: Linux x86_64 with official Swift **6.2.4**, Swift 5 language mode, warnings as errors, read-only source and no container network. iOS version: **N/A** for every model row.

| Test case | Expected | Actual | Status | Device / iOS | Issue/fix | Retest |
| --- | --- | --- | --- | --- | --- | --- |
| Save neither original | Delivery record/independent reporting allow advancement without fabricated proof | Reached Act 3 locked Wall; no evidence entries | PASS (model) | Linux / N/A | No blocker reproduced | Passed final suite |
| Save email only | Authentic email survives removal; video follows independent route | Exactly one original-email snapshot; reached locked Wall | PASS (model) | Linux / N/A | No blocker reproduced | Passed final suite |
| Save video only | No email proof; exact Alex transcript/metadata compares against live v2 | Exactly one original-video text snapshot; reached locked Wall | PASS (model) | Linux / N/A | No blocker reproduced | Passed final suite |
| Save both originals | Both immutable snapshots survive their live changes | Two original snapshots retained; reached locked Wall | PASS (model) | Linux / N/A | No blocker reproduced | Passed final suite |
| Eleven interruptions per path | Reopening the file-backed store restores exact state and archive bytes | **44** exact reopen checks passed across four paths | PASS (model) | Linux / N/A | Not OS termination/device execution | Passed final suite |
| Reads/unread/notifications | Explicit reads change counts; boundary/consumption cannot duplicate notification | Email/message counts decreased on explicit reads; one notification remained acknowledged | PASS (model) | Linux / N/A | No counter/event change needed | Passed final suite |
| Optional exploration and reveal gates | Lists/passive queries do not advance; optional saves/games remain optional | Four journeys use no games, VR preview or fabricated facts; passive queries left state unchanged | PASS (model) | Linux / N/A | Existing separate suites test omitted prerequisites | Passed final suite |
| Locked Banana Wall/reopen | Visible only after legitimate Act 3 handoff; no solution/access granted | Locked resource survives reopen; pending challenge rejects submission; puzzle/access sets empty | PASS (model) | Linux / N/A | TBD design remains TBD | Passed final suite |

The file-store reopen checks compare the entire decoded state and stored snapshot bytes; they construct new production stores over the saved file **within the test process**. They do not claim operating-system lifecycle behavior. Existing first-anomaly and Act 2 suites additionally launch separate test processes at nine checkpoints per evidence path, validating persisted facts through process boundaries; these also are not iPhone app execution.

## Required player/device matrix

Device and iOS entries are **unavailable** until a Mac or authorized iPhone runs the case. All rows are **NOT RUN**, not inferred passes from model evidence. Issue **QA-APPLE-01**: no Apple tools/platform. Retest status **pending Apple execution** for every row.

| Test case | Expected result | Actual result | Status | Device / iOS | Issue/fix | Retest |
| --- | --- | --- | --- | --- | --- | --- |
| Fresh launch/Home/exploration | Normal splash and fictional phone; no premature leak/Act 2 source | No app execution | NOT RUN | Unavailable / unavailable | QA-APPLE-01 | Pending |
| Launch coverage + official promo | Explicit article open and all five panels/Finish unlock the leak in either order | No native control execution | NOT RUN | Unavailable / unavailable | QA-APPLE-01 | Pending |
| ECHO original read and save | Original stays preservable in detail until a return boundary | No rendered read/preserve | NOT RUN | Unavailable / unavailable | QA-APPLE-01 | Pending |
| Email saved path | Exact original opens in Evidence; live source unavailable; factual comparison | Model evidence only | NOT RUN | Unavailable / unavailable | QA-APPLE-01 | Pending |
| Email unsaved path | No saved original/proof; trace and warning provide a route forward | Model evidence only | NOT RUN | Unavailable / unavailable | QA-APPLE-01 | Pending |
| Warning/Assistant/contradiction/Act 2 | Warning remains unread until opened; explicit question/investigation then handoff | No native navigation | NOT RUN | Unavailable / unavailable | QA-APPLE-01 | Pending |
| Alex original/presentation/replacement | Each version requires final Finish; changed source has same location; no imaginary media | No native presentation | NOT RUN | Unavailable / unavailable | QA-APPLE-01 | Pending |
| Alex saved path | Original transcript/metadata retained, no playable-video claim; real v2 differences | Model evidence only | NOT RUN | Unavailable / unavailable | QA-APPLE-01 | Pending |
| Alex unsaved path | No fabricated archive; independent corroboration remains available | Model evidence only | NOT RUN | Unavailable / unavailable | QA-APPLE-01 | Pending |
| Reports → Daniel → Maya → ECHO-07 | Explicit inspection unlocks the approved leads without later revelations | No rendered investigation | NOT RUN | Unavailable / unavailable | QA-APPLE-01 | Pending |
| Diagnostic/Assistant/Connect/Act 3 | Questioning and proof/corroboration precede explicit synthesis and handoff | No native actions | NOT RUN | Unavailable / unavailable | QA-APPLE-01 | Pending |
| Browser → locked Wall | Locked entry accessible; no Submit/input/approved solution | No native locked screen | NOT RUN | Unavailable / unavailable | QA-APPLE-01 | Pending |
| All story apps/Home/nested Back | One persistent Home, vertical root transitions, reliable scrolling and returns | Source/model review only | NOT RUN | Unavailable / unavailable | QA-APPLE-01 | Pending |
| Gesture conflicts and native modals | Home strip separate from source scrolling/game controls; no real Home interception | No touch/modal testing | NOT RUN | Unavailable / unavailable | QA-APPLE-01 | Pending |
| Small/large/Island/safe areas | Fictional status only; safe controls, readable long content and archives | No rendered layouts | NOT RUN | Unavailable / unavailable | QA-APPLE-01 | Pending |
| iOS 18 fallback / iOS 26 glass | Both supported runtimes build and behave correctly | Guarded source reviewed only | NOT RUN | Unavailable / unavailable | QA-APPLE-01 | Pending |
| VoiceOver/Dynamic Type/Reduce Motion | Essential actions remain accessible and non-gesture alternatives work | IDs added, no assistive execution | NOT RUN | Unavailable / unavailable | QA-APPLE-01 | Pending |
| Keyboard | Existing story uses incoming threads/scripted choices; pending Wall has no input. Any available input must remain safe | No keyboard execution; no new composer added | NOT RUN | Unavailable / unavailable | QA-APPLE-01 | Pending |
| Physical iPhone | Authorized signed install, real touch/haptics/performance and relaunch work | No device/provisioning | NOT RUN | Unavailable / unavailable | QA-APPLE-01 | Pending |

## Interrupted-session matrix

Run each checkpoint with both email choices and both Alex choices. Store reopen: **PASS (model)** at every row; actual termination/relaunch: **NOT RUN**, device/iOS unavailable, QA-APPLE-01, retest pending. The native test's screenshot-and-relaunch steps are prepared coverage, not completed results.

| Checkpoint | Resume expectation | Model reopen | Device result / retest |
| --- | --- | --- | --- |
| Before email read | Email available/unread, original unchanged | PASS in all four paths | NOT RUN / pending |
| After email read | Read fact and any exact snapshot persist | PASS in all four paths | NOT RUN / pending |
| Before first removal | Source still original until a real return/inbox boundary | PASS in all four paths | NOT RUN / pending |
| After first removal | Source unavailable, delivery/warning once, evidence unchanged | PASS in all four paths | NOT RUN / pending |
| Before warning read | Warning unread; no read credit from notification/list | PASS in all four paths | NOT RUN / pending |
| After Assistant questioning | Factual interaction persists; no trust/cooperation score | PASS in all four paths | NOT RUN / pending |
| Before Alex replacement | Original viewed and any preserved text record persist | PASS in all four paths | NOT RUN / pending |
| After Alex replacement | Live v2 and original snapshot remain distinct | PASS in all four paths | NOT RUN / pending |
| After ECHO-07 | Explicit research read and eligible diagnostic lead persist | PASS in all four paths | NOT RUN / pending |
| Immediately before Act 3 | Explicit Connect saved; act remains 2 until handoff | PASS in all four paths | NOT RUN / pending |
| At locked Wall | Act 3 and locked entry persist; no breach/access facts | PASS in all four paths | NOT RUN / pending |

Force termination does not imply a SwiftUI `onDisappear` callback ran. Relaunch should reconstruct Home and reconcile eligible changes only at the existing return/inbox/library boundaries. Do not require the interrupted detail's transient panel/scroll/selection position to survive: those are not saved narrative state. Verify no archive is reconstructed from internal read receipts.

## Validation actually attempted

```sh
bash scripts/validate-acts-journey.sh \
  com.apple.CoreSimulator.SimRuntime.iOS-18-0 \
  com.apple.CoreSimulator.SimDeviceType.iPhone-16
xcodebuild -project 'Banana Corp/Banana Corp.xcodeproj' -scheme 'Banana Corp' \
  -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16' \
  '-only-testing:Banana CorpUITests/ActsJourneyTests/testActsOneTwoPlayerJourney' test
xcrun simctl list runtimes
```

The runner returned **69** before simulator creation: unavailable platform. Both Apple tools returned **command not found / 127**. Runtime/device labels above are command parameters, **not proof that a simulator exists**.

Run the model checks with `bash scripts/check-acts-journey.sh`. All **11** current Foundation/check suites passed in the official Swift container, including the four new combined paths and existing separate-process checks. All **51** app/native-test sources parsed in DEBUG and Release; structural project membership, **68** local Markdown references, shell syntax and whitespace checks passed. No Apple compilation/build/test result is inferred from them.

## Finish QA on a Mac/iPhone

1. Complete [native integration validation](IOS_INTEGRATION_VALIDATION.md) with Xcode 26+, installed SDK/runtimes and Python 3. Repair actual compiler/test failures first; no SDK suppression or progression shortcut.
2. List installed runtime/device-type IDs with `xcrun simctl list runtimes` and `xcrun simctl list devicetypes`. Choose an iOS 18 runtime and a small supported iPhone, then iOS 26 and a larger Dynamic Island iPhone. Record any missing runtime explicitly.
3. Run the dedicated QA script for each available combination:

   ```sh
   bash scripts/validate-acts-journey.sh INSTALLED_IOS_RUNTIME_ID IPHONE_DEVICE_TYPE_ID
   ```

   This runs four preservation choices in both Debug and Release, on separate new simulators. Do not use DEBUG diagnostics, replay/reset controls, injected story flags or edited saves. Review XCTest failures/skips, native logs, captured screens and final app-save assertions. Preserve failures in the report and rerun after a concrete repair.
4. Manually repeat at least one uninterrupted fresh primary journey and all preservation choices using the exact existing controls: News → official Video → ECHO Email → return boundary → warning Messages → Assistant → trace/Evidence comparison → Continue investigation; original Alex → Finish/optional preserve → return boundary → live Alex Finish → reports/official response → Daniel Messages → Maya Email → ECHO-07 Browser → Diagnostics → comparison/independent report → Assistant question → Connect → Act 3 → Browser Banana Wall. Read/scroll bodies, use Previous/Back, explore optional sources out of order, preserve repeatedly and verify no extra milestones/duplicate entries.
5. Manually terminate at every matrix checkpoint, then relaunch normally. Check warning/message badges and notification non-replay, exact archive bytes/titles/metadata, version/act continuity and both recovery paths. The native runner collects checkpoint screenshots but does not prove every layout/gesture/assistive edge case.
6. Test tap/VoiceOver/swipe Home, nested Back/links, long text/archives, both orientation support and safe-area sizes, Reduce Motion/Transparency, large text, game controls and native alert dismissal. Current video evidence is text/metadata only; do not label it saved playable footage. Do not introduce free-form chat or an input into the pending Wall just for keyboard QA.
7. If an authorized physical iPhone is available, follow the signing/install/launch commands in the integration report, then repeat the player/device matrix with its actual model and OS version. No physical validation is claimed until executed.
8. Update each row with actual outcome, device/runtime, issue reference, repair and retest evidence. A model PASS cannot close a device NOT RUN row. Keep the PR's Apple QA status open until a real primary journey reaches the locked Wall and critical failures are resolved.

No implementation/canon conflict was resolved silently. The remaining known blocker is **QA-APPLE-01**; full player-facing completion and absence of native defects are still unverified.
