# DungeonMMO Development Handoff

**Date:** 6 September 2026

## Current accepted gameplay boundary

- Gate 2B.B - Gameplay + Base Progression: ACCEPTED and frozen.
- Gate 2B.C - Persistence + Published Acceptance: IN PROGRESS.
- Active gameplay branch: `wip/phase-2b-c-published-persistence`.
- Accepted Gate 2B.B checkpoint:
  `ac9546c73d3f2f57221ae71b2f1e7a6ebcd35137`.
- `main`, `origin/main`, and the frozen 2B.B branch resolve to `ac9546c`.
- Canonical roadmap: `docs/roadmap/DungeonMMO_Roadmap_v1_22.docx`.

Gate 2B.C starts from the exact accepted 2B.B checkpoint. The published TEST
checklist is now present. RED was verified in a fresh Base build: the new
`ProgressionSnapshotBuilderTest` failed specifically because the shared builder
was absent. The GREEN candidate adds that shared sanitized builder and routes
both Base and Dungeon through it. Fresh Base and Dungeon runs now report
`Progression Snapshot Builder Tests` PASS with 22 assertions. The Dungeon run
also surfaced two pre-existing test defects: `Phase2AFailurePathTest` used a
stale 1058/1059 wipe boundary despite the configured 30-second window, and
`AutomaticFreeReviveTest` contained ambiguous leading-parenthesis callback
syntax. The test-only repair is now verified in a fresh Dungeon build:
`Phase2A Failure Path Tests` PASS with 25 assertions and
`Automatic Free Revive Tests` PASS with 10 assertions, with no red errors
reported.

## Gate 2B.B evidence

### Resolved Profile HUD defect

The stale HUD path was fixed at the authoritative mutation boundary. Successful
level/XP mutations notify the Place snapshot publisher, so the top-left Profile
HUD updates immediately; opening the Progression Trainer is not a refresh
mechanism. Fresh Base Studio verification passed Level 10 HUD/trainer agreement
at AP/SP entitlement 9/9 with no red runtime error reported.

### Resolved six-slot gap defect

Root cause: sparse numeric arrays sent through RemoteEvent lost later entries
after an intentional nil slot. `ReplicatedStorage/Core/Shared/LoadoutSnapshot`
now encodes six dense wire slots using `false` for empty entries. Persistent
profile/loadout state remains sparse. Base and Dungeon snapshots use the shared
encoder.

Fresh Base visual acceptance passed:

- Slot 1 occupied / Slot 2 empty / later-slot placement;
- all six target slots;
- moves and replacement;
- no duplicate selected skill;
- intentional gaps preserved;
- slot click with no selected skill is a no-op;
- selection clears after successful placement;
- authoritative UI refresh is immediate.

The Base combined gate also passed Attribute preview/commit, proficiency-gated
rank purchases and both independent TEST respec flows.

### Dungeon acceptance

Fresh Dungeon validation passed the relevant Gate 2B.B and accepted regression
families with no red runtime errors reported. Manual gameplay confirmed:

- first death -> forced automatic three-second free revive at latest checkpoint;
- second death -> normal defeated/simulated paid-revive flow;
- Captain first clear -> one-time bound Arc Slash Skill Book;
- fresh progression snapshot -> `BookOwned=true`, `ArcSlashFirstClear=true`.

## Separate art work

`art/dungeon-environment-prototype` is separate. Do not do gameplay work there,
merge it into the current gate, or pop the preserved art-side stash onto the
gameplay branch.

## Exact next action

Gate 2B.C / Task 9 is active:

1. add the published TEST progression checklist;
2. RED/GREEN one shared sanitized progression-snapshot builder used by Base and
   Dungeon;
3. rerun both Place regression builds and fresh Studio regressions;
4. run the real private TEST Base -> Dungeon -> Base -> leave -> rejoin proof;
5. verify the full progression state, reconnect/idempotency and duplicate
   protection survive;
6. freeze Phase 2B only after user acceptance.

Do not begin real race/base-class definitions or class-specific trainer
catalogues before Gate 2B.C is accepted.
