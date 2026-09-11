# DungeonMMO Current Engineering State

**State date:** 11 September 2026
**Canonical long-form roadmap:** external DungeonMMO Roadmap v1.34
**Current phase:** Phase 2 - Vertical Slice
**Current gate status:** Phase 2C functionally complete
**Phase 2C.E status:** ACCEPTED - MERGED / PUSHED GAMEPLAY CHECKPOINT

## Canonical accepted baseline

- Phase 1: ACCEPTED / functionally complete.
- Phase 2A: ACCEPTED / functionally complete.
- Phase 2B.A/B/C: ACCEPTED; Phase 2B functionally complete.
- Phase 2C.A Race + Character Identity Foundation: ACCEPTED / merged / pushed.
- Phase 2C.B Equipment + Trainer Architecture: ACCEPTED / merged / pushed.
- Phase 2C.C Equipment Effects + Combat Integration: ACCEPTED / merged / pushed.
- Phase 2C.D Mage Base-Class + Support Foundation: ACCEPTED / merged / pushed.
- Phase 2C.E Ranger Marksman-Hunter Foundation: ACCEPTED / merged / pushed.
- Phase 2C.E accepted gameplay checkpoint:
  `6fe47a178987dc51a75212692201651eb0167326`.
- Phase 2C.E started from canonical pre-Ranger main:
  `86d27228977dd6c98bd404f12086e93ad94fbe9a`.

The documentation closeout commit containing this file becomes the new
canonical `main`. Its exact SHA is recorded by the Phase 2C.E closeout receipt
and external Roadmap v1.34. No Roblox publish occurred.

## Accepted Phase 2C.E Ranger architecture

Human and Elf can begin as Ranger while Fighter and Mage remain supported.

Ranger starts with one Apprentice Longbow in persistent Weapon Equipment. The
Longbow is two-handed and reserves OffHand without changing the accepted
six-slot schema. While Longbow is equipped, OffHand is unavailable, no shield
presentation is created and Block is not a legal combat action. Swapping away
from a two-handed weapon releases the reservation normally.

The Ranger basic attack is a server-timed held draw:

- short release = Normal arrow;
- approximately 0.45 seconds = Precision;
- approximately 0.80 seconds = Full Draw;
- holding beyond Full Draw adds no further tier;
- draw movement is reduced but not rooted;
- Dodge cancels an active draw without firing an arrow;
- Normal, Precision and Full Draw are free basic attacks.

Precision and Full Draw increase damage and critical chance. Dexterity is the
Ranger's primary ranged-damage scaling attribute. Existing race critical rules
remain in force.

The starter hotbar is:

1. Piercing Shot - 20 Stamina; penetrates lined-up targets with diminishing
   damage. Human Ranger retains more damage after penetration.
2. Crippling Shot - 20 Stamina; applies a non-stacking movement slow. Elf
   Ranger receives the stronger and slightly longer control profile.
3. Volley - 30 Stamina; ground-targeted area attack with an initial impact and
   short follow-up arrow-rain damage pulses.

Ranger slow state is server-owned and is respected by both ordinary Marauder
movement and the Marauder Captain controller rather than relying on fragile
client or Humanoid WalkSpeed overrides.

## Equipment and persistence invariants

The accepted schema-v5 Equipment table remains authoritative:

- Weapon
- OffHand
- Helmet
- Body
- Gloves
- Boots

Persistent Equipment, not Tool/model presence, owns weapon-family authority.
Two-handed reservation is generic equipment metadata rather than a hard-coded
Longbow-only save format.

Dungeon Equipment remains read-only and run-locked. The Dungeon deep-clones the
Equipment brought into the run, preserving the accepted Phase 2C.B/C contract.
No profile schema bump was introduced for Phase 2C.E.

## Accepted evidence

Project-owner Studio acceptance was received for both Base and Dungeon.
Observed evidence included:

- Human/Elf Ranger identity flow and persistent Apprentice Longbow grant;
- OffHand reservation for the two-handed Longbow;
- Normal, Precision and Full Draw release states;
- reduced movement while drawing and restoration afterward;
- Dodge cancelling an active draw with no arrow fired;
- Piercing Shot, Crippling Shot and Volley functioning in combat;
- Piercing Shot multi-target penetration/falloff;
- Crippling Shot working against ordinary Marauders and the Captain;
- normal Marauder/Captain pursuit and Dungeon progression;
- complete Dungeon clear and completion rewards;
- Ranger definition, identity, draw and slow automated test families reporting
  PASS during the acceptance run;
- a follow-up hotfix removing the inherited fallback shield and Longbow Block;
- the post-hotfix Base/Dungeon retest reported fully passing by the project
  owner, including no Ranger shield and no accepted Block while Longbow is
  equipped;
- stale Base-only Ranger/Mage definition test placement and the old
  Ranger-as-unknown-class assertion were corrected in the accepted candidate;
- fresh TEMP Base and Dungeon Rojo builds succeeded during candidate/hotfix
  verification;
- no Roblox place was published;
- no PROD / Robux / monetisation action occurred;
- the separate art worktree was not touched.

## Deferred presentation work

The current Longbow, arrow, draw and Ranger skill animation/VFX are functional
prototype presentation. Final animation, VFX, sound and polish are deliberately
deferred and do not invalidate the accepted Phase 2C.E gameplay architecture.

## Evidence qualifications that remain visible

The Phase 2C.D historical qualification remains: the stale Mage identity slot
expectation was corrected before its closeout and rebuilt, but a separate fresh
Studio PASS for that one corrected assertion was not captured at that time.

The earlier Phase 2C.C qualifications remain historical notes: Arc Slash was
not manually exercised during the 2C.C acceptance run, and the new 2C.C Roblox
automated runtime family was not separately captured GREEN at that time.

The pre-player live legacy migration proof waiver is still not a PASS. A real
live migration proof remains mandatory before any release that must support real
existing profiles.

## Environment and safety

- Local primary repo:
  `C:\Users\Remko\Documents\Roblox\DungeonMMO`
- Accepted Phase 2C.E gameplay worktree:
  `C:\Users\Remko\Documents\Roblox\DungeonMMO_Phase2CE_Ranger_v1`
- `base.project.json` = Starting Base.
- `default.project.json` = Test Dungeon.
- Environment: TEST.
- Live paid revives: disabled.
- No PROD / Robux / monetisation action is authorized by this closeout.
- `art/dungeon-environment-prototype` remains isolated and must not be mixed
  into gameplay work.

## Exact next engineering action

Phase 2C is now functionally complete with Fighter, Mage and Ranger starting
archetype foundations accepted.

Do **not** infer or automatically number a Phase 2D gate. Select the next
remaining Phase 2 vertical-slice gate from Roadmap v1.34 before source work.
Prioritize making the Starting Base and dungeon loop increasingly polished and
repeatable and/or proving the next modular dungeon/rare-state slice, depending
on the selected gate. Secondary-class advancement remains Phase 3 scope.

Preserve Fighter/Mage/Ranger combat, race identity, equipment/run-lock,
progression/loadout/proficiency, revive/completion, TEST/PROD and art-isolation
contracts while selecting the next gate.
