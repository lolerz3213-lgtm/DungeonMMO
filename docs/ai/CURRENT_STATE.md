# DungeonMMO Current Engineering State

**State date:** 9 September 2026
**Canonical roadmap:** Version 1.23
**Current phase:** Phase 2C - Race/base-class implementation
**Current gate:** Phase 2C.A - Race + Character Identity Foundation
**Phase 2C.A status:** IN PROGRESS - LOCAL GREEN
**Gate 2B.C status:** ACCEPTED
**Phase 2B status:** FUNCTIONALLY COMPLETE

## Accepted baselines

- Phase 1 combat: ACCEPTED.
- Phase 2A core Base-to-Dungeon slice: ACCEPTED.
- Phase 2B.A Progression Foundation: ACCEPTED.
- Phase 2B.B Gameplay + Base Progression: ACCEPTED.
- Phase 2B.C Persistence + Published Acceptance: ACCEPTED.
- Accepted Phase 2B.C code checkpoint:
  `4a82d7486e7455f7597a777e862393c5bbb56cfb`.
- Gate 2B.C acceptance documentation checkpoint:
  `cf67bb32f9643beca7875b5f35e82b4bbe1114ce`.
- Accepted gameplay baseline:
  `main` and `origin/main` at
  `8be005ff1ef87712bff8fde01d313fd2569771ac`.
- Archived Gate 2B.C branch:
  `origin/wip/phase-2b-c-published-persistence` at `cf67bb3`.

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

## Gate 2B.C accepted evidence

Published TEST acceptance passed the complete Phase 2B persistence proof:

- Base -> Dungeon -> Base -> leave -> rejoin preserves the accepted progression state;
- attributes, AP/SP allocation, ranks, proficiency, trainer learning, Arc Slash
  knowledge/loadout and independent respec state persist;
- the first-clear bound Arc Slash Skill Book remains exactly-once and survives
  the return to Base;
- Arc Slash learning consumes the book and 3 SP atomically and auto-fills the
  first free active slot;
- active Dungeon encounters reject loadout swaps and cleared-room windows accept them;
- first death performs the automatic approximately three-second free revive and
  later deaths use the normal paid/spectator boundary;
- published sword presentation works;
- one combat HUD/runtime presentation is shown;
- one Captain/boss runtime is spawned;
- the client-only camera-parented shield presentation remains visible;
- the shield arm remains behind the shield during Block and Shield Bash;
- swept-volume dodge clearance prevents the previously observed
  under-monster/floor fall-through regression.

Detailed acceptance evidence is stored in
`docs/testing/phase2b-gate-c-acceptance-record.md`.

## Separate environment-art branch

`art/dungeon-environment-prototype` is not the gameplay branch. Its preserved
art-side work/stash remains separate. Do not merge or pop that work into the
race/base-class gameplay branch.

## Exact next engineering action

Run Task 13 - Published TEST persistence acceptance and Phase 2C.A gate
close-out from the reviewed local-green candidate.

Before publishing:

1. verify the candidate commit and clean worktree;
2. verify `DungeonMMOEnvironment = TEST`;
3. verify Starting Base Place ID `134132328219009`;
4. verify Test Dungeon Place ID `117293035754309`;
5. verify live paid revives remain disabled;
6. verify no PROD DataStore namespace is selected;
7. verify no monetisation changes are present.

Published TEST must then prove:

- a genuinely new Human Fighter through
  Base -> Dungeon -> Base -> leave -> rejoin;
- a separate genuinely new Elf Fighter through
  Base -> Dungeon -> Base -> leave -> rejoin;
- Elf ears persist through Dungeon, return and rejoin;
- one accepted Phase 2B legacy character performs exactly one race migration;
- legacy earned allocation is translated using the approved neutral-5 rule;
- Level/XP/Gold/AP/SP/skills/ranks/proficiency/loadout/rewards/respec state is
  preserved without duplication;
- a second race-selection attempt is rejected without mutation;
- sensitive published combat/presentation/revive/loadout behaviour remains
  correct.

Do not mark Phase 2C.A ACCEPTED yet.

Do not update the canonical roadmap yet.

Do not merge to `main` until the published evidence has passed and explicit user
acceptance has been received.

## Phase 2C.A local-green checkpoint - 9 September 2026

**Status:** IN PROGRESS - LOCAL GREEN

**Branch:** `wip/phase-2c-a-race-identity`

**Latest tested gameplay commit:**

`c7ae49faf7c2449ca3bfd00d2422c16c202ca18b`

`feat: add persistent elf race presentation`

### Fresh local build evidence

Both approved Rojo compositions built successfully.

Base build:

`%TEMP%\DungeonMMO_Phase2C_A_Base_FULL.rbxl`

Dungeon build:

`%TEMP%\DungeonMMO_Phase2C_A_Dungeon_FULL.rbxl`

The Task 12 build commands completed successfully and `git diff --check`
reported no whitespace error before the regression run.

### Fresh Base Studio evidence

Observed fresh automated Base results include:

- Phase 2C.A Race Definitions - PASS: 35 assertions;
- Profile Schema/Migration - PASS: 43 assertions;
- Phase 2C.A Profile Migration - PASS: 38 assertions;
- Phase 2C.A Identity Service - PASS: 58 assertions;
- Attribute Config - PASS: 14 assertions;
- Attribute Service - PASS: 30 assertions;
- Progression Service - PASS: 9 assertions;
- Phase 2B Progression Service - PASS: 42 assertions;
- Progression Snapshot Builder - PASS: 37 assertions;
- Base Progression Controller - PASS: 25 assertions;
- Character Combat Stats - PASS: 32 assertions;
- Race Presentation Service - PASS: 51 assertions;
- accepted Core/Base regression families remained green.

Observed fresh manual Base behaviour:

- unresolved identity opens mandatory race selection;
- trainer/progression access is unavailable before identity completion;
- Dungeon entry is blocked before identity completion;
- Human -> Fighter completes successfully;
- Human baseline is STR 5 / DEX 4 / VIT 6 / INT 5 / SPI 5;
- Human Resolve is applied;
- Human Fighter receives Shield Bash + Mend;
- Elf -> Fighter completes successfully;
- Elf baseline is STR 5 / DEX 6 / VIT 4 / INT 5 / SPI 5;
- Elven Grace is applied;
- Elf Fighter receives Shield Bash + Mend;
- Elf ears appear automatically;
- Elf ears return after Reset Character;
- repeated race presentation does not create duplicate ears;
- existing Base progression works once identity is Complete.

### Fresh Dungeon Studio evidence

Observed fresh automated Dungeon results include:

- Character Combat Stats - PASS: 32 assertions;
- Phase 2C.A Identity Service - PASS: 58 assertions;
- Phase 2C.A Race Definitions - PASS: 35 assertions;
- Phase 2C.A Profile Migration - PASS: 38 assertions;
- Race Presentation Service - PASS: 51 assertions;
- Damage Service - PASS: 15 assertions;
- Basic Attack Timing Rules - PASS: 25 assertions;
- Critical Hit Rules - PASS: 10 assertions;
- Shield Bash Integration - PASS: 17 assertions;
- Arc Slash Integration - PASS: 10 assertions;
- Mend Service - PASS: 9 assertions;
- Defensive Combat Integration - PASS: 42 assertions;
- Dodge Direction - PASS: 45 assertions;
- Dodge Swept Clearance - PASS: 8 assertions;
- accepted combat/state/block/parry/skill families remained green;
- accepted Dungeon/Phase 2A/Phase 2B families remained green.

Observed fresh manual Dungeon behaviour:

- direct Dungeon Studio logged the intended Studio-only Human/Fighter bootstrap;
- Dungeon admission succeeded;
- normal Slash1 -> Slash2 -> Finisher sword sequence worked;
- attack buffering worked;
- Block/parry worked;
- Dodge worked;
- Shield Bash worked;
- Mend worked;
- Arc Slash worked;
- no red runtime exception was observed.

### Known presentation note

The current Elf ears are accepted as functional first-pass Phase 2C.A
presentation geometry.

Their final visual modelling can be refined later without changing identity,
persistence, server authority, Base/Dungeon application or respawn behaviour.

### Safety boundary

No PROD path was used.

No Robux spend occurred.

Live paid revives were not enabled.

Nothing was pushed, merged or published during Task 12.

The separate `art/dungeon-environment-prototype` branch/stash was not touched.
