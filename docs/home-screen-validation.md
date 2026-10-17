# Home screen redesign validation

This change builds on the merged Task 1 PR (#7). The separate PR targets main.

## Actual results

- Passed the production Foundation layout/persistence checks using the official Swift 6.2 Linux container (repository mounted read-only; container network disabled). Run locally with `bash scripts/check-home-layout.sh`.
- Checks cover the default dock, duplicate/oversized layout repair without losing apps, grid and dock reorder, transfers between sections, full/empty dock behavior, self-drop and wrong-section rejection without mutation, all source/target pairs (160 successful moves), malformed/multiple drag payload rejection, missing-route append, UserDefaults v1 reload, and corrupt-data fallback.
- Passed Swift 6.2 syntax parsing of all 27 app source files. This does not typecheck SwiftUI against an Apple SDK.
- Passed `git diff --check`, source-reference checks, and verification that all 14 existing OS routes retain icon metadata and destinations.
- Checked sizing arithmetic for 320/375/390/430-point widths: four columns; 58-point icons at 320 and 64-point icons at the other widths. This is an arithmetic check, not rendered simulator validation.
- At the original validation time, no Apple SDK, Xcode, or iPhone simulator was available. Native continuation results are recorded in [the integration record](IOS_INTEGRATION_VALIDATION.md) and [agent progress](../AGENT_PROGRESS.md); this historical checklist does not establish native touch drag/drop or editing coverage.

## Architecture and changed behavior

- HomeScreenView lays out a top-aligned scrolling grid and a bottom floating dock inside PhoneShellView's hardware-safe content region. Equal dock slots remain stable with fewer than four visible apps.
- BananaAppIcon is the reusable icon component. It supports SF Symbols or asset images, labels, capped visual badges with full accessible counts, locked/unlocked rendering, editing wiggle, reduced motion, press feedback, and injectable future appearance. Only the standard appearance is used.
- PhoneAppInfo contains display metadata; PhoneAppRoute remains identity; HomeScreenLayout stores positions. No ARG story state is activated.
- The iOS 18-compatible draggable modifier is active only while editing. Drop destinations remain attached in normal mode; AppState accepts moves only while editing and Home is ready. Long press or the accessibility action enters editing. Done and taps in the background/gaps finish editing. Taps on icons cannot launch while editing, including the coordinator guard.
- AppState applies accepted moves through the transactional model and persists immediately using the existing v1 key. There is no drag-preview lifecycle state to leave app launching blocked after a canceled drag.
- Normalization retains hidden routes and appends missing routes, preserving customized order when apps are unlocked or new known routes are added.
- Dock styling uses guarded iOS 26 Liquid Glass, a dark translucent purple custom surface on iOS 18–25, and an opaque themed surface for Reduce Transparency.
- Task 1's root transitions and all app destinations are preserved.

## Required iPhone simulator checks

Use Xcode 26+ with iOS 18 and iOS 26 runtimes. Check a small iPhone and a large Dynamic Island iPhone.

1. Inspect four columns, labels, consistent icons, scrolling on short screens, and the dock above the real system gesture area. Rotate and check large text, Reduce Motion, and Reduce Transparency.
2. Long press an icon: verify subtle wiggle, no launch, and no shift of the grid when Done appears.
3. Reorder the grid and dock by dropping before another icon; drop in a section's empty area to append. Move a dock app to the grid, then a grid app into the free dock slot.
4. Drop a grid app on a full dock: it must stay in the grid. Cancel a drag and reject unknown/multiple payloads without changing the arrangement. Verify no duplicated or deleted app routes.
5. Tap an icon while editing: no launch. Tap Done or background/gaps: editing exits. Verify ordinary taps work after canceled and rejected drags.
6. Customize, force quit, and relaunch. Verify both section membership and ordering persist.
7. In a debug harness, lock and unlock an existing route after customization: its saved position and the relative order of other routes must survive.
8. Open and return home from Email, Web, Social X, Video, Messages, Photos, Settings, Phone, News, AI Assistant, VR, Snake, Pong, and X / O. Repeat and reopen games; verify Task 1 navigation remains reliable.
