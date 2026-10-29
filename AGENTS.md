# Repository instructions

## Story authority

Read [BANANA_CORP_GAME_BIBLE.md](BANANA_CORP_GAME_BIBLE.md) before changing story content, gameplay, app behavior, progression, puzzles, endings, or story presentation. It is the canonical design reference, not a claim that its features are implemented. Inspect the current implementation and relevant tests before editing. Use [docs/STORY_IMPLEMENTATION.md](docs/STORY_IMPLEMENTATION.md) for the implementation inventory and documentation conventions.

- Preserve the five-act chronology and reveal order, including knowledge boundaries on notifications, accessibility labels, and all other player-visible surfaces. The older six-phase outline is superseded; phone interference and breaking the Banana Wall are beats within the five acts.
- Preserve established names, clues, progression rules, puzzle frameworks, and ending requirements. Keep `[TBD]` decisions unresolved and `[PROPOSED]` items unapproved unless explicitly authorized by the user. Do not invent missing story content.
- For approved changes to story, mechanics, puzzle paths, progression contracts, or ending requirements, update the relevant bible sections and its change log in the same PR. Never add story requirements only through code. Implementation-only refactors that leave game design unchanged do not require rewriting the bible.
- Keep content IDs stable once used in persisted saves. Distinguish preserved evidence from live content versions; document and test any approved save migration.
- Report implementation/canon differences; do not silently resolve them or rewrite canon to justify existing code.

Without explicit story approval, do not introduce hidden morality scoring, trust meters or credibility formulas, alternative endings, new mandatory mini-game gates, new major characters, changes to ASCENSION / DAWN / LANTERN / BLACKOUT / Observer requirements, or calendar-specific launch dates. Negotiation's established use of evidence and credibility does not authorize numerical scoring or thresholds.

## Implementation and validation

- Preserve the iOS 18 deployment target. Protect iOS 26 APIs with availability checks and retain iOS 18-compatible fallbacks.
- Preserve the black, purple, pink, and white Banana Corp theme and immersive fictional OS, hardware-safe controls, and supported system gestures.
- Avoid modifying mini-games unless explicitly requested. A story proposal is not authorization to change their mechanics or make them mandatory gates.
- Keep OS navigation and presentation ownership centralized in AppState; consult the current models rather than creating competing state sources.
- The Xcode project is `Banana Corp/Banana Corp.xcodeproj`, scheme `Banana Corp`. Use Xcode 26+ for the existing Liquid Glass symbols; validate supported iOS 18 and iOS 26 runtimes when available.
- Run applicable checks: `bash scripts/check-restricted-access.sh`, `bash scripts/check-act-two.sh`, `bash scripts/check-first-anomaly.sh`, `bash scripts/check-act-one.sh`, `bash scripts/check-evidence-vault.sh`, `bash scripts/check-story-content.sh`, `bash scripts/check-story-progression.sh`, `bash scripts/check-os-navigation.sh`, `bash scripts/check-home-layout.sh`, and `bash scripts/check-os-presentation.sh` on a Swift-equipped machine; run `git diff --check` and check documentation links for documentation changes.
- Author story content through the shared local catalogue described in [docs/story-content-schema.md](docs/story-content-schema.md), not independent view-local copy. Keep published version IDs and asset identities immutable, retain original versions and preserve saved evidence bytes. Neutral test fixtures must stay outside the production content bundle.
- Reuse the canonical Evidence route and existing preserved-evidence ledger; do not create another archive store or overwrite saved snapshots to match live content. Follow [docs/evidence-vault.md](docs/evidence-vault.md) for preservation eligibility, truthful comparison and explicitly authored evidence facts.
- Foundation checks can run on Linux. They do not replace Apple-SDK typechecking or simulator/device validation. Report actual results and unavailable tools accurately.
- For Xcode integration work, run `python3 scripts/check-ios-project.py`. On a Mac with Xcode 26+, use the shared `Banana Corp` scheme and `bash scripts/validate-ios-integration.sh SIMULATOR_UDID` for Debug/Release builds, actual bundle checks and XCTest/UI smoke tests. Use a dedicated test simulator, retain the logs/xcresult evidence, and follow [IOS_INTEGRATION_VALIDATION.md](docs/IOS_INTEGRATION_VALIDATION.md) for iOS 18/26 and physical-device validation. Do not call static project or syntax checks an iPhone build.

Existing build details and manual UI validation remain in [docs/banana-os-validation.md](docs/banana-os-validation.md), [docs/home-screen-validation.md](docs/home-screen-validation.md), [docs/ui-modernization-validation.md](docs/ui-modernization-validation.md), [docs/motion-interaction-validation.md](docs/motion-interaction-validation.md), and [docs/story-visual-system.md](docs/story-visual-system.md). These are technical records, subordinate to the bible for story design.

Pass 5 opening content and its approved prerequisites are documented in [docs/act-one-content.md](docs/act-one-content.md). Preserve the ECHO email’s immutable original; its read marks readiness only. Do not deliver the unknown warning, replace/remove sources, enable Assistant denial or configure Act 2 advancement as part of an opening-content refactor.

Pass 6 explicitly authorizes the initial removal/warning/denial and Act 2 handoff described in [docs/first-anomaly.md](docs/first-anomaly.md). Keep that removal at a return-to-inbox/Home boundary, distinguish read receipts from player evidence, validate saved proof before the challenge and preserve both investigation paths. Do not infer understanding from app appearance or repeat the consumed visual event. Later Act 2 scenes/act transitions require separate approval.

Pass 7 authorizes only the Act 2 content, source changes and explicit cross-app confirmation/handoff in [docs/act-two-content.md](docs/act-two-content.md). Keep transcript-only evidence honest, validate saved proof and knowledge-gated questions, and preserve the independent-corroboration route when no original was saved. Never advance Act 3 on content appearance, reveal later motives/Observer purpose, or implement the Banana Wall as a side effect of this pass.

Pass 8's [ACT3_PUZZLE_DESIGN.md](docs/ACT3_PUZZLE_DESIGN.md) distinguishes approved foundations from TBD puzzle/ending design. The user explicitly approved the cross-reference design on 2026-10-14; bible v1.8 and [banana-wall-implementation.md](docs/banana-wall-implementation.md) now govern its implementation. Keep the retired pending descriptor inert; do not add further puzzle answers or unlocks without approval. Never treat a development fixture as canon or a campaign bypass. Protected content must use registered resource IDs and the shared store's authorized queries; validate links both ways and retain legitimate saved evidence after live access loss.

Acts 1–2 journey QA is recorded in [ACTS_1_2_DEVICE_QA.md](docs/ACTS_1_2_DEVICE_QA.md). Run `bash scripts/check-acts-journey.sh` for model-only four-path/reopen checks. Native journey QA uses `bash scripts/validate-acts-journey.sh INSTALLED_IOS_RUNTIME_ID IPHONE_DEVICE_TYPE_ID` on Xcode 26+: it creates its own fresh test simulators and exercises normal controls without app launch flags, debug replay or direct save edits. The UI test skips when its runner-only path is absent; ordinary integration tests do not establish full journey coverage. Do not turn a Linux model result into a device QA pass, or invent story content to resolve a blocker.

Run `bash scripts/check-banana-wall.sh` for the approved puzzle: four natural preservation paths, exact normalization/retry, voluntary hints, atomic puzzle/event/access/milestone success, pending-save recovery, one-resource delivery and separate-process reward/evidence reload. Existing Act 1–2 definitions and snapshots must stay immutable. The native journey test now continues through normal clue review and puzzle solving; Apple execution remains a separate requirement.

Act 3 Part One is documented in [act-three-part-one.md](docs/act-three-part-one.md). Run `bash scripts/check-act-three-part-one.sh`; preserve immutable earlier records and the explicit scope → MIRROR → ECHO → influence read gates. The new research authorizes no autonomy/ASCENSION reveal, scientific mechanism, Assistant cooperation or Act 4 transition.

Act 3 Part Two is authorized in [act-three-part-two.md](docs/act-three-part-two.md). Run `bash scripts/check-act-three-part-two.sh`. Keep two-source autonomy and public/restricted synthesis explicit; ASCENSION purpose knowledge must never write `AscensionMilestone` or advance Act 4. Preserve TBD science/chronology and later character/Observer reveals.

Act 3 Part Three is authorized in [act-three-part-three.md](docs/act-three-part-three.md); [the complete inventory](docs/act-three-content-inventory.md) covers all three parts. Run `bash scripts/check-act-three-part-three.sh`. Keep Maya missing, references tied to actual saved facts, mandatory Observer knowledge separate from optional hidden clues/ending eligibility, and the Act 4 transition closed until Pass 8.

Pass 8 authorizes the explicit Act 3 → Act 4 entry contract in [ACTS_1_3_RELEASE_QA.md](docs/ACTS_1_3_RELEASE_QA.md), superseding the prior closed-handoff limitation. Run `bash scripts/check-acts-release.sh`. Keep optional proof/Observer clues/late questions independent and full takeover/countermeasure/Act 5 requirements reserved. Query caching must invalidate on saved-state and access-reference changes; it must never become a story authority.

Image planning uses [BANANA_CORP_ASSET_REGISTRY.md](BANANA_CORP_ASSET_REGISTRY.md) and [Assets/README.md](Assets/README.md). `Assets/Images/<prefix>/` is staging, not an app-bundle lookup path. Keep existing compiled assets intact until explicit integration work. Planned inventory/attached art conventions do not override bible identities, reveal order or TBD decisions; review ECHO-07 identity/avatar wording before production.

## Autonomous development mandate

The creator's [development directive](AUTONOMOUS_DEVELOPMENT_DIRECTIVE.md) authorizes routine engineering, coordinated agents, tests, focused branches/PRs and safe merges within `bryce496913/Banana-Corp`. Maintain [the roadmap](DEVELOPMENT_ROADMAP.md), [progress/handoff](AGENT_PROGRESS.md) and [QA plan](QA_TEST_PLAN.md). Preserve existing canon/TBD boundaries; delegation does not approve missing puzzle values, endings or identities. The written Synthetic Reality direction is approved; unavailable mood-board imagery must not be claimed as reviewed.

Do not access other repositories/ChatGPT projects or unrelated personal data. No paid operations, signing/distribution, external release or App Store submission without the necessary specific approval. Do not bypass required checks/protections or treat Linux/mock/syntax results as Apple execution. Merge only when the concrete change is validated and GitHub requirements permit it. Request playtesting only with an actual supported build/install route and the directive's readiness information.

Run `bash scripts/check-native-runners.sh` for portable runner command contracts. These isolated fake-toolchain checks do not constitute native builds or simulator gameplay; retain actual Apple validation as a separate requirement.

# Mandatory Agent Cleanup Policy

## Objective

Keep the local development environment clean, efficient, and storage-conscious, especially on macOS Apple Silicon.

All coding agents (Codex, Claude Code, and other automated developers) must follow this policy.

## 1. Cleanup After Every Task

After completing coding, building, debugging, or testing, perform a cleanup pass before providing the final task summary.

Remove temporary artifacts created during the task when they are no longer required, including:

- Temporary scripts and debugging files.
- Temporary logs and diagnostic output.
- Disposable test databases and test fixtures.
- Temporary screenshots and generated test media not required for review.
- Temporary downloaded files and extracted archives.
- Disposable simulator or testing artifacts.
- Task-specific temporary build directories.
- Python `__pycache__` directories and `.pytest_cache` when safe.
- Other clearly identified disposable files generated during the task.

Only remove files when their purpose, ownership, and disposability are established.

## 2. Protect Important Files

NEVER automatically delete:

- Source code or application assets.
- `.env` files, credentials, certificates, or provisioning profiles.
- Dependencies or package directories required for development.
- Package lockfiles.
- Production or development databases containing persistent information.
- User-generated files.
- Git repositories, branches, commits, or stashes.
- Test results required to diagnose unresolved failures.
- Shared caches, environments, or build outputs potentially being used by another process or agent.

Never use broad, unverified recursive deletion commands.

Do not delete files merely because Git ignores them.

## 3. macOS and Xcode Cleanup

For Swift, SwiftUI, or Xcode projects:

- Identify task-specific DerivedData directories.
- Remove only disposable build outputs created for the task that are no longer in use.
- Preserve active Xcode simulator environments.
- Do not delete simulators, runtimes, signing assets, or archives automatically.
- Do not erase global Xcode caches.
- Avoid leaving unnecessary `.xcresult` bundles or test recordings.
- Preserve diagnostic artifacts associated with unresolved issues.

For Node.js, Python, and web projects:

- Remove disposable test outputs and temporary build artifacts.
- Preserve active virtual environments and installed dependencies.
- Do not automatically delete `node_modules`, `.venv`, or global package caches.
- Preserve generated files required by the development workflow.

## 4. Process and Environment Safety

Before cleanup:

1. Identify files created during the current task.
2. Confirm they are no longer needed.
3. Check that another agent, build, test, or application process is not using them.
4. Prefer targeted deletion rather than broad directory cleanup.
5. Avoid deleting files outside the current project or explicitly designated temporary workspace.

When file ownership or safety is uncertain, leave the file intact and report it.

## 5. Storage Efficiency

During development:

- Prefer reusing existing build and dependency environments.
- Store temporary artifacts in clearly identified task-specific directories.
- Avoid creating unnecessary duplicate project copies.
- Avoid repeatedly downloading the same dependencies.
- Avoid accumulating redundant screenshots, logs, archives, or build results.
- Use appropriate project ignore rules to prevent temporary artifacts from entering version control.

## 6. Final Cleanup Report

At the end of every task, include a short cleanup summary:

**Cleanup Report**

- Removed: temporary files and directories cleaned up.
- Preserved: important build artifacts, test evidence, or environments.
- Disk space recovered: measured amount, if available.
- Remaining cleanup opportunities: anything requiring user approval.

If no cleanup was necessary, report "No disposable artifacts found."

## 7. Mandatory Completion Requirement

A task is not considered complete until:

- Implementation is finished.
- Required tests have been performed.
- Temporary task artifacts have been reviewed.
- Safe cleanup has been performed.
- A cleanup summary has been provided.

Cleanup must never compromise project integrity, reproducibility, active development processes, or the ability to investigate unresolved defects.


## Daily-driver iPhone QA sessions

The creator's daily-driver iPhone must be tested in roughly ten-minute blocks, not continuous thirty-minute-plus campaigns. Pause at a natural saved/Home boundary, terminate the QA app, finish the block's verification and check in with the creator. Do not start another block or perform further phone interaction until the creator explicitly says to continue; the phone may be disconnected for work. Build preparation can happen separately before a phone-use window.

Use a separate QA identity to preserve the original game/save. A successful partial block is not a full campaign pass. Resume the same verified QA save through normal controls, without app launch bypasses or direct save edits, and require the complete ordered journey plus final save/evidence checks before claiming full playthrough acceptance. Stop the owned test session promptly if the creator needs the phone sooner.
