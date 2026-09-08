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

Execute Phase 2C.A Task 13 only.

1. Verify the reviewed local-green candidate and clean Git state.
2. Verify `DungeonMMOEnvironment = TEST`.
3. Verify Starting Base Place ID `134132328219009`.
4. Verify Test Dungeon Place ID `117293035754309`.
5. Verify live paid revives remain disabled.
6. Verify no PROD DataStore or monetisation path is active.
7. Deliberately publish only the reviewed TEST candidate after explicit approval.
8. Prove one genuinely new Human Fighter through
   Base -> Dungeon -> Base -> leave -> rejoin.
9. Prove a separate genuinely new Elf Fighter through the same path.
10. Verify Elf ears persist in Dungeon, after return and after rejoin.
11. Prove one accepted Phase 2B legacy character enters LegacyRaceSelection.
12. Record its pre-choice progression state.
13. Choose one race and verify exact neutral-5 earned-allocation translation.
14. Verify all accepted Phase 2B progression state is otherwise unchanged.
15. Attempt a second race choice and verify rejection with no mutation.
16. Run Base -> Dungeon -> Base -> leave -> rejoin for the migrated character.
17. Verify no remigration, duplicate reward or AP/SP minting.
18. Recheck sensitive published combat/presentation/revive/loadout behaviour.
19. Write the Phase 2C.A acceptance record only from observed evidence.
20. Obtain explicit user acceptance before marking Phase 2C.A ACCEPTED.
21. Only after acceptance update state/roadmap and deliberately merge.

Keep `art/dungeon-environment-prototype` completely separate.

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
