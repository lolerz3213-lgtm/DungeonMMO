# DungeonMMO Development Handoff

**Date:** 11 September 2026
**Active workstream:** Phase 2 - Vertical Slice
**Phase 2C status:** FUNCTIONALLY COMPLETE
**Phase 2C.E status:** ACCEPTED - GAMEPLAY MERGED / PUSHED
**Canonical external roadmap:** DungeonMMO Roadmap v1.34

## Accepted gameplay boundary

- Phase 1: ACCEPTED.
- Phase 2A: ACCEPTED.
- Phase 2B.A/B/C: ACCEPTED; Phase 2B functionally complete.
- Phase 2C.A: ACCEPTED / merged / pushed.
- Phase 2C.B: ACCEPTED / merged / pushed.
- Phase 2C.C: ACCEPTED / merged / pushed.
- Phase 2C.D Mage: ACCEPTED / merged / pushed.
- Phase 2C.E Ranger: ACCEPTED / merged / pushed.
- Phase 2C.E accepted gameplay checkpoint:
  `6fe47a178987dc51a75212692201651eb0167326`.
- Ranger parent / prior canonical main:
  `86d27228977dd6c98bd404f12086e93ad94fbe9a`.

The docs closeout commit containing this handoff is the new canonical `main`.
Its SHA is recorded in the closeout receipt and Roadmap v1.34. No Roblox publish
occurred.

## Phase 2C.E locked player-facing behaviour

Human and Elf can select Ranger.

Ranger starts with:

1. Apprentice Longbow in persistent Weapon Equipment.
2. Normal / Precision / Full Draw as the free basic-attack draw tiers.
3. Piercing Shot in starter skill slot 1.
4. Crippling Shot in starter skill slot 2.
5. Volley in starter skill slot 3.

The Longbow is two-handed. It reserves OffHand, cannot present a shield and
cannot use Block while equipped. This reservation is server-owned Equipment
state, not dependent on the visible bow model.

Normal/Precision/Full Draw thresholds are server-timed. Precision begins at
approximately 0.45 seconds and Full Draw at approximately 0.80 seconds. Drawing
reduces movement without rooting the Ranger. Dodge cancels an active draw.
Precision/Full Draw reward timing with increased damage and critical chance.

Piercing Shot costs 20 Stamina and loses damage across successive penetrations;
Human Ranger keeps more penetration damage. Crippling Shot costs 20 Stamina and
applies a non-stacking slow; Elf Ranger receives stronger/slightly longer
control. Volley costs 30 Stamina and uses ground-targeted initial impact plus a
short arrow-rain pulse sequence.

Dexterity is the Ranger's primary ranged-damage scaling attribute. Basic arrows
do not consume ammunition in this foundation gate.

## Authority and persistence

Server authority owns:

- race/base-class runtime identity;
- persistent Equipment and Longbow weapon tags;
- two-handed OffHand reservation;
- draw start/release elapsed timing and tier resolution;
- ranged damage and critical rolls;
- Stamina spending and cooldowns;
- projectile travel/collision and penetration;
- Crippling Shot slow state;
- Volley ground placement/range and damage pulses;
- target legality and race-specific Ranger behaviour.

Persistent Equipment, not Tool/model presence, owns weapon-family authority.
Dungeon Equipment remains Base-selected, read-only and run-locked. Ranger uses
the accepted schema-v5 identity/progression/inventory/equipment structures with
no new profile schema version.

## Accepted evidence

Project-owner Studio acceptance was received after the Ranger Base/Dungeon
candidate and functional hotfix were tested.

Observed/accepted behaviour included:

- Ranger identity and starter Longbow flow;
- Longbow OffHand reservation;
- Normal, Precision and Full Draw attacks;
- movement reduction while drawing;
- Dodge cancellation of a held draw;
- Piercing Shot, Crippling Shot and Volley;
- Crippling control against normal Marauders and the Captain;
- normal enemy/Captain behaviour;
- successful full Dungeon completion and rewards;
- Ranger automated definition/identity/draw/slow test families reporting PASS;
- follow-up retest confirming the Ranger has no fallback shield and cannot
  Block with Longbow equipped;
- stale Base-only test issues corrected and retested successfully;
- no reported red Ranger runtime error after the accepted hotfix;
- no Roblox publish, PROD, Robux, monetisation or art-branch action.

Animation/VFX quality is still prototype-level and intentionally deferred.

## Qualifications that must remain visible

The historical Phase 2C.D Mage corrected-test qualification remains visible;
do not rewrite it as a separately observed Studio PASS.

Carry the earlier Phase 2C.C evidence qualifications as historical notes: Arc
Slash was not manually exercised in that acceptance run and its newly authored
runtime test family was not separately observed GREEN then.

The pre-player legacy migration waiver is not a migration PASS and must be
revalidated before a release involving real existing player profiles.

## Safety / worktrees

Primary repository:
`C:\Users\Remko\Documents\Roblox\DungeonMMO`

Accepted Ranger worktree:
`C:\Users\Remko\Documents\Roblox\DungeonMMO_Phase2CE_Ranger_v1`

Do not reset, clean, switch into, merge, copy from or otherwise disturb
`C:\Users\Remko\Documents\Roblox\DungeonMMO_Art` or
`art/dungeon-environment-prototype`.

Preserve older/recovery worktrees unless an explicit cleanup decision says
otherwise.

## Exact next action

Phase 2C is functionally complete. Do not infer a numbered Phase 2D from the
sequence alone.

Read Roadmap v1.34 and select the next remaining Phase 2 vertical-slice gate
before implementation. The next gate should continue toward a polished,
repeatable Starting Base/dungeon experience or the next modular dungeon/rare
state proof while preserving the accepted Fighter/Mage/Ranger, equipment,
persistence, progression and Dungeon contracts. Secondary-class advancement
remains Phase 3.
