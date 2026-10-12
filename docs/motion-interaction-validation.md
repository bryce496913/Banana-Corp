# Motion and interaction polish

Built on merged UI modernization PR #9. This PR targets main.

## New behavior

| Interaction | Motion / feedback |
| --- | --- |
| Open an OS app | 0.32-second upward entry with opacity; one light impact |
| Return home | 0.28-second upward exit; home becomes interactive when removal completes |
| Reduce Motion | 0.12-second fades, no home/icon/button scaling, no editing wiggle |
| Press an icon / dock icon | 0.12-second feedback; 0.96 scale and restrained opacity |
| Press a standard button | 0.12-second feedback; 0.98 scale and restrained opacity |
| Actionable card / row | Optional shared button wrappers; 0.99 scale and restrained opacity |
| Segmented selection | Native control with a scoped 0.18-second animation |
| Rearrange icons | 0.20-second non-bouncing layout animation |
| Enter editing | One selection haptic; SwiftUI-managed ±1.2-degree wiggle only while editing |
| Changed, accepted icon drop | One selection haptic |
| Failed / unchanged drop | No haptic, persistence write, or layout restart |
| Important confirmation | Native confirmation control and one light impact on the confirmed action; cancellation is silent |

The home has a subtle 0.99 scale / 0.95 opacity under an active app. Its identity, layout, and ScrollView remain mounted. The four-second splash delay remains intact and its fade respects Reduce Motion.

## Navigation lifecycle and gesture scope

OSNavigationState owns home/opening/active/closing phases and completion identifiers. AppState owns this transient state and continues to expose activeApp to existing game update guards. Going home clears activeApp immediately, so outgoing games stop advancing before removal finishes.

The root drives only presentation state with withAnimation and completionCriteria: removed. It rejects another open while an app is opening, active, or closing. Stale completion callbacks cannot finish a newer transition. Home hit testing and accessibility remain disabled until outgoing removal completes. Root appearance/disappearance can settle an abandoned transition without a delay or timer.

Home is never conditionally recreated or assigned a navigation ID. Each app retains its own NavigationStack. No horizontal root push, screen-wide drag gesture, nested-navigation gesture override, blur, animation timer, or frame-driven haptic was added.

The Home button stays inside the existing 44-point fictional strip above the hardware-safe bottom region. A high-priority drag recognizer on that button prevents a recognized downward/horizontal drag from also becoming a tap. Only upward, mostly vertical displacement beyond 24 points returns home. Tap and VoiceOver activation remain supported. Actual recognizer behavior still needs simulator/device validation.

Editing uses a conditional phaseAnimator instead of manually starting repeatForever from onAppear/onChange. Ordinary metadata changes do not explicitly restart it; leaving editing or enabling Reduce Motion removes it. Drag sources still exist only during editing. Long-press callbacks go through a guarded coordinator method, so repeated callbacks do not emit repeated haptics or launch an app.

AppFeedbackModifier uses supported SwiftUI sensoryFeedback (iOS 17+, compatible with the iOS 18 minimum). Feedback is emitted for accepted actions, not animation completions, scrolling, tabs, game controls, or game ticks. Haptic output remains subject to device support and system settings.

Passive cards and list rows remain passive. Their new optional button wrappers and confirmation/selection feedback are exercised in the debug-only component catalogue, without adding fake interactions to placeholder apps.

## Validation actually run

- Production OSNavigationState and HomeSwipeIntent compiled and ran with Swift 6.2 in a read-only, network-disabled Linux container: **1,400 full app cycles** across all routes, double-open and rapid-reopen rejection, cancel-during-opening, out-of-order/idempotent completions, root recovery, and **14 swipe-intent cases** passed.
- Production home layout/persistence checks passed, including **160 valid moves**, rejected-move atomicity, dock limits, duplicate/overflow repair, malformed payloads, missing routes, and UserDefaults v1 reload.
- Swift 6.2 syntax parsing of all **30 app sources**, including DEBUG previews, passed. This does not typecheck SwiftUI against an Apple SDK.
- Static comparisons confirmed all game source files, photo shell, route identity, and layout persistence source are unchanged.
- One persistent home, completion-based navigation, strip-only drag, no new timers/manual repeatForever, iOS 18 deployment target, all 30 source references, and all 14 destinations/icon metadata were checked.
- git diff --check and shell-script syntax checks passed.
- Attempted xcodebuild build for Banana Corp / iphonesimulator / generic iOS Simulator / signing disabled: command not found.
- Attempted xcrun simctl list devices available: command not found.

No Apple SDK, Xcode, or iPhone simulator is available. No rendered transition, frame-rate/stutter measurement, native touch/drag test, keyboard/modal interaction, or physical haptic output is claimed.

Run the Foundation checks on a Swift-equipped machine:

- bash scripts/check-os-navigation.sh
- bash scripts/check-home-layout.sh

## Manual checks still required

Use Xcode 26+ with iOS 18 and iOS 26 iPhone simulators; verify haptics on a supported physical iPhone.

1. Open every app and return home by tap, VoiceOver activation, and upward strip swipe. Verify entry/exit direction, preserved nested navigation, no black/flickering frame, and responsive controls after completion.
2. Scroll the home grid, customize its layout, open/close repeatedly, and verify the same arrangement and scroll position. Try rapidly reopening the same game during closing: only one session may exist after removal.
3. Attempt downward, horizontal, short, and diagonal drags beginning on the Home strip. Verify they do not become tap-to-home actions. Verify real iOS Home gestures remain normal.
4. Scroll app content, use Snake directions, drag the Pong paddle, and use Tic Tac Toe cells. None may trigger OS navigation or repeated haptics. Existing photo/media apps are placeholders; when real content exists, verify their own gesture recognizers too.
5. Long press once, repeatedly long press, reorder both sections, move between grid/dock, cancel a drag, and reject a full-dock drop. Verify no accidental launches, one edit-entry haptic, feedback only for changed successful drops, and reliable Done/outside-tap exit.
6. Enable Reduce Motion before launch and while editing. Verify fades, no custom press scaling/wiggle, stable transition completion, and normal native controls.
7. In Shared components previews, press cards/rows/buttons, change a segment, confirm and cancel the native dialog. Verify short visual feedback, VoiceOver labels, and one haptic only for confirmation.
8. Background/foreground during opening/closing, present/dismiss a modal, and repeatedly reopen games. Verify the coordinator never stays locked and game cleanup remains intact.
9. Use Instruments/Core Animation on a supported iPhone to assess frame pacing, allocations, and animation lifecycle during ordinary navigation, long editing sessions, repeated drops, and Reduce Motion.
