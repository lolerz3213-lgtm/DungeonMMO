# DungeonMMO Agent Operating Rules

These rules apply to autonomous or semi-autonomous development agents working
in this repository.

## Startup sequence

Before modifying source:

1. Read `docs/ai/CURRENT_STATE.md`.
2. Read `docs/ai/HANDOFF.md`.
3. Read `docs/ai/TEST_MATRIX.md`.
4. Read `docs/ai/AUTOMATION.md`.
5. Treat external `DungeonMMO Roadmap v1.31` as the canonical long-form
   roadmap. Tracked roadmap copies are historical unless deliberately updated.
6. Read the active approved design and implementation plan under
   `docs/superpowers/specs/` and `docs/superpowers/plans/`.
7. Inspect the current branch, HEAD, status, worktrees, remotes and
   `git diff --check` before changing source.

If repository state disagrees with the continuity documents, stop source
modification and reconcile the mismatch without destructive Git operations.

## Current accepted boundary

- Phase 1: ACCEPTED / functionally complete.
- Phase 2A: ACCEPTED / functionally complete.
- Phase 2B.A/B/C: ACCEPTED; Phase 2B functionally complete.
- Phase 2C.A Race + Character Identity Foundation: ACCEPTED / merged / pushed.
- Phase 2C.B Equipment + Trainer Architecture: ACCEPTED / merged / pushed.
- Phase 2C.B acceptance checkpoint:
  `fd0d73df70b97efc4b3fb241e2fc6e5061a3ed47`.
- Phase 2C.B gameplay merge:
  `0edc542fafccd4a05c13a0a8940718575e536ab2`.
- Canonical GitHub server `main` baseline before Phase 2C.C:
  `8587c1546aa1689b69606f860fb5c18a847de617`.
- Active engineering gate:
  Phase 2C.C - Equipment Effects + Combat Integration.

Do not reopen accepted architecture merely for cosmetic polish unless a real
regression or readability blocker is demonstrated.

## Git safety

- `main` is for deliberately accepted checkpoints.
- Do not develop directly on `main`.
- Phase 2C.C must use an isolated feature branch/worktree.
- Never reset hard, clean, force-push, rewrite history, or discard local work
  without explicit user approval.
- Installers and patches must not stage, commit, push, merge or publish
  automatically.
- Review exact diffs before deliberate commits.
- Commit, push, merge and Roblox publish remain explicit approval gates.

## Build and validation rules

- `default.project.json` builds the Dungeon Place.
- `base.project.json` builds the Starting Base Place.
- When shared/Core/Base/Dungeon composition changes, build both Places.
- Write validation `.rbxl` files only to timestamped TEMP paths.
- Never overwrite `DungeonMMO.rbxl`.
- Run `git diff --check` after source changes.
- Preserve relevant accepted regression families.
- New behaviour follows test-first RED -> GREEN development.
- A Rojo build does not prove Roblox runtime tests passed. Record fresh Studio
  output before claiming a runtime test family green.

## Roblox authority and environment rules

Combat results, progression, inventory, equipment, trainer authorization,
rewards, saves, handoff state and other value-bearing systems remain
server-authoritative.

Do not autonomously:

- publish PROD;
- publish TEST without explicit approval;
- enable live paid-revive Developer Products;
- spend Robux;
- mutate production DataStores;
- alter monetisation;
- bypass TEST/PROD environment guards.

TEST-only debug hooks must remain rejected or disabled in PROD.

## Phase 2C.C scope discipline

The approved 2C.C architecture extends the accepted six-slot Equipment state
through one server-authoritative equipment-stat resolver and the existing
combat runtime snapshot.

Representative equipment may prove only these working modifier families:

- physical-damage bonus;
- flat MaxHealth;
- critical-chance bonus.

The Dungeon must use the Equipment snapshot brought into the run. Equipment
remains non-mutable in Dungeon, and newly looted equipment must not affect the
active run. Persistent Equipment, not a client Tool or visual object, owns
weapon-family authority.

Do not pull into Phase 2C.C:

- Mage or Ranger implementation;
- advanced classes or advancement quests;
- crafting, trading or economy;
- unique item instances or random affixes;
- durability or enhancement;
- final gear-stat balance;
- large equipment-content production;
- Race Change / Robux systems;
- environment-art work.

The previous live legacy migration proof was waived only for a pre-player TEST
project. It is not a PASS. A real live migration proof remains mandatory before
any future release involving existing player profiles.

## Separate environment-art branch

`art/dungeon-environment-prototype` is a separate art worktree/branch.

Do not switch to it, merge it, reset it, clean it, apply its stash, copy its
work into gameplay, or otherwise modify it during Phase 2C.C.

## Handoff discipline

At every meaningful WIP checkpoint:

- update `docs/ai/CURRENT_STATE.md`;
- update `docs/ai/HANDOFF.md`;
- update `docs/ai/TEST_MATRIX.md` when evidence changes;
- record branch/checkpoint and exact next action;
- record known defects and unresolved evidence.

At an accepted gate, update the canonical roadmap through the established
roadmap maintenance workflow.

No critical implementation knowledge may exist only in an agent chat.
