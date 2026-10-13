# First anomaly — Pass 6

This completes the first playable mystery loop authorized by the user under [the canonical bible](../BANANA_CORP_GAME_BIBLE.md). It adds five immutable catalogue entries to the [20-item opening](act-one-content.md), without changing those published definitions or introducing the rest of Act 2.

## Authored slice

| Stable item suffix (`content.act1.first_anomaly.*`) | Surface | Purpose |
| --- | --- | --- |
| `trace` | Email | Legitimate delivery record: opened subject and unavailable status, explicitly not the original body or preserved proof |
| `warning` | Messages | Unknown incoming sender; exact **You found the email… Do not trust the assistant.** text |
| `denial` | Assistant | Calm synchronization explanation, available only after the warning is read |
| `challenge` | Assistant | Optional challenge using an authentic preserved original; no saved-proof claim on the other path |
| `notification` | Fictional OS notification | Same warning, pointing to the Messages conversation; never a real push notification |

Each has `version.act1.first_anomaly.<suffix>.v1`. Dialogue and source copy live in bundled `StoryContent.json`. Typed conversations/Assistant payloads gain optional local `links`; their references are validated, and old definitions/snapshots decode with absent links. `recordAssistantFact` is a closed declarative read effect validated against declared `assistantFact` IDs. No arbitrary executable content or scoring is added.

## Removal and preservation boundary

`FirstAnomalyContract` in `StoryPrerequisites.swift` centralizes stable IDs and approved conditions. `StoryContentStore.activateFirstAnomalyAtBoundary` requires Act 1, the saved article/promo context milestones, `milestone.act1.first_suspicious_material`, and a read of `version.act1.echo_review.v1`.

The explicit `event.act1.first_anomaly.email_removed` transaction retains the original receipt, marks the source unavailable, reveals/freezes the trace and warning, and freezes/queues the notification. All changes save before becoming observable; any validation or write failure leaves the live email and all delivery facts unchanged. Duplicate calls are no-ops.

The boundary is an actual return from the original detail to the inbox, an explicit fictional Home action/swipe, or opening the inbox after a saved original read. Reading/preserving, rendering a list, elapsed real time and merely loading a save do not activate removal. The original detail remains live indefinitely while the player stays there, with Preserve Evidence available. No countdown or unrelated-app gate is used.

The original source/version remain immutable in the catalogue. Removal uses the existing content-delivery unavailable state, not deletion or replacement of its bytes. Preserved snapshots and timestamps never change. Source read receipts are internal version-consistency records: they are **not** evidence and cannot be used to manufacture a player archive after removal.

- **Preserved path:** Evidence opens the exact original; explicit Compare observes that its current source was deliberately removed. This earns `milestone.act1.first_contradiction_investigated`. A separate `event.act1.first_anomaly.evidence_compared` ensures an earlier unchanged comparison does not swallow that later action.
- **Unpreserved path:** No evidence is fabricated. The player explicitly opens the delivery record from the inbox or warning link; that meaningful inspection earns the same investigation milestone. Its authored subject/status are supported by the saved original read/removal facts; it explicitly retains no original body. The warning and its local links remain available, so this path cannot softlock.
- **Optional challenge:** The warning must have been read and the preserved original must validate against its source receipt. Corrupt/unreadable evidence cannot unlock the saved-copy response or its investigation effect.

## Warning, denial and Act 2

Messages lists the incoming unknown conversation and derives unread indicators from the central store. Notification delivery does not mark that conversation read; only opening it commits the read. Both its incoming text and its links persist across launches. Local links lead directly to the mail trace and the Assistant question, so the player need not guess an unrelated app.

Choosing the denial or eligible challenge records `assistant.act1.first_anomaly_questioned` atomically with that response's read. It is a factual interaction, not agreement, trust or cooperation: `assistant.cooperation` remains `notEstablished`. The Assistant neither confesses nor threatens and never names the sender.

Production configures **only** Act 1 → Act 2. All of the following are required:

1. Article context: `milestone.act1.news_context`.
2. Explicitly completed promotion: `milestone.act1.promo_viewed`.
3. Original email read plus `milestone.act1.first_suspicious_material`.
4. Completed removal: `event.act1.first_anomaly.email_removed`.
5. Warning version actually read.
6. Explicit Assistant interaction: `assistant.act1.first_anomaly_questioned`.
7. Explicit inspection/comparison/challenge: `milestone.act1.first_contradiction_investigated`.

**Continue investigation** invokes the existing guarded `advanceAct` transaction. Rendering its control never advances. It appears on eligible source details, the Assistant and the saved/live comparison screen. Failed persistence leaves Act 1 intact and permits retry. A successful handoff persists Act 2; the later Act 2 scenes and all Act 3–5 transitions remain unimplemented. No evidence requirement, optional-app visit, mini-game gate, wait, hidden trust threshold or numerical cooperation calculation is involved.

## Restrained presentation

The durable `event.act1.first_anomaly.presentation_consumed` acknowledges the fictional notification and records the existing first-glitch compatibility flag **before drawing**. AppState then presents one two-second carrier irregularity (`BANANA 5G…`) and the warning card through the existing story-aware presentation system. The palette remains standard; there is no flash, distortion, permanent theme change, timer-based story trigger or gesture interception. The existing monotonic cooldown applies.

The two-second expiry task only ends an already earned visual event; it does not change the plot. Dismissal/expiry restores Normal. Reduce Motion requires no animated equivalent because the effect is a static, brief label override. Essential information stays in the unread Messages thread. If a process dies between consumption and rendering, the cosmetic moment is not replayed; the warning remains. If removal saved but consumption did not, an OS appearance/foreground return can deliver the still-pending moment once. Narrative handoff never depends on seeing it.

## Persistence and development tools

Story save schema remains 2. All five new versions are additive; optional typed links default to nil. Prior opening version receipts and preserved bytes remain valid. New facts/events/notification records use existing sets and the existing local atomic save. Home layout, routes, launch, game mechanics and network/permission behavior are unchanged.

DEBUG builds expose **Settings → Story slice diagnostics**: act, milestone/Assistant facts, live definition and availability, authentic evidence state, delivered/unread conversation counts and completed anomaly events. Confirmed reset archives the current story bytes without resetting Home layout. Replay with/without preservation executes actual catalogue reads, promo completion, preservation and the removal boundary. Release builds contain neither the link nor diagnostic view nor replay helper. The ordinary visual cooldown still applies to rapid debug replays.

## Automated validation

Run `bash scripts/check-first-anomaly.sh`. It checks both evidence paths, original/live immutability, meaningful preservation opportunity, once-only atomic delivery, passive queries, unread warning, exact anonymous text, conditional denial/challenge, explicit investigation, every missing handoff prerequisite, no later-act rule and save/resource failure rollback. Both paths run nine separate-process checkpoints: before original read, after read, before change, after removal, before warning read, after Assistant question, after investigation, after Act 2 unlock and after relaunch. The remaining seven repository checks remain relevant.

## Manual playthrough checklist — Apple SDK required

Use Xcode 26+ and available iPhone simulators on iOS 18 and iOS 26. These steps are a checklist, not claimed simulator results.

- [ ] Fresh install/reset: launch/splash enters the ordinary Home; warning, denial and trace are absent.
- [ ] Read one news article and complete the promo; the original ECHO email becomes available in either order.
- [ ] Open the email and stay in its detail: no timed removal. Preserve Evidence remains available, including after background/foreground without leaving the detail.
- [ ] Preserved path: preserve, optionally compare unchanged, then use Back or fictional Home. Source disappears once; the saved original still opens unchanged.
- [ ] Unpreserved path: leave without saving. Evidence has no original copy. Open the delivery record or follow the warning link; it shows only subject/status, never reconstructed correspondence.
- [ ] Carrier irregularity/notification appear once, restore Normal after two seconds and do not block Back/Home or game gestures. Reduce Motion shows no flash/animated distortion.
- [ ] Messages badge becomes unread; background/relaunch leaves the warning available and unread until its thread is opened.
- [ ] Question the Assistant from its app or the warning/trace link. Its explanation is calm; saved-copy challenge is present only with authentic evidence. No cooperation/trust score appears.
- [ ] Without deliberate trace inspection, changed-source comparison or evidence challenge, Continue investigation stays unavailable. With the investigation and all other prerequisites, it advances once to Something Isn’t Right.
- [ ] Quit/relaunch at every automated checkpoint above. No lost facts, duplicate warning/evidence, cosmetic replay, reverted act or unavailable recovery lead.
- [ ] Repeatedly navigate all apps, preserve/reorder the customized Home, dismiss native alerts and verify Dynamic Type/VoiceOver labels and system gesture regions.
- [ ] DEBUG diagnostics inspect and replay both paths; a Release build has no diagnostics entry or replay UI.

### Actual results — 2026-10-13

All eight Foundation suites passed using official Swift 6.2, language mode 5 and warnings as errors in a network-disabled container with a read-only source mount. The anomaly suite compiled with DEBUG and passed both evidence paths, corrupt-evidence fallback, debug reset/replay, every omitted handoff prerequisite and atomic save/resource failure recovery. Each path passed nine separate-process checkpoints. Existing content, evidence and progression save/reload tests passed; navigation covered 1,500 cycles/14 swipe cases, layout 185 valid moves, and presentation safety checks passed.

All 45 app Swift sources parsed in both DEBUG and Release configurations. All 37 local Markdown links resolved, project references and the iOS 18 target checked, and whitespace/shell syntax checks passed. The 20 published opening definitions remain identical; five anomaly entries are additive. Mini-games, home layout, routes, launch/splash and save schema remain unchanged.

`xcodebuild` and `xcrun` are unavailable on this Linux host. No Apple-SDK typecheck/build, iPhone simulator, visual layout, native gesture, VoiceOver or haptic validation was possible. Source parsing and Foundation tests do not establish those results; the manual checklist above remains outstanding.
