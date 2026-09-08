# DungeonMMO Test and Acceptance Matrix

This file records accepted evidence and current gate status. It is not a
replacement for fresh test output when claiming a new result.

## Phase 1 - Combat prototype

**Roadmap status:** ACCEPTED

Previously accepted runtime coverage includes basic attack/swept melee,
blocking, parry, Guard Break, dodge invulnerability, Shield Bash, Mend channel
and cancellation, four-Marauder pressure, death/respawn lifecycle,
controller/mobile emulation and approximately 150 ms simulated round-trip
latency diagnostics.

Presentation remains placeholder quality and is intentionally deferred.

## Phase 2A - Core Base-to-Dungeon slice

**Roadmap status:** ACCEPTED

Accepted coverage includes separate Base/Dungeon builds, central profile/save,
DEV/TEST/PROD namespaces, leases/handoff, 1-4-player session contract,
reconnect/reconstruction, monster XP/Gold, room-start checkpoints, revive and
spectating/wipe flows, Marauder Captain, immutable completion eligibility,
exactly-once rewards, save-before-return, Base/Dungeon UI, reserved-server
teleport, Base -> Dungeon -> Base persistence, timed/manual return, abandon and
deliberate TEST teleport-failure recovery.

Live paid-revive activation remains disabled.

## Phase 2B.A - Progression Foundation

**Roadmap status:** ACCEPTED
**Accepted Git checkpoint:** `24dee751b87d831abe22cd046dd3b9934c566a56`

Accepted PASS families include profile migration, Level/AP/SP entitlement,
Attribute Config/Service, Skill Progression, Loadout, Proficiency, Progression
Damage, Mend Progression, Dungeon Progression Bridge and existing Phase 1/2A
regression families.

## Phase 2B.B - Gameplay + Base Progression

**Status:** ACCEPTED
**Accepted Git checkpoint:**
`ac9546c73d3f2f57221ae71b2f1e7a6ebcd35137`

### Base combined acceptance

- [x] Level 10 Profile HUD/trainer agreement.
- [x] Attribute preview/cancel and atomic spend flow.
- [x] proficiency/rank purchase flow.
- [x] six-slot rearrangement including intentional empty gaps.
- [x] exact later-slot placement, moves, replacement and uniqueness.
- [x] no-op slot clicks without selection and selection clearing after success.
- [x] Attribute TEST respec.
- [x] Skill TEST respec preserving proficiency/knowledge.
- [x] no red runtime errors reported.

### Dungeon combined acceptance

- [x] Arc Slash integration/PASS family.
- [x] first-clear Arc Slash reward/PASS family.
- [x] automatic-free-revive/PASS family.
- [x] first death performs forced three-second free revive.
- [x] second death uses normal defeated flow.
- [x] Captain first-clear awards the bound Arc Slash Skill Book.
- [x] fresh progression snapshot reports `BookOwned=true`.
- [x] fresh progression snapshot reports `ArcSlashFirstClear=true`.
- [x] relevant Phase 1/2A/2B.A regression families remain green.
- [x] no red runtime errors reported.

### Six-slot regression cause/fix

Sparse numeric RemoteEvent arrays lost later entries after an intentional nil
gap. Shared `LoadoutSnapshot.encode` produces six dense wire entries and uses
`false` for empty slots; persistent profile/loadout state remains sparse.

## Phase 2B.C - Persistence + Published Acceptance

**Status:** ACCEPTED
**Accepted code checkpoint:**
`4a82d7486e7455f7597a777e862393c5bbb56cfb`
**Merged accepted main:**
`8be005ff1ef87712bff8fde01d313fd2569771ac`

Published TEST acceptance confirmed:

- [x] fresh Level 1 profile = 5/5/5/5/5, 0 AP/SP, Mend R1 + Shield Bash R1;
- [x] each level gain grants exactly +1 AP/+1 SP;
- [x] Strength changes basic sword damage;
- [x] Vitality changes MaxHealth;
- [x] Spirit changes Mend;
- [x] Mend/Shield Bash proficiency caps at the next threshold;
- [x] DEV/TEST proficiency mutation changes proficiency only;
- [x] trainer rank purchase persists;
- [x] first Captain clear grants exactly one bound Arc Slash book;
- [x] return to Base preserves the book;
- [x] trainer consumes the book + 3 SP atomically and learns Arc Slash;
- [x] Arc Slash auto-fills the first free slot;
- [x] Character -> Skills swaps in Base;
- [x] active Dungeon encounter rejects swap and clear window accepts it;
- [x] Arc Slash requires one-handed sword and multi-target proficiency diminishes;
- [x] Attribute/Skill respec counters and allocation cannot mint points;
- [x] first death auto-revives after approximately three seconds at checkpoint;
- [x] later death uses paid/spectator flow;
- [x] Base -> Dungeon -> Base -> leave -> rejoin preserves the complete state;
- [x] reconnect/idempotency and duplicate protection remain correct;
- [x] fresh Base/Dungeon regressions remained green with no reported red runtime errors.

### Targeted published regression close-out

- [x] only one combat HUD/runtime presentation appears;
- [x] published sword attack presentation works;
- [x] only one Captain/boss runtime spawns;
- [x] shield presentation remains visible in published play;
- [x] shield arm remains behind the shield during Block and Shield Bash;
- [x] swept-volume dodge clearance prevents the under-monster/floor
  fall-through regression.

Detailed evidence is recorded in
`docs/testing/phase2b-gate-c-acceptance-record.md`.

**Phase 2B status:** FUNCTIONALLY COMPLETE.

## Phase 2C - Race/base-class definitions and class-specific trainer catalogues

**Status:** ACTIVE - PHASE 2C.A LOCAL GREEN

Phase 2C.A is the active race/base-class gate.

Fresh local evidence exists for the Human/Elf Fighter identity foundation, but
no Phase 2C.A acceptance may be claimed until the published TEST persistence
gate passes and explicit user acceptance is received.

## Phase 2C.A - Race + Character Identity Foundation

**Status:** IN PROGRESS - LOCAL GREEN

**Latest tested gameplay commit:**

`c7ae49faf7c2449ca3bfd00d2422c16c202ca18b`

### Task 12 local build verification

- [x] `git diff --check` clean before full regression.
- [x] Base full Task 12 build succeeded.
- [x] Dungeon full Task 12 build succeeded.

Base build:

`%TEMP%\DungeonMMO_Phase2C_A_Base_FULL.rbxl`

Dungeon build:

`%TEMP%\DungeonMMO_Phase2C_A_Dungeon_FULL.rbxl`

### Fresh Base automated regression

- [x] Phase 2C.A Race Definitions PASS - 35 assertions.
- [x] Profile Schema/Migration PASS - 43 assertions.
- [x] Phase 2C.A Profile Migration PASS - 38 assertions.
- [x] Phase 2C.A Identity Service PASS - 58 assertions.
- [x] Attribute Config PASS - 14 assertions.
- [x] Attribute Service PASS - 30 assertions.
- [x] Progression Service PASS - 9 assertions.
- [x] Phase 2B Progression Service PASS - 42 assertions.
- [x] Progression Snapshot Builder PASS - 37 assertions.
- [x] Base Progression Controller PASS - 25 assertions.
- [x] Character Combat Stats PASS - 32 assertions.
- [x] Race Presentation Service PASS - 51 assertions.
- [x] accepted Core/Base regression families remained green.

### Fresh Base manual regression

- [x] unresolved fresh identity opens mandatory race selection.
- [x] trainer/progression unavailable before identity Complete.
- [x] Dungeon entry blocked before identity Complete.
- [x] Human -> Fighter completes.
- [x] Human baseline is 5/4/6/5/5.
- [x] Human Resolve applied.
- [x] Human Fighter receives Shield Bash + Mend.
- [x] Elf -> Fighter completes.
- [x] Elf baseline is 5/6/4/5/5.
- [x] Elven Grace applied.
- [x] Elf Fighter receives Shield Bash + Mend.
- [x] Elf ears appear automatically.
- [x] Elf ears survive Reset Character.
- [x] repeated presentation does not duplicate ears.
- [x] existing Base progression works after identity Complete.
- [x] no red Base runtime exception observed.

### Fresh Dungeon automated regression

- [x] Character Combat Stats PASS - 32 assertions.
- [x] Phase 2C.A Identity Service PASS - 58 assertions.
- [x] Phase 2C.A Race Definitions PASS - 35 assertions.
- [x] Phase 2C.A Profile Migration PASS - 38 assertions.
- [x] Race Presentation Service PASS - 51 assertions.
- [x] Damage Service PASS - 15 assertions.
- [x] Basic Attack Timing Rules PASS - 25 assertions.
- [x] Critical Hit Rules PASS - 10 assertions.
- [x] Shield Bash Integration PASS - 17 assertions.
- [x] Arc Slash Integration PASS - 10 assertions.
- [x] Mend Service PASS - 9 assertions.
- [x] Defensive Combat Integration PASS - 42 assertions.
- [x] Dodge Direction PASS - 45 assertions.
- [x] Dodge Swept Clearance PASS - 8 assertions.
- [x] accepted combat/state/block/parry/skill families remained green.
- [x] accepted Dungeon/Phase 2A/Phase 2B families remained green.

### Fresh Dungeon manual regression

- [x] Studio-only Human/Fighter bootstrap logged.
- [x] Dungeon admission succeeded.
- [x] Slash1 -> Slash2 -> Finisher works.
- [x] attack buffering works.
- [x] Block works.
- [x] parry works.
- [x] Dodge works.
- [x] Shield Bash works.
- [x] Mend works.
- [x] Arc Slash works.
- [x] no red Dungeon runtime exception observed.

### Presentation note

- [x] Elf race presentation is functional and persistent.
- [x] ears survive Base respawn.
- [x] repeated application remains idempotent.
- [ ] final Elf-ear mesh/art polish is deferred and is not a Task 12 blocker.

### Task 13 - Published TEST acceptance

- [ ] reviewed Task 12 local-green candidate identified.
- [ ] TEST environment confirmed.
- [ ] Starting Base TEST Place ID confirmed.
- [ ] Test Dungeon Place ID confirmed.
- [ ] live paid revives confirmed disabled.
- [ ] no PROD DataStore namespace selected.
- [ ] no monetisation changes active.
- [ ] genuinely new Human Fighter persists through Base -> Dungeon -> Base -> leave -> rejoin.
- [ ] Human baseline/passive/starter kit remain correct after rejoin.
- [ ] genuinely new Elf Fighter persists through Base -> Dungeon -> Base -> leave -> rejoin.
- [ ] Elf baseline/passive/starter kit remain correct after rejoin.
- [ ] Elf ears persist through Dungeon, return and rejoin.
- [ ] accepted Phase 2B legacy character enters LegacyRaceSelection.
- [ ] legacy pre-choice progression state recorded.
- [ ] legacy attributes translate exactly once.
- [ ] legacy Level/XP/Gold/AP/SP remain preserved.
- [ ] legacy skills/ranks/proficiency/loadout remain preserved.
- [ ] legacy rewards/inventory/respec state remain preserved.
- [ ] second legacy race-selection attempt rejected without mutation.
- [ ] legacy Base -> Dungeon -> Base -> leave -> rejoin succeeds.
- [ ] no remigration occurs after rejoin.
- [ ] no AP/SP minting occurs.
- [ ] no duplicate rewards occur.
- [ ] published combat HUD/runtime presentation remains singular.
- [ ] published sword presentation works.
- [ ] only one Captain runtime appears.
- [ ] camera-parented shield remains visible.
- [ ] shield arm remains behind shield during Block/Shield Bash.
- [ ] swept dodge clearance remains correct.
- [ ] first free revive remains correct.
- [ ] later defeated flow remains correct.
- [ ] Arc Slash book/learning/loadout persistence remains correct.
- [ ] Phase 2C.A acceptance record written from observed evidence.
- [ ] explicit user acceptance received.

Phase 2C.A must not be marked ACCEPTED from local evidence alone.
