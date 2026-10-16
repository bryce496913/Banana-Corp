# Agent progress and continuation record

Updated: 2026-10-15. Current phase: **B — native Debug/Release integration passed; full journey validation in progress**. See [roadmap](DEVELOPMENT_ROADMAP.md), [test plan](QA_TEST_PLAN.md), [creator directive](AUTONOMOUS_DEVELOPMENT_DIRECTIVE.md) and [repository instructions](AGENTS.md).

## Authority and baseline

Only `bryce496913/Banana-Corp` and the named `Banana Corp App` ChatGPT project are authorized development resources. Work in this pass used this repository and explicitly supplied documents; no unrelated projects, personal files or credentials were accessed. ChatGPT project conversations were not read. No paid operation, signing/distribution or application release was performed.

Baseline main commit: `bd2f5bb98f94f5616142eccf0fa6bc02f0c23e6b`, tree `a38943281b292b3c6ab4a182ca617b1bda3289b8`. Recent merged PRs #25–29 covered Act 3/entry stabilization, asset scaffolding and the preview key-path fix. No GitHub Actions workflows exist in this baseline. Do not assume historical model/syntax checks are proof of an Xcode build.

## Completed reconnaissance

- Read current repository instructions, canon/open decisions, progression/inventory/QA documentation, asset workflow and native test/build configuration; used parallel read-only build/story audits scoped to this repository.
- Confirmed 70 production records, 25 restricted resources, the approved Wall puzzle, schema-2 single-authority persistence/Evidence, 15 routes, Acts 1–3 plus minimal Act 4 entry, and incomplete takeover/endings.
- Confirmed source-art inventory is planned, videos are transcripts where no media exists, and Photos/Phone content gaps are not authorization to invent new clues/calls.
- Created durable directive, roadmap, QA plan and this handoff. Existing story requirements and source/snapshot IDs remain unchanged.

## First focused improvement

The native journey script built the shared scheme's hosted `@testable` tests in Release without `ENABLE_TESTABILITY=YES`, while the integration script already applied that test-only override. The journey invocation now passes it explicitly; ordinary Release product configuration is untouched.

Both native runners now retain stderr with stdout in build/test logs. A portable six-case fake-toolchain harness exercises both scripts in isolated temporary repositories: Debug/Release command flags, combined diagnostic logs, exit-42 failure propagation, skipped-test rejection and cleanup only for owned journey simulators. It does not compile or run the iOS app.

Fresh validation on 2026-10-15:

- All 16 existing Swift check suites passed using Swift 6.2.4 in a network-disabled, read-only-source Linux container.
- The new portable suite passed all six mocked runner cases (17 check scripts total).
- All 52 app/native-test Swift files passed frontend syntax parsing in Debug and Release; this does not type-check SwiftUI against an Apple SDK.
- Static Xcode configuration checks passed for 3 targets and 49 app sources; 156 local Markdown references, shell syntax and whitespace checks passed.
- Both native runners exited 69 on Linux as designed. Actual Xcode builds, XCTest, simulator gameplay and device checks remain NOT RUN.

B-01 is complete. The focused PR records publication and integration status; next session verify main includes the runner flag/log fixes before continuing. No runtime SwiftUI, narrative, gameplay, save schema, assets or Xcode build configuration was changed in this pass.

## Current blockers and next authorized work

1. **APPLE-01 — BLOCKED:** no Xcode/Apple SDK, simulator or connected authorized iPhone in this environment. Native Debug/Release compile, actual journey, image loading, gestures, VoiceOver and Instruments remain NOT RUN. Do not request a human playtest without an actual build/install route.
2. **DESIGN-01 — unresolved:** exact later Act 4/5 puzzle/route/ASCENSION/cooperation/replay decisions remain TBD in the bible. Prepare a concrete proposal or implement independently established requirements; never silently decide passwords, note/baseline values, hidden scores, identities or ending conditions.
3. **ART-01 — incomplete production media:** 132 planned image IDs are not approved image files; mood-board/character/headset reference images were not available for independent review. Preserve existing logo/icons and integrate only actual approved art.
4. **QA-01 — incomplete corpus/device evidence:** no real archived-player save corpus or production optional-clue collection was supplied/validated. Fixture/model tests do not close that gap.

Next session: inspect latest main and this record, run the portable/native preflight checks, and prioritize the first available Apple compile. If Apple execution remains unavailable, proceed with an Act 4 approved-versus-TBD implementation specification and other evidenced technical repairs within canon; do not add a paid hosted runner or new external access automatically. Keep detailed outcomes here and in focused PRs. No creator decision is needed for ordinary engineering; ask only for a concrete consequential permission or an explicit unresolved design approval when genuinely required.


## Native Mac execution — 2026-10-15

This exported workspace has no `.git` metadata. Verified authorized remote main is `da5c42ba16403c5a1aaf974479377963061baaf9`; a temporary clone at `/tmp/banana-corp-native-git` has branch `fix/native-launch-validation`. No PR or merge has been completed in this run.

- Host macOS 26.5 (25F71), arm64; selected developer directory `/Applications/Xcode.app/Contents/Developer`; Xcode 26.5 (17F42), Apple Swift 6.3.2, iOS and simulator SDK 26.5. Project has app, hosted-test and UI-test targets with shared Banana Corp scheme and iOS 18.0 minimum.
- Installed runtimes: iOS 26.5 (23F77) and iOS 16.1. iOS 18 is absent; iOS 16.1 is below the deployment target and was not used.
- Dedicated iPhone 17 Pro simulator `8F247F02-8046-4E63-85E2-84AF2513BB82`; sandbox initially denied CoreSimulator access, host escalation enabled actual execution.
- **PASS:** actual Debug and Release simulator builds, plus actual product bundle checks. Logs/DerivedData retained at `validation/native-20261015/`. Only build warning: no AppIntents dependency for metadata extraction.
- **PASS:** five Debug hosted XCTest cases, including catalogue loading, passive queries, artwork/Info.plist, route model cycles and evidence save/new-store reload.
- **FAIL:** three Debug launch UI tests cannot find Home email button within launch timeout. Existing original smoke also fails. Journey test skipped intentionally without its runner path. Integration runner correctly stopped with exit 65; Release XCTest and full native journey remain NOT RUN.
- Expanded LaunchSmokeTests with all-15-route screenshots and fictional Home-strip swipe coverage. These tests are not yet passing; no app behavior/story was changed.
- Normal manual `simctl launch` eventually displayed Home; retained screenshots `/tmp/banana-native-screen.png` (splash) and `/tmp/banana-native-later.png` (Home). This is diagnostic evidence, not a journey pass. Failure attachments exported under `validation/native-20261015/attachments/`; process sample `/tmp/banana-launch-sample.txt` shows SwiftUI rendering, not a proven deadlock.
- **PASS:** all 17 portable check scripts and static project check on this Mac, with exact exit results in `validation/model-20261015/results.txt`. Initial sandbox-cache failures retained separately. These do not establish native gameplay.

Next: finish warmed original smoke rerun (`validation/native-20261015/smoke-retry.log` / `.xcresult`), diagnose launch accessibility/timing with actual attachments, repair only confirmed defects, rerun full integration Debug/Release, then execute all four native journey paths in both configurations. Review all-route screenshots and remaining accessibility/gesture/reset coverage. Keep Act 4/5 design TBDs closed. Physical build signing/install route remains unverified; no human playtest readiness claimed.

Diagnosis update: warmed smoke reproduced the failure. `smoke-tree.log` proves all four visible dock buttons inherited `bananaOS.dock` instead of their per-route identifiers, while grid buttons retained theirs. Removed the unused dock-container identifier (no production lookup depended on it). This is an accessibility/integration repair, with no narrative, mechanics, persistence, deployment or visual change. Full native rebuild/retest is running in `validation/native-fixed-20261015/`; no passing UI claim yet.

Repair retest: actual Debug and Release simulator builds/bundle checks passed again. Debug XCTest now passes all five hosted cases and all three UI smoke cases (all 15 apps, repeated launch/Home, reserved-strip upward swipe); journey correctly skipped in this integration run. Release XCTest is running. Full four-path/two-configuration journey runner is started separately (`validation/journey-native-runner.log`). Git push failed with no CLI credentials; commit `f87aea2` remains in the temporary feature branch. Browser publication is being attempted through the signed-in authorized repository UI without extracting credentials.

Continuation: Release hosted tests passed, but two Release UI cases failed waiting for Home after an app open; Home swipe passed. These ran while the fresh journey simulator was preparing, so resource contention remains a hypothesis, not a verified cause. Both native processes were interrupted before finalization; full journey has no completed path. A serial Release XCTest rerun is now retained in `test-Release-serial.log` / `tests-Release-serial.xcresult`. Do not merge until native failures are resolved and reviewed.

PR #31 is published as a draft: https://github.com/bryce496913/Banana-Corp/pull/31 (remote commit `534091e43c75df69de031a5d1ecd91a1c98f83e3`). The connector recovered, permitting publication without credentials extraction. Serial Release suite completed with one all-app failure at Browser; original smoke and swipe passed. Discovered interrupted journey simulator remained booted; shut down only that owned simulator, retaining data. Targeted Release all-15-route rerun now PASSED (`route-diagnostic.xcresult`, exit 0), without increasing timeouts or changing app behavior. Complete isolated Release suite is running (`tests-Release-isolated.xcresult`). Failure-only hierarchy logging added to the shared test wait helper. Earlier failures remain retained; simulator-resource contention is a plausible explanation, not established app causation.


## Isolated native confirmation — 2026-10-16 continuation

The completed results below supersede the pending statuses in earlier chronological notes:

| Check | Actual result / retained evidence |
| --- | --- |
| Debug + Release Apple simulator builds | PASS, `validation/native-fixed-20261015/build-{Debug,Release}.log` |
| Actual Debug + Release bundle inspection | PASS, `bundle-{Debug,Release}.txt` in that directory |
| Debug hosted XCTest | PASS: 5 cases, `tests-Debug.xcresult` |
| Debug UI smoke | PASS: all 15 routes, repeated launch/Home, reserved-strip swipe; 3 cases. Journey correctly skipped |
| Release hosted + UI XCTest, isolated | PASS: 5 hosted + 3 UI cases; `tests-Release-isolated.xcresult`, process exit 0. Journey correctly skipped |
| Full normal-control journey | New isolated matrix running via `validation/journey-isolated-runner.log`; no completed path claimed yet |
| Portable/static checks | PASS: 17 scripts + project structure; prior exact results retained in `validation/model-20261015/results.txt` |
| Visual QA | Incomplete: several earlier screenshots need settled recapture; no confirmed layout defect from incomplete captures |
| iOS 18 / physical iPhone / signing | NOT RUN: iOS 18 runtime absent; physical signing/install not established |

Release failures before isolation remain retained and are not relabeled passes. The targeted all-route and complete isolated Release reruns passed without raising timeouts or changing app behavior. Only one owned QA simulator should be booted during subsequent native runs. The interrupted journey simulator was shut down without deleting its data; the integration simulator was shut down before restarting the journey matrix. An interrupted tool session may leave an owned simulator booted, so verify ownership/status before resuming.

PR #31 remains draft pending final record sync/review. Next: inspect the first real journey outcome, repair verified integration failures, complete remaining evidence paths/configurations, then close visual/accessibility/reset gaps. Do not use diagnostics/replay shortcuts in journey tests and do not activate later canon TBDs.

PR #31 merged successfully as `7d5071a3445720ee627ea3125de62be9553e9f18` after native Debug/Release integration, scoped review and GitHub mergeability/requirements checks. No protections were bypassed. Full journey continues separately in `validation/acts-20261016-105502/` (runner session 82858); it has no completed result yet.

First isolated journey result: FAIL after 299.98 seconds on Debug/both. Normal UI completed Acts 1–2 (leak preservation/removal/warning/denial, Alex original+replacement/evidence, Daniel/Maya/ECHO-07 and explicit cross-source synthesis), with multiple real relaunch checkpoints. At the next Browser icon tap the app stayed on Home; the test failed waiting for `bananaOS.home`, before Act 3 handoff. Failure video last-frame extraction confirms Home, not a proven story-gate defect. Logs/xcresult/attachments retained in `validation/acts-20261016-105502/`. New branch `fix/native-journey-navigation` starts at merged PR31. A fresh rerun adds failure-only hierarchy/screenshot diagnostics to ActsJourneyTests; no timeouts, app behavior, progression, save or canon changed. Runner log: `validation/journey-diagnostic-runner.log` (session 10730). No completed full journey path claimed.

Second diagnostic journey: FAIL after 427.68 seconds, now beyond the previous Browser tap, through normal Act3 entry, clue review, four-field Wall solve, draft retention and scope record reload. Failed opening the neural-capabilities detail after earlier research reads. Recording shows the main story list squeezed below an unscrollable growing RestrictedAccessEntries list; the target card remains at the clipped bottom. This confirms a Browser composition problem independent of the earlier transient Home tap. Repair in progress: a single Browser AppScreenScroll owns both protected entries and shared source rows; StorySurfaceContent keeps its existing default scrolling for catalogue/recovery screens and preserves existing placeholder ownership. No authorizer, content ID, read action, prerequisite, save or story change. Debug/Release integration rerun requested in `validation/browser-scroll-20261016/`; no pass claimed yet. ActsJourney openAndRead now uses the existing readiness diagnostic helper for its Back check, retaining the five-second timeout.

Review correction: the placeholder guard was first bundled with an escalated build command whose approval review timed out, so that edit did not execute. The standalone build retry compiled the earlier wrapper variant. Review caught the mismatch; the guard is now actually applied and independently reread. Earlier `browser-scroll-20261016` build results must not be used as final validation for the corrected shared-row revision. Native final rebuild/journey remains required.

Temporary Debug navigation stress probe completed PASS: 20 ordinary terminate/launch/open/Home cycles, 246.26 seconds, no retries; narrowly filtered local unified-log samples record action → AppState home-phase acceptance. The intermittent missed tap did not reproduce, so its root cause remains unproven. Probe logs/extended loop are now removed, original smoke loop restored. Removed RestrictedAccessEntries horizontal padding because its only caller is now inside the shared Browser scroll padding, retaining source alignment. Clean corrected revision now needs final Debug/Release integration and full journey regression; PR32 stays draft.

Clean Browser repair integration PASS (`validation/browser-scroll-clean-20261016/`, runner exit 0): actual Debug/Release builds, both bundles, five hosted + three UI tests in each configuration. Binaries checked to exclude temporary probe strings. Published app revision `f82895ef1a66cdb22c555b3a0a830292e96686ce`. Journey helper now additionally requires target center inside the owning scroll viewport before tap, preserving its 16-scroll limit/timeouts and adding no retries; this addresses the observed partially clipped card condition. Full fresh journey rerun is the next validation gate.
