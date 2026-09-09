# DungeonMMO Development Handoff

**Date:** 9 September 2026

## Current accepted gameplay boundary

- Phase 1 combat: ACCEPTED.
- Phase 2A - Core Base-to-Dungeon slice: ACCEPTED.
- Phase 2B.A - Progression Foundation: ACCEPTED.
- Phase 2B.B - Gameplay + Base Progression: ACCEPTED.
- Phase 2B.C - Persistence + Published Acceptance: ACCEPTED.
- Phase 2B: FUNCTIONALLY COMPLETE.
- Accepted Gate 2B.C code checkpoint:
  `4a82d7486e7455f7597a777e862393c5bbb56cfb`.
- Accepted merged gameplay baseline:
  `main` / `origin/main` at
  `8be005ff1ef87712bff8fde01d313fd2569771ac`.
- Archived Gate 2B.C branch:
  `origin/wip/phase-2b-c-published-persistence` at
  `cf67bb32f9643beca7875b5f35e82b4bbe1114ce`.
- Canonical roadmap:
  `docs/roadmap/DungeonMMO_Roadmap_v1_23.docx`.

## Gate 2B.C published acceptance

The user completed and accepted the published TEST Base -> Dungeon -> Base ->
leave -> rejoin proof. The complete Phase 2B progression state persisted across
Places and reconnect without duplicate reward or point-minting regressions.

Targeted published regressions are also closed:

- duplicate HUD/runtime presentation: fixed;
- published sword attack presentation: fixed;
- duplicate Captain/boss runtime: fixed;
- shield disappearing in published play: fixed through the independent
  camera-parented client visual;
- left arm appearing in front of the shield during Block/Shield Bash: fixed;
- dodge pushing the player under a monster/floor: fixed with swept-volume
  clearance rules.

The Gate C acceptance record is
`docs/testing/phase2b-gate-c-acceptance-record.md`.

## Separate art work

`art/dungeon-environment-prototype` remains separate. Do not do gameplay work
there, merge it into the next race/class slice, or pop the preserved art-side
stash onto the gameplay branch.

## Exact next action

Phase 2C.A is ACCEPTED.

Next:

- generate Roadmap v1.27 with the exact final acceptance checkpoint;
- merge the accepted Phase 2C.A branch to `main` only after explicit approval;
- verify `main` ancestry and clean repository state;
- push only after explicit approval;
- begin Phase 2C.B - Equipment + Trainer Architecture only from the deliberate
  accepted baseline.

Carry forward:

- live legacy Phase 2B migration proof was waived only for this pre-player TEST
  gate and must be revalidated before a release involving real existing
  profiles;
- the Skill Book is correctly awarded to Inventory but omitted from the Dungeon
  Completed summary; fix that presentation issue in the next patch.

The separate `art/dungeon-environment-prototype` branch remains untouched.

## Phase 2C.A local-green engineering checkpoint - 9 September 2026

Phase 2C.A Race + Character Identity Foundation is currently:

**IN PROGRESS - LOCAL GREEN**

Local gameplay branch:

`wip/phase-2c-a-race-identity`

Latest tested gameplay commit:

`c7ae49faf7c2449ca3bfd00d2422c16c202ca18b`

`feat: add persistent elf race presentation`

### Implemented in Phase 2C.A

The branch now contains:

- data-driven Human and Elf race definitions;
- Fighter as the only selectable Phase 2C.A base class;
- schema-v4 persistent character identity;
- new-vs-legacy Phase 2B migration handling;
- one-time legacy race selection;
- exact legacy attribute translation;
- exactly-once Fighter starter grants;
- racial attribute baselines;
- racial-baseline-aware AP spending and respec;
- Level 20 progression cap;
- 19 AP and 19 SP entitlement at Level 20;
- mandatory Base race then Fighter selection UI;
- server-side incomplete-identity progression gates;
- server-side incomplete-identity Dungeon-entry/admission gates;
- race-aware MaxHealth;
- race-aware critical chance;
- race-aware critical damage;
- server-owned basic-attack rate;
- server-authoritative basic-melee critical hits;
- race-adjusted basic attack timing;
- synchronized server/client attack timing and presentation;
- persistent server-replicated Elf race presentation;
- Base/Dungeon/respawn presentation application.

### Task 12 build outputs

Base:

`%TEMP%\DungeonMMO_Phase2C_A_Base_FULL.rbxl`

Dungeon:

`%TEMP%\DungeonMMO_Phase2C_A_Dungeon_FULL.rbxl`

Both Rojo builds completed successfully.

### Fresh Base evidence

Observed headline automated results:

- Race Definitions - PASS: 35 assertions;
- Profile Schema/Migration - PASS: 43 assertions;
- Phase 2C.A Profile Migration - PASS: 38 assertions;
- Identity Service - PASS: 58 assertions;
- Attribute Config - PASS: 14 assertions;
- Attribute Service - PASS: 30 assertions;
- Progression Service - PASS: 9 assertions;
- Phase 2B Progression Service - PASS: 42 assertions;
- Progression Snapshot Builder - PASS: 37 assertions;
- Base Progression Controller - PASS: 25 assertions;
- Character Combat Stats - PASS: 32 assertions;
- Race Presentation Service - PASS: 51 assertions.

Manual Base validation passed:

- mandatory unresolved race selection;
- incomplete-identity trainer/progression restriction;
- incomplete-identity Dungeon-entry rejection;
- Human -> Fighter;
- Human baseline 5/4/6/5/5;
- Human Resolve;
- Shield Bash + Mend starter kit;
- Elf -> Fighter;
- Elf baseline 5/6/4/5/5;
- Elven Grace;
- Elf ears;
- Elf ears after Reset Character;
- no duplicate ears;
- normal Base progression after identity completion.

### Fresh Dungeon evidence

Observed headline automated results:

- Character Combat Stats - PASS: 32 assertions;
- Identity Service - PASS: 58 assertions;
- Race Presentation Service - PASS: 51 assertions;
- Damage Service - PASS: 15 assertions;
- Basic Attack Timing Rules - PASS: 25 assertions;
- Critical Hit Rules - PASS: 10 assertions;
- Shield Bash Integration - PASS: 17 assertions;
- Arc Slash Integration - PASS: 10 assertions;
- Mend Service - PASS: 9 assertions;
- Defensive Combat Integration - PASS: 42 assertions;
- Dodge Direction - PASS: 45 assertions;
- Dodge Swept Clearance - PASS: 8 assertions.

Manual Dungeon validation passed:

- deliberate Studio-only Human/Fighter bootstrap;
- admission;
- normal three-hit sword combo;
- attack buffering;
- Block/parry;
- Dodge;
- Shield Bash;
- Mend;
- Arc Slash;
- no red runtime exception observed.

### Known non-blocking presentation note

Elf ears are accepted as functional first-pass geometry for this gate.

Their visual shape can be refined later without changing the Phase 2C.A
identity/persistence architecture.

### Still outstanding

Phase 2C.A is NOT accepted yet.

Task 13 published TEST must still prove:

- genuinely new Human persistence;
- genuinely new Elf persistence;
- published Elf-ear persistence;
- one-time legacy Phase 2B migration;
- preservation of legacy progression;
- Base -> Dungeon -> Base -> leave -> rejoin;
- idempotency and duplicate protection;
- sensitive published gameplay regressions.

No PROD, Robux or live paid-revive path was used in Task 12.

## Phase 2C.A published TEST gate - 9 September 2026

Phase 2C.A is **ACCEPTED**.

The project owner explicitly accepted the gate after reviewing the complete
Task 13 evidence.

### Published TEST results

New Elf Fighter:

- Level 1;
- 5/6/4/5/5;
- Elven Grace;
- Shield Bash + Mend;
- ears in Base and Dungeon;
- Base -> Dungeon -> Base;
- leave -> rejoin;
- identity, stats, passive, ears, skills and progression persisted.

New Human Fighter:

- Level 1;
- 5/4/6/5/5;
- Human Resolve;
- Shield Bash + Mend;
- Base -> Dungeon -> Base;
- leave -> rejoin;
- identity, stats, passive, skills and progression persisted.

Sensitive published Dungeon regression passed:

- one combat HUD/runtime;
- sword presentation;
- one Marauder Captain;
- shield visibility;
- shield-arm position;
- swept Dodge clearance;
- first free revive;
- later defeated/paid-revive-disabled path;
- Arc Slash inventory, learning, loadout and rejoin persistence.

### Accepted live-migration qualification

The project owner waived the live published Phase 2B legacy migration proof for
this gate because the project is still pre-player and the current TEST profiles
contain only developer/test data.

The waiver applies only to this pre-player gate.

Automated migration coverage remains green.

A live migration proof is still required before any release that must migrate
real existing player profiles.

### Deferred patch item

The Arc Slash Skill Book is awarded correctly and appears in Inventory but is
not listed in the Dungeon Completed reward summary.

Fix the completion-summary presentation in the next patch.

### Explicit acceptance

Project-owner statement:

`I accept Phase 2C.A`

Phase 2C.A - Race + Character Identity Foundation is ACCEPTED.
