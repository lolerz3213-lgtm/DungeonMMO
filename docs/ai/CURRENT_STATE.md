# DungeonMMO Current Engineering State

**State date:** 9 September 2026
**Canonical roadmap:** Version 1.23
**Current phase:** Phase 2C - Race/base-class implementation
**Current gate:** Phase 2C.A - Race + Character Identity Foundation
**Phase 2C.A status:** ACCEPTED
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

Phase 2C.A is ACCEPTED.

The next gameplay architecture gate is:

**Phase 2C.B - Equipment + Trainer Architecture**

Before Phase 2C.B implementation:

- generate canonical Roadmap v1.27 using the final Phase 2C.A acceptance
  checkpoint;
- merge the accepted Phase 2C.A branch to `main` only after explicit approval;
- verify the resulting `main` ancestry and clean repository state;
- push only after explicit approval;
- keep the Dungeon Completed Skill Book summary defect in the next patch;
- require a live legacy-profile migration proof before any future release with
  real existing player data;
- keep `art/dungeon-environment-prototype` fully isolated from gameplay work.

Do not begin Phase 2C.B from an ambiguous or unmerged baseline.

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

## Phase 2C.A published TEST evidence - 9 September 2026

**Status:** ACCEPTED

Task 13 published TEST evidence is complete and was explicitly accepted by the
project owner on 9 September 2026.

### Published targets

- Universe: `10765241947`
- Starting Base: `134132328219009`
- Dungeon: `117293035754309`
- Environment: `TEST`
- live paid revives remained disabled;
- PROD DataStores were not used;
- no Robux was spent;
- no monetisation change was made.

### New Elf

Published TEST passed:

- Elf -> Fighter;
- Level 1;
- baseline 5/6/4/5/5;
- Elven Grace;
- Shield Bash + Mend;
- permanent ears;
- Base -> Dungeon;
- published combat;
- Dungeon -> Base;
- leave -> rejoin;
- race/class/stats/passive/ears/skills/progression persistence.

### New Human

Published TEST passed:

- Human -> Fighter;
- Level 1;
- baseline 5/4/6/5/5;
- Human Resolve;
- Shield Bash + Mend;
- Base -> Dungeon;
- published combat;
- Dungeon -> Base;
- leave -> rejoin;
- race/class/stats/passive/skills/progression persistence.

### Sensitive published regressions

Published TEST passed:

- one combat HUD/runtime presentation;
- sword presentation;
- one Marauder Captain;
- camera/view shield presentation;
- shield arm position during Block and Shield Bash;
- swept Dodge clearance;
- first free revive;
- later defeated / paid-revive-disabled boundary;
- Arc Slash book inventory grant;
- Arc Slash learning;
- Arc Slash loadout;
- Arc Slash persistence after rejoin.

### Accepted legacy live-migration waiver

The project owner deliberately waived the published live Phase 2B
legacy-character migration proof for this pre-player TEST gate.

This waiver is limited to the current developer-only environment.

Automated migration coverage remains green.

A live migration proof remains mandatory before any future release where real
existing player profiles require migration.

### Deferred next-patch issue

The Arc Slash Skill Book is correctly awarded and appears in Inventory but is
omitted from the Dungeon Completed reward summary.

Reward ownership and persistence passed.

The completion-summary presentation defect is explicitly deferred to the next
patch.

### Acceptance

The project owner explicitly stated:

`I accept Phase 2C.A`

Phase 2C.A - Race + Character Identity Foundation is ACCEPTED.
