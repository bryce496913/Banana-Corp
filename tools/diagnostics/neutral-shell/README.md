# Neutral shell input reproduction

Developer-only standalone SwiftUI/XCTest project. It is not linked into Banana Corp, wired into CI, or a gameplay acceptance gate. The baseline app, UI tests, project, shared scheme and copied style provenance are byte-for-byte copies of the reviewed 2026-10-22 fixture; `baseline-fixture-sha256.json` inventories those five native/provenance files.

The neutral launcher retains Home underneath a disposable NavigationStack, models opening/active/closing states, uses two one-second clocks, pressed styles, icon long press and a reserved Home strip gesture. No story, assets, catalogue, persistence, signing team or player data is present. `source-comparison.json` records the original AppMotion.swift source SHA256 and copied-prefix SHA256 from the main 8d5 baseline; the copied prefix ends before AppFeedbackModifier. It is frozen provenance, not a requirement that future canonical source hashes remain equal to that historical hash.

## Recorded baseline evidence

On 2026-10-22, Debug on iOS26.5 / iPhone17Pro simulator compiled and ran both native tests. The reserved-strip swipe passed in24.819seconds. The two-round, fifteen-application tap test failed in75.551seconds opening neutral.app.10, the first round's eleventh route, after20 successful open/Home taps. The launcher remained visible; “Neutral launcher” showed editing was not active, and the target frame was inside its scroll viewport. One test passed, one failed, none skipped.

This is a missed-navigation symptom. No touch cancellation was captured in that run. It establishes neither an SDK bug nor the cause of Banana Corp's missed taps, and it supplies no production fix. Other fixture ingredients remain combined. Local raw logs/xcresults are retained separately and are not committed; no machine paths, simulator IDs or player content belong in this directory.

## Run safely

From the repository root, after other native work has finished:

```sh
python3 tools/diagnostics/neutral-shell/run.py unique-label
```

Requires macOS, selected Xcode26+, installed iOS26.5 and the iPhone17Pro simulator device type. The runner checks actual installed metadata and refuses fallback. No runtime downloads, paid services, network, physical-device signing/distribution or system settings are requested. It creates its own fresh simulator, runs the two exact tests once with signing disabled, testability enabled and parallel testing disabled, then shuts down and retains that simulator with its ownership ledger and data. It never automatically deletes or erases a simulator. It never selects an existing player simulator, retries failed taps/tests, injects state or changes application launch flags.

Results go into a new `validation/neutral-shell-repro-<label>` directory; existing paths are refused. Complete native log, original xcodebuild exit, xcresult, summary, actual runtime/device metadata, owned-UUID ledger and cleanup results are retained. A diagnostic pass requires native exit0 and exactly2 passed/0 failed/0 skipped. Missing/unreadable/extra/skipped results invalidate success. Cleanup always retains ownership metadata, including successful shutdown. Failed shutdown retains the exact failure and makes an otherwise successful runner fail; it never replaces an existing native failure. No broad simulator shutdown or erasure occurs.

The fixture inventory hashes explicit native inputs, copied provenance, runner and this README. Xcode-generated workspace/user data, build outputs and result directories are excluded. The canonical read-only inventory covers Swift/JSON/project/shared-scheme files under this repository's Banana Corp directory plus AGENTS.md/game bible; it does not inspect unrelated repositories or personal directories. Before/after integrity is recorded and any change makes an otherwise successful runner fail. There is no fixed49-file assumption. Run without concurrent source edits/builds so provenance remains assessable.

Each test launches normally. The two-round test attempts60 ordinary taps with8second readiness waits, one action per intended tap, stopping on first failure. The separate normal upward swipe is unchanged. No delays, retries, debug gameplay shortcuts, animation disabling, capture pauses or hidden state writes are added. No automatic external bug report is sent.

## Interpretation and maintenance

Use the exact baseline hashes and actual runtime/model when comparing one-factor variants. A passing fixture does not certify game navigation, story progression, evidence bytes, saves, accessibility or physical-device readiness. A failing fixture can narrow required ingredients but cannot by itself prove a common mechanism. Preserve failed results; do not add retries or weaken assertions to obtain green output.

The portable runner was executed against the tracked fixture on2026-10-22 with Xcode26.5/iOS26.5/iPhone17Pro. The SDK build succeeded; XCTest returned exit65 with0passed/2failed/0skipped. The swipe case opened item15 then failed its upward return (51.267seconds); the tap-loop case failed opening item0 (33.573seconds). Retained failure screenshots showed the neutral item15 screen and launcher respectively. Both fixture/canonical inventories remained unchanged, and owned simulator shutdown/delete returned0. This is successful operational validation of the runner retaining a real failure, not a passing fixture or game.

A prior portable invocation exited70 before any test because lowercasing the simulator UUID prevented Xcode destination matching. The runner now preserves the exact identifier returned by simctl. That infrastructure result remains separate from the executed XCTest failures.

A separate scratch comparison removed only `NavigationStack { NeutralApplication(route: route) }`, leaving `NeutralApplication(route: route)` with the same underlay/clocks/gestures/styles/tests. It passed both tests, including all60 taps. Restoring the original native inputs in this portable baseline failed as recorded above. These observations prioritize navigation-host composition for investigation but do not prove a necessary or sufficient cause; timing and other fixture differences from the game remain limitations. The comparison is not shipped as a game change.

Local records: `validation/neutral-shell-repro-20261022/run-retained-home-a/`, `validation/neutral-shell-no-navigation-stack-20261022/run-no-stack-a/`, and `validation/neutral-shell-repro-portable-baseline-20261022-b/`. No raw xcresults, screenshots, machine paths, device IDs or player data are committed. App SDK checks and actual gameplay validation remain separate responsibilities.

The redundant noncompiled prefix text copy was omitted during packaging because its historical trailing blank line failed whitespace checks. The exact prefix remains in the compiled fixture source and its original hash remains in source-comparison.json; no native source was changed. Summary validation also rejects non-object JSON, missing/noninteger counts, skipped tests and extra tests.


Cleanup policy update (2026-10-30): current runs shut down and retain their owned simulator on success, failure and interruption. Earlier recorded shutdown/delete results above describe the historical runner only. Current cleanup.json always records retained=true and the UUID for explicit review/reuse. No automatic deletion/erasure or global cleanup is performed.
