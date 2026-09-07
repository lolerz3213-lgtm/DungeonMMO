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

**Status:** IN PROGRESS

Task 9 started from accepted checkpoint
`ac9546c73d3f2f57221ae71b2f1e7a6ebcd35137` on
`wip/phase-2b-c-published-persistence`.

RED verified in a fresh Base build: `ProgressionSnapshotBuilderTest` failed for
the expected missing-builder reason while the surrounding accepted Base
regressions remained green. GREEN is now verified for the shared builder in
fresh Base and Dungeon runs at 22 assertions each. The first full Dungeon run
also exposed two pre-existing test defects, not runtime regressions:
`Phase2AFailurePathTest` had a stale wipe-deadline expectation and
`AutomaticFreeReviveTest` had ambiguous Luau callback syntax. The test-only
repair is verified: `Phase2A Failure Path Tests` PASS with 25 assertions and
`Automatic Free Revive Tests` PASS with 10 assertions in a fresh Dungeon run,
with no red runtime/test errors reported.

Task 9 is the final Phase 2B gate. Published TEST acceptance must prove:

- [ ] fresh Level 1 profile = 5/5/5/5/5, 0 AP/SP, Mend R1 + Shield Bash R1;
- [ ] each level gain grants exactly +1 AP/+1 SP;
- [ ] Strength changes basic sword damage;
- [ ] Vitality changes MaxHealth;
- [ ] Spirit changes Mend;
- [ ] Mend/Shield Bash proficiency caps at the next threshold;
- [ ] DEV/TEST proficiency mutation changes proficiency only;
- [ ] trainer rank purchase persists;
- [ ] first Captain clear grants exactly one bound Arc Slash book;
- [ ] return to Base preserves the book;
- [ ] trainer consumes the book + 3 SP atomically and learns Arc Slash;
- [ ] Arc Slash auto-fills the first free slot;
- [ ] Character -> Skills swaps in Base;
- [ ] active Dungeon encounter rejects swap and clear window accepts it;
- [ ] Arc Slash requires one-handed sword and multi-target proficiency diminishes;
- [ ] Attribute/Skill respec counters and allocation cannot mint points;
- [ ] first death auto-revives after three seconds at checkpoint;
- [ ] later death uses paid/spectator flow;
- [ ] Base -> Dungeon -> Base -> leave -> rejoin preserves the complete state;
- [ ] reconnect/idempotency and duplicate protection remain correct;
- [ ] all fresh Base/Dungeon regressions are green with no red runtime errors.

Phase 2B is not functionally complete until Gate 2B.C passes and is accepted.
