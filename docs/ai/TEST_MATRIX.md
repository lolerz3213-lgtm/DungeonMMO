# DungeonMMO Test and Acceptance Matrix

This file records accepted evidence and current gate status. It is not a
replacement for fresh test output when claiming a new result.

## Phase 1 - Combat prototype

**Roadmap status:** ACCEPTED

Previously accepted runtime coverage includes:

- basic attack / swept melee behaviour;
- blocking;
- parry;
- Guard Break;
- dodge invulnerability;
- Shield Bash;
- Mend channel and cancellation;
- four-Marauder pressure;
- death/respawn lifecycle;
- controller/mobile emulation;
- approximately 150 ms simulated round-trip latency diagnostics.

Presentation remains placeholder quality and is intentionally deferred.

## Phase 2A - Core Base-to-Dungeon slice

**Roadmap status:** ACCEPTED

Previously accepted coverage includes:

- separate Base and Dungeon Rojo builds;
- profile/save layer;
- DEV/TEST/PROD namespaces;
- profile leases and handoff;
- 1-4-player dungeon session contract;
- reconnect/reconstruction;
- persisted monster XP and Gold;
- room-start checkpoints;
- one free revive + later revive boundary;
- spectating and wipe window;
- Marauder Captain;
- immutable completion eligibility;
- exactly-once completion rewards;
- save-before-return;
- Base/Dungeon UI;
- reserved-server teleport;
- Base -> Dungeon -> Base persistence;
- 60-second auto-return;
- abandon-to-Base;
- deliberate TEST teleport-failure recovery.

Live paid-revive activation remains disabled.

## Phase 2B.A - Progression Foundation

**Roadmap status:** ACCEPTED
**Accepted Git checkpoint:** `24dee751b87d831abe22cd046dd3b9934c566a56`

Previously accepted PASS families include:

- profile migration;
- Level/AP/SP entitlement;
- Attribute Config/Service;
- Skill Progression;
- Loadout;
- Proficiency;
- Progression Damage;
- Mend Progression;
- Dungeon Progression Bridge;
- existing Phase 1/2A regression families.

## Phase 2B.B - Gameplay + Base Progression

**Status:** NOT ACCEPTED
**Current WIP checkpoint:** `c5e2a59`

### Confirmed current evidence

- [x] DEV/TEST Client Command Bar bridge reaches server-bound progression.
- [x] Level 10 mutation reports AP/SP entitlement 9/9.
- [x] Trainer reflects the Level 10 authoritative state.
- [x] Proficiency mutation route works.
- [ ] Profile HUD immediately reflects Level 10.
- [ ] Exact selected-skill placement into Slot 3 with Slot 2 empty.
- [ ] Full Base combined acceptance check.
- [ ] Full Dungeon combined acceptance check.

### Base combined acceptance requirements

- [ ] Level 10 Profile HUD/trainer agreement.
- [ ] Attribute spend flow.
- [ ] proficiency/rank purchase flow.
- [ ] six-slot rearrangement including intentional empty gaps.
- [ ] Attribute TEST respec.
- [ ] Skill TEST respec.

### Dungeon combined acceptance requirements

Run only after Base is clean.

- [ ] Arc Slash integration/PASS family.
- [ ] first-clear Arc Slash reward/PASS family.
- [ ] automatic-free-revive/PASS family.
- [ ] first death performs forced three-second free revive.
- [ ] second death uses normal defeated flow.
- [ ] Captain first-clear awards the bound Arc Slash Skill Book.
- [ ] relevant Phase 1/2A/2B.A regression families remain green.
- [ ] no red runtime errors.

## Phase 2B.C

**Status:** NOT STARTED

Published Base -> Dungeon -> Base persistence/rejoin/reconnect/idempotency
acceptance begins only after Gate 2B.B is accepted.
