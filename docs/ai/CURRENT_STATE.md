# DungeonMMO Current Engineering State

**State date:** 6 September 2026
**Canonical roadmap:** Version 1.22
**Current phase:** Phase 2 - Vertical Slice
**Current gate:** Phase 2B.C - Persistence + Published Acceptance
**Gate 2B.B status:** ACCEPTED
**Gate 2B.C status:** IN PROGRESS

## Accepted baselines

- Phase 1 combat: ACCEPTED.
- Phase 2A core Base-to-Dungeon slice: ACCEPTED.
- Phase 2B.A Progression Foundation: ACCEPTED.
- Phase 2B.B Gameplay + Base Progression: ACCEPTED.
- Accepted Gate 2B.B checkpoint:
  `ac9546c73d3f2f57221ae71b2f1e7a6ebcd35137`.
- `main`, `origin/main`, and the frozen
  `wip/phase-2b-b-pre-ai-continuity` branch resolve to that accepted checkpoint.
- Active Gate 2B.C branch:
  `wip/phase-2b-c-published-persistence`, forked exactly from `ac9546c`.

## Experience composition

- Local project:
  `C:\Users\Remko\Documents\Roblox\DungeonMMO`
- `default.project.json` = Test Dungeon.
- `base.project.json` = Starting Base.
- Universe ID: `10765241947`.
- Starting Base Place ID: `134132328219009`.
- Test Dungeon Place ID: `117293035754309`.
- Published environment: TEST.
- Live paid revives: disabled.

## Gate 2B.B accepted evidence

### Base combined acceptance

Fresh Base Studio validation passed:

- Profile HUD immediately matched the authoritative Level 10 mutation.
- HUD and Progression Trainer agreed at Level 10 with AP/SP entitlement 9/9.
- Attribute multi-point preview cancelled without saving.
- Attribute Confirm committed atomically and reduced available AP correctly.
- Shield Bash and Mend proficiency thresholds enabled the expected Rank 2
  purchases and SP costs.
- Six active slots preserved intentional empty gaps.
- Selected-skill placement into later slots, moves, replacement, uniqueness,
  selection clearing and no-op slot clicks without selection all worked.
- Attribute TEST respec restored entitlement and incremented only its counter.
- Skill TEST respec refunded allocated SP while preserving starter knowledge and
  saved proficiency and incremented only its counter.
- No red runtime errors were reported.

### Six-slot gap root cause and fix

The authoritative profile was correct, but sparse numeric RemoteEvent arrays
lost entries after an intentional nil gap. Shared `LoadoutSnapshot.encode`
produces six dense wire entries and represents empty slots as `false`.
Persistent profiles and service mutations remain sparse. Base and Dungeon
snapshot builders use the shared encoder.

### Dungeon combined acceptance

Fresh Dungeon Studio validation passed:

- relevant Gate 2B.B and accepted regression families reported PASS;
- no red runtime errors were reported;
- first death automatically consumed the free revive, entered forced Reviving,
  and returned after approximately three seconds at the latest checkpoint with
  restored HP/Stamina;
- second death returned to the normal defeated flow instead of another
  automatic free revive;
- Marauder Captain first-clear reward succeeded;
- a fresh progression snapshot reported:
  `ArcSlash BookOwned = true` and `ArcSlash FirstClear = true`.

## Separate environment-art branch

`art/dungeon-environment-prototype` is not the gameplay branch. Before returning
to gameplay, its uncommitted `docs/ai/TEST_MATRIX.md` change was preserved in a
timestamped recovery copy and Git stash. Do not pop that stash onto the gameplay
branch and do not mix environment-art work into Gate 2B.C.

## Exact next engineering action

1. RED was verified in a fresh Base build: the new snapshot regression failed
   specifically because `ProgressionSnapshotBuilder` did not yet exist.
2. Shared snapshot GREEN is verified in fresh Base and Dungeon builds:
   `ProgressionSnapshotBuilderTest` reports PASS with 22 assertions in both.
   The first full Dungeon run exposed two pre-existing regression-test defects:
   a stale wipe-deadline expectation and ambiguous Luau callback syntax. The
   test-only repair is now verified in a fresh Dungeon build:
   `Phase2A Failure Path Tests` PASS with 25 assertions and
   `Automatic Free Revive Tests` PASS with 10 assertions, with no red
   runtime/test errors reported.
3. Build both Places and run the complete Studio regression suite.
4. Reconfirm TEST environment, Base Dungeon Place ID, both forced teleport
   failure switches false/absent, and live paid revives/progression Robux
   products disabled.
5. Run the published TEST Base -> Dungeon -> Base -> leave -> rejoin proof for
   the complete Phase 2B progression state, reconnect/idempotency and duplicate
   protection.
6. Mark Phase 2B functionally complete only after the user accepts Gate 2B.C.
