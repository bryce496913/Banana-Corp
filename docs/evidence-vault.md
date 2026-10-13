# Evidence preservation and Vault

Pass 4 implements the Evidence utility and player controls under [the canonical bible](../BANANA_CORP_GAME_BIBLE.md). The route and title are consistently `evidence` / **Evidence**. It is a neutral utility available from the start; no intro, mandatory puzzle, story chapter, character or new ending condition is added. Production story JSON remains empty. Eligible approved content will appear through the existing catalogue; test data never enters the player bundle.

## Reused state and immutable record

There was already a persistent preservation API and ledger from Passes 2–3, but no player-facing archive, preservation control or comparison screen. This pass extends that authority rather than creating an independent Files app/store.

The existing immutable PreservedEvidenceRecord stores unique ID, original content ID, exact source version ID, the player's preservation Date and snapshot bytes. Its typed StoryContentSnapshot contains source surface and the complete immutable StoryContentVersion: version number/title/subtitle, author/source, original timestampLabel and relative narrativeTimestamp, structured payload, optional narrativeMetadata and evidenceRules. This composition persists all original metadata with the snapshot instead of duplicating mutable fields or retaining only a live pointer.

Original fictional timestamps and the player's real preservation time are separate fields and labels. Media entries preserve versioned metadata, transcript/caption and immutable bundled asset references; this is not a capture of external streams or the real photo library. Existing evidence bytes are never regenerated from the current catalogue. No new file permission, backend or persistence key is used. Save schema 2 and snapshot schema 1 remain readable; new version metadata is optional and the record's opaque snapshot bytes retain it across older envelope decoding.

The core ledger now rejects two IDs for the same content/version pair. The content API returns unchanged for an already valid saved copy, regardless of a later replacement/removal or a new preservation timestamp. Conflicting, damaged or inconsistent records remain intact and return a typed error; repeated saving does not repair them by silently substituting current data.

## Eligibility, controls and readers

PreserveEvidenceButton is shared by source lists and details, with an archive icon, readable Preserve Evidence label, saved confirmation, VoiceOver hint and one confirmation haptic for a newly committed save. Catalogue versions without preservedEvidenceID do not receive a save control. Hidden/locked/removed/stale versions cannot be preserved retroactively; the list offers saving before a read effect changes a source. Saving does not mark content read or run read effects.

StorySurfaceContent wraps Email, News, Social X, Browser, Video and Photos inside their existing PhoneShellView. When that surface has no catalogue entries, its original placeholder hierarchy/text/unavailable controls render unchanged. When authored entries exist, a shared themed list/detail reader renders only available versions. Explicit row selection records meaningful engagement; list rendering and detail appearance do not. The detail retains the exact engaged receipt when read effects change the live version, labels it as no longer live, and prevents saving it after it becomes ineligible. This does not grant access to past versions without a preserved record.

Preservation UI and source readers are shared rather than independently authored in six app files. Existing home/grid/dock layout and game interfaces are not redesigned. Messages/Assistant content rendering remains future app work; their payloads are already supported by snapshot inspection/comparison.

## Vault and nested navigation

EvidenceVaultView lists saved records by preservation time, with stable ID tie ordering, title, source-app symbol/name and date. Empty state explains eligible preservation. Records whose snapshots cannot be decoded remain in the list with an unavailable detail, rather than disappearing. A story-save recovery error is displayed separately from the empty state, with an explicit retry that does not reset progress.

EvidenceDetailView presents the preserved version, original source/time fields, preservation time and an explicit saved-copy label. Compare with live source opens EvidenceComparisonView within the app's existing NavigationStack. Custom accessible Back controls return through that nested stack. PhoneShellView retains the fictional status bar, supported hidden real status bar, black safe-area background and Home control. Opening Evidence itself uses the existing vertical OS presentation.

Appending PhoneAppRoute.evidence lets existing HomeScreenLayout normalization retain the user's old grid/dock order and append Evidence once to the grid. Dock limits and single placement remain unchanged; rearrangement remains persistent. Existing route raw values, including messager, stay stable.

## Truthful comparison and progression

Comparison requires an existing, validated preserved snapshot. It never reconstructs an earlier source from a current definition or substitutes live data for missing evidence. Original snapshots remain inspectable even if the source catalogue is absent.

EvidenceComparison normalizes displayed source fields deterministically and compares actual text/metadata. Changed, added or removed fields are shown with preserved/live values. Internal source/asset references can be compared without exposing code IDs as product copy. Structured message/turn/diagnostic positions are compared, and photo metadata keys sort consistently. Internal narrative IDs/rules are frozen but do not count as visible differences. No animation, corruption effect, accusation or supernatural interpretation is added.

The current source must pass existing act/visibility/access rules and receipt verification before its content can be shown. Explicit story removal, absent source, absent current version, hidden/locked access, unavailable catalogue and unverifiable definition are separate unavailable reasons. The UI reports what it knows without treating an ordinary loading error as an authored disappearance. A new version ID/number with identical displayed fields is described as matching content, not an edit.

`comparison(for:)` is read-only. `recordComparison` runs only on the explicit Compare action. For a comparable live source or an explicitly removed source it commits `event.compare.<evidenceID>` once. A visible live difference also commits `event.diff.<evidenceID>` once, enabling a later changed comparison after an earlier unchanged comparison. Missing, inaccessible or unverifiable live definitions do not emit successful-comparison facts. No comparison automatically reads another source, runs its read effects or advances an act.

Optional version evidenceRules contain only securedObserverClueID, preservationMilestoneID and comparisonMilestoneID. The loader requires a preservable version, declared facts of the correct kind and no self-generated unlock prerequisite. Preserve commits only that version's authored clue/milestone with its record in the same atomic transaction. Compare awards its frozen authored comparison milestone only when there are real displayed-field differences against accessible live data. Unrelated content, unchanged versions and unavailable sources earn no such milestone. There is no generic evidence/trust/morality score. Scene-specific eligibility/timing and actual clue/milestone names require story approval.

## Tests and Apple-platform checks

Run `bash scripts/check-evidence-vault.sh`, followed by the existing content, progression, navigation, home-layout and visual-state suites. Evidence checks use [neutral fixtures](../Tests/Fixtures/evidence-fixtures.json) outside the app target and cover Email, News, Social, Web, Video and Photos; original timestamps and metadata; authored facts; repeated saves; immutable bytes; version switches; removed/missing sources; unavailable catalogue; missing proof; invalid/corrupt snapshots; atomic failures; separate-process reopen; and upgrading a persisted fourteen-route home layout without duplication/reset.

Xcode 26+ with iOS 18 and iOS 26 simulators is required for actual SwiftUI/resource/gesture verification. Inject the development catalogue and an isolated in-memory story store into AppState for a temporary harness; do not bundle or activate fixtures in normal play. Verify:

1. Evidence appears once in the grid after loading an old customized home layout. Move it between grid/dock, relaunch, and check placement/limits.
2. On each eligible source, preserve before opening, open/read and preserve from detail when still eligible. Verify exact title/source/time, saved confirmation, accessible label and no duplicate on retry.
3. Return Home, open Evidence, inspect the original snapshot, use Back and Home repeatedly, then reopen after relaunch.
4. Use explicit fixture effects to switch News to v2/remove Social; compare the saved originals to available live data or the removed-source explanation. Confirm no save/compare action claims supernatural interference or creates proof without a record.
5. Try non-preservable, missing/unverified and corrupt cases; check retained evidence and recovery/error messaging. Verify no milestone for unrelated/unchanged content.
6. Test VoiceOver, Dynamic Type, Reduce Motion/Transparency, portrait/landscape, small/large devices and modal errors. Verify only fictional system chrome and working real iOS Home gesture. Reopen every old app and play mini-games to check unchanged controls.

Actual validation in this workspace:

- Evidence, content and progression checks passed using official Swift 6.2 in Swift 5 language mode with warnings as errors, read-only repository access and container networking disabled. All three suites' separate-process save/reopen checks passed.
- OS navigation checks passed for all fifteen routes: 1,500 cycles and 14 swipe-intent cases. Home layout/persistence checks passed, including 185 valid moves; the evidence suite separately verified a persisted fourteen-route customization gains Evidence once without reset. Existing presentation checks passed.
- All 45 app sources passed DEBUG syntax parsing. Static checks verified source references, unique project IDs, iOS 18 target, fifteen route destinations/icon definitions, fixture exclusion and unchanged empty production JSON. Mini-games, launch, home design/layout store, OS coordinator and status bar are unchanged. Source fallback texts/controls remain intact. All 26 local Markdown links resolve.
- Script syntax and whitespace checks passed with the bible's existing Markdown hard-break spaces preserved. `xcodebuild` and `xcrun` are unavailable; no Apple SDK, simulator, native resource/UI/gesture, haptic, VoiceOver or rendered-screen result is claimed. Syntax parsing does not typecheck SwiftUI against an Apple SDK.
