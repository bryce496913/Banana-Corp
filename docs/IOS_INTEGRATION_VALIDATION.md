# iOS integration validation

Validation date: **2026-10-13**. Baseline: merged Pass 8 / PR #19, repository tree `cda35f32bdf830b8a3f77b83377af38b68136754`.

**Apple-platform readiness is not yet established.** This pass audited project structure, repaired configuration metadata and added native coverage. The available machine runs Linux; it cannot build SwiftUI/UIKit against an Apple SDK or execute an iPhone application. Historical reports' Foundation and syntax results remain valid within their stated limits, not evidence of an Xcode build.

## Environment and actual outcomes

| Item | Observed result |
| --- | --- |
| Execution host | Linux x86_64 |
| Xcode version | Unavailable: `xcodebuild: command not found` |
| Swift compiler | Swift **6.2.4**, `swift-6.2.4-RELEASE`, `x86_64-unknown-linux-gnu`, official `swift:6.2` container; no host Swift executable |
| Language mode | Swift 5 (`SWIFT_VERSION = 5.0`; regression checks use `-swift-version 5`) |
| Apple iOS SDK version | Unavailable; not discovered or used |
| Simulator runtimes/destinations | Not discoverable: `xcrun: command not found`; no simulator execution available |
| Debug iOS simulator build | Attempted; blocked before build by missing `xcodebuild` |
| Release iOS simulator build | Attempted; blocked before build by missing `xcodebuild` |
| Native XCTest / UI-test execution | Attempted via `xcodebuild test`; blocked. Newly added tests are **uncompiled/unrun against Apple SDKs** |
| Physical device / signing | No Apple device tooling or connected authorized iPhone available; team, certificate, profile and device provisioning not verified |
| Structural validation | Passed: parsed project, target/source/resource membership, shared scheme, settings, local references and route registration |
| Foundation regressions | All **10 existing suites passed**, including separate-process persistence checks and Release fixture exclusion |
| Swift syntax | All **50** files (48 app + 2 native test sources) parsed with DEBUG, and without DEBUG. No Apple typechecking/macro expansion of SwiftUI previews claimed |
| Actual app-bundle inspection | **Not run**: no Xcode-built `.app` exists here. Source build-phase membership is verified; actual copying/asset compilation awaits Mac builds |
| Rendered UI / performance | Not run: no simulator, physical haptics, VoiceOver, native drag/drop or Instruments measurements |

Foundation checks ran with warnings as errors in a network-disabled container and a read-only repository mount. They exercise real production Foundation models, Observation, save codecs and catalogue validation; they do not compile the app's SwiftUI/UIKit views.

## Integration findings and repairs

- All **48** app Swift files have exactly one app source-phase entry, including progression, content, evidence, restricted-access, visual presentation and DEBUG preview sources. No Foundation executable's `@main` test harness is compiled into the app. The app has one entry point, `Banana_CorpApp`, in `Banana_CorpApp.swift`.
- Added a checked-in shared **Banana Corp** scheme; the prior repository had only user scheme-management data and no native test target. The scheme now registers **Banana CorpTests** (hosted XCTest) and **Banana CorpUITests** (UI smoke test), with explicit app dependencies, distinct bundle IDs and source membership. Existing command-line Foundation harnesses remain independent.
- Explicitly fixed the app module name to `Banana_Corp` for the native test import. Kept iOS **18.0**, Swift **5.0**, iPhone family **1**, automatic signing, existing team/bundle ID and both simulator/device platforms. No signing authorization is implied by a team ID in a project file.
- Removed the empty `INFOPLIST_KEY_UIStatusBarStyle` string in Debug and Release. Kept generated `UIStatusBarHidden = YES`, the explicit source Info.plist, generated launch/scene metadata, and all existing root/shell/modal `.statusBarHidden(true)` modifiers. No launch flow or UI component changed.
- Repaired the app-icon catalogue's metadata: added standard `info.version` / `info.author`, removed nonstandard `folder` / `expected-size` keys, retained every filename, idiom, scale and size. Existing PNG dimensions match their entries; inspection found fully opaque alpha values. No image pixels/artwork were changed. Apple asset compilation and distribution validation remain unrun.
- No custom entitlements file or explicit entitlement build setting is present. No new entitlement, permission, dependency, capability or network service was added.
- Added [check-ios-project.py](../scripts/check-ios-project.py), which parses OpenStep project structure rather than relying only on filename searches. It rejects duplicate keys, unresolved references, absent source/resource entries, duplicate build inputs, wrong effective platform settings, test-host/scheme mismatches and route omissions. Its optional `--app-bundle` mode verifies the **actual product** Info.plist, executable, `Assets.car`, exact JSON/media bytes and fixture exclusion.
- Added [validate-ios-integration.sh](../scripts/validate-ios-integration.sh): requires macOS/Xcode 26+, a caller-selected simulator UDID and a new results directory. Captures tools/runtimes/destinations, builds Debug and Release, validates both products and runs both configurations' tests. Only test invocations set `ENABLE_TESTABILITY=YES` for `@testable`; ordinary Release build settings/optimization remain unchanged. Local logs, DerivedData and xcresult bundles are ignored under `/validation/`.

## SwiftUI and lifecycle review

`Banana_CorpApp` owns one `@StateObject AppState` and injects it above LaunchView. The existing four-second cancellable splash task transitions to BananaOSView. The persistent Home and disposable app NavigationStack remain under one OS navigation owner. StoryProgressionStore remains the single saved narrative authority, with AppState's observation bridge and direct story observations; content and access query the same store.

App navigation, bounded presentation tasks and game cleanup source were inspected without changes. Root app opens/closes still use vertical transitions and completion IDs. Home hit testing/accessibility is suppressed while an app is active; the fictional Home strip owns its own gesture above the safe system-gesture region. Snake/Pong update guards stop on inactive routes; internal scroll/game gestures remain separate. The compiled legacy Flap Flap view is not one of the 15 registered routes; its game-over sheet already carries black presentation styling and status-bar hiding. It was not given a new route or changed during this integration pass.

The two Liquid Glass call sites are inside `#available(iOS 26.0, *)` branches in GlassCompatibility and HomeDockSurface, with themed pre-26 and Reduce Transparency fallbacks. **Xcode 26+ is still necessary to compile these symbols**, even when running on iOS 18. Other inspected SwiftUI presentation, sensory feedback, drag/drop, Observation and navigation APIs precede the iOS 18 minimum. These are source observations, not proof of SDK typechecking, animation behavior or gesture correctness.

## Production resource inventory

| Resource | Inclusion and loading contract |
| --- | --- |
| `StoryContent.json` | App Resources build phase; `Bundle.url(forResource: "StoryContent", withExtension: "json")`; contains 45 immutable item definitions with Act 1–2 sources/version metadata |
| `RestrictedAccess.json` | App Resources build phase; matching Bundle lookup; production Banana Wall descriptor remains awaiting approval/non-completable |
| Puzzle definitions | Inside `RestrictedAccess.json`; no separate approved production puzzle-answer file |
| Local web content | Structured payloads inside StoryContent.json. Fictional paths are local content metadata, not missing HTML files or remote URLs |
| Videos/photos/evidence | Current content catalogue declares **no local media assets**. Video material is explicitly transcript/metadata; photos are records/metadata. Evidence snapshots are stored in the existing story save, not a separate bundled archive |
| `Assets.xcassets` | App Resources build phase; AppIcon, AccentColor and Logo-Black references resolve. Existing LaunchImage entries retained; the launch flow was not migrated/redesigned |
| Preview assets | Existing resource entry and `DEVELOPMENT_ASSET_PATHS` retained; Xcode's actual Release handling remains to be checked |
| Neutral fixture JSON | Under repository Tests/Fixtures only; absent from app/test resource phases. The isolated Swift DEBUG demo remains compiled out of Release |

An actual bundled catalogue must also decode successfully. Hosted XCTest uses `Bundle(for: AppState.self)` for direct production loading, while AppState's default initialization exercises the production `.main` path. It checks both catalogues, artwork, generated Info.plist, passive initial queries, all route metadata/coordinator cycles, and evidence persistence through a newly constructed store using a temporary file. No native test resets the player's story or reorganizes their Home layout. The UI test uses the ordinary splash and accessible buttons, repeated Email/Home navigation, status-bar absence and relaunch; it waits for conditions rather than fixed animation sleeps. It does not establish full gameplay or all modal behavior.

## Commands actually attempted here

```sh
xcodebuild -version
xcodebuild -project 'Banana Corp/Banana Corp.xcodeproj' -scheme 'Banana Corp' \
  -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO build
xcodebuild -project 'Banana Corp/Banana Corp.xcodeproj' -scheme 'Banana Corp' \
  -configuration Release -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO build
xcodebuild -project 'Banana Corp/Banana Corp.xcodeproj' -scheme 'Banana Corp' \
  -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16' \
  CODE_SIGNING_ALLOWED=NO test
xcrun simctl list runtimes
xcrun devicectl list devices
```

Every Apple command above returned **command not found** (exit 127). The native validation script was also invoked and correctly returned **69** with an explicit missing-platform message, before any native build/test. No device was selected or contacted.

`python3 scripts/check-ios-project.py`, shell syntax, whitespace and all **60 local Markdown references** passed. Temporary fault-injection checks verified rejection of omitted source/resource membership, wrong effective deployment, unresolved dependencies and duplicate project keys. A synthetic bundle exercised changed-resource rejection **only as a validator test**, not an Apple build. The initial syntax-check shell invocation had an invalid compiler argument order; the corrected `swiftc -frontend -parse -swift-version 5` invocation passed all 50 files in both modes.

All existing suites passed:

```sh
bash scripts/check-act-one.sh
bash scripts/check-act-two.sh
bash scripts/check-evidence-vault.sh
bash scripts/check-first-anomaly.sh
bash scripts/check-home-layout.sh
bash scripts/check-os-navigation.sh
bash scripts/check-os-presentation.sh
bash scripts/check-restricted-access.sh
bash scripts/check-story-content.sh
bash scripts/check-story-progression.sh
```

These cover unchanged story/snapshot contracts, migration/atomic saves/relaunch, protected queries and non-completable production access, 1,500 navigation cycles, 14 Home-swipe intent cases and 185 valid layout moves. Model outcomes are not native touch or UI rendering tests.

## Complete native validation on a Mac

Use full **Xcode 26+**, with its Command Line Tools selected, Python 3 and dedicated clean test simulators. The UI tests intentionally retain normal app saves; do not use a simulator containing a player's customized campaign/layout as an assumed fresh fixture. Tests do not bypass the splash, story conditions or app unlocks.

```sh
xcodebuild -version
xcrun swift --version
xcodebuild -showsdks
xcodebuild -project 'Banana Corp/Banana Corp.xcodeproj' -list
xcodebuild -project 'Banana Corp/Banana Corp.xcodeproj' -scheme 'Banana Corp' -showdestinations
xcrun simctl list runtimes
xcrun simctl list devices available

# Substitute actual available iPhone simulator UDIDs; run each installed runtime.
bash scripts/validate-ios-integration.sh IOS18_SIMULATOR_UDID validation/ios18
bash scripts/validate-ios-integration.sh IOS26_SIMULATOR_UDID validation/ios26
```

The two UDID labels above are placeholders, not destinations known to be installed. Replace them before running. If a runtime is missing, record it and validate the available runtime; do not claim iOS 18/26 execution from the SDK deployment target alone. The script stops on build/test failures with pipefail and retains prior logs; fix actual errors without suppressing them. Review both xcresult bundles and actool/compiler warnings. Update this report with Xcode/SDK versions, actual destinations, outcomes and unresolved issues.

For a compile-only device product on that Mac (not installable without signing):

```sh
xcodebuild -project 'Banana Corp/Banana Corp.xcodeproj' -scheme 'Banana Corp' \
  -configuration Debug -destination 'generic/platform=iOS' \
  -derivedDataPath validation/device-unsigned CODE_SIGNING_ALLOWED=NO build
```

For a **connected, authorized iPhone**, choose the developer's authorized team/account and device UDID. Confirm Developer Mode, pairing/trust and provisioning in Xcode. Keep the existing app identity; do not add capabilities to work around signing.

```sh
xcrun devicectl list devices
# Set PHONE_UDID and APPLE_TEAM to authorized values from Xcode/device listing.
xcodebuild -project 'Banana Corp/Banana Corp.xcodeproj' -scheme 'Banana Corp' \
  -configuration Debug -destination "platform=iOS,id=$PHONE_UDID" \
  -derivedDataPath validation/device DEVELOPMENT_TEAM="$APPLE_TEAM" \
  -allowProvisioningUpdates build
python3 scripts/check-ios-project.py \
  --app-bundle 'validation/device/Build/Products/Debug-iphoneos/Banana Corp.app'
xcrun devicectl device install app --device "$PHONE_UDID" \
  'validation/device/Build/Products/Debug-iphoneos/Banana Corp.app'
xcrun devicectl device process launch --device "$PHONE_UDID" \
  Bryce-Cameron-Design.Banana-Corp
```

These device commands are a handoff, **not executed results**. Physical signing, install and launch remain blocked here.

## Focused iPhone execution checklist / remaining blockers

- Build/run on installed iOS 18 and iOS 26 runtimes, a small iPhone and a Dynamic Island iPhone. Confirm normal splash, black edges, hardware-safe controls and fictional status bar only, including modal presentation/dismissal, foregrounding and relaunch.
- Open all 15 routed apps, nested source/detail/comparison links and the Assistant diagnostic source. Return by accessible tap and strip swipe, reopen games, and repeat navigation without duplicate Home/app instances. Flap Flap remains a separate legacy preview check, not a new route.
- Verify grid/dock native drag/drop, Done/outside-tap exit, canceled/invalid/full-dock drops and layout relaunch persistence. Verify Snake directions and Pong paddle drags do not trigger Home; background/close stops updates.
- Play both approved evidence-preserved/unpreserved Act 1–2 paths, save/relaunch during changes, compare real source versions, and reach the still-locked Banana Wall. No unapproved answer or DEBUG campaign bypass should exist in Release.
- Check VoiceOver, larger Dynamic Type, Reduce Motion/Transparency, safe-area/keyboard layout and native alerts/dialogs. Test actual haptics and ordinary performance on a supported physical iPhone.
- Resolve any Apple compiler, asset compiler, test-host, signing or runtime issue uncovered on that Mac and attach logs/xcresult evidence before calling the app iPhone-ready.

No canonical narrative event, Banana Wall solution, Act 3 content, save schema, mini-game mechanic, theme, launch behavior or navigation implementation changed in this pass. The bible does not need an implementation-only rewrite. Relevant earlier manual checklists: [Banana OS](banana-os-validation.md), [home layout](home-screen-validation.md), [UI](ui-modernization-validation.md), [motion](motion-interaction-validation.md), [Act 1](act-one-content.md), [first anomaly](first-anomaly.md), [Act 2](act-two-content.md), [restricted access](ACT3_PUZZLE_DESIGN.md).
