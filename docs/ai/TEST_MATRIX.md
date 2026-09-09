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

**Status:** ACCEPTED - PHASE 2C.B MERGED / PUSHED

Phase 2C.A is accepted, merged and pushed.

Phase 2C.B - Equipment + Trainer Architecture is the active engineering gate.

## Phase 2C.A - Race + Character Identity Foundation

**Status:** ACCEPTED

**Reviewed local-green checkpoint:**

`d13c5b8f834ab9642b0fb3f629bf05f46616e543`

### Task 12 local build and Studio regression

- [x] `git diff --check` clean before full local regression.
- [x] Base full Task 12 build succeeded.
- [x] Dungeon full Task 12 build succeeded.
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
- [x] Damage Service PASS - 15 assertions.
- [x] Basic Attack Timing Rules PASS - 25 assertions.
- [x] Critical Hit Rules PASS - 10 assertions.
- [x] Shield Bash Integration PASS - 17 assertions.
- [x] Arc Slash Integration PASS - 10 assertions.
- [x] Mend Service PASS - 9 assertions.
- [x] Defensive Combat Integration PASS - 42 assertions.
- [x] Dodge Direction PASS - 45 assertions.
- [x] Dodge Swept Clearance PASS - 8 assertions.
- [x] accepted Core/Base/Dungeon/Phase 2A/Phase 2B regression families remained green.

### Local manual Base/Dungeon regression

- [x] mandatory unresolved race selection.
- [x] incomplete identity blocks gated Base/Dungeon behaviour.
- [x] Human -> Fighter.
- [x] Human baseline 5/4/6/5/5.
- [x] Human Resolve.
- [x] Human Shield Bash + Mend.
- [x] Elf -> Fighter.
- [x] Elf baseline 5/6/4/5/5.
- [x] Elven Grace.
- [x] Elf Shield Bash + Mend.
- [x] Elf ears.
- [x] Elf ears survive respawn.
- [x] race presentation remains idempotent.
- [x] sword combo.
- [x] attack buffering.
- [x] Block/parry.
- [x] Dodge.
- [x] Shield Bash.
- [x] Mend.
- [x] Arc Slash.
- [x] no red runtime exception observed.

### Task 13 published TEST safety

- [x] reviewed Task 12 local-green candidate identified.
- [x] TEST environment confirmed.
- [x] Universe ID `10765241947` confirmed.
- [x] Starting Base Place ID `134132328219009` confirmed.
- [x] Test Dungeon Place ID `117293035754309` confirmed.
- [x] live paid revives remained disabled.
- [x] no PROD profile/DataStore path used.
- [x] no Robux spend.
- [x] no Task 13 monetisation changes.

### New Elf published persistence

- [x] fresh TEST race selection.
- [x] Elf -> Fighter.
- [x] Level 1.
- [x] baseline 5/6/4/5/5.
- [x] Elven Grace.
- [x] Shield Bash + Mend.
- [x] Elf ears in Base.
- [x] Base -> published Dungeon.
- [x] Elf ears in Dungeon.
- [x] normal sword/basic attack behaviour.
- [x] Block/parry.
- [x] Dodge.
- [x] Shield Bash.
- [x] Mend.
- [x] normal Dungeon completion.
- [x] Dungeon -> Base.
- [x] Elf / Fighter preserved after return.
- [x] ears preserved after return.
- [x] leave Experience.
- [x] rejoin Starting Base.
- [x] Elf / Fighter persisted.
- [x] baseline/passive persisted.
- [x] ears persisted.
- [x] skills/progression persisted.

### New Human published persistence

- [x] TEST profile reset to a fresh identity.
- [x] Human -> Fighter.
- [x] Level 1.
- [x] baseline 5/4/6/5/5.
- [x] Human Resolve.
- [x] Shield Bash + Mend.
- [x] Base -> published Dungeon.
- [x] normal sword/basic attack behaviour.
- [x] Block/parry.
- [x] Dodge.
- [x] Shield Bash.
- [x] Mend.
- [x] normal Dungeon completion.
- [x] Dungeon -> Base.
- [x] Human / Fighter preserved after return.
- [x] leave Experience.
- [x] rejoin Starting Base.
- [x] Human / Fighter persisted.
- [x] baseline/passive persisted.
- [x] skills/progression persisted.

### Published sensitive regressions

- [x] one combat HUD/runtime presentation.
- [x] published sword presentation.
- [x] one Marauder Captain runtime.
- [x] camera/view shield visible.
- [x] shield arm remains behind shield during Block.
- [x] shield arm remains behind shield during Shield Bash.
- [x] swept Dodge does not place player under floor.
- [x] swept Dodge does not place player inside monster.
- [x] first free revive works.
- [x] second death reaches normal defeated boundary.
- [x] live paid revive remains disabled.
- [x] Return to Base remains available.
- [x] Arc Slash Skill Book awarded to Inventory.
- [x] Arc Slash learning works.
- [x] Arc Slash loadout works.
- [x] Arc Slash knowledge/loadout persists after rejoin.

### Legacy published migration qualification

- [x] automated Profile Schema/Migration coverage green.
- [x] automated Phase 2C.A Profile Migration coverage green.
- [x] automated Identity Service coverage green.
- [ ] LIVE LEGACY MIGRATION PROOF WAIVED FOR THIS PRE-PLAYER TEST GATE.

The project owner deliberately waived the live legacy-character migration proof
because there are no real players and the current TEST data is disposable
developer/test data.

A live legacy migration proof remains required before any future release that
must migrate real existing player profiles.

### Known deferred issue

- [x] Skill Book reward is correctly granted to Inventory.
- [ ] Skill Book is not listed in the Dungeon Completed reward summary.

The completion-summary display issue is explicitly deferred to the next patch
and is not being treated as a reward/persistence failure.

### Acceptance close-out

- [x] Phase 2C.A acceptance evidence record created.
- [x] explicit user acceptance received.
- [x] Phase 2C.A marked ACCEPTED.
- [x] canonical roadmap updated through external Roadmap v1.30.
- [x] acceptance documentation committed at d3685be4a507f00e0b08bf8d948a41ecfa80b47.
- [ ] merge to `main` deliberately approved/completed.

Phase 2C.A was explicitly accepted by the project owner on 9 September 2026.

## Phase 2C.B - Equipment + Trainer Architecture

**Status:** DESIGN APPROVED - RED CONTRACT PREPARATION
**Starting baseline:** `19f8c31284da80dc87cf5d44560d366e48427888`
**Formal Phase 2C.A acceptance ancestor:** `ad3685be4a507f00e0b08bf8d948a41ecfa80b47`

### Design lock

- [x] user approved Phase 2C.B architecture.
- [x] equipment slots locked: Weapon / OffHand / Helmet / Body / Gloves / Boots.
- [x] Base-only server-authoritative equipment mutation locked.
- [x] race/base-class/class restriction architecture locked.
- [x] level/attribute restrictions deferred.
- [x] unique item instances / random affixes / durability deferred.
- [x] accepted combat sword/shield visual pipeline preserved.
- [x] data-driven Fighter trainer catalogue required.
- [x] Human Fighter trainer path required.
- [x] Elf Fighter trainer path required.
- [x] functional trainer UI required.
- [x] functional six-slot equipment UI required.
- [x] Dungeon Completed Arc Slash Skill Book summary presentation fix included.
- [x] PROD/Robux/monetisation remain out of scope.
- [x] art/dungeon-environment-prototype remains isolated.

### TDD RED bootstrap

The following checks are intentionally expected to fail before production
implementation:

- [x] Equipment Slots contract RED observed.
- [x] Equipment Rules RED observed.
- [x] Phase 2C.B schema-v5 equipment migration RED observed.
- [x] Equipment Service RED observed.
- [x] Phase 2C.B remote contract RED observed.
- [x] Trainer Catalogues RED observed.
- [x] Trainer authorization transport RED observed.
- [x] Completion Reward Presentation RED observed.

Do not mark any of these green merely because Rojo builds successfully.
Actual Roblox Studio runtime output is required.

### Critical migration guard

When schema advances to v5, only pre-v4 data is legacy. Accepted schema-v4
Phase 2C.A Human/Elf profiles must retain their identity and progression and
receive an empty/sanitized Equipment table.

### Acceptance status

Phase 2C.B is NOT accepted and no implementation PASS is claimed at this
checkpoint.
### Phase 2C.B GREEN candidate gate

- [x] Equipment Slots GREEN observed.
- [x] Equipment Rules GREEN observed.
- [x] schema-v5 equipment migration GREEN observed.
- [x] Equipment Service GREEN observed.
- [x] Phase 2C.B remote contract GREEN observed.
- [x] Trainer Catalogues GREEN observed.
- [x] Trainer authority GREEN observed.
- [x] Completion Reward Presentation GREEN observed.
- [x] accepted Base/Core regression families remain GREEN.
- [x] Human Fighter six-slot equipment visual check passed.
- [x] Human TEST Elven Helmet shows RaceRestricted.
- [x] Human Fighter trainer catalogue check passed.
- [x] Elf Fighter trainer catalogue check passed.
- [x] Elf TEST Elven Helmet is eligible/equippable.
- [x] Dungeon accepted regression families remain GREEN.
- [x] Dungeon completion summary lists a newly awarded Arc Slash Skill Book.
- [x] no PROD / Robux / monetisation action occurred.
### Phase 2C.B observed GREEN evidence

Date: 9 September 2026

Base:
- new 2C.B RED families all transitioned to PASS;
- Equipment Slots PASS: 24 assertions;
- Equipment Rules PASS: 9 assertions;
- Equipment Migration PASS: 20 assertions;
- Equipment Service PASS: 38 assertions;
- Trainer Catalogues PASS: 10 assertions;
- Trainer Authority PASS;
- Remote Contract PASS;
- Completion Reward Presentation PASS: 4 assertions;
- Phase 2B / Phase 2C.A migration and identity regressions remained green;
- Human/Fighter and Elf/Fighter equipment/trainer visual checks passed;
- race-specific TEST helmet restriction behaved correctly.

Dungeon:
- accepted combat/dungeon/revive/reward/progression regression families passed;
- Marauder Captain playthrough completed;
- completion rewards committed successfully;
- return window opened normally;
- Arc Slash Skill Book appeared in the completion reward summary.

Result:
GREEN and ready for explicit Phase 2C.B acceptance.

No commit, merge, push, Roblox publish, PROD or Robux action is part of this
GREEN evidence record.
### Phase 2C.B acceptance result

- [x] Fresh Base GREEN evidence reviewed.
- [x] Fresh Dungeon GREEN evidence reviewed.
- [x] Human/Fighter equipment and Fighter Trainer functional check passed.
- [x] Human TEST Elven Helmet correctly rejected.
- [x] Elf/Fighter equipment and Fighter Trainer functional check passed.
- [x] Elf TEST Elven Helmet eligible/equippable.
- [x] Dungeon combat/revive/completion regression check passed.
- [x] Arc Slash Skill Book appeared in the Dungeon Completed reward summary.
- [x] Project owner explicitly accepted Phase 2C.B on 9 September 2026.
- [x] No PROD, Robux, monetisation or art-branch action was used for acceptance.

Result: ACCEPTED. This checkpoint may now be committed on the Phase 2C.B
feature branch. Merge and push remain separate deliberate actions.
### Phase 2C.B local merge verification

- [x] Accepted checkpoint commit verified before merge.
- [x] Local `main` and `origin/main` verified at accepted Phase 2C.A baseline.
- [x] Deliberate no-ff merge used.
- [x] Gameplay/source tree remains identical to accepted Phase 2C.B checkpoint.
- [x] Base and Dungeon rebuilt from merged local `main`.
- [x] Art worktree remains untouched.
- [x] No Roblox publish, PROD, Robux or monetisation action occurred.
- [x] Push local `main` to `origin/main` completed after explicit approval.
### Phase 2C.B remote push verification

- [x] Remote `origin/main` verified unchanged immediately before push.
- [x] Server-side `refs/heads/main` verified unchanged immediately before push.
- [x] Accepted Phase 2C.B merge pushed without force.
- [x] Server-side main verified at the Phase 2C.B merge commit.
- [x] Accepted Phase 2C.B checkpoint verified reachable from remote main.
- [x] Final continuity-doc closeout changes only CURRENT_STATE/HANDOFF/TEST_MATRIX.
- [x] Final local main, origin/main and server main verified equal.
- [x] Final origin/main...main ahead/behind verified 0/0.
- [x] No Roblox publish, PROD, Robux, monetisation or art-branch action occurred.

## Phase 2C.C - Equipment Effects + Combat Integration

**Status:** COMMIT APPROVED - BUILD/MANUAL EVIDENCE RECORDED; AUTOMATED RUNTIME GREEN NOT SEPARATELY OBSERVED
**Starting canonical GitHub server main:**
`8587c1546aa1689b69606f860fb5c18a847de617`
**Phase 2C.B accepted checkpoint:**
`fd0d73df70b97efc4b3fb241e2fc6e5061a3ed47`

### Design lock

- [x] reuse the accepted six-slot Equipment state;
- [x] one pure server-authoritative equipment stat resolver;
- [x] representative physical-damage / MaxHealth / crit-chance proof effects;
- [x] runtime Equipment snapshot locks the gear brought into the Dungeon;
- [x] Dungeon equipment mutation remains rejected;
- [x] newly looted equipment cannot change the active runtime snapshot;
- [x] runtime Equipment, not prototype Tool presence, owns weapon tags;
- [x] Base Equipment UI receives server-computed effects/previews/deltas;
- [x] prototype sword/shield presentation may follow equipped representative items;
- [x] no duplicate DungeonSession equipment store;
- [x] deferred scope remains out of 2C.C;
- [x] art branch remains isolated;
- [x] legacy live-migration waiver remains NOT PASS.

### Test-first contract preparation

The following focused tests were authored before their corresponding production
behaviour in the isolated candidate. This environment cannot execute Roblox
Studio tests, so these are **not** being marked runtime RED/GREEN yet.

- [ ] Equipment Stat Resolver runtime GREEN observed.
- [ ] Progression Runtime Equipment runtime GREEN observed.
- [ ] Equipment Weapon Requirement runtime GREEN observed.
- [ ] Equipment Service Effects runtime GREEN observed.
- [ ] Equipment Effect Presentation runtime GREEN observed.
- [ ] Equipment Presentation Rules runtime GREEN observed.
- [ ] Dungeon Studio Equipment Bootstrap runtime GREEN observed.
- [ ] Arc Slash integration regression GREEN observed.
- [ ] accepted Character Combat Stats regression GREEN observed.
- [ ] accepted Equipment Service regression GREEN observed.
- [ ] accepted Base/Core regression families GREEN observed.
- [ ] accepted Dungeon/combat/revive/completion regression families GREEN observed.

### Build and manual evidence

- [x] `git diff --check` clean in the real feature worktree.
- [x] TEMP Base Rojo build succeeded.
- [x] TEMP Dungeon Rojo build succeeded.
- [x] Base Equipment UI functional placeholder accepted; visual overhaul deferred.
- [x] Dungeon gear-aware sword/shield presentation passed manual play.
- [ ] brought-in gear affects combat as expected.
- [ ] newly looted gear does not affect the active run.
- [ ] Human/Elf, crit, attack-rate, Mend, Shield Bash, Arc Slash, revive and
      completion regressions remain accepted.
- [x] no PROD / Robux / monetisation / art-branch action occurred.

The project owner approved the exact local Phase 2C.C commit after fresh build
and manual evidence. Arc Slash was not manually exercised because it was not
unlocked/equipped, and the authored Roblox automated runtime tests were not
separately observed GREEN. Do not rewrite either limitation as a PASS.
Push, merge and publish remain separate explicit approval gates.
