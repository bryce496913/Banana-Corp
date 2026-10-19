# Native reset and accessibility validation

This coverage supplements [integration validation](IOS_INTEGRATION_VALIDATION.md) and the [normal campaign journey](ACTS_1_3_RELEASE_QA.md). It does not establish full VoiceOver, Reduce Motion, physical-device or ending/replay coverage. No game content or progression contract changes.

## Owned simulator runner

```sh
bash scripts/validate-native-experience.sh INSTALLED_IOS_RUNTIME_ID IPHONE_DEVICE_TYPE_ID
# Optional exact cases, in serial order:
bash scripts/validate-native-experience.sh INSTALLED_IOS_RUNTIME_ID IPHONE_DEVICE_TYPE_ID Debug-audit
```

Default cases: Debug-reset, Release-absence, Debug-audit, Release-audit. Optional Debug-type/Release-type select a separate Home-only Dynamic Type audit with distinct runner metadata; the default full audit is unchanged. Each receives a newly created simulator; the runner records ownership before boot and cleans up only that returned UUID. Caller-owned simulators and player saves are never selected. Runner metadata reaches XCTest only, with no app launch flags, replay shortcuts or save edits. Destructive reset and accessibility audits skip without dedicated metadata. The nondestructive Release absence test also runs during ordinary Release integration; dedicated results require exactly one pass, zero failures and zero skips. There are no automatic tap/test retries, accessibility exclusions or suppressed audit issues.

Logs, xcresults, summaries and available campaign files remain under a unique validation/native-experience-* directory. Failed native execution stops the runner after retaining evidence. Artifact-export or cleanup failures are separately recorded and cannot replace an existing native failure. A failed deletion leaves its UUID in outstanding-owned-simulator.txt for deliberate owned-only cleanup.

## Coverage

The Debug reset test reads and preserves opening launch News, verifies cancel retains progress, confirms the existing Settings reset, checks empty Evidence and fresh unread content, then terminates/relaunches to check persistence. Reset is an existing Debug-only control. The Release absence test checks development diagnostics/replay controls are absent. Ending/chapter replay remains unresolved and is not introduced here.

The public XCTest accessibility audit checks settled Home then all 15 registered routes. It records each screen before auditing, and stops normally at the first failure. Passing a visible-screen audit does not establish offscreen content, VoiceOver reading/gesture experience or Reduce Motion behavior.

A separate focused opening-presentation test uses ordinary News→relaunch→Video controls, exact section assertions, Previous/Continue, explicit Finish and relaunch. It requires dedicated fresh-simulator presentation metadata and has already reproduced an intermittent tap failure. Its later assertions have not yet passed as a complete focused run.

## Actual results

2026-10-18: project structure PASS (3 targets,49 app sources); portable runner contracts PASS (6 existing mocked cases +11 experience scenarios; no native claim). First real Debug accessibility build compiled on Xcode26.5/iOS26.5. Audit FAIL44.940s at Home clock: Dynamic Type font sizes partially unsupported; no application route audited. Result: validation/native-experience-20261018-095856-70341/Debug-audit.xcresult. At this first audit, reset/Release absence were NOT RUN; no native audit pass claimed. Debug/Release full integration and a clean journey matrix remain separate requirements. iOS18 runtime is not installed.

The prior temporary touch probes were restored/hash-verified before this run. Original press animation is retained; the insufficient animation experiment PR34 was closed without merge. The missed-tap diagnosis remains unresolved. See [progress record](../AGENT_PROGRESS.md) for native evidence and continuation.

StatusBar repair rerun: Debug compiled; default audit FAIL73.786s at Home with Apple audit errorCode-56 (failed to complete in time). Result validation/native-experience-20261018-134112-71906/Debug-audit.xcresult. No Dynamic Type/all-route pass is established, and no issue category was excluded. Separate integration/reset validation follows.

Repair-branch integration (StatusBar PR37): actual normal Debug/Release builds and bundle checks PASS. Debug5hosted+3UI PASS,5opt-in skips; Release5hosted+4UI PASS,4opt-in skips. Release development-diagnostics absence PASS12.948s. Evidence: validation/status-type-integration-20261018/. Counts precede adding the focused method.

Focused Dynamic Type coverage supplements the unchanged full audit, with no issue handler. Its pass could establish only the selected Home category on the recorded configuration, not all-routes/default-audit/VoiceOver/Reduce Motion coverage. Debug-type, Release-type and Debug-reset are now running serially on fresh owned simulators; no focused/reset pass claimed yet.

Portable focused runner contracts: all20 mocked scenarios PASS in the working copy (validation/native-focused-contracts-20261018.log). Native focused/reset cases remain in progress.

Focused batch results: Debug Dynamic Type PASS (68.027 seconds; one pass, zero failures/skips). Release failed before its audit while XCTest exposed an infinite, zero-sized accessibility window. The final video renders normal Home. Reset was not reached because the runner correctly stopped. Original results remain in validation/native-experience-20261018-140340-74930/.

The readiness helper now requires finite positive in-window geometry before hittability, resets stability on unavailable snapshots, and rejects invalid scroll viewports before generating coordinates. Enabled/hittable requirements and readiness timeouts are unchanged. The fresh pack in validation/native-experience-20261018-142814-77365/ completed with exit65: Release-type PASS65.191s (one pass, zero failures/skips); Debug-reset FAIL40.459s after the first Evidence tap did not produce observable navigation. The reset flow was not reached; cancel, confirm and relaunch reset semantics remain unverified. Both owned simulators were cleaned. This failure is retained separately from the earlier invalid-geometry failure.
