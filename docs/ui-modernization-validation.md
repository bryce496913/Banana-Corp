# App UI modernization validation

Built on the merged OS shell (#7) and home screen (#8). The PR targets main.

## Inventory and scope

The repository has 14 routed applications and one compiled, unrouted game. Email, Messages, News, AI Assistant, Web Browser, Social X, Photos, Video, Phone, Settings, and VR Experience were entirely placeholder views before this change. There were no real messages, conversations, articles, posts, photos, videos, browser pages/history, calls, settings toggles, or headset activation flow.

Their original status and descriptive text are preserved in polished, scrollable shells. No sample ARG content or service implementations were introduced.

| App | Presentation |
| --- | --- |
| Email | Inbox section, unavailable search field, scoped empty state |
| Messages | Conversations section, scoped empty state, unavailable composer |
| News | Latest section and editorial empty state |
| AI Assistant | Banana Assist branding, scoped connection state, unavailable composer |
| Web Browser | Unavailable address/search bar, page state, unavailable back/forward/reload controls |
| Social X | Feed section and identity-verification state; no fabricated posts |
| Photos | Library section and indexing state; no fabricated media or viewer |
| Video | Library section and locked state; no fabricated player |
| Phone | Calls section and existing registration-limited state; no fabricated keypad or calls |
| Settings | Grouped device information and managed-settings state; no invented preferences |
| VR Experience | Headset section, Banana VR branding, larger headset artwork, original calibration state |
| Snake | Shared header, score panel, opaque game-over overlay, adaptive directional pad |
| Pong | Shared header and score panels; unchanged board and paddle drag |
| Tic Tac Toe | Shared header/status panel, reset action area, cell coordinates for accessibility |
| Flap Flap | Shared start/game-over presentation and sheet actions; remains unrouted |

No app-level feed/chat/reading/player/navigation functionality was replaced by a mockup. Search and composer inputs have explicit unavailable states and do not accept text or simulate successful submission.

## Shared design system

- The exact five requested colors are unchanged.
- Screen title, section title, body, caption, and system-label tokens use semantic SwiftUI fonts that follow Dynamic Type. The h1/h2/h3/paragraph case names remain as compatibility aliases.
- AppComponents contains shared headers, scrolling containers, cards, passive list rows with timestamp/unread/badge slots, search and text fields, navigation/floating controls, empty/loading/error states, composers, segmented controls, toggle rows, adaptive media grids, score panels, and game overlays.
- Primary/secondary button styles have at least 44-point touch targets and honor enabled state and Reduce Motion. Native alert and confirmation wrappers preserve platform behavior.
- Reading cards and game overlays are opaque. Guarded iOS 26 glass is reserved for navigation/action controls, with themed iOS 18 fallbacks and an opaque Reduce Transparency surface.
- The app root consistently requests dark appearance and the theme accent. PhoneShellView owns a single shared header and status bar; nested view content does not duplicate them.
- Snake uses a compact four-button row on short screens and scrolling for very short/accessible layouts. Tic Tac Toe scrolls for short layouts and large text. Board sizing formulas, cell/paddle coordinates, colors, timing, collision/scoring rules, and resets are preserved.
- Pong stays outside any ancestor ScrollView, preserving its drag control. Its HUD and the fictional status bar cap Dynamic Type at xxxLarge to leave space for hardware regions and game controls. Snake's board overlay is similarly bounded; other reading content supports accessibility sizes.
- AppComponents has debug-only interactive previews for component behavior, large text, keyboard/composer layout, alerts, and confirmation dialogs. These previews are not routed apps or story state.

## Checks actually run

1. Production HomeScreenLayoutChecks compiled and ran with Swift 6.2 in the official Linux container, repository mounted read-only and networking disabled. Passed all existing regression checks, including 160 valid moves, rejected-move atomicity, duplicates, overflow retention, dock limits, payload validation, and UserDefaults v1 reload.
2. Swift 6.2 syntax parsing passed for all 28 app source files, with DEBUG enabled to include the interactive catalogue. Syntax parsing does not typecheck SwiftUI with an Apple SDK.
3. Source comparisons passed: Snake/Pong models unchanged; Tic Tac Toe rules/status/reset unchanged; Flap Flap mechanics/timers unchanged; Pong board/paddle gesture unchanged; Snake/XO board sizing formulas preserved.
4. Static checks passed: all 11 existing placeholder status/descriptive strings retained, exact five theme colors retained, OS coordinator/routes/persistence/launch source unchanged, all 14 routes still have destinations and icon metadata, all 28 project source references resolve.
5. git diff --check passed.
6. Attempted xcodebuild with the Banana Corp scheme, iphonesimulator SDK, generic iOS Simulator destination, and signing disabled: command not found.
7. Attempted xcrun simctl list devices available: command not found.

No Apple SDK, Xcode, or iPhone simulator is available in this workspace. No Apple-platform build, rendered screen, runtime navigation, gesture, keyboard, alert/dialog, or game execution result is claimed.

## Manual checks still required

Use Xcode 26+ with both iOS 18 and iOS 26 simulators, including a small iPhone and a larger Dynamic Island device.

- Build and launch Banana Corp. Verify splash, edge-to-edge black, fictional status bar only, root vertical transitions, home customization, and repeated app reopening.
- Open each of the 14 routed apps. Verify one app header/status bar, readable states, scrolling, black background, safe controls, and no overlaps in portrait/landscape or at larger Dynamic Type sizes.
- For the eleven placeholder apps, verify original descriptions, unavailable inputs/actions, and no fake data or successful service behavior. Keyboard interaction is intentionally unavailable in these apps because their underlying feature is absent.
- Run the Shared components previews with small/large frames and accessibility text sizes. Type in search and composer inputs, submit/clear a preview message, dismiss the keyboard, toggle/select controls, and present/dismiss the native alert/confirmation dialog. Verify the keyboard does not cover the composer or bottom actions.
- Verify Reduce Motion/Reduce Transparency, VoiceOver labels/badges, game directional labels, and Tic Tac Toe cell coordinates.
- Play Snake: all directions, collisions, score, game-over restart, short-screen compact pad and scrolling fallback. No OS gesture should steal game input.
- Play Pong: paddle drags, scoring/round messages, resize, background/foreground, return/reopen. Verify HUD changes do not compromise board interaction.
- Play Tic Tac Toe: both winners, draw, full board, reset, and repeated return/reopen.
- Preview Flap Flap with AppState injected: start/flap, game-over sheet, dismiss/restart, disappearance/background cleanup. Do not add a route solely for validation.
