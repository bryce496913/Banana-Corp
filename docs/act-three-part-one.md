# Act 3 Part One — MIRROR, ECHO and neural influence

Canonical authority: [bible, Act 3](../BANANA_CORP_GAME_BIBLE.md). Content is bundled in [StoryContent.json](../Banana%20Corp/Banana%20Corp/StoryContent.json); the existing [restricted registry](../Banana%20Corp/Banana%20Corp/RestrictedAccess.json) remains the only access authority.

## Progression map

Every arrow represents an explicit source read, never list appearance. All records require Act 3 and the approved Banana Wall puzzle, event and access effects. Opening the placeholder cannot grant access.

| Record (prefix `content.act3.`) | Required read | Read effect |
| --- | --- | --- |
| `banana_wall.scope_record` | Approved Banana Wall success | Unchanged; no new effect |
| `mirror.origins` | Scope record v1 | `milestone.act3.restricted_research_opened`, `milestone.act3.mirror_origins_discovered` |
| `echo.correspondence` | MIRROR v1 | `milestone.act3.mirror_echo_relationship_established` |
| `neural.capabilities` | MIRROR v1 and ECHO correspondence v1 | `milestone.act3.neural_influence_evidence_discovered` |
| `assistant.mirror` | ECHO correspondence v1 | `assistant.act3.lineage_questioned` |
| `assistant.influence` | Capability note v1 | `assistant.act3.influence_questioned` |

All new records have `version.act3.<suffix>.v1`, deterministic catalogue ordering, source metadata, relative archive-index narrative timestamps and the dedicated registered protected-resource ID. The timestamps label indexing, not invented research dates. The three research records are preservable as `evidence.act3.<suffix>.v1`; Assistant questions are not. Snapshots retain exact blocks, links, source, narrative timestamp and `accessContext` metadata. Existing versions are byte-for-byte unchanged as decoded records, including prior scope evidence.

The MIRROR brief supplies the interpretation purpose; archived ECHO correspondence supplies the later response capability. The player reads these complementary sources independently before the capability note becomes available. The note separates original purpose, observed capability and unanswered questions about later use. Maya/ECHO-07 links return to existing recoverable sources. No mandatory preservation, timer, hidden score, additional puzzle or act transition is introduced. Assistant facts acknowledge questioning without granting cooperation. Autonomy, ASCENSION, Daniel's complicity and the wider conspiracy remain reserved.

## Delivery and recovery

Browser → Banana Wall → existing scope record → return to the Wall’s newly available MIRROR link (or Browser) → MIRROR brief → correspondence → capability note. Each new available title appears in Browser’s existing protected resource list. Five subordinate resource IDs (`resource.act3.<suffix>`) use the same approved Wall puzzle/access, plus their exact read prerequisites; they stay hidden until those prerequisites hold. This also protects current/original-version queries, rather than relying only on list filtering. Links and direct queries apply the same authorization. Assistant questions also appear in the existing Assistant app after their read prerequisites. The action label names the selected record instead of calling every document a scope record.

Old schema-2 saves with legitimate scope reads continue directly; no source rewrite, receipt replacement or migration is necessary. Read effects and preservation are idempotent. Leaving/reopening the OS apps or restarting retains progress and snapshots in the one story save. The new research can be read without internet access; no service, permission or backend was added.

## Validation

Run `bash scripts/check-act-three-part-one.sh` on a Swift-equipped machine. This extends the existing natural Acts 1–2 / approved Banana Wall journey through four optional-preservation paths. It checks early direct-read rejection, passive queries, sequential source visibility, Assistant knowledge gates, exact evidence/access metadata, milestones, unchanged cooperation, bounded access, repeated reads/preservation and exact file-store recovery. It runs a separate process to reopen the completed investigation. Existing catalogue validation covers duplicate IDs, versions, references and structured payloads.

Apple-platform manual check (requires Xcode 26+, iOS 18/26 simulator or device): follow the normal Acts 1–2 journey, solve the approved Wall, open scope, return to the resource and read each new record, preserve all three, ask both Assistant questions, reopen Evidence and restart. Confirm title-specific buttons, VoiceOver, scroll/readability, gated records and preserved source metadata. **Not run in this Linux environment**; no Apple SDK, simulator or device is available. Model tests are not device QA.

Actual validation on 2026-10-14: all 13 `scripts/check-*.sh` suites passed using Swift 6.2.4 in Swift 5 language mode with warnings treated as errors, in a network-disabled container with a read-only repository mount. The new suite completed all four natural paths, exact file-store reopen checkpoints and separate-process recovery. Debug/Release syntax parsing passed for all 51 app/native-test Swift files. Static Xcode project/resource checks, 90 local Markdown references, unchanged decoded earlier records and `git diff --check` passed. No Apple SDK typechecking, app build or native manual playthrough was performed.
