# Act 1 — The Perfect Product

Pass 5 supplies the first playable introduction authorized by the user. The [root bible](../BANANA_CORP_GAME_BIBLE.md) remains canonical. All narrative copy is in the bundled `StoryContent.json`, using the [shared content schema](story-content-schema.md); views do not maintain independent dialogue or story facts. No media file, network request, permission, backend or new dependency is required.

## Content inventory

Every entry has an immutable `version.act1.<key>.v1` and stable `content.act1.<key>` identity. Fictional source names and social display names are incidental voices, not new major characters.

| Key | Surface | Content |
| --- | --- | --- |
| `news.launch` | News | Tomorrow’s launch and practical mixed-reality expectations; Circuit Daily |
| `news.interface` | News | Adaptive-interface claims and internal preference review; Interface Review |
| `news.influence` | News | Banana Corp’s growing ecosystem influence; Market & Matter |
| `promo` | Watch Video | Official **A New Way to See Everything** presentation, five authored panels |
| `social.early`, `.commentary`, `.creator`, `.prediction`, `.ordinary` | Social X | Five distinct positive public reactions, names/handles and timestamps |
| `product` | Browser | Local `/banana-vision` page, features, launch information, preview caveat and working presentation/preview links |
| `vr_preview` | VR Experience / Browser | Optional local `/banana-vision/preview`, workspace/sharing/return teaser |
| `welcome` | Email / Home introduction | Corporate welcome, navigation guidance, 9:41 timestamp |
| `echo_review` | Email | **RE: Project ECHO — Internal Review**, anonymous internal correspondence signed **— D.** |
| `messages.welcome` | Messages | Two incoming service messages, conversation list, thread and unread state |
| `assistant.welcome`, `.vision`, `.launch`, `.navigation`, `.evidence`, `.choices` | AI Assistant | Welcome and five explicit question/answer choices |

The three articles, five social posts, promo, product page and ECHO email are preservable. Their exact snapshots use the existing Evidence utility. Neither ordinary saves nor the ECHO preservation award a story milestone or Observer clue. Photos, Phone, Settings and games remain accessible; no new content or mechanics are introduced there.

## Progression and engagement

The Home screen includes a catalogue-backed welcome and an Explore action to News in the existing header area. The launch/splash, clock, home arrangement and OS navigation remain intact.

- Explicitly opening any one article records `milestone.act1.news_context`. Opening News or rendering rows does not.
- Opening the promo displays an unfinished-video disclosure and the first panel. Continue visits each subsequent panel; Previous is supported. At the final panel, **Finish presentation** calls `StoryContentStore.completePresentation`, which validates the selected live video version and final-panel state, then records its read and `milestone.act1.promo_viewed` atomically. No fake duration or playback timer is used. Leaving before Finish earns nothing; panel position is transient and restarts when reopened.
- The ECHO email becomes available only after both milestones, in either order. Browser links can lead to the promo; optional apps and preservation are not gates.
- Explicitly opening the email records `milestone.act1.first_suspicious_material` once. This is readiness for Pass 6, **not completion of the whole act or permission to advance into Act 2**. The source remains live, immutable and preservable. No replacement, removal, unknown warning or Assistant denial occurs.
- Finishing the optional VR presentation records `event.read.version.act1.vr_preview.v1` and `milestone.act1.vr_preview_engaged`. Opening its full local Browser page also counts as engagement. Neither is a main-path requirement.
- Incoming Messages use catalogue conversations and per-version unread counts, including the existing home badge. Selecting a thread reads only that thread. This service thread explicitly has no reply interface; future dialogue must be authored in the catalogue.
- Assistant choices display the authored user/assistant turns and explicitly read the chosen response. There is no free-form input, live model, arbitrary request matching, hidden trust calculation or canned denial. Saved reads persist; the last displayed answer is transient. Later response changes must use validated progression conditions/versions, not view-local story flags.

Failure to save leaves reads, effects and readiness unchanged and shows an error. Corrupt or newer-schema saves remain preserved; readers do not substitute a new campaign. Conditional readers retain empty fallbacks for surfaces whose future catalogue has not been authored.

## Time and reveal boundaries

`NarrativeTimestamp(day: 1, hour: 9, minute: 41)` on the welcome items establishes the opening reference. Source timestamps use `StoryContentTime` with the saved relative story day; `launchDay` is narrative day 2, so “tomorrow” does not depend on installation date, device time zone or elapsed real days. There is no automatic day advancement. The fictional status bar continues to show current real-world time. No permanent 9:41 clock, specific launch date, research calendar or new player backstory is introduced; any later fixed-to-live clock sequence remains TBD.

The ECHO draft concerns an unresolved internal review and mismatched public wording, echoing `news.interface`. It does not name Daniel, disclose sentience, behavioral control, human energy harvesting, ASCENSION, Observer purpose, later characters or ending requirements. Act 2 transition rules remain empty. Pass 6 owns the first contradiction, warning and handoff.

## Validation

Run `bash scripts/check-act-one.sh` with Swift available. It loads the actual bundled catalogue offline, checks initial visibility and passive queries, both-order gates without optional apps, unfinished presentation rejection, final confirmation, source payloads and references, ECHO preservation/read distinction, deterministic Assistant content, conversation unread states, calendar independence, spoiler boundaries, no Act 2 advancement and separate-process save/reopen with immutable evidence and idempotent events. Existing content, evidence, progression, navigation, layout and presentation suites remain relevant.

On an Apple-SDK machine, build with Xcode 26+ and exercise iPhone simulators on iOS 18 and iOS 26: launch into Home, open all three articles, complete/cancel/reopen the presentation, follow both product links, preserve/read/reopen the ECHO email, compare its unchanged live copy, select every Assistant question, reopen Messages, finish the optional VR teaser and relaunch. Check Dynamic Type, VoiceOver, Reduce Motion, native Back/Home controls, repeated OS navigation and custom home layout retention. These UI checks cannot be replaced by Linux Foundation tests or Swift syntax parsing.

### Results — 2026-10-13

All seven Foundation scripts passed using official Swift 6.2, Swift language mode 5 and warnings as errors in a network-disabled container with a read-only source mount. Act 1, content, evidence and progression saves each reopened successfully in separate processes. Navigation covered 1,500 app cycles and 14 swipe cases; layout covered 185 valid moves and persistent reload. All 45 app Swift sources parsed with DEBUG enabled. All 32 local Markdown links resolved; source/resource project references and the iOS 18 target were checked. Launch, game mechanics, OS coordinator and save schema are unchanged.

`xcodebuild` and `xcrun` are unavailable on this Linux host. No Apple-SDK build/typecheck, iPhone simulator run, visual layout, VoiceOver, haptic or native gesture verification was possible. Swift syntax parsing and Foundation tests do not establish those results. The simulator checklist above remains required on an Apple-SDK machine.
