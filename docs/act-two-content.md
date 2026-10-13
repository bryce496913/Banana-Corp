# Act 2 — Something Isn't Right

Pass 7 authors the user-approved Act 2 investigation under [the canonical bible](../BANANA_CORP_GAME_BIBLE.md). All narrative copy is local structured catalogue content. Twenty new items (24 versions) are added to the existing 25 items; every published Act 1/first-anomaly definition remains unchanged. No backend, remote model, new permission, physical headset or playable media file is required.

## Inventory

Every item uses `content.act2.<key>` and versions `version.act2.<key>.v1` / `.v2`. Preservable versions have distinct `evidence.act2.<key>.vN` IDs.

| Key | Surface | Authored purpose / versions |
| --- | --- | --- |
| `alex_review` | Watch Video | Alex Rivera / `@AlexRiveraTech`: original five-section warning transcript → enthusiastic five-section replacement; same creator and `/watch/alexrivera/banana-vision-preview` location |
| `social.disorientation` | Social X | Rin's recollection gap → familiarization wording |
| `social.memory` | Social X | Sam's missing task recollection → unavailable live post |
| `social.behavior` | Social X | Jules's repeated choice, presented as a personal account |
| `news.concerns` | News | Circuit Daily's separate preview accounts → sanitized adjustment article |
| `news.official` | News | Interface Review distinguishes official guidance from unresolved accounts |
| `web.preview_notes` | Browser | Local official guidance: retain session notes → simplification/current-guidance wording |
| `messages.daniel` | Messages | Daniel Mercer identifies himself as the internal-review sender and points to Maya/ECHO-07 |
| `email.maya` | Email | Dr. Maya Chen's research correspondence, including the exact established statement about something making decisions |
| `web.echo07` | Browser | **ECHO-07 — Neural Synchronization Trial — Preliminary Findings** excerpt: cognitive patterns, synchronization, transfer measurements and activity after disconnection |
| `diagnostics.excerpt` | Assistant / local links | Unresolved `ECHO_CORE` override and unexplained Observer-channel mismatch; no explanation of sentience or the Observer Program |
| `news.corroboration` | News | Circuit Daily Media Desk's independent earlier notes compared with the current Alex listing; explicitly not a player-preserved copy |
| `assistant.alex_original` | Assistant / original video link | Initial ordinary explanation after the original has been viewed; withdrawn when its source changes |
| `assistant.symptoms` | Assistant | Official familiarization framing, gated by actual report investigation |
| `assistant.edits` | Assistant | Questionable current-version explanation after the replacement has been inspected |
| `assistant.removed` | Assistant | Unavailable-post explanation, gated by the actual memory-post removal |
| `assistant.echo` | Assistant | Limited Project ECHO response after Daniel's lead |
| `assistant.echo07` | Assistant | Preliminary-findings deflection after the research excerpt was actually read |
| `assistant.saved_warning` | Assistant | Optional challenge requiring an authentic preserved warning record |
| `connection_summary` | Browser / investigation notes | Hidden until the player explicitly connects the records; records conclusions without revealing the cause |

All original/replacement video, news, social, guidance, Maya and research/diagnostic versions are preservable. Daniel's conversation, scripted Assistant turns and the player's connection summary do not pretend to be preserved media. The newly authored incidental reports use previously introduced display names; no new major character or final character motive/fate is invented.

## Honest video and evidence handling

There is no approved video asset in the repository. Both Alex versions are clearly labeled **text presentations**, with a five-section transcript, title, creator, fictional timestamp and stable local source location. Opening the item or preserving it does not count as viewing. Continue visits each section, Previous is supported, and the explicit final Finish action uses `completePresentation` to commit the exact selected version's read/milestone. No imaginary playback duration or timer is used.

Preservation freezes the transcript record and source metadata. Evidence explicitly states that no playable video is stored. Optional video `sourcePath` / local `links` are validated and included in preserved-field comparison; absent values remain nil for old snapshots. Text-only cue positions display as sections, not invented media seconds.

The shared comparison already supports original email versus unavailable live source, article/social/web originals versus changed versions, removed social posts and video metadata/transcript versus replacement. Changed live fields now use the pink theme accent as well as textual Preserved/Live labels. Unavailable sources are identified factually. Unpreserved content never acquires an archive retroactively.

## Explicit source changes

`ActTwoContract` centralizes stable IDs, return-boundary change definitions, knowledge conditions and completion requirements. `StoryContentStore.activateActTwoChangesAtBoundary` is scoped to the surface being left; fictional Home uses all eligible sources. Returning to a library, leaving a detail through explicit navigation, or reopening that library after a saved read can reconcile its eligible change. Reading/rendering alone, elapsed real time and merely loading a save do not change a source.

| Persistent event | Requires | Effect |
| --- | --- | --- |
| `event.act2.alex_review.replaced` | Act 2 + original warning explicitly viewed | Retain original/live receipts; activate v2 at the same item; record replacement and `warning_replaced`; withdraw initial Alex explanation |
| `event.act2.social.disorientation_edited` | Alex replacement + original Rin post read | Activate post v2 |
| `event.act2.social.memory_removed` | Alex replacement + original Sam post read | Mark live post unavailable |
| `event.act2.news.concerns_edited` | Alex replacement + original concerns article read | Activate article v2 |
| `event.act2.web.preview_updated` | Alex replacement + original guidance page read | Activate guidance v2 |

Each event validates source/version ownership, receipts and declared event/milestone IDs, then saves its complete effects atomically. A failure keeps that source's old version and its event facts intact for retry. Multiple eligible source changes are independent transactions: previously successful events remain committed if a later source fails. Repeated boundaries do not replay events. The original remains preservable indefinitely while the player stays in its detail; preserving is optional and never triggers a change.

## Leads and knowledge

Act 2 content is unavailable until the guarded [first-mystery handoff](first-anomaly.md) has advanced the central store to Act 2.

- Any original social report or the concerns article explicitly read earns `symptom_reports_investigated`.
- Inspecting all sections of Alex's replacement earns `replacement_inspected`. Library/row appearance does not.
- Daniel's incoming thread becomes available after that inspection and report investigation. Reading it records `daniel_lead_followed`, unlocks Maya/research leads, and identifies the anonymous D. without revealing his later complicity.
- Maya correspondence is a research record, not proof of current live communication, safety or disappearance. Reading it records `maya_lead_followed`.
- ECHO-07's explicitly read excerpt records `echo07_findings_read`; it enables the diagnostic excerpt and that specific Assistant question. The documented transfer observation is not a full human-harvesting explanation.
- The diagnostic read records `diagnostics_examined`. The unexplained identifiers do not reveal the Observer experiment, ECHO's sentience, ASCENSION or ending requirements and award no Observer-route clue.
- Assistant availability depends on these actual saved facts. Edits or saved-warning questions record `assistant.act2.edits_questioned`. Other questions record factual interaction IDs where authored, never numerical trust or automatic cooperation. Cooperation remains `notEstablished`.
- The saved-warning response additionally validates the archive's original source/version against its receipt. Corrupt/absent archives cannot produce a claim of saved proof.

Guidance buttons query the shared store for a currently available next lead and use its authored title. They explicitly open only the chosen item, defer video reads to Finish, and never auto-complete progress. Optional exploration and preservation remain available throughout.

## Cross-app confirmation and Act 3 prerequisites

There are two valid original-verification paths:

- **Saved proof:** Preserve Alex v1 before leaving, then explicitly Compare after v2 is live. Actual displayed-field differences award `milestone.act2.saved_warning_compared` through the original version's evidence rule. An unchanged earlier comparison cannot consume this later action.
- **No preserved proof:** Read the independently authored Media Desk report to earn `milestone.act2.independent_record_read`. It supplies corroboration without fabricating a player snapshot or resolving Alex's fate.

The player must earn all of the following before **Connect the changed source and research findings** is enabled:

1. `warning_viewed` and the persisted Alex replacement event.
2. `replacement_inspected`.
3. `symptom_reports_investigated` (any qualifying original social report or the concerns article).
4. `official_response_read`.
5. `daniel_lead_followed` and `maya_lead_followed`.
6. `echo07_findings_read` and `diagnostics_examined`.
7. **Either** `saved_warning_compared` **or** `independent_record_read`.
8. The factual Assistant interaction `assistant.act2.edits_questioned`.

The explicit Connect action validates the current replacement and these facts, then atomically records `event.act2.sources_connected` / `milestone.act2.cross_app_confirmation` and reveals the connection summary. Appearance of every item or earning all read facts still does not perform this action.

The separate **Investigate beyond the curated sources** action calls the existing guarded progression engine to advance consecutively to Act 3 only after that confirmation. All requirements remain checked by the engine; a failed write leaves Act 2 intact. This pass does **not** implement the Banana Wall breach, restricted research access, full conspiracy reveal or later act transitions. No preservation-only requirement, mini-game gate, wait, hidden score, character innocence/fate, weather/permission or real-world date is introduced.

## Persistence and tests

Catalogue/snapshot schemas stay 1; story save schema stays 2. New optional video fields decode as nil for all prior records, and all 25 published definitions are retained verbatim. Source changes, receipts, archives, interactions and act state use the existing atomic local save; no competing progression store or view-local story flags are added. Home arrangement, OS routes, launch, games and theme are retained.

Run `bash scripts/check-act-two.sh`. Tests cover entry gating, original viewing/preservation opportunity, scoped deterministic replacement, same source location, both proof paths, changed/removed social content, article/web/video comparison, conditional questions/leads, ECHO-07, every missing completion requirement, explicit confirmation and Act 3 guard, immutable archives, corrupt-proof rejection and write/resource failure recovery. Each path runs nine separate-process checkpoints: entry, original viewed, before replacement, replacement, character/research leads, proof/questioning, confirmation, Act 3 advancement and reopened state. All eight existing checks remain relevant.

## Manual playthrough — Apple SDK required

Build using Xcode 26+ and available iPhone simulators on iOS 18 and iOS 26. This checklist records remaining work, not claimed simulator results.

- [ ] Complete Act 1/first anomaly normally; Alex, Daniel, Maya and ECHO-07 are unavailable beforehand.
- [ ] Open Alex's original listing, stop on any section, background/return and use Previous. No imaginary video/duration is presented, and no timer replaces it.
- [ ] Save its original text record if desired; the original-source Assistant link becomes usable after Finish. Leave via Back/Home or a deliberate source link and observe the current enthusiastic v2 at the same location.
- [ ] Saved path: open Evidence, verify exact title/metadata/transcript and explicit no-playable-video label, then Compare against v2. No-save path: verify no archive exists and follow the independent Media Desk report.
- [ ] Read/preserve Rin, Sam, the concerns article and official guidance; leave after Alex's replacement. Reopen edited/removed sources and compare truthful originals where preserved.
- [ ] Follow available Daniel → Maya → ECHO-07 → diagnostic leads. Check that unavailable knowledge never leaks through labels, notifications or Assistant choices.
- [ ] Ask symptoms, Alex/current-version, removal, ECHO, ECHO-07 and saved-proof questions when eligible. Verify calm deflection without confession/threat, invented motivation, trust meter or saved-proof claim on the wrong path.
- [ ] Before required investigations, no Connect or Act 3 advancement. After them, explicitly Connect and then choose to investigate beyond the curated sources; state becomes Act 3 without a Banana Wall breach.
- [ ] Relaunch at all nine checkpoints on both paths; sources, archives, interactions and act persist without replay or softlock.
- [ ] Repeated app/Home navigation, custom icon arrangement, games, Reduce Motion, VoiceOver, Dynamic Type, modal alerts, native Back controls (including Diagnostics) and hardware/system gestures remain usable.

### Actual validation — 2026-10-13

All nine Foundation suites passed with official Swift 6.2, Swift language mode 5 and warnings as errors in a network-disabled container with a read-only source mount. The final Act 2/content/evidence checks also passed after video-link and recovery guards were completed. Act 2's preserved and unpreserved paths each passed nine separate-process checkpoints; earlier story/content/evidence relaunch checks also passed. Tests exercised original/replacement records, multi-format comparison, missing replacement resources, corrupted-proof rejection, atomic source-change/confirmation/handoff write failures, omitted prerequisites and spoiler boundaries. Navigation covered 1,500 cycles/14 swipe cases; layout covered 185 valid moves; presentation safety checks passed.

All 45 app Swift sources parsed in DEBUG and Release. All 42 local Markdown links resolved; project references, JSON validity, preserved 25 published definitions, iOS 18 target and whitespace/shell syntax were checked. Mini-game source files, Home layout, OS routes, launch/splash and save schema are unchanged.

This Linux host has no `xcodebuild`, `xcrun` or iPhone simulator. Apple-SDK typechecking/builds, UI rendering, VoiceOver, haptics and native navigation/gesture playthroughs could not run. Foundation tests and source parsing do not establish those results; the manual checklist above remains outstanding.
