# Persistent story progression engine

This implements the infrastructure authorized by Pass 2, governed by [the game bible](../BANANA_CORP_GAME_BIBLE.md). No Act 1 content, later-act rules, puzzle solutions, ending evaluator, scoring formula, elapsed-time advancement, weather service or new UI is included.

## Ownership and state

AppState owns one main-actor, Observation-based StoryProgressionStore. Its read-only StoryState is the narrative authority. Store callbacks bridge notifications to the existing ObservableObject AppState without copying narrative state; SwiftUI can also observe the store directly. OSNavigationState and OSPresentationState retain their existing roles. App-state callbacks capture weakly and no new timer/background loop exists.

The app source directory `Banana Corp/Banana Corp/` contains:

| File | Responsibility |
| --- | --- |
| StoryState.swift | Five acts; schema-v1 Codable facts, immutable evidence/version records, explicit Assistant cooperation, optional ASCENSION milestone, route/Observer/event facts, compatibility flags and app locks |
| StoryPrerequisites.swift | Pure deterministic AND/OR conditions and injected act-transition requirements |
| StoryProgressionStore.swift | Validated actions, idempotent transactions/events, controlled next-act advancement, load/save/reset and observable recovery status |
| StoryPersistence.swift | Native atomic JSON file adapter, injectable test/preview adapter and explicit version migration registry |
| StoryTime.swift | Real context, relative story day, configurable fictional time and fixed narrative timestamps |

New games start at The Perfect Product, story day 1, no discovered/read content or earned facts, Assistant cooperation not established, ASCENSION unset and all existing apps available. No historical persistent story flags exist to import. Home customization continues using its existing UserDefaults key without changes.

## Action and prerequisite contracts

Use `perform(_:when:)` for explicit player/story actions. It returns a typed changed/unchanged outcome or validation, prerequisite, recovery or save failure. Story IDs follow stable lower-case hierarchical names; technical IDs are independent of canon's display labels such as M-01. Do not rename saved route raw values, including `messager`.

- Discover and read are separate. Marking read requires discovery and must be called by a meaningful content-engagement handler, never a row renderer or app-opening callback. No view call sites are added yet.
- Evidence records have independent IDs, source content/version IDs, capture timestamps and opaque immutable snapshots. Both source identities must have been discovered. Reusing a preserved ID for different data fails. Replacement records retain original/replacement identities without mutating evidence or implicitly discovering/reading a new version. A replacement may happen before a player discovers its source.
- Conditions support discovery, reads, preserved evidence, solved puzzles, access, milestones, act reached, explicit Assistant cooperation/facts, Observer clues, route prerequisites and completed events. AND/OR compose them. Empty/malformed combinations fail closed; nesting is limited to 32 levels. There are no clock, app-appearance, trust or morality conditions.
- `completeEvent(_:actions:when:)` commits all validated effects plus its event ID once. A failed effect or write commits none. Retrying an already completed ID returns unchanged, even if the caller's current condition has changed. Event IDs must identify a stable authored event, not a dynamically regenerated action list.
- `advanceAct(to:)` accepts only the next act, a configured nonempty milestone list, and a satisfied condition. Production rules are deliberately empty because exact prerequisites remain TBD. Synthetic fixture rules test all consecutive transitions; they are never loaded into the app. No later acts are activated.
- Direct puzzle/access/milestone actions do not invent puzzle answers or approved gates. Future content callers must supply their approved conditions; the generic engine is not a catalogue of authorized story content.
- Assistant cooperation is explicit, with not-established/cooperating/separated states and independent relationship facts. Separation does not implicitly satisfy cooperation equality. ASCENSION is an optional named milestone with an optional 0–100 percentage, not a timer; neither can advance acts automatically.

## AppState field audit

| Existing field | Integration |
| --- | --- |
| currentDay | Read-only projection of saved relative story day; not an act or elapsed-real-time counter |
| hasOpenedVRApp | Saved compatibility fact, initially false; explicit action only, with no new app-open trigger |
| hasSeenFirstGlitch | Saved compatibility fact, initially false; no new glitch/event is introduced |
| unlockedApps | Derived from all existing routes minus saved locked raw IDs; initial availability unchanged; Settings stays available |
| unreadEmails / unreadMessages | Read-only zero placeholders until actual content exists; future counts must derive from available/read content, not a second saved counter |
| aiCorruptionLevel | Retained cosmetic input, initially zero and transient; not narrative authority, scoring or act progression |

The existing conditional availability API now saves before changing access. Failed persistence leaves access/navigation unchanged. A successful lock through either AppState or its store returns the active app home through the current coordinator, preserving game cleanup. Unlocking never resets saved icon positions. `resetStoryForNewGame()` is the OS-facing explicit reset action: it resets story facts after a successful archive/save, returns home, restores normal cosmetics and leaves the home layout intact. There is no new reset button in this pass.

## Persistence and recovery

The single save is `Application Support/BananaCorp/story-save.json` inside the app sandbox. A small native JSON file is sufficient for the current structured state, needs no network/cloud/dependency, and lets significant actions use Foundation's atomic file replacement. Actions encode and write synchronously on the main actor before publishing the new state, so they do not depend on background/termination callbacks. Event batches make one write; no-op repeats make none. Storage and codec are injectable for deterministic tests. Future large content should use the content layer's storage rather than high-frequency game/animation writes to this store.

Load distinguishes no file from read/decode/invariant/migration failures. Missing storage on first launch creates a new save. A file disappearing on a later load requires recovery even if no facts have been earned; retrying cannot silently create a new campaign. An invalid or unsupported save stays untouched; saveStatus becomes recoveryRequired and progression queries/actions fail closed. Default state is only a safe display fallback, not evidence that the campaign restarted. A failed write returns an error and leaves memory unchanged; the caller may retry.

Callers must handle typed errors and observe saveStatus when future content/recovery UI is built; this infrastructure pass does not add player-facing recovery controls. `load()` retries an externally restored save. `resetForNewGame()` is explicit and archives existing bytes as `story-reset-<UUID>.json` before replacing the save. If archiving or writing fails, it does not publish a reset. Archives are local and deliberately retained for recovery; there is no silent deletion or automatic reset. Home customization is independent.

Schema version 1 is the first shipped story schema. Registered migrations transform one version at a time and must emit the next version before validation/write. There is no fabricated production v0 migration. Synthetic v0 tests prove registration, missing/broken migration blocking, relaunch of migrated facts and original-byte preservation on write failure. Newer versions are rejected without overwriting. Future migrations must preserve stable IDs and approved facts and be tested against retained old-save fixtures.

This is a single-owner local save, not a cross-process concurrent-writer system. Development locking previews inject InMemoryStoryPersistence and cannot modify the player's story save.

## Story time

StoryTimeContext snapshots the real device date/time and time zone beside saved StoryTimeState. NarrativeTimestamp represents a relative story day and fixed hour/minute without a Gregorian launch date. Relative labels distinguish today/tomorrow/yesterday/offset; they do not compare against the real calendar. Relative days are bounded only for representability, not as a campaign-duration rule.

Fictional time and opening clock presentation are independently configurable via an explicit action. The default is deviceTime; StatusBar remains unchanged and continues displaying real time. This pass does not wire a fixed 9:41 clock, reinterpret “tomorrow,” choose timing rules, request permissions or infer progression from elapsed time.

## Validation

Run `bash scripts/check-story-progression.sh` with Swift 6.2 in the project's Swift 5 language mode (warnings treated as errors). It compiles the actual Foundation/Observation production models and store. Tests cover new-game defaults, observation, stable ID validation, discovery/read separation, event rollback/idempotency, every condition type, empty/malformed gates, injected consecutive-act advancement, production transition blocking, evidence immutability/version preservation, Assistant/Observer facts, time separation, saved app locks, Settings safety, corrupt/newer-schema recovery, migrations, explicit reset archives, real file I/O, write/archive failure atomicity and independence from home customization. Separate write/read process invocations prove synchronous disk persistence without graceful shutdown.

Existing OS navigation, home layout and presentation checks remain applicable. Apple-platform builds and AppState/SwiftUI runtime integration must be verified with Xcode 26+ on iOS 18 and iOS 26 simulators when available. Pure Foundation checks do not claim rendered UI, game/session, or Apple-SDK typechecking results.

Actual results for this pass:

- Story checks passed in the official Swift 6.2 Linux container, using Swift 5 language mode with warnings as errors, a read-only repository mount and networking disabled. Separate-process write/relaunch checks passed.
- Existing navigation checks (1,400 app cycles and 14 swipe cases), home layout/persistence checks (including 160 valid moves), and presentation checks passed.
- All 38 app sources passed Swift syntax parsing with DEBUG enabled. All source references and unique PBX IDs were verified; the deployment target remains iOS 18.
- Static comparisons verified unchanged mini-games, launch/root UI, home, status bar, route IDs, OS navigation and home persistence. All 15 local Markdown links resolve; script syntax checks passed.
- Whitespace checks passed outside the bible and with Markdown end-of-line whitespace allowed for the bible. The version metadata retains its existing hard-break formatting, which the default whitespace check flags.
- `xcodebuild` and `xcrun` are not installed. No Apple SDK, simulator, rendered UI, or AppState/SwiftUI runtime result is claimed.
