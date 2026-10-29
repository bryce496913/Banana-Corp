# Browser and Email gameplay integration QA

Scope: the currently implemented Acts1–3 and minimal Act4 entry, not the unfinished five-act game. Bible1.13 and existing explicit read/preservation/access contracts remain unchanged.

## Integrated controls

The natural campaign now exercises Browser address entry, Go, Back, Home, local refresh, available ECHO-07 navigation and rejection of an unavailable future address. Email exercises search, unread filtering and Inbox reset without marking correspondence read, plus refresh while the original source is still preservable. Cross-app Maya correspondence checks Back to the puzzle and the correctly labeled Browser Home action. No new mandatory game gate, narrative source, launch flag, save edit or action retry was introduced. All17 campaign checkpoint names/order and both preservation branches are retained.

MailChrome now names its root action for the actual app container: Inbox in Email, Browser Home in Browser, App home elsewhere. New toolbar icon labels have explicit44point content shapes after a real hit-area audit finding. Campaign readiness now requires finite, in-window stable frames within the existing8/20second limits; this strengthens the harness and is not a claim that a game-navigation defect caused the earlier missed tap.

## Actual native evidence

- Xcode26.5, iOS26.5/iPhone14Pro Simulator. No installed iOS18 runtime.
- Initial real Debug/Release simulator builds and actual bundle checks passed. Debug XCTest:8passed,1failed,7explicit opt-in skips. Five hosted integration tests,15app navigation77.782s, repeated Home30.547s and reserved Home gesture14.521s passed. Release tests were not reached after the Debug audit failure.
- Default audit completed Home and found a small Email Inbox hit area. After content shapes, subsequent audits failed with Text clipped. Unsuppressed issue-node logging identified inactive Home welcome text while Email was open. The contain/ignore grouping experiment failed and was reverted. No navigation/scale/touch workaround or suppressed finding was adopted. Default acceptance still calls the ordinary public audit when diagnostic metadata is absent.
- First fresh-app Debug/both campaign built, passed actual product/mapping/resource/freshness checks, passed the new opening controls and reached three real screenshot/terminate/relaunch checkpoints. It then failed readiness175.138s after a tap on Email did not open it following source removal. Native65/0passed1failed0skipped; no full playthrough pass. The partial save retains eight read IDs and the preserved original. All artifacts remain in validation/single-simulator-campaign-design-20261026/native-20261027/Debug-both.
- After normal relaunch and Mac unlock, one Computer Use pointer click opened Email from that failed QA save and displayed the legitimate delivery record. This is a resumed-state check, not an isolated proof of an XCTest defect or a completed campaign. Computer Use also showed foreground Email controls rather than inactive Home controls; spoken VoiceOver was not tested.

## Fresh-app matrix and constraints

A reviewed validation-only executor uses one retained task-created simulator and eight UUID-derived app sandboxes for Debug/Release × both/email/video/neither. This is shared-runtime cold-app testing, not eight cold-device environments. Successful Apple simctl/plutil inventory must prove all QA identities absent, actual product Info/resources/xctestrun/empty arguments are checked, and each result requires exactly one passed canonical journey with all17 ordered checkpoints, no failures/skips, followed by unchanged official final-save and published snapshot assertions. Original app/player saves are never reset. No automatic simulator deletion occurs.

XCTest can reinstall into a different data-container UUID. Export therefore queries the current exact bundle and verifies its MCMMetadataIdentifier in the owned device before copying the save read-only; it does not assume the pre-test installation path persists.

Storage dropped to334MiB during testing. Targeted cleanup removed47 verified inactive task-owned compiler/index cache directories (1367.2MiB logical), preserving products, symbols, logs, xcresults, source, saves, signing inputs and simulators. A new setup stopped at its disk guard before any test. The current workflow keeps the owned simulator stopped during compilation and requires2GiB free after boot and before UI testing. Full matrix, final current-source Release checks and accessibility acceptance remain pending.

## Latest continuation — 2026-10-27

The stronger-readiness campaign source compiled successfully with the Apple SDK in native-c-20261027. Product verification reached the post-boot free-space guard and stopped before installation/testing: fewer than2GiB remained. The earlier native-b setup also stopped at its space guard before any campaign. A prior verify command was not executed when automatic approval review hit a usage limit; later normal review succeeded. None of these stops is a game-playthrough pass or a demonstrated game defect.

The Mac reported only about2.2GiB before the latest boot, despite the creator's storage cleanup. The guard remains enforced. Read-only audit found no old simulators matching the explicit completed task-ownership records, so none were offered for deletion. The current owned simulator, all data and native products/results are retained. Next attempt requires sufficient measured free space, a fresh workflow/app namespace, unchanged strict result/save/checkpoint assertions and current-source Release validation. Do not rerun attempted phases or reset a partial campaign.


## Daily-driver physical blocks — 2026-10-27

The creator requires approximately ten-minute phone-use windows and explicit continuation after every natural pause. A separate block test shares the exact17section campaign implementation with the full test. Full acceptance still executes0→17 without a pause budget; block acceptance uses its distinct test identity, runner-only bounds and a seven-minute soft pause after a completed canonical checkpoint/Home reload. The QA app is terminated and asserted not running at block end. The controller bounds the native command to600seconds and cannot automatically launch another block. Partial results never become full-campaign acceptance.

Block1 targets checkpoints1–3 (or an earlier completed checkpoint at the soft budget), covering new Browser/Mail controls and the opening evidence path. Read-only prefix validation checks only that actual prefix, exact allowed content+version read IDs and published receipt/preserved bytes; Act4/full assertions remain reserved for the complete journey. Build preparation uses a generic iPhone destination so phone access is needed only for installation/testing. Current signed build and both product/signature/resource checks passed; first authorized block is running on the wired iPhone. Further blocks require explicit creator go-ahead and the same verified QA-save lineage.


## Complete-story native continuation — 2026-10-29

PR55 merged into fix/inactive-home-audit-layer at ee1473216631cc228ed91454e45472776e061944; main remains e3b6b48cd9beab68e4b1ebf1a89369420e547d71. All merged production files match locally. Preserve newer bounded journey/progress notes. The creator removed earlier QA apps, so their phone data containers no longer exist; retained Mac save exports are evidence, not permission to inject campaign progress into a new installation.

Prepare a fresh unique QA identity and progress through normal controls in authorized roughly ten-minute blocks. The first17 checkpoints still establish opening throughAct4entry; after reading entry, the expected next lead is now Signal, not the already-read entry. Eight new late-story phase selectors exercise components, takeover, BLACKOUT, Maya reconstruction, DAWN, agreement, unverified assurance and optional Observer escape. A final outcome must be observed and saved before replay; model20combination success does not replace this UI gate. No new physical run has started for the merged story.
