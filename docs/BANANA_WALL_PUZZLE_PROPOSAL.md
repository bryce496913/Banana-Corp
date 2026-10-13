# Banana Wall — Review cross-reference

**PROPOSED — AWAITING STORY APPROVAL**

This entire document is a design proposal, including all new puzzle copy, answers, reward copy, IDs and implementation contracts. Quotations explicitly identified as existing evidence are verified against the current catalogue; reproducing them here does not approve this new puzzle. Approval of a PR containing this document alone must not be interpreted as permission to activate it. Obtain explicit story approval for the checklist below before implementation.

The [game bible](../BANANA_CORP_GAME_BIBLE.md) remains canonical. Its Banana Wall solution is TBD. Production [RestrictedAccess.json](../Banana%20Corp/Banana%20Corp/RestrictedAccess.json) remains unchanged: `resource.banana_wall` requires `puzzle.banana_wall.pending_design`, whose `awaitingApproval` rule has no inputs, answer, hints or effects. This documentation does not unlock anything or update the bible.

## Premise and intended difficulty

**Proposed premise:** the curated Browser hides direct access to a research attachment, but an older review cross-reference can locate one omitted record when the player correctly identifies its originating discipline, trial, public claim and different research observation. The player assembles a precise review request, not a real account password, an employee impersonation or a cryptographic exploit. This limited lookup mechanism is new fictional framing and needs approval.

The first breach is an accessible cross-source investigation puzzle, not a cipher. Daniel supplies the internal-correspondence context; ECHO-07 supplies the research reference; public and internal wording supply a contrast. Four jointly required values implement these **three concepts**: the discrepancy needs both sides rather than one vague keyword. Guessing “ECHO” or one character's name cannot complete the request. Unlimited attempts remain possible, but no essential progress depends on guessing.

The reward confirms the scope of that discrepancy through one internal review record. It does not explain ECHO's sentience, MIRROR, ASCENSION, energy harvesting, Daniel's complicity, Maya's fate or Observer purpose. This is intentionally a modest first opening, not the entire Act 3 reveal. The reward's dramatic adequacy and the credibility of the old lookup require human review.

## Encounter, relevance and leads

Keep the existing encounter: after the explicit Act 2 Connect action and separate Act 3 handoff, open **Web Browser → Banana Wall**. `milestone.act2.cross_app_confirmation` and Act 3 continue to govern discovery; no additional mandatory app, preservation, mini-game, timer or score gate.

The already authored **Connected accounts** page (`content.act2.connection_summary`, `version.act2.connection_summary.v1`) explains why this matters: “The next step is to reach information beyond the curated summaries.” Daniel identifies his internal-review email and sends the player to Maya/ECHO-07; the findings state the excerpt is not the complete archive. The existing Wall message says restricted research is beyond the boundary. These justify trying the lookup without giving Act 3 knowledge away.

**Proposed entry title:** “Research review cross-reference”. Add a short explanation and four labelled fields, Submit review request, Hint, Clear input, native Back and fictional Home. Add explicit source links labelled with existing titles to Daniel's conversation, the official-response article, Maya's correspondence and ECHO-07. Links must use the shared store's available-source queries; they are in-game records, never external websites. Returning to the Wall must be straightforward. No new clue is hidden in a decorative glitch, timestamp, app icon, developer diagnostic or source-code ID.

## Evidence audit and exact clue values

All references below are to [StoryContent.json](../Banana%20Corp/Banana%20Corp/StoryContent.json). Values are selected from actual player-visible wording, not derived from JSON IDs. These main-path Act 2 versions have no authored removal/replacement event and remain available in Act 3 under the current monotonic conditions.

| Proposed field / answer | Exact existing evidence | Source identity and location | Availability before the Wall |
| --- | --- | --- | --- |
| Originating discipline: **`neural systems`** | “I sent the internal-review email. My name is Daniel Mercer. I work on neural systems at Banana Corp.” | `content.act2.messages.daniel` / `version.act2.messages.daniel.v1`; Messages → Daniel Mercer; message `message.act2.daniel.identity` | Act 2, after replacement inspection and a qualifying symptom report. Daniel read is required for the Act 3 handoff |
| Trial reference: **`ECHO-07`** | “Look at Dr. Maya Chen’s ECHO-07 preliminary findings. They concern neural synchronization.” Also the findings title contains “ECHO-07 — Neural Synchronization Trial — Preliminary Findings” | Daniel's message `message.act2.daniel.maya`; `content.act2.web.echo07` / `version.act2.web.echo07.v1`; Browser/research links → findings title and Review scope | Findings unlock after Daniel's lead. ECHO-07 read is required before Act 3 |
| Publicly described boundary: **`selected preferences`** | “Its public guidance presents the adaptive interface as operating within selected preferences.” | `content.act2.news.official` / `version.act2.news.official.v1`; News → Banana Corp points to familiarization as questions grow; first paragraph | Available in Act 2; official-response read is required before Act 3 |
| Research observation: **`recorded cognitive patterns`** | “Synchronization coincides with changes in recorded cognitive patterns.” Supporting instruction: “Please distinguish an interface adjustment from a change in the recorded cognitive patterns.” | ECHO-07, Observations paragraph; `content.act2.email.maya` / `version.act2.email.maya.v1`, second paragraph | Maya unlocks after Daniel; Maya and findings reads are required before Act 3 |

**Why these words matter:** Daniel identifies the research discipline rather than a surname. His lead identifies a numbered trial rather than the general Project ECHO name. The official article describes presentation within preferences; Maya explicitly asks the reader to distinguish that from recorded cognitive changes. Entering both concepts retains the difference instead of pretending the public description accounts for the research finding.

This is an unexplained **scope discrepancy**, not proof of causation or intentional manipulation. Public “selected preferences” wording does not explicitly promise all neural activity ends at disconnection. Accordingly, “after disconnection” is supporting concern, **not** an invented logical negation of that public claim or a secret password component.

### Earlier/optional context and excluded clues

- Act 1's `content.act1.news.interface` / `version.act1.news.interface.v1` says internal review checks consistency with a user's selected preferences. It reinforces the public boundary, but that particular article is optional: any one launch article satisfies Act 1.
- The original Project ECHO email (`content.act1.echo_review`, `version.act1.echo_review.v1`) says the circulating sign-off treats unresolved cases as closed without a corresponding review. It motivates the puzzle. Its live source is removed at the first anomaly; a player-preserved copy is optional. It is **not** the only source of any answer or a required archive.
- Daniel's existing Act 2 conversation restates the public/internal mismatch and identifies the sender. This is his internal-review correspondence context. There is **no** existing Daniel password, challenge phrase, four-part access code or authorisation credential; this proposal does not claim there is one.
- Official preview guidance (`content.act2.web.preview_notes`) also retains “selected preferences” wording in both v1 and v2. It is an optional alternate public source; never require its removed/changed session-notes paragraph.
- The Assistant diagnostic (`content.act2.diagnostics.excerpt`, `version.act2.diagnostics.excerpt.v1`) contains `ECHO_CORE`, an unexplained Observer-channel mismatch and an unresolved origin. It supplies caution/context, **not** an approved credential. Neither identifier becomes an answer, Observer-route award or explanation of the core's purpose.
- Alex's earlier transcript, removed social posts and preserved comparisons remain useful context, but neither saved Alex evidence nor any deleted-only source is required by this puzzle. Both Act 2 proof/corroboration routes reach the same puzzle.
- No Act 3-only knowledge, MIRROR reference, ASCENSION value, Maya fragment/note, LANTERN/BLACKOUT/DAWN requirement or late Assistant cooperation enters the answer.

## Player-facing instructions and input

**All copy in this section is proposed, not inserted into the app.**

> Direct archive browsing is restricted. A review cross-reference can retrieve one matching attachment.
>
> Identify the discipline of the person who sent the internal review, and the trial he asks you to investigate. Then pair the public description with the different change recorded in the findings.
>
> Use the exact short phrases from the records. Enter the discipline, the trial reference, the boundary described in public guidance, and what changed in the trial's observations. This is a record lookup, not an account sign-in.

Four **text** fields, no concealed password masking:

| Proposed input ID | Visible label | Supporting prompt |
| --- | --- | --- |
| `input.banana_wall.discipline` | Originating discipline | The internal-review sender's field of work, not his name |
| `input.banana_wall.trial` | Trial reference | The numbered trial in the preliminary findings; keep its hyphen |
| `input.banana_wall.public_scope` | Publicly described boundary | The two-word phrase following “within” in the official response |
| `input.banana_wall.research_scope` | Research observation | The three-word phrase identifying what changed in Observations |

These prompts constrain scope fairly while leaving source identification and comparison to the player. Do not prefill answers, invent arbitrary character extraction, concatenate timestamps or rely on keyboard autocorrection. Copy/paste and text selection are permitted. The four values must be submitted together through **Submit review request**; opening links or reading a source cannot auto-complete the puzzle.

### Exact proposed answer and normalization

The exact answer is the **field mapping**, not a single space-delimited password:

| Field | Proposed expected value |
| --- | --- |
| `input.banana_wall.discipline` | `neural systems` |
| `input.banana_wall.trial` | `ECHO-07` |
| `input.banana_wall.public_scope` | `selected preferences` |
| `input.banana_wall.research_scope` | `recorded cognitive patterns` |

Use the existing `exactFields` contract: require exactly these four input IDs; reject missing/extra fields and raw values exceeding 256 UTF-8 bytes; apply Unicode canonical precomposition, trim leading/trailing whitespace/newlines and compare case-insensitively. Expected values receive the same normalization. This accepts ` Neural Systems ` / `echo-07` / `SELECTED PREFERENCES` / `recorded cognitive patterns`.

Internal single spaces and the ASCII hyphen in `ECHO-07` remain significant under the current rule. `ECHO`, `ECHO_CORE`, `echo07`, a different trial number, field swapping, repeated internal spaces and paraphrases are not accepted. Do not silently add undocumented aliases, fuzzy matching or normalization in a view. Disable autocorrection and smart-dash substitution on the reference input, show a copyable reference-format example and explain the hyphen in the field prompt. Accessibility/keyboard usability of exact phrases requires playtesting. Broader whitespace/dash acceptance would require a separately approved, declarative rule/model change; it is not claimed to exist now.

## Intended solution, step by step

1. Reach Act 3 through the existing explicit investigation and open the Browser Wall. Read the explanation that one review record can be retrieved by matching descriptors.
2. Reopen Daniel's conversation. His identification of himself as the email sender resolves who “the internal-review sender” means. Extract **neural systems**, not “Daniel Mercer”.
3. Follow his Maya/ECHO-07 research lead. The title and Review scope provide **ECHO-07**, including `07`; do not substitute the generic project or diagnostic override name.
4. Reopen the official-response article. Extract **selected preferences** from the sentence about the public adaptive interface.
5. Compare Maya's instruction with ECHO-07's Observations. The distinct thing changing is **recorded cognitive patterns**. The task asks what the record observed, not for an explanation of who caused it.
6. Return to the Wall, place the four values in their labelled fields and Submit review request. All four must match. The source links, Back/Home and on-demand hints remain usable throughout.
7. A successful saved request grants only the scoped first access and offers **Open review record**. Opening that record is a separate explicit read, not a success-side effect. Further Act 3 content remains unavailable unless separately approved.

The essential reasoning is the distinction between preference-scoped presentation and a recorded cognitive change. It does not prove sentience, identify an antagonist or require interpreting speculative energy physics. Copying a one-word project name alone fails.

## Hints and failure experience

**Proposed availability:** Hint is available immediately upon opening the discovered challenge, before any attempt. Each deliberate tap reveals the next hint; all previous hints remain readable. No wait, attempt threshold, consumable, progress penalty or hidden score. Hint display index may reset on leaving/relaunching, but all hints remain immediately obtainable again. Choosing hints grants no story fact or answer credit. A “Show previous hints” section must remain accessible when input/keyboard is visible.

1. **Sources:** “Return to Daniel’s conversation, the official response in News, and Maya’s ECHO-07 findings. The sender’s work, the trial title, and the contrast between public wording and observations are the pieces you need.”
2. **Relationship:** “Daniel identifies the discipline and the trial. The other two fields form a pair: what public guidance says the interface stays within, and what the research record says actually changed.”
3. **Reasoning:** “Use the sender’s field of work rather than his name, and the complete numbered trial reference rather than the project name. In the official response, copy the short phrase after ‘within’. In the findings, look under ‘Observations’ for the phrase after ‘changes in’. Maya’s correspondence explains why those two kinds of change should be distinguished.”

Hint 3 gives a concrete extraction method, not the assembled answer. If playtesting shows this still blocks comprehension or copying, improve labelled prompts/accessibility through approval rather than imposing a late optional evidence gate.

| Result | Proposed message / behavior |
| --- | --- |
| Empty/missing/oversized field | “Complete all four short fields using phrases from the records.” Focus the first incomplete/oversized field; preserve valid entered values |
| Complete but incorrect tuple | “No matching review record. Check the sender’s discipline, the trial reference, and the public/research wording. You can retry or open a hint.” Keep input editable; no countdown, lockout, partial-match oracle or state change |
| Source/catalogue unavailable | “The local review sources are unavailable. No access has been granted. Return to your investigation and retry.” Preserve saves; do not substitute fabricated clues or require source-code inspection |
| Completion save fails | “The request could not be saved. No access has been granted. Your input is still here; try again.” No partial success, puzzle/access marker or resource leak |
| Success saved | “Review record located. Access is available to one research attachment.” Offer Open review record and Back/Home; do not say all research/security restrictions are removed |
| Previously completed | “This review record is already available.” Offer the same resource; do not replay success effects, notifications or animation |

No timer, flashing/glitch effect, dramatic scare, haptic on every failed input or fictional destructive consequence. A single restrained confirmation haptic may use the existing meaningful-action feedback after durable success; Reduce Motion uses the standard simplified feedback.

## Proposed first restricted record — approval dependency

**There is no currently approved, separate protected research reward in the production catalogue.** The approved ECHO-07 excerpt is already a required pre-Wall read; newly gating that existing item would create a circular dependency and would not reward the player. Do not pretend a new internal attachment is approved merely because its subject is canonical.

The recommendation is this **complete minimal draft**, to be approved together with the puzzle. It recontextualizes already known observations as an internal scope-reconciliation record without delivering new conspiracy revelations:

> **ECHO-07 — Scope reconciliation record**
>
> Internal research review
>
> Originating discipline: neural systems.
>
> Referenced trial: ECHO-07 — Neural Synchronization Trial — Preliminary Findings.
>
> Public description: the adaptive interface operates within selected preferences.
>
> Research observation: synchronization coincides with changes in recorded cognitive patterns.
>
> These statements concern different kinds of change. The preliminary excerpt does not establish that the recorded findings are confined to the public description.
>
> Review status: discrepancy unresolved. Read the preliminary findings and research correspondence alongside this record before drawing a conclusion about the cause.

**Proposed metadata/structure:** one Browser web payload with headings and labelled blocks; source “Internal research review”; subtitle “Limited review attachment”; no invented author, launch/research calendar date, media file or reference to the unseen full archive. Explicit links to the existing ECHO-07 and Maya sources. Proposed local path `/research/echo-07/scope-reconciliation`, content `content.act3.banana_wall.scope_record`, immutable original `version.act3.banana_wall.scope_record.v1`, preservation ID `evidence.act3.banana_wall.scope_record.v1`. Preservable, with no read/preserve effects or generic evidence score. All names/copy/IDs and the claim of internal-record provenance require approval.

Once approved, this **one** new item is the approved internal resource made available on success. If its draft is rejected, hold implementation until a replacement reward is approved; do not open a blank document, relabel an already public item as newly unlocked, invent an Act 3 research chapter or silently change the puzzle's promised reward.

## Proposed completion and access contract

Use the [existing framework](ACT3_PUZZLE_DESIGN.md), [models/validator](../Banana%20Corp/Banana%20Corp/RestrictedAccessModels.swift) and [central store](../Banana%20Corp/Banana%20Corp/RestrictedAccessStore.swift). This is a mapping for future review, **not a production JSON patch**.

- New deliberate puzzle ID: `puzzle.banana_wall.review_cross_reference`; event `event.puzzle.banana_wall.review_cross_reference`. Keep the pending descriptor unchanged during this pass and never reinterpret its ID or historical injected facts as real completion.
- Available act 3; requirement `milestone.act2.cross_app_confirmation`, with the existing production Act 3 handoff intact. No saved-evidence, optional-source, hint/attempt, game, cooperation or Observer prerequisite. Register referenced facts and the four input IDs according to loader rules. Do not add a dependency on the access this puzzle itself produces.
- The existing solver's successful `completeEvent` atomically records the new puzzle as solved, its named success event and a single declared `grantAccess` effect for existing **`access.banana_wall.breached`**. This is the first restricted research access milestone; no second hidden score or additional undeclared access award.
- In a later approved implementation, point `resource.banana_wall.requiredPuzzleID` at the new puzzle and retain its existing access ID. Set its linked content to **only** the proposed scope record. The new item must reciprocally declare `restrictedResourceID: resource.banana_wall`, act 3 and the same approved access condition. Validate registry links both ways; no reference may reveal the resource before successful access.
- Availability follows saved puzzle completion **and** success event **and** access. No separate UI `isUnlocked` store. The new record need not be “revealed” through an unsupported puzzle effect: an ordinary catalogue item with an access condition becomes available when its registered resource unlocks. If hidden-until-revealed is chosen instead, that additional delivery contract needs explicit design/implementation review.
- Do not read the reward, advance acts, establish Assistant cooperation, award Observer clues/route prerequisites, queue a notification, unlock other apps/research or increment ASCENSION as part of success. Keep later transitions unconfigured.
- Relaunch retains the saved completion/access and immutable snapshots using save schema 2. Repeated submissions return alreadyCompleted without saving/reapplying effects. Atomic write failure leaves all three completion facts absent. Inconsistent partial markers fail closed for recovery, not automatic success.
- Audit old saves for pending-placeholder/test facts and new ID collisions. Production awaitingApproval descriptors currently reject even injected solved/access facts. New completion must require the new approved puzzle/event; neither DEBUG fixtures nor pending/test IDs can substitute for it. No unapproved migration or retroactive content/snapshot rewrite.

## Accessibility, recovery and softlock review

| Risk | Proposed prevention / verification |
| --- | --- |
| Original email or Alex transcript was never preserved | Neither is an essential answer source. Daniel, official response, Maya and ECHO-07 remain recoverable on all four preservation combinations |
| Optional Act 1 interface article was not read | Use the required Act 2 official-response article. Do not add an optional article requirement after the handoff |
| Guidance/social content changes | Required values come from stable v1 sources; guidance is only an alternate. Never demand deleted text or an internal receipt as player proof |
| Existing save already reached Act 3 | Provide source links and allow rereading stable sources; no backward act transition, reset or preservation requirement |
| A future content pass removes/edits a required clue | Maintain approved, player-visible recovery content before shipping that pass and update canon/contracts/tests. Do not silently replace preserved evidence snapshots or expose raw catalogue originals through a “recovery” bypass |
| Keyboard/type/punctuation error | Visible exact-phrase prompts, copy/paste, explicit hyphen guidance, case/edge-whitespace normalization and clear validation. Proposed four fields must scroll above the keyboard on small iPhones |
| Leaving or force quitting mid-attempt | Fields may clear; all sources/hints remain recoverable. Earned success must persist. No attempt counter or irreversible failure |
| Slow reading, no vision/audio or Reduce Motion | No transient clue, colour-only distinction, required sound, shake/wiggle or timer. Every clue, field and feedback is selectable/readable text |
| VoiceOver/Dynamic Type/navigation | Label fields individually in discipline → trial → public → research order; announce validation/result without stealing focus; retain values; expose Hint, Submit, Clear, Back and Home as accessible buttons. All remain reachable at accessibility text sizes |
| Repeated/wrong/partial submissions | Exact whole-tuple validation, neutral retry, no success before durable commit, no partial correctness scoring, no permanent lockout |
| Corrupt/unavailable save or broken catalogue | Existing fail-closed recovery and truthful error, never an automatic reset/bypass; retain archives. Packaging failures are bugs to repair, not story punishments |

Pre-26 themed surfaces, iOS 26 guarded glass, black/purple/pink/white theme and hardware-safe Home remain unchanged. Keep puzzle gestures within standard text/buttons/scrolling; never attach a root swipe that competes with scrolling, games or real iOS Home. No weather, time-zone/date, network, real credentials or permissions.

## Future automated tests and player validation

These are proposed acceptance tests, **not tests of an implemented solution**:

1. Before Act 3/cross-app confirmation: no active puzzle/reward/answer-bearing preview or unread badge. Direct content/read/preserve queries fail closed.
2. Complete all four email/Alex preservation combinations through normal content actions; at the Wall, the four essential v1 sources and links remain available. Repeat with a different Act 1 article and no optional exploration.
3. Exact four-field tuple succeeds; uppercase/mixed case, canonical normalization and edge whitespace succeed. Wrong discipline/trial/public/internal phrase, swapped fields and `ECHO` alone fail without saved changes.
4. Empty/missing/extra/oversized fields fail; explicitly test the documented internal-space/hyphen policy. Copy/paste and keyboard entry yield equivalent validation. No view-local validator can disagree with the central rule.
5. Each source quote/extraction still matches its immutable definition; test removal/change of a required clue fails the readiness review rather than shipping an unsolvable puzzle. No requirement depends on the new protected reward.
6. Hints can be requested before an attempt, reread and reopened without score/act/access effects. Wrong submissions and Clear never remove progress or archives.
7. Success writes puzzle + event + scoped access in one transaction. Inject write failure and verify unchanged state/no readable reward; retry succeeds. Double submit/reopen does not repeat effects.
8. Save/load and separate-process relaunch retain new completion and original reward evidence bytes. Old schema 1→2 saves and already-Act-3 schema 2 saves retain their arrangement/evidence. Pending/test/partial facts cannot confer genuine success.
9. Only the one approved scope record becomes available/unread; opening it explicitly marks it read. No other research, app, milestone, ending route, Observer fact or act changes.
10. Preserve the reward, later lose live authorization and compare honestly without modifying the snapshot. Do not invent a future removal event just to demonstrate this case.
11. Production loaders accept only approved production definitions, validate input/fact/content links and reject fixture solutions, cycles, self-produced prerequisites, missing resources and invalid effects. DEBUG demonstrations cannot affect a campaign.
12. Build with Apple SDK/Xcode 26+; test iOS 18/26, small/large/Dynamic Island iPhones, keyboard, long text, VoiceOver, Dynamic Type, Reduce Motion/Transparency, nested source links, Home/Back, backgrounding and repeated correct/incorrect attempts. No executed Apple puzzle test is claimed in this proposal.

## Required content changes and approval checklist

**No changes to existing Act 1–2 narrative copy are required by this design.** Existing stable facts/quotes already supply all values. Do not append a secret credential to Daniel's published messages, alter his anonymous signature, patch old snapshots or make the initial removed email reappear as proof. New entry/field/hint/result copy and one Act 3 scoped-record draft are proposed additions only.

Human story approval is required for **every** item below before any runtime/catalogue/bible activation:

- [ ] The old cross-reference lookup premise, its credibility as a limited Banana Wall breach and the intended accessible first-puzzle difficulty.
- [ ] Selection of three investigation concepts, four exact values, their field order, source/extraction mapping and public/internal discrepancy interpretation. Confirm it does not falsely prove causation or an unspoken corporate promise.
- [ ] All entry instructions, field prompts/format rules, source links, Submit/Clear labels and failure/success/completed/error copy above.
- [ ] Case/whitespace/Unicode/hyphen policy; whether keyboard/playtest findings justify a separately reviewed broader declarative normalization rule.
- [ ] Three hint texts, immediate voluntary availability, re-display and no-penalty policy; no new Assistant hint dialogue or automatic confession.
- [ ] The full scoped-record draft, title/source/provenance, metadata, links, preservation eligibility and whether this modest first reward is sufficient. **No approved protected reward currently exists**; implementation cannot complete this checklist without explicit reward approval.
- [ ] Exact new puzzle/event/input/content/version/evidence IDs and retained access ID; retirement/reference strategy for the pending descriptor and old-save collision/partial-marker audit.
- [ ] Atomic puzzle/event/access completion, one-resource-only unlock, explicit reward read and repeat-success behavior; no wider Act 3/ending/Observer/cooperation effects.
- [ ] Essential clue recovery on every preservation path, no new Act 1–2 prose or gate, keyboard/VoiceOver usability and the proposed testing plan.
- [ ] A subsequent implementation PR must update the approved bible sections/change log and documentation alongside approved definitions, UI/support contracts and tests. Approval must identify which proposal decisions were accepted or revised; merging documentation is not activation authorization.

## Validation for this documentation pass

The source audit checked the quoted fragments, stable IDs/versions, unlock conditions and authored replacement set against production catalogue/models. Essential clues are current pre-Wall records; no existing protected reward was found. Markdown references and repository diff checks are the applicable validation for this documentation-only pass. No puzzle code, answer JSON, catalogue, save, UI or bible change is authorized here; production remains awaitingApproval and non-completable. Future solution tests and native playtesting above are requirements for a later approved implementation, not executed results.
