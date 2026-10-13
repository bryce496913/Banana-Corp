# Local story catalogue and delivery

This implements Pass 3 under [the canonical bible](../BANANA_CORP_GAME_BIBLE.md). The production resource `Banana Corp/Banana Corp/StoryContent.json` is intentionally empty. All eleven story-app placeholder views remain intact, including their unavailable controls. Their activation/registration/calibration text does not establish new story gates. There is no full Act 1 rollout or Act 2 replacement scene.

## Ownership and files

AppState owns StoryContentStore and the existing StoryProgressionStore. ContentStore holds an immutable validated catalogue; all mutable delivery facts live in the progression save. Email/Messages badges query available unread versions from this store, with no second saved counter. Production has zero entries, so badges stay zero until approved content is authored. Catalogue diagnostics remain observable through the store even if a resource is absent; placeholders continue rendering.

The app source directory contains StoryContentModels.swift (typed formats), StoryContentRules.swift (tagged Codable conditions/effects), StoryContentCatalogue.swift (offline loader/validator) and StoryContentStore.swift (queries, explicit reads/preservation and passive notification queue). StoryState/StoryProgressionStore retain ownership of persistent delivery facts and atomic commits. No service, dependency, notification permission, timer or background delivery pump is introduced.

## Catalogue schema 1

The UTF-8 JSON envelope has `schemaVersion: 1`, `facts` and `items`. Optional `assets` declares bundled media. The valid empty production envelope is:

```json
{"schemaVersion": 1, "facts": {}, "items": []}
```

`facts` maps supported external condition names to arrays of approved stable IDs: puzzleSolved, accessGranted, milestoneCompleted, assistantFact, observerClueFound, routePrerequisite and eventCompleted. These declarations let validation identify dangling/mistyped references; they do not grant any fact or approve new story decisions. Content/version, preserved-evidence and generated read-event references resolve from catalogue definitions and must not be redeclared as external facts.

| Item field | Contract |
| --- | --- |
| id | Stable content identity, independent of titles, labels and versions |
| appSurface | email, news, messages, social, video, web, photos, assistant, diagnostics or notifications; these are surfaces, not new OS routes |
| actAvailable | Integer 1–5 using the existing five acts; a lower bound, never automatic advancement |
| order | Nonnegative authored order; ties sort by content ID, independently of JSON array order |
| visibility | Optional listed (default) or hiddenUntilRevealed |
| unlockConditions | Optional condition array combined with AND; absent/empty means no extra condition |
| initialVersionID | Explicit version-1 identity; never inferred from the latest version number |
| versions | Nonempty immutable source records, retaining unique contiguous numbers 1…N and globally unique version IDs |

Each version requires `id`, `version`, `title` and `payload`. Optional fields are subtitle, author, source, timestampLabel, narrativeTimestamp, preservedEvidenceID, effectsOnRead, optional evidenceRules and optional narrativeMetadata. A narrativeTimestamp is the existing relative `{day, hour, minute}` value, not a calendar launch date. A preservedEvidenceID authorizes preservation of that version and is distinct from content and version IDs; absence means not preservable. Pass 4 evidenceRules may explicitly associate securedObserverClueID, preservationMilestoneID and comparisonMilestoneID from declared facts; rules are rejected for non-preservable versions or self-generated availability gates. Narrative metadata remains frozen internal context rather than player-facing copy.

IDs use the existing lower-case hierarchical StoryID format and 128-byte bound. Derived `event.read.<versionID>`, `event.preserve.<evidenceID>`, `event.compare.<evidenceID>`, `event.diff.<evidenceID>`, `notification.<versionID>` and `replacement.<sourceVersionID>.e<effectIndex>` identities must also fit. After publication, retain IDs and original definitions. Read-effect order is part of a published version: append a new version instead of rearranging effects under an already saved ID.

## Structured payloads

Every payload is a tagged object `{"type": "<surface>", "data": {...}}` matching its item's surface. Optional fields may be omitted. Text blocks have kind heading/paragraph/quote plus text. Content links have label and contentID. All links refer to catalogue items; no browser/network fetch is implied.

| Type | Data fields |
| --- | --- |
| email | sender, recipients, blocks; optional attachment content links |
| news | publication, blocks; optional relatedContent links |
| messages | participants and ordered messages; each message has stable id, sender, text, incoming/outgoing direction and optional timestampLabel |
| social | handle and text; optional mediaAssetIDs and structured replies using message records |
| video | Optional creator, durationSeconds, mediaAssetID, thumbnailAssetID and timed transcript cues (startSeconds/text); no simulated player or stream |
| web | Fictional local path beginning `/`, blocks and optional content links |
| photos | Optional assetID/caption and metadata dictionary; metadata-only records are supported |
| assistant | Ordered turns with stable id, user/assistant/system role and text |
| diagnostics | Ordered entries with stable id, info/warning/error level, key/value and optional timestampLabel |
| notifications | message and optional targetContentID; this is fictional content, not a real iOS notification request |

`assets` entries have stable id and a simple local fileName. Media references must resolve to declared, present bundled files. URLs, traversal paths and network loading are rejected by the loader. Once published, media identities/files must also remain immutable; revised media needs a new asset identity. A preserved photo/video snapshot records its original version and asset references rather than fetching or copying remote media.

## Conditions and effects

Conditions use `type` with exactly the applicable value field:

```json
{"type":"contentRead","id":"content.fixture.email"}
```

Supported ID conditions are contentDiscovered, contentRead, evidencePreserved, puzzleSolved, accessGranted, milestoneCompleted, assistantFact, observerClueFound, routePrerequisite and eventCompleted. Content conditions can refer to an item (ever discovered/read) or a specific version. actReached uses `act`; assistantCooperation uses `cooperation` (notEstablished/cooperating/separated). all/any use a nonempty `conditions` array and the existing deterministic evaluator, with a 32-level nesting limit. There is no executable expression, clock-driven rule, trust score or morality formula.

Effects use a closed set of tags:

| type | Fields / result |
| --- | --- |
| revealContent | id: content becomes revealed without pretending the player read/discovered it |
| markMilestone | id: a declared milestone fact |
| unlockRoute | route: an existing PhoneAppRoute raw value, including the persisted `messager` spelling |
| queueNotification | id: notification content is queued at its explicit current version and revealed; no automatic read/effect execution |
| changeVersion | contentID and versionID: version must belong to that item; original records remain intact |
| makeUnavailable | id: content is removed from live delivery, while saved versions/evidence remain intact; reveal does not implicitly restore removed content |
| recordClue | id: a declared Observer clue fact in the existing progression authority; no hidden ending is automatically unlocked |

Unknown tags and extra rule fields are rejected. Validation detects duplicate IDs, invalid/borrowed/noncontiguous versions, unsupported schemas, missing content/asset/fact references, incorrect surfaces, malformed structured payloads, invalid unlock rules and cycles in reveal/notification/version-delivery effects. It conservatively rejects references to an item's own discovery/read/evidence/read event and its read-produced facts as availability gates; split such content into separately authored items. These checks do not substitute for story/reveal review.

## Query and engagement contracts

`availableItems(for:state:)` returns only available unread/read live entries for a surface, in stable order. `unreadCount` derives from their per-version read IDs. `currentVersion` and `originalVersion` inspect explicit definitions; player-facing lists must use availability filtering rather than showing locked/hidden metadata. `availability` distinguishes availableUnread, read, locked, hidden, removed, replaced (with live version ID) and unresolved. `preservedItems` returns separately archived snapshots with preserved status, so a live replacement/removal does not erase the player's copy.

Queries do not mutate discovery, read facts, events or storage. A future detail/conversation/player UI must explicitly call `read(contentID, versionID:)` on meaningful engagement, never list rendering/onAppear alone. The supplied version must match the opened live version; a stale selection cannot read a replacement automatically. It records both item and version discovery/read facts and applies validated read effects in one progression transaction with a stable read-event ID. Effects run once per version, including across relaunches. Repeating a completed read is unchanged even if its earlier effects removed/replaced the item. No effect calls another read or runs another item's effects.

`preserve` is an independent meaningful action; it does not mark content read or fire read effects. It copies the immutable typed version to the existing preserved-evidence record with a snapshot schema marker. Repeating preservation returns the original record instead of regenerating a snapshot from edited definitions. Archived snapshots do not execute their stored read effects. Pass 4 adds an Evidence utility and shared controls; see [the Vault contract](evidence-vault.md) for explicit preservation/comparison facts and truthful differences.

`pendingNotifications` filters the saved queue by current availability/version and stable enqueue sequence. Future presentation calls `acknowledgeNotification` explicitly after delivering it; acknowledgement is distinct from reading and cannot requeue a completed delivery. Locked, removed or superseded queue entries remain saved but do not display. Actual notification/card UI is future work.

## Save compatibility and immutable evidence

Story save schema 2 adds revealed/unavailable IDs, explicit active-version IDs, immutable used-version receipts and notification records. The registered v1→v2 migration adds empty delivery state and preserves all previous discoveries, reads, evidence, story facts, flags, app locks, time and act. No production v0 migration exists. Content catalogue schema 1, snapshot schema 1 and story save schema 2 are distinct versions.

Receipts are cached once per validated catalogue. Saved receipts compare typed snapshot values if encoder formatting differs across SDKs, retaining original bytes. If an already used version definition changes under the same ID, queries report unresolved/definitionChanged rather than silently adopting it. Missing saved references and unsupported old evidence snapshot formats produce diagnostics while keeping the save/opaque evidence bytes intact. Authors must restore missing published definitions or supply an approved migration; never refresh a preserved snapshot to match new copy.

The content layer uses the existing atomic story transaction: effects, notification queue, receipts, read IDs and completion ID save together before becoming observable. Validation/save failure commits none. It does not create another persistence key or change home customization. Resetting the existing story save resets delivery facts and archives its prior bytes through the existing explicit reset contract.

## Fixtures and validation

[The development fixture catalogue](../Tests/Fixtures/story-content-fixtures.json) covers all ten payload formats with neutral development labels, synthetic facts and an alternate article version. It is not an ARG scene and is not referenced in the app's Resources build phase. [The production catalogue](<../Banana Corp/Banana Corp/StoryContent.json>) is the only content resource bundled by this pass. Neither adds characters, real launch dates, canonical puzzle answers or a story chapter.

Run `bash scripts/check-story-content.sh`, then the existing progression, navigation, home-layout and presentation checks. The content checks compile actual production code, validate malformed catalogues, test availability and deterministic ordering, verify query purity/read effects/event idempotency, version/evidence preservation, queued notification acknowledgement, schema migration and atomic failures. Separate-process write/read tests verify saved delivery after relaunch. Tests run offline; no Apple-SDK/runtime claim follows from Foundation compilation.

Actual results in this workspace:

- Content and progression suites passed using official Swift 6.2, Swift 5 language mode with warnings as errors, read-only repository access and container networking disabled. Both suites' separate-process persistence/relaunch checks passed. Content tests include local Bundle loading and preservation of original snapshot bytes when only encoder formatting changes.
- Existing navigation (1,400 app cycles and 14 swipe cases), home layout/persistence (160 valid moves), and visual presentation checks passed. All 42 app sources passed DEBUG syntax parsing.
- Static checks verified all 42 source references, unique project IDs, iOS 18 deployment target, production resource membership, and fixture exclusion from the target. All app/placeholder/game views, launch, routes, home layout, navigation and status bar are unchanged. All 21 local Markdown links resolve; script syntax and whitespace checks passed with the bible's existing Markdown hard-break whitespace allowed.
- `xcodebuild` and `xcrun` are unavailable. No Apple-SDK typecheck, simulator launch, native resource-copy runtime, badge rendering or SwiftUI integration result is claimed. Those require Xcode 26+ on supported iOS 18/iOS 26 simulators.
