# Banana OS validation

## Results in this workspace

- Linux x86_64 workspace; no Swift compiler, Apple SDK, Xcode, or iPhone simulator.
- Attempted `xcodebuild -list -project "Banana Corp/Banana Corp.xcodeproj"`: command not found.
- Attempted `xcrun simctl list devices available`: command not found.
- `git diff --check`: passed.
- Static checks: all 14 existing OS routes still have destinations and icons; all referenced Swift source files exist; HomeButton references removed; deployment target remains iOS 18; existing Liquid Glass usage remains availability guarded.
- No build, device execution, gesture behavior, or modal runtime result is claimed.

## Required simulator checks before merge

Use Xcode 26 or newer (the project already uses Liquid Glass APIs). Run on both an iOS 18 and iOS 26 iPhone simulator, including a device with Dynamic Island.

1. Cold launch: four-second logo, fade into home; only the fictional status bar appears. Verify real-world time, readable carrier and fictional connectivity icons.
2. Open each of the 14 grid/dock apps. Verify upward entry, black screen edges, and safe-area controls in portrait and landscape.
3. Return via a tap, VoiceOver activation, and upward swipe on the reserved fictional indicator strip. Verify upward exit. Downward/horizontal swipes must not return home.
4. Repeat open/home/reopen rapidly, including the same game. Verify one home screen, fresh game sessions, and no unexpected score advancement.
5. In Pong, drag the paddle; in Snake, use all direction controls; in home, scroll and rearrange icons. These actions must not trigger OS navigation.
6. Background/foreground Snake and Pong. Verify no game advancement while inactive. Verify the real iOS Home gesture works normally.
7. Enable Reduce Motion and VoiceOver. Verify fade transitions and no focusable home icons behind an active app.
8. Flap Flap is compiled but has no existing OS route. In a temporary preview/test harness with AppState injected, trigger its game-over sheet, dismiss/restart, and leave the view. Verify hidden system status bar, black modal background, and timer cleanup. Do not add an OS route solely for testing.
9. For any future nested destinations or modals, retain their local navigation and use PhoneShellView / explicit statusBarHidden(true) on presented content.

## Changed behavior and files

- ContentView: cancellable launch delay and dedicated BananaOSView with one persistent home, a per-app NavigationStack, vertical transitions, and Reduce Motion fallback.
- AppState: read-only published active route; guarded opens and centralized home/edit cleanup.
- HomeScreenView: home layout only; destination presentation moved to the OS root.
- PhoneShellView / PhoneHomeIndicator: hidden system status bar and safe-area 44-point Home button with direction-filtered upward swipe.
- StatusBar: larger carrier/time/connectivity typography and fictional indicator accessibility labels.
- SnakeGameView / PongGameView: gate updates on active OS route and scene activity, including outgoing animations.
- FlapFlapGameView: supported SwiftUI game-over sheet, owned timers, disappearance/background cleanup, and prevention of duplicate starts.
- HomeButton and project references: remove unused legacy component.
