# Development roadmap

Updated: 2026-10-15. Authority: [game bible](BANANA_CORP_GAME_BIBLE.md) and [creator's development directive](AUTONOMOUS_DEVELOPMENT_DIRECTIVE.md). Implementation inventory is evidence of work, not proof of a finished game. See [agent progress](AGENT_PROGRESS.md) and [QA plan](QA_TEST_PLAN.md).

| Phase | Current state | Next concrete outcome |
| --- | --- | --- |
| A — Reconnaissance | Initial repository/history/code/asset/test audit complete | Keep inventory and blockers current after each focused PR |
| B — Stabilization | Core offline progression covered; Apple build/device validation outstanding | Repair native QA invocation/logging, then execute actual Debug/Release builds on available Apple tooling |
| C — Opening acts | Acts 1–2 implemented with preserved/unpreserved routes and local content | Verify actual launch, scrolling, accessibility, source replacement and relaunch on iOS 18/26 |
| D — Conspiracy/takeover | Act 3 and explicit Act 4 entry implemented; full takeover/resistance absent | Prepare approved Act 4 dependency/presentation contracts; implement only established portions |
| E — Final choice | Canonical endings described; playable route/ending evaluators absent | Settle explicit puzzle/route/cooperation/replay contracts before implementation |
| F — Polish/device QA | Modern OS, themed surfaces and motion infrastructure present; native proof absent | Close Apple build/QA, integrate approved art/media, then prepare a valid playtest installation route |

## Verified inventory at reconnaissance

- One AppState owns OS navigation and shared story/content/access stores. Story save schema 2 holds version receipts, immutable Evidence snapshots, milestones and explicit events. No parallel narrative store is needed.
- 15 reachable fictional app routes, including Evidence and three routed games. FlapFlap is an existing unrouted implementation; no new game gate or mechanics change is authorized by this audit.
- Production catalogue: **70** items — 25 Act 1, 20 Act 2, 24 Act 3 and one Act 4 entry. **25** restricted resources; one approved Banana Wall puzzle plus an inert retired descriptor. Acts 2/3/4 have explicit consecutive handoffs; Act 5 remains closed.
- Photos supports delivery but has no production photo records; Phone is a service-limited empty state. These are content gaps, not approved requirements to create new calls/photos.
- Media remains accurately identified transcript/metadata where no playable asset exists. Asset registry has **132 planned image IDs**; the only ordinary imported image set is the legacy logo. App icons and launch images already exist in the compiled catalogue. Source staging has 14 tracked categories.
- Sixteen Foundation/check suites, hosted integration tests and a native Acts 1–3 journey exist. Their historical Linux success does not establish an Apple build. This pass adds portable native-runner command-contract checks.

## Priority work queue

1. **B-01 — Native QA runner reliability:** use invocation-local testability for hosted Release tests; retain compiler stderr; test failure propagation and owned simulator cleanup. First focused implementation in this pass.
2. **B-02 — Apple compile and player journey:** run the existing native scripts with actual Xcode 26+ and installed iOS 18/26 runtimes, repair compiler/test failures, retain logs and xcresults. No paid hosted runner or new external access is authorized implicitly.
3. **B-03 — Device behavior/performance:** inspect safe areas, scrolling, Reduce Motion, VoiceOver, Home/swipe reliability, app/game lifecycle, modal dismissal, Evidence retention and native memory/rendering. Fix observed defects rather than speculative rewrites.
4. **D-01 — Act 4 implementation specification:** map established Signal/resistance, research accountability and takeover beats into explicit dependencies; distinguish approved facts from unresolved details. Prepare a reviewable proposal where design is still TBD, without activating it as canon. Engineering draft: [dependency and presentation specification](docs/ACT4_DEPENDENCY_SPECIFICATION.md); production contracts remain unresolved.
5. **D-02 — Approved takeover/resistance implementation:** implement the agreed graph and recovery behavior; preserve mandatory/optional Observer independence, Maya's missing status and earned Assistant cooperation.
6. **E-01 — Route design contracts:** exact LANTERN/component puzzles, Maya identity fragments/notes/baseline, DAWN stabilization, negotiation conditions, optional Observer clue acquisition/session refusal and replay/reset remain unresolved. Do not guess values or encode hidden scores.
7. **F-01 — Production art/media integration:** import approved derivatives through the typed asset map and structured content metadata; preserve versions. Planned registry items are not produced files, new identities or approved story beats.
8. **F-02 — Playtest readiness:** only request hands-on testing after the intended scope passes available checks, real builds/install route exist, known missing material is disclosed, and critical blockers are resolved.

## Missing inputs and boundaries

Apple SDKs/runtimes and an authorized connected iPhone are not present in the current Linux execution environment. No native build or physical result is claimed. Creating paid macOS CI, obtaining signing/distribution access, spending, external build distribution and App Store submission require the creator's consequential approval.

The supplied directive approves the written Synthetic Reality direction. Actual mood-board/reference images and approved character/headset likeness sheets are not present in the repository; they were not independently reviewed. ChatGPT project conversations were not read in this audit; repo canon and explicitly supplied documents are the evidence used. Missing final puzzle/ending decisions must be documented or proposed, not silently inferred from inaccessible conversations.

Existing historical validation documents retain their original results. [Release QA](docs/ACTS_1_3_RELEASE_QA.md), [Act 3 inventory](docs/act-three-content-inventory.md), [asset workflow](Assets/README.md) and [story implementation](docs/STORY_IMPLEMENTATION.md) provide detailed contracts. Future updates should clearly supersede historical limitations without rewriting old results into new passes.


Native Mac update (2026-10-15): Xcode 26.5 and iOS 26.5 are available. Actual Debug/Release simulator builds and bundle checks passed; five Debug hosted tests passed. Launch UI tests failed and remain under diagnosis; Release XCTest/full native journey are not yet established. iOS 18 runtime is absent. See [current native results and continuation](AGENT_PROGRESS.md#native-mac-execution--2026-10-15). Historical Linux limitations above describe the earlier run.


Isolated confirmation (2026-10-16 continuation): actual Debug/Release builds and bundle checks passed. Five hosted and three UI smoke cases passed in each configuration, including all 15 apps, repeated launch/Home and reserved-strip swipe. Release evidence: `validation/native-fixed-20261015/tests-Release-isolated.xcresult`. Full journey is running separately; its integration skip is not a journey pass. Earlier Release failures are retained. Run one QA simulator at a time and check for owned simulators left booted after interruption. See [current tracking](AGENT_PROGRESS.md).
