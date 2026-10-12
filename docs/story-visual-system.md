# Story-aware Banana OS visual system

Built on merged motion/interaction PR #10. This adds presentation infrastructure, not chapters or an independent progression engine.

## Ownership and defaults

AppState owns the published OSPresentationState beside the existing day, VR/glitch flags, corruption level, unread counts, unlockedApps, and navigation state. Those existing declarations/defaults and all eleven app placeholder/story files remain unchanged.

BananaOSView injects a read-only presentation snapshot through EnvironmentValues. Individual apps do not create a second visual/story store. Shared headers, status indicators, icon metadata, theme controls, and dedicated modifiers consume that snapshot.

OSVisualMode supports normal, subtleAnomaly, interference, compromised, and critical. A mode is a presentation label/eligibility state; it does not invent messages, schedule effects, advance days, or infer progression from corruption level. Release builds have no automatic presets or mode-transition rules.

Normal starts with:
- Standard palette using the exact existing theme colors.
- BANANA 5G, full fictional signal, connected fictional Wi-Fi, and 75% fictional battery.
- Original icon symbols/names and unlocked-app filtering.
- No interruption, corruption, animation engine, or expiry task.

Normal configurations are sanitized back to the complete baseline, even if a caller supplies overrides. The existing real clock Text(Date, style: .time) and one-second clock timer remain unchanged. Normal rendering preserves the prior text/styles/default data; rendered pixel equivalence still requires an Apple-platform comparison.

## Explicit story integration

Three entry points require a condition evaluated against a read-only snapshot of the existing AppState story fields:

- configureStoryPresentation(configuration, when: condition): installs display configuration and cancels any transient event.
- presentStoryEvent(event, when: condition): requests one bounded presentation event; returns false for normal mode, invalid payloads, a busy channel, or cooldown.
- setStoryAppAvailability(route, unlocked: value, when: condition): updates the existing unlockedApps authority. It never creates a competing lock store.

Example for a future caller using an existing condition; this code is documentation, not a new runtime rule:

```swift
let configuration = OSPresentationConfiguration(mode: .subtleAnomaly)
appState.configureStoryPresentation(configuration, when: { $0.hasSeenFirstGlitch })
appState.presentStoryEvent(
    OSPresentationEvent(status: OSStatusOverride(signal: .weak)),
    when: { $0.hasSeenFirstGlitch }
)
```

No caller was added to launch, navigation, app screens, or progression. Predicate false means no mutation. configure/present/restore do not change any story flag/day/corruption value.

restoreNormalPresentation() cancels pending work and restores cosmetics/messages, while preserving the rate-limit history. It does not rewind unlockedApps or story progress. Mode switches/restoration cannot bypass cooldown. Settings cannot be locked through the new availability API; Home remains independent of presentation effects. Locking an active app returns through the existing coordinator and immediately stops its game update guards. Unlocks preserve saved grid/dock positions.

## Configuration and event contracts

| Mechanism | Contract |
| --- | --- |
| Palette | Optional named, restrained background/accent profiles; standard is unchanged. Reading surfaces/text remain legible and game elements retain their original styling. |
| Status | Fictional carrier, signal, Wi-Fi and battery overrides. Carrier limited to 24 characters; battery clamped to 0–100. No hardware/network state is queried or changed. |
| App display | Per-route name/symbol overrides. Names limited to 32 characters; invalid SF Symbols fall back to original artwork. Route identity, launch targets, badges, and saved positions remain separate. |
| Locked icon visibility | Optional visibleLockedApps only reveals a lock-rendered icon; it cannot authorize launching/dragging. unlockedApps remains authoritative. |
| Interruption | notification, systemAlert, or assistantMessage payload. Text is supplied by a future caller, not invented by this task. Titles/messages are bounded and cleaned of control characters. |
| Motion | One finite 1.2-second drift of at most 2 points or a single 6% opacity dip. No rapid flash, loop, shader, or blur. |
| Text corruption | Short, targeted glyph substitution. Original text layout/accessibility label is retained; header renames also preserve original intrinsic height to avoid resizing a game board. |
| Lifetime | One event channel, duration clamped to 1.2–4 seconds, at least 20 elapsed seconds between accepted requests. Invalid/empty events allocate no task. |
| Clock changes | Rate limiting uses supplied monotonic system uptime, independently of real-world dates. Expiry uses monotonic Task.sleep plus a wall-clock visibility check and foreground catch-up. |
| Restoration | Expiry/dismissal uses an event UUID. A stale callback cannot remove a newer event. There is no queued burst after rejection. |

Event status/name/symbol fields temporarily overlay only supplied fields on the base configuration. Expiry restores the configured values, not necessarily initial values. A normal restoration clears all cosmetics.

## Rendering and player safeguards

OSStoryText, OSControlledEffect, OSInterruptionHost, and OSVisualPalette are shared components/modifiers. No corruption code is duplicated inside game/app files.

Allowed effect targets are carrier/connectivity information, app artwork/names, and app header titles. Home, navigation gestures, composers, game boards, paddle drags, and directional controls are not targetable. Artwork offsets do not change hit regions.

Interruption cards are in-world presentation, not real iOS modal alerts. They do not resize the underlying app, capture pointer input, or steal focus. They expire automatically and expose an accessible Dismiss action. Their clipped height budget is at most 160 points and always reserves 64 points for Home, including short/keyboard-constrained layouts.

Reduce Motion suppresses drift, opacity pulse and text corruption; semantic status/palette/name changes remain readable. Corrupted visual text retains the readable accessibility label. Hidden home content suppresses decorative effects.

Normal has no effect animator or presentation task. An accepted event owns at most one weakly captured, cancellable expiry task. Changes, restoration, dismissal, foreground expiry and deinitialization clean it up. Animation frame updates stay local to the affected decorative component; they do not publish AppState changes per frame. There is no persistent visual-state store or new background service.

## Real-world context

OSEnvironmentContext exposes an explicit date, time-zone identifier, and optional caller-supplied weather summary/observation time. AppState.environmentalContext returns a local snapshot with weather absent.

This interface performs no collection. No location/weather framework, permission, network request, battery monitoring, background fetch, or data service was introduced. A future provider must be separately authorized/implemented; the real clock cannot be overridden by a visual event.

## Development demonstration

OSVisualPreviews.swift is entirely under DEBUG. Xcode previews cover all five modes plus Critical with Reduce Motion. The toolbar can explicitly request a pulse, distortion, short text substitution, or a development-only fake alert, and restore normal. The standard 20-second cooldown still applies; preview messages are clearly labeled and are not ARG content.

Only the debug harness demonstrates VR locking/unlocking; the release app receives no automatic availability changes. Normal restoration in production preserves story locks; the debug selector separately resets its own test lock.

## Actual validation and limitations

- Production presentation model compiled and ran in the official Swift 6.2 Linux container, read-only mount/network disabled: normal identity/override stripping, explicit modes without events, single channel, expiry/restoration, cooldown including clock jumps, stale dismissal, partial overrides, sanitization, duration/battery/text bounds, reserved Home budget, and passive context checks passed.
- Existing navigation checks passed: 1,400 app cycles, rapid reopen/double-open rejection, stale/idempotent completion, root recovery, and 14 swipe-intent cases.
- Existing layout/persistence checks passed: 160 valid moves, invalid payloads, dock limits, duplicates/overflow, missing routes, and UserDefaults v1 reload.
- Swift 6.2 syntax parsing passed for all 33 app sources with DEBUG previews enabled. This is not Apple-SDK SwiftUI typechecking.
- Static comparisons passed for unchanged game files, Home control, navigation model, route identity, layout persistence, all existing story/progression declarations/defaults, and all eleven placeholder/story files. Real clock, iOS 18 target, all 33 source references and all 14 destinations/icons were checked.
- git diff --check and shell-script syntax checks passed.
- Attempted Banana Corp xcodebuild / iphonesimulator build and xcrun simulator discovery: both commands not found.

No Apple SDK, Xcode or iPhone simulator is available. Rendered normal equivalence, actual keyframes, accessibility actions, expiry-task lifecycle, touch passthrough, modal/keyboard interactions and performance measurements remain unverified.

Before merge, use Xcode 26+ with iOS 18/iOS 26 simulators to compare normal mode, open every app, run all six visual previews, exercise expiry/restore/clock changes, verify Home and gameplay controls during interruptions, inspect VoiceOver/Reduce Motion/large text, check locked/unlocked layout preservation, and use Instruments to compare idle/active-event allocations and frame pacing. Confirm changing day/flags/corruption alone never advances the visual state.
