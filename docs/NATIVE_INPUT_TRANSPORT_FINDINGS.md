# Native input transport findings — 2026-10-22

Native interaction reliability remains unresolved. Actual Apple-SDK builds and individual smoke passes coexist with failed normal-control campaign runs. No production input workaround or canonical UI-test action substitution was adopted. The 49 production app Swift files remain identical to main `d7949ab` (same app sources as `8d5ab77`); the four UI-test files retain their pre-comparison PR39 bytes. PR39 remains draft. These experiments do not change story, progression, persistence or supported system gestures.

This record supplements [progress](../AGENT_PROGRESS.md), the [QA plan](../QA_TEST_PLAN.md), [integration requirements](IOS_INTEGRATION_VALIDATION.md), [native experience validation](native-experience-validation.md) and the developer-only [neutral reproducer](../tools/diagnostics/neutral-shell/README.md). Local evidence paths below are relative to the repository. They identify retained logs, xcresults, summaries and source/cleanup proofs, rather than distributable artifacts.

## What the captures establish

The neutral fixture excludes story/catalogue/assets/player saves while retaining the shell's navigation, persistent Home underlay, clock, button styling and gestures. Its uninstrumented missed-navigation symptom shows those game systems are unnecessary for at least one similar failure. It does not prove that every original-game opening failure has the same mechanism.

The corrected neutral touch/model capture narrowed one Home failure to input cancellation before the model action: successful item6→Home ended normally; item7→Home at the same point began then cancelled after 177.806 ms, remained active and had no model Home callback. Both lifecycle flushes were complete for both app processes, with 46/158 unique records and zero drops. The original-game notification capture separately observed successful AI→Home and cancelled VR→Home at the same point, with 88 complete records. These are correlated observations across different sources and runs, not a shared-cause proof.

The scoped system-log comparison supplies a more specific boundary:

- Successful neutral item2→Home contact ended after 66.667 ms, called the Home model action, and subsequently removed its digitizer with an empty contact set and no soft cancellation.
- Failed item3→Home contact cancelled after 186.128 ms. BackBoard removed the digitizer while its contact/path was still touching and locked to the app scene, then cancelled paths with `softcancel=1`. Seven skipped-path messages occurred in that failed cluster.

Digitizer disappearance alone occurs during successful cleanup. The distinguishing observation is removal with an active contact followed by cancellation. Neither this sequence nor a system gesture recognizer's state identifies why the expected up/path was rejected. Wall/uptime alignment is approximate; contact/path/scene sequence is stronger evidence than submillisecond alignment. This is not an established SDK defect.

## Retained execution results

Counts are **passed/failed/skipped** from actual XCTest summaries. Native test failure and diagnostic capture validity are independent outcomes. Neutral runs use Xcode 26.5, iOS 26.5 and an owned iPhone 17 Pro simulator; their results do not establish game acceptance.

| Local evidence path | Actual result and scope |
| --- | --- |
| `validation/status-clock-refresh-20261020/run-awake-20261021-c/` | Actual Debug/Release builds and bundle checks passed; Debug tests **7/1/7**, initial Email tap failed. Release XCTest was not reached. Clock candidate was retired, PR40 closed unmerged. |
| `validation/release-integration-20261022/run-main-clock-a/` | Restored-main Release build/bundle checks and five hosted plus three UI tests **8/0/0**. |
| `validation/release-journey-20261022/run-main-both-a/` | Uninstrumented restored-main Release/both campaign **0/1/0**, 53.693 s, first Email→Home before the first progression checkpoint. Partial save retained; full-campaign assertions did not pass. |
| `validation/first-open-diagnostic-20261020/run-notification-20261021-c/` | Original-game instrumented all-apps test **0/1/0**, VR→Home failure; complete 88-record lifecycle capture. |
| `validation/neutral-shell-repro-20261022/run-retained-home-a/` | Uninstrumented baseline **1/1/0**: swipe passed; ordinary loop failed opening item10 after 20 successful open/Home taps. |
| `validation/neutral-shell-no-navigation-stack-20261022/run-no-stack-a/` | Single-wrapper removal **2/0/0**; 60 ordinary taps and upward swipe passed. One comparison does not establish necessity or sufficiency. |
| `validation/neutral-shell-repro-portable-baseline-20261022-b/` | Restored portable baseline **0/2/0**: item15 opened then upward return failed; separate loop failed opening item0. |
| `validation/neutral-shell-opacity-transition-20261022/run-opacity-a/` | Retained NavigationStack, opacity-only transition **1/1/0**; loop failed opening item5; swipe passed. |
| `validation/neutral-shell-trace-20261022/run-trace-a/` | **1/1/0**, but capture invalid: DEBUG instrumentation compiled out. No touch/model inference. |
| `validation/neutral-shell-trace-20261022/run-trace-debug-b/` | Explicit app-module DEBUG compile proof; **1/1/0**; complete strict 46/158-record capture, zero drops. |
| `validation/neutral-shell-home-simultaneous-20261022/run-simultaneous-a/` | **0/2/0**, both initial opens failed before Home gestures were reached. |
| `validation/neutral-shell-home-inset44-20261022/run-inset44-a/` | **0/2/0**, both initial opens failed before the raised Home strip was reached. |
| `validation/neutral-shell-runloop-trace-20261022/run-interval-a/` | **1/1/0**; overall capture **invalid**: failed process lacked required `didEnterBackground` flush. Its positive cancellation/interval records remain evidence; missing events cannot be inferred. |
| `validation/neutral-shell-dispatch-trace-20261022/run-dispatch-a/` | **1/1/0**, second-round item0 opening failed; strict capture complete for both processes, **40/370** unique records, zero drops. |
| `validation/neutral-shell-system-logs-20261022/run-system-a/` | **1/1/0**, item3→Home failed; strict app capture and scoped live/retained system-log capture passed. Same native fixture bytes as dispatch run. |
| `validation/neutral-shell-press-action-20261022/run-press-a/` | **0/2/0**; strict app/system capture passed. Item15 opened, then unchanged upward swipe failed; loop opened item0, then 0.10-second Home press cancelled. |

Source-integrity and owned-simulator cleanup checks passed for the completed comparison runs above. Instrumentation can perturb timing; complete capture means the declared record contract passed, not that XCTest or gameplay passed. Repeated lifecycle flushes are snapshots, not additional unique events.

## Measurements and rejected candidates

The partial interval run recorded a 360.259 ms adjacent run-loop observer interval across an initial-open cancellation. Its existing event bracket included metadata collection, so it could not assign that cost to UIKit. The subsequent complete dispatch run separated collection and original forwarding: the failed began event used 1.053 ms before-collection, 23.220 ms original forwarding and 0.073 ms after-collection, with 27.504 ms entry lag. No recorded ≥50 ms observer interval overlapped that failure. Earlier successful Home events had 309.649/443.534 ms forwarding and 834.076/1150.746 ms entry lag. These observations do not support a simple measured-delay threshold explanation; they do not exclude unobserved work, nested loops or scheduling effects. Observer intervals are wall intervals, not CPU profiles or automatic stalls.

The live-clock candidate failed clean navigation despite separate successful builds and a physical full Debug/both campaign on that experimental source. That physical campaign is retained historical evidence, not validation of restored-main campaign reliability. Physical installation/eight-case smoke evidence has its own source provenance in the QA record.

Home gesture composition and the 44-point raised strip supplied no verified repair: their neutral comparisons failed before Home was exercised. Original-game gesture and fixed pressed-scale comparisons also failed initial Email opens; no Home swipe conclusion follows. Opacity-only transition retained a failure. None was adopted.

The short-press comparator changed exactly three test action sites to one public `press(forDuration: 0.10)` each, below the existing 0.4-second long-press threshold; assertions, readiness bounds and the upward swipe stayed intact. It failed both tests. Review of the failed swipe's captured stream found no moved/ended touch delivery; that observation does not establish where delivery was lost. The proposed 14 substitutions across four canonical UI-test files were **rejected and remain unapplied**. No tap retries, cancelled-touch actions or system-gesture suppression were introduced.

## Next differential measurement — pointer input not executed

An ignored scoped launcher is prepared at `validation/neutral-shell-cua-driver-20261022/`. It will install the exact proven instrumented neutral app binary on one fresh owned simulator, record source/binary provenance, retain scoped guest trace/system logs and expose only that simulator's app identity for a normal Simulator-window pointer comparison. Its explicit finish path stops owned logging children, exports evidence and cleans only its owned simulator. It adds no app launch flags, build, source changes or test retries.

Computer Use initially reported permission unavailable. The creator confirmed it enabled, then the CLI fixture installed and launched the exact app on its owned simulator. The first CUA reconnect timed out and reset its kernel; the next still reported permission not granted. No GUI observation or pointer input was obtained, and no alternative desktop-input mechanism was used. The fixture exported its available logs and passed source/binary integrity and owned shutdown/deletion; without input or background flush, this is infrastructure preparation only. The creator was asked to verify the separate macOS Screen Recording and Accessibility permissions. Evidence: `validation/neutral-shell-cua-driver-20261022/run-cua-a/session-final.json`. Any eventual CUA result will be a driver differential, not a replacement for required clean XCTest and campaign validation. No external bug report has been sent. A production repair still requires evidence, clean Debug/Release interaction and progression/persistence checks, and the documented physical-device readiness requirements.
