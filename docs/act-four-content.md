# Act 4 — resistance, takeover and explicit final investigation

Implemented from the creator-approved [completion contract](STORY_COMPLETION_PROPOSAL.md) and [bible](../BANANA_CORP_GAME_BIBLE.md). This slice preserves the first 70 published catalogue item/version definitions, existing source identities and saved evidence bytes. It adds nine Act 4 sources and the minimal Act 5 entry; endgame content uses the same catalogue in its separate implementation.

## Investigation graph

Explicitly read the existing Act 4 entry, then The Signal's collective resistance packet. Reading the packet awards no component. Its linked investigations may proceed in any order:

| Investigation | Explicit inspected sources | Separate action / saved result |
| --- | --- | --- |
| Vale accountability | `act4.vale.authorization`, `act4.vale.loss` | Compare records → `milestone.act4.vale_accountability_compared`; then obtain Root Authorization → `route.blackout.root_authorization` |
| Deployment | `act4.deployment.relay` | Verify channel → `route.blackout.deployment_channel`; no network operation or deployment |
| LANTERN | `act4.lantern.protocol` | Authorize safety access → `access.lantern.authorized`, `route.blackout.neural_signature`, `milestone.act4.lantern_authorized` atomically |

Source shorthand above expands to stable `content.<suffix>` / `version.<suffix>.v1` identities. All ten new slice sources have reciprocal registered restricted-resource bindings. Their catalogue unlock conditions and shared access queries protect direct reads, lists and preservation.

LANTERN makes `act4.maya.signature` diagnostics available: a continuing connection suggests survival, not safety, freedom or location. Its BLACKOUT Neural Signature is an emergency credential, not reconstructed Maya identity. Two explicit Assistant exchanges follow: `act4.assistant.conflict.safety` then `act4.assistant.conflict.core`. They acknowledge competing directives without awarding cooperation.

After all three investigations, their explicit acquisition/verification events, Maya's diagnostic and both exchanges are inspected, **Connect takeover evidence** commits `event.act4.takeover_connected`, `milestone.act4.takeover_connected` and `AscensionMilestone(id: "ascension.act4.takeover", percentage: 87)` together. It does not start a timer or interpolate progress. `act4.echo.address` becomes available; it preserves usable Home/system controls and existing evidence.

The player must read that address and separately choose Act 5 entry. `beginActFive()` validates the same saved investigation, fixed milestone and protected entry access before the central consecutive-act transition. The new `content.act5.entry` explains revisitable investigation directions and points to common Recovery Diagnostics; it does not commit an ending. No Act 4 read commits BLACKOUT, reconstruction, cooperation or optional Observer eligibility.

## Integration APIs

`ActFourContract` centralizes IDs and exact conditions in `StoryPrerequisites.swift`. `StoryContentStore` owns:

- `valeComparisonAvailable` / `compareValeRecords()`
- `rootAuthorizationAvailable` / `obtainRootAuthorization()`
- `deploymentVerificationAvailable` / `verifyDeploymentChannel()`
- `lanternAuthorizationAvailable` / `authorizeLanternSafetyAccess()`
- `takeoverConfirmationAvailable` / `confirmTakeoverEvidence()`
- `actFiveHandoffAvailable` / `beginActFive()`
- passive `actFourSuggestedLead` and `actFiveEntry` queries

Availability checks require the exact saved read and read-event facts, authentic authored version receipts, current authorization and the current act. Actions validate declared facts, save once atomically, and return unchanged on a legitimate repeated event. Failed persistence grants no partial component, access, fixed percentage or act advancement. Preserved evidence remains optional; earlier original snapshots are retained unchanged.

## Validation scope

`bash scripts/check-act-four.sh` compiles the production Foundation models with a task-local module cache. The new model suite starts from an explicit seeded Act 4 fixture (not a native campaign bypass), exercises all six investigation orderings through ordinary store read/action APIs, injects failed writes before each component/synthesis and handoff, checks idempotence, restores fresh stores, and reopens the final save in a separate process. It checks exact preserved original evidence bytes and absence of premature cooperation/Observer awards. Historical native Acts 1–3 coverage remains separate; this model suite is not an iPhone gameplay pass.

Apple Debug/Release integration, new native controls, full ending routes and roughly ten-minute physical QA blocks are separate validation requirements. See [native integration](IOS_INTEGRATION_VALIDATION.md) and [existing journey scope](ACTS_1_3_RELEASE_QA.md). No native Act 4 completion or full-game readiness is claimed by this document alone.
