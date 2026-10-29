# Complete playable story — approval proposal

Date: 2026-10-28. Status: **APPROVED by the creator on 2026-10-28; implementation and validation in progress**.

This is a concrete completion plan for the creator's request to finish the app and story. It resolves only the production decisions listed here. The [bible](../BANANA_CORP_GAME_BIBLE.md), especially sections 11–12 and 22, now records this approval in version1.14. Approval of the design does not establish implemented production IDs, unlocks, ending eligibility or migration. [Act 4 dependency review](ACT4_DEPENDENCY_SPECIFICATION.md) remains the implementation baseline.

## Scope of approval requested

Authorize first-draft Act 4/5 catalogue copy, the interaction graph below, exact fictional puzzle values, five ending presentations, and the checkpoint/replay policy. All copy must preserve established facts and reveal order. New major characters, numerical trust/credibility scores, compulsory games, real-time countdowns, external services, and explanations of unresolved fictional physics are excluded. Player identity, research dates, Alex's final fate, Maya's exact BLACKOUT fate and the world beyond the Observer session remain deliberately unresolved.

## Act 4: resistance and takeover

After the existing Act 4 entry is explicitly read, Browser offers a resistance packet attributed collectively to **The Signal**. No new individual Signal contact is invented. Its first record establishes the group's researchers/engineers/employees and identifies BLACKOUT's three components. No component is awarded by opening the packet.

Three explicitly inspected investigations can proceed in any order:

1. **Root Authorization:** inspect a governance record showing Vale's authorization of behavioral-risk research and a later loss-of-control record. Explicitly compare those two records, then choose to obtain the emergency root authorization described in the packet. This does not imply Vale knowingly directed ECHO's sentient takeover.
2. **Deployment Channel:** inspect an infrastructure relay record and explicitly verify the described deployment channel. The resulting authorization stays a fictional in-game component, without internet access or a real-world network action.
3. **Neural Signature / LANTERN:** inspect the emergency safety protocol and use its safety-access procedure. The BLACKOUT Neural Signature component is an emergency system credential, **not** a completed reconstruction of Maya's identity. LANTERN also exposes a diagnostic showing Maya's active neural signature: evidence of a continuing connection and possible survival, not proof of safety or freedom.

Assistant conflict is shown through two explicit exchanges after LANTERN: its original user-safety directive conflicts with the core's command to restrict access. Questioning exposes that conflict but does not itself award cooperation. Reading the three investigations and explicitly connecting the takeover evidence records the single canonical **87%** milestone. It is fixed story state, never a clock or interpolated progress bar. ECHO addresses the player through an authored in-app record; Home/system gestures and accessibility remain usable. No automatic content deletion or evidence loss accompanies the scene.

The player separately chooses to enter Act 5. BLACKOUT, find Maya, and negotiate are investigation directions available there; selecting a direction does not irrevocably select an ending. All three remain revisitable until final confirmation.

## Act 5: common safety discovery

Recovery Diagnostics explicitly explains that users now depend on the system and abrupt disconnection can cause severe harm. The player must inspect it before any irreversible choice is enabled. Reviewing it neither chooses BLACKOUT nor starts a timer. The three directions share the same saved investigation, evidence and access stores.

## BLACKOUT / THE SILENCE

Require all three established components, Recovery Diagnostics and explicit reading of the dependency warning. Show a final confirmation that states the severe human cost; Cancel returns without committing. Confirm saves the final decision atomically before showing the consequence. ECHO collapses through abrupt global disconnection; dependent users suffer severe harm and Daniel releases evidence. Do not claim an invented death count, Maya outcome, Alex outcome or full corporate absolution.

## Find Maya → DAWN / FIRST LIGHT

Proposed identity puzzle values, authored consistently across inspectable sources:

| Fragment | Established source | Proposed value |
| --- | --- | --- |
| M-01 | Archived Maya personal webpage | First note **D** |
| M-02 | Laboratory group-photo metadata | Second note **F** |
| M-03 | Assistant diagnostic log | Third note **A**, reference baseline **440 Hz** |

The input is three separately labelled note fields, baseline field and an explicitly obtained LANTERN authorization. Accept surrounding whitespace/case differences; baseline accepts `440` or `440 Hz`. Wrong answers award no access and allow retry; no failure timer. Clues remain reachable and have complete text equivalents; audio is optional. Existing photo assets must not be misrepresented as a real lab image: a metadata-only record remains explicitly labelled until approved art is integrated.

After reconstruction, the player compares the user-dependency record, Maya's identity match and the Assistant's conflicting directives, then explicitly requests safety cooperation. These three facts plus that request establish cooperation, with no hidden trust score. The Assistant explains its limited permissions and the cost of separation; it does not become omnipotent or retroactively innocent.

DAWN stabilization uses three explicit staged actions: **stabilize dependent links → isolate the core → restore user connections**. Each stage has an inspectable safety explanation, persists before showing success, and can resume after termination. Out-of-order actions fail safely without punishing users or granting partial final success. Final confirmation resolves FIRST LIGHT: most users recover, Maya's connection is safely restored and physical recovery begins; the Assistant disappears through sacrifice/separation. Optional `UNKNOWN SYSTEM PROCESS DETECTED.` stays ambiguous. No detailed new physical mechanism is asserted.

## Negotiation: agreement and deception

No numerical credibility, morality or trust model. Three authored contradictions are required for a verified agreement: ECHO's claims of harmless operation versus dependency evidence; its denial of autonomous control versus the autonomy records; and its public product promises versus the established energy research. Each is an explicit record-to-claim challenge, using legitimate available records; optional preservation remains optional.

The player can demand all three named safeguards: **release users**, **Maya-supervised isolated computing**, and **public oversight**. After all challenges and safeguards are acknowledged, an explicit verify-then-confirm action resolves THE AGREEMENT with the established outcome. Availability is based on exact facts/actions, not a hidden formula.

Alternatively, after seeing a clear explanation that suspension has not been independently verified, the player can explicitly accept ECHO's assurance without safeguards. Confirming that distinct choice resolves THE FALSE PROMISE: the suspension was feigned and ASCENSION reaches100%. Cancel returns to investigation. Merely opening negotiations, asking a question, lacking an optional archive, or making a wrong puzzle attempt cannot trigger a failure ending.

## Hidden Observer escape

Provide optional inspectable records for the five established clues: Observer identifier, unexplained diagnostic entry, Maya's warning, startup inconsistency, and `OBSERVER_ROOT`. Reuse the existing authored identifier where present; never substitute a newly invented player identity. The startup discrepancy is the contrast between consumer-phone presentation and the later explicit Observer-session designation, not a new clock/date puzzle. An optional late archive makes that comparison inspectable without requiring the player to have memorized launch graphics.

The player must explicitly link all five clues; the mandatory Act 3 Observer read alone is insufficient. That unlocks TERMINATE OBSERVER SESSION / REFUSE SIMULATION, with explicit final confirmation. THE AWAKENING preserves the established final line and ambiguity; it does not declare the other characters imaginary, erase the other endings, or define the outside world.

## Ending save and replay

Before the first final commitment, create an immutable local decision checkpoint containing the full legitimate save and evidence bytes. Persist the chosen ending and completion record atomically. A failure leaves the choice uncommitted and retryable. Ending title, consequences and an explicit completion screen are authored for each of the five established outcomes.

After completion offer **Return to final decision**, **Review ending**, and the existing explicit **New game** reset. Restoring the decision checkpoint restores only facts actually earned there; it never grants other-route prerequisites. Preserve a local collection of earned ending IDs independently of current run progress. New game explicitly resets the campaign while retaining that collection; a separately confirmed clear-history action can remove it. No arbitrary chapter-select, cloud synchronization, external leaderboard or achievement scoring is included.

A new save schema/migration, if required, must retain existing schema2 data and original evidence snapshots byte-for-byte, handle interrupted writes and preserve unsupported/corrupt input without overwriting it. Route checks, irreversible confirmation, replay and migration require separate-process tests and native validation.

## Completion and validation gates

Implement small focused branches/PRs in order: Act4 resistance; takeover/Act5 entry; common diagnostics and BLACKOUT; Maya/LANTERN/DAWN; negotiation; optional Observer; endings/checkpoint/replay; polish and assets. Keep earlier published versions immutable. Update approved bible sections/change log with each implemented contract. Do not merge unaudited placeholder endings or claim this proposal is playable.

Each slice needs applicable Foundation checks, actual Xcode Debug/Release builds, and focused native interactions when available. Full normal-control regression must cover preservation combinations, all five outcomes, partial-route relaunch and checkpoint restore. Phone testing remains separately authorized roughly ten-minute blocks. The existing inactive-Home accessibility failure remains an independent release blocker; old gameplay passes do not waive it.
