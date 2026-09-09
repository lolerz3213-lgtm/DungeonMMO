# DungeonMMO Agent Operating Rules

These rules apply to autonomous or semi-autonomous development agents working
in this repository.

## Startup sequence

Before modifying source:

1. Read `docs/ai/CURRENT_STATE.md`.
2. Read `docs/ai/HANDOFF.md`.
3. Read `docs/ai/TEST_MATRIX.md`.
4. Read `docs/ai/AUTOMATION.md`.
5. Treat external `DungeonMMO_Roadmap_v1_30.docx` as the current canonical
   long-form roadmap. Tracked roadmap copies in this repository are historical
   snapshots unless deliberately refreshed.
6. Read the active approved design and implementation plan under
   `docs/superpowers/specs/` and `docs/superpowers/plans/`.
7. Inspect:
   - `git branch --show-current`
   - `git log -1 --oneline`
   - `git status --short`
   - `git diff --check`

If these disagree with `CURRENT_STATE.md`, stop source modification and report
the mismatch. Do not guess which state is correct.

## Current accepted boundary

- Phase 1 combat: ACCEPTED.
- Phase 2A: ACCEPTED.
- Phase 2B.A: ACCEPTED.
- Phase 2B.B: ACCEPTED.
- Phase 2B.C: ACCEPTED.
- Phase 2B: FUNCTIONALLY COMPLETE.
- Phase 2C.A - Race + Character Identity Foundation: ACCEPTED, MERGED, PUSHED.
- Formal Phase 2C.A acceptance checkpoint:
  `ad3685be4a507f00e0b08bf8d948a41ecfa80b47`.
- Current accepted `main` / `origin/main` baseline:
  `19f8c31284da80dc87cf5d44560d366e48427888`.
- Active engineering gate:
  Phase 2C.B - Equipment + Trainer Architecture.

Do not reopen accepted architecture merely for cosmetic polish unless a real
regression or readability blocker is demonstrated.

## Git safety

- `main` is for deliberately accepted checkpoints.
- Do not develop directly on `main`.
- Phase 2C.B must use an isolated worktree/branch.
- Never run `git reset --hard`, `git clean`, destructive checkout, force push,
  history rewrite, or any operation that discards local work without explicit
  user approval.
- Installers and patches must not stage, commit, push, merge or publish
  automatically.
- Review exact diffs before deliberate commits.
- Merge and push remain separate explicit approvals.

## Build and validation rules

- `default.project.json` builds the Dungeon Place.
- `base.project.json` builds the Starting Base Place.
- When shared/Core/Base/Dungeon composition changes, build both Places.
- Write validation `.rbxl` files only to TEMP/timestamped paths.
- Never overwrite `DungeonMMO.rbxl`.
- Run `git diff --check` after source changes.
- Preserve relevant accepted regression families.
- New behaviour follows RED -> GREEN test-first development.
- A build succeeding does not prove Roblox runtime tests passed; record actual
  Studio output before claiming a test family green.

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

## Phase 2C.B scope discipline

The approved 2C.B design establishes:

- six equipment slots:
  `Weapon`, `OffHand`, `Helmet`, `Body`, `Gloves`, `Boots`;
- schema-v5 persistent equipment;
- Base-only server-authoritative equip/unequip;
- race/base-class/class equipment eligibility;
- data-driven trainer catalogues;
- Human/Elf Fighter trainer proof;
- functional equipment/trainer UI;
- targeted Dungeon Completed Arc Slash Skill Book summary fix.

Do not pull in:

- advanced classes or advancement quests;
- level/attribute equipment requirements;
- procedural/unique item instances, durability or random affixes;
- full gear-stat balancing;
- trading/economy;
- race-change monetisation;
- large equipment-content production;
- replacement of the accepted prototype combat sword/shield presentation.

The pre-player live legacy Phase 2B migration proof waiver is NOT permanent.
A live migration proof is required before any future release involving real
existing player profiles.

## Separate environment-art branch

`art/dungeon-environment-prototype` is a separate art worktree/branch.
Do not switch to it, merge it, reset it, clean it, apply its stash, or copy its
changes into Phase 2C.B gameplay work.

## Handoff discipline

At every meaningful WIP checkpoint:

- update `docs/ai/CURRENT_STATE.md`;
- update `docs/ai/HANDOFF.md`;
- update `docs/ai/TEST_MATRIX.md` when evidence changes;
- record branch/checkpoint;
- record known defects and exact next action.

At an accepted gate, update the canonical roadmap through the established
roadmap maintenance workflow.

No critical implementation knowledge may exist only in an agent chat.
