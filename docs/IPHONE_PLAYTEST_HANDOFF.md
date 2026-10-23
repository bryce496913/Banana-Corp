# Physical iPhone playtest handoff — draft

Updated: 2026-10-23. **Preparation only; no human playtest requested.** All four current-source physical Release preservation policies passed, each with 17 termination/relaunch checkpoints and read-only save verification. Debug/both also passed. Other Debug policies, the simulator input matrix and wider accessibility coverage remain incomplete. Production app sources remain unchanged; full Act 4 takeover, Act 5 and endings remain unfinished.

## Build and supported scope

- Project/scheme: `Banana Corp/Banana Corp.xcodeproj`, **Banana Corp**. Current marketing version/build settings are 1.0 (1); identify the exact source commit and new build identifier again before any later playtest invitation.
- Tested hardware: iPhone 14 Pro, iOS 27.0.1; Xcode 26.5 on macOS 26.5. Deployment target remains iOS 18.0, but no iOS 18 runtime/device test is established. Simulator validation uses installed iOS 26.5.
- Implemented narrative scope: Acts 1–3, approved Banana Wall puzzle, and explicit minimal Act 4 entry. Full Act 4 takeover, Act 5 and playable endings are incomplete. The [Act 4 specification](ACT4_DEPENDENCY_SPECIFICATION.md) is a draft, not additional implemented content.
- Main includes native QA coverage through PR #36. Readiness helper changes remain separately tracked in draft [PR #39](https://github.com/bryce496913/Banana-Corp/pull/39); do not treat that branch as a completed campaign certification.

## Actual physical evidence

Retained locally under `validation/device-install-route-20261019/`:

| Check | Executed result |
| --- | --- |
| Signed Debug device SDK build with existing configured signing | Passed; no provisioning updates, new certificates or credential changes |
| Product bundle/resource checks | Passed |
| Normal iPhone installer and launch | Accepted and launched |
| Physical XCTest | Five hosted plus three normal launch/navigation UI cases passed: eight total, zero failed/skipped; `test-summary.json` and `launch-navigation.xcresult` |

The restricted command environment initially returned `CSSMERR_TP_NOT_TRUSTED`; rerunning read-only verification through normal host trust services passed with exit0 (`codesign-verification.json`). The initial failure is retained. The iPhone installer and physical UI tests also accepted the build. No trust setting was changed, certificate check bypassed or alternate installer used. The packaged provisioning profile expires 2027-06-09 UTC; signing remains device/profile-specific.

The existing app was not erased. A preinstall save-directory listing failed; it does not prove an empty save. Physical launch/navigation smoke tests do not establish campaign persistence, reset, full accessibility or complete progression. Separate iOS 26.5 simulator Debug reset/cancel/confirm/relaunch passed (295.828 seconds, one pass, zero failures/skips); Release diagnostics absence passed (25.807 seconds, one pass, zero failures/skips). Evidence: `validation/native-experience-20261019-135341-9708/`.

An isolated side-by-side **Banana Corp QA** installation subsequently passed the full normal-control Debug/both campaign on this phone:1756.072seconds,1passed/0failed/0skipped,17termination/relaunch checkpoints through Acts1–3 and minimal Act4entry. Read-only final-save export passed official progression assertions plus35receipt/7preserved-snapshot catalogue checks. Evidence: `validation/physical-campaign-qa-20261021/qa-auto-20261021/Debug-both-unlocked.xcresult`. The original game/save was never targeted. This historical QA build includes the StatusBar refactor from closed, unmerged PR40; it is not a Release or all-path pass and does not resolve the failed iOS26.5 simulator input check. Initial runner authentication failed before gameplay when the phone locked; that separate result remains retained.

Current-source physical evidence now supersedes the retired-source limitation for **Debug/both only**: `validation/physical-campaign-qa-20261021/qa-no-diag-20261023/`. Actual SDK build, exact signature/profile/resource checks, built test configuration, fresh QA installation and full normal-controls campaign passed. Read-only export and unchanged official assertions plus snapshot checks passed for35receipts/7preserved records. Final save integrity is verified; full-state raw bytes were not exported at each checkpoint. Original/priorQA saves were untouched. The separate Release identity `qa-release-20261023` also passed build/product/install, full campaign and final save/snapshot checks (1/0/0,1754.814s,17checkpoints). Debugger authorization and the wired developer tunnel were verified before execution; diagnostics never was recorded in the test CLI, without attribution of the previous failure to any single change.

## Tested local installation route

Use a connected, unlocked, paired iPhone with Developer Mode enabled and recognized by Xcode. Keep the project's existing app identity and configured signing team. Device identifiers below are placeholders selected locally, not public device information.

```sh
xcrun devicectl list devices
xcodebuild -project 'Banana Corp/Banana Corp.xcodeproj' \
  -scheme 'Banana Corp' -showdestinations

# Set PHONE_UDID to the physical destination reported by Xcode.
# Set CORE_DEVICE_ID to that same phone's identifier from devicectl list devices.
xcodebuild -project 'Banana Corp/Banana Corp.xcodeproj' \
  -scheme 'Banana Corp' -configuration Debug \
  -destination "platform=iOS,id=$PHONE_UDID" \
  -derivedDataPath validation/device-install-route-20261019/DerivedData build

python3 scripts/check-ios-project.py \
  --app-bundle 'validation/device-install-route-20261019/DerivedData/Build/Products/Debug-iphoneos/Banana Corp.app'

xcrun devicectl device install app --device "$CORE_DEVICE_ID" \
  'validation/device-install-route-20261019/DerivedData/Build/Products/Debug-iphoneos/Banana Corp.app'
xcrun devicectl device process launch --device "$CORE_DEVICE_ID" \
  Bryce-Cameron-Design.Banana-Corp
```

For a later build, choose a fresh evidence/DerivedData directory and update all paths consistently. These command shapes were exercised for the current local route; they do not promise that signing remains valid indefinitely or that another device is provisioned. If existing signing fails, record the error and stop before certificate/profile creation or provisioning changes. An unsigned `CODE_SIGNING_ALLOWED=NO` build cannot replace installation validation. No public distribution, App Store Connect upload or external release is covered by this handoff.

## Remaining gates before invitation

| Gate | Current status |
| --- | --- |
| Complete normal-control Acts 1–3 → Act 4 entry matrix | **INCOMPLETE overall**; current-source physical Release all four policies and Debug/both passed. Remaining physical Debug policies have not completed; the clean simulator matrix failed its first Home return and stopped. Do not combine these separate scopes into a full matrix pass |
| Meaningful progress and authentic preserved evidence after termination/relaunch | **PASS for physical Release all four policies and Debug/both**;17 normal relaunch checkpoints per case and official final save/snapshot checks passed. Release receipts/preserved: both35/7, email36/1, video35/6, neither36/0. Other Debug policies and clean simulator matrix remain incomplete |
| Reset cancel/confirm, archive retention and replay where implemented | **PASS on iOS 26.5 Debug simulator**; one test passed in 295.828 seconds, zero failures/skips. Cancel retained meaningful progress; confirmed fresh state survived relaunch. Exported archive/source/receipt comparison passed. Release has no player reset control. |
| Intermittent missed taps/Continue/Previous actions | **UNRESOLVED**; no proven production root cause/fix |
| Complete accessibility, VoiceOver and Reduce Motion coverage | **PENDING**; focused Home Dynamic Type/contrast passes do not establish full coverage; default audit timed out with framework Code -56 |
| iOS 18 and wider physical device matrix | **NOT RUN**; deployment support is not runtime proof |
| Complete Acts 4–5 / ending routes | **NOT IMPLEMENTED**; unresolved canon contracts remain reserved |

See [current progress](../AGENT_PROGRESS.md), [QA plan](../QA_TEST_PLAN.md) and [native integration instructions](IOS_INTEGRATION_VALIDATION.md). This draft must be updated with the actual final scope, exact commit/build, remaining known issues and completed gate evidence before inviting hands-on testing.

## Future playtest checklist

Once the intended milestone is ready, test normal controls without debug shortcuts: launch and explore existing apps; follow the opening investigation; preserve disappearing evidence or use the legitimate independent route; compare Alex's original/replacement; investigate Daniel, Maya and ECHO-07; review clues and solve the Banana Wall; complete the explicit Act 3 synthesis/conclusion and Act 4 entry. Stop at the implemented entry objective rather than expecting takeover/endings.

Across that journey, terminate/relaunch after meaningful discoveries and preserved evidence, confirm progress and original snapshots remain, and note navigation, scrolling, safe-area, gesture, text-size or media problems. Reset testing must use an explicitly disposable campaign after preserving bug evidence; do not reset an ongoing campaign merely to install a build.

Gameplay duration is **unmeasured; planning estimate 30–60 minutes** for the recorded Acts 1–3/minimal Act 4 route. Its 31 read authored versions contain approximately 3,070 readable words (body plus titles/subtitles, excluding content-ID aliases and repeated snapshot copies). Assuming 180–240 words/minute gives 13–17 minutes of reading, plus an estimated 15–40 minutes for investigation, navigation, clue review and puzzles. These are planning assumptions, not measured player timing; optional exploration, repeated comparisons and accessibility needs can extend the session. Automated test duration was not used.

## Bug report template

```text
Build/version and source commit:
iPhone model / iOS version:
Approximate act / app / last completed objective:
Steps from the last known working screen:
Expected result:
Actual result (including missed tap or exact displayed text):
Does it persist after ordinary terminate/relaunch? (Do not reset.)
Evidence preserved before the issue? Which source/version, if visible?
Approximate occurrence time and frequency:
Screenshot or screen recording, if useful:
Accessibility settings relevant to the issue:
```

Capture only the fictional game and relevant system settings; exclude unrelated personal screens. A report need not contain device serial numbers, account details or credentials.
