# DungeonMMO Current Engineering State

**State date:** 10 September 2026
**Canonical long-form roadmap:** external DungeonMMO Roadmap v1.33
**Current phase:** Phase 2C
**Current gate:** Phase 2C.D - Mage Base-Class + Support Foundation
**Phase 2C.D status:** ACCEPTED - MERGED / PUSHED GAMEPLAY CHECKPOINT
**Phase 2C.C status:** ACCEPTED - MERGED / PUSHED

## Canonical accepted baseline

- Phase 1: ACCEPTED / functionally complete.
- Phase 2A: ACCEPTED / functionally complete.
- Phase 2B.A/B/C: ACCEPTED; Phase 2B functionally complete.
- Phase 2C.A Race + Character Identity Foundation: ACCEPTED / merged / pushed.
- Phase 2C.B Equipment + Trainer Architecture: ACCEPTED / merged / pushed.
- Phase 2C.C Equipment Effects + Combat Integration: ACCEPTED / merged / pushed.
- Phase 2C.D Mage Base-Class + Support Foundation: ACCEPTED; gameplay checkpoint merged/pushed.
- Phase 2C.D accepted gameplay checkpoint:
  `41ac374496f01a1685b62cfd6d6237d0a7e702ec`.
- Phase 2C.D started from:
  `38feb4a3c15286c56a98ab686357b7cf30f2c693`.

GitHub `main` was independently verified at
`41ac374496f01a1685b62cfd6d6237d0a7e702ec` after the approved fast-forward.
The feature branch `wip/phase-2c-d-mage-foundation-v6` was preserved at the
same checkpoint. No Roblox publish occurred.

## Accepted Phase 2C.D gameplay architecture

Human and Elf can begin as Mage while Fighter remains supported.

Mage starts with:

- free ranged Spirit Orb basic attacks;
- Wind Strike as a charged magical damage skill;
- Arcane Ward as a Spirit-scaled absorption shield;
- Mage Heal as a Spirit-scaled self/ally heal;
- one Apprentice Arcane Wand equipped in the persistent Weapon slot.

Spirit Orb is a basic attack, not a hotbar skill or Mana spender. Its three-hit
cadence is Orb -> Orb -> larger AoE Orb. Projectile travel, collision, legal
targets and damage remain server-authoritative.

Wind Strike establishes the charged-cast contract: 1.0 second charge, visible
commitment, Intellect-scaled magical damage, 25 Mana and 5 second cooldown.
Block or Dodge can cancel the charge before release; cancelled charge spends no
Mana and starts no Wind Strike cooldown.

Mage Wand basic attacks and offensive charged casts movement-lock the caster
during their committed attack phases. Block/Dodge retain higher-priority
cancellation. This is intentional anti-kiting combat pacing.

The Marauder Captain prototype chase speed is 17.5 studs/second, slightly above
ordinary 16-stud player movement, so sustained damage-while-running cannot
kite the boss forever.

## Mana and support foundation

Mage runtime Mana uses the accepted effective-stat/diminishing-return
architecture:

- baseline Max Mana 100;
- baseline regen 8/second;
- 1 second post-spend regen delay;
- Spirit primarily improves Max Mana, regen, healing and Ward;
- Intellect primarily improves magical damage and secondarily Max Mana.

Arcane Ward is replace-not-stack, consumes Ward HP before Humanoid Health and
replicates current/max Ward values for the local Ward HUD.

Mage Heal targets a valid injured aimed ally or falls back to injured self.
Human and Elf use different immediate/HoT delivery profiles while retaining the
same baseline total.

Fighter Mend remains available but is self-only in this gate and costs
20 Stamina.

## Equipment and persistence invariants

The accepted six-slot Equipment table remains authoritative:

- Weapon
- OffHand
- Helmet
- Body
- Gloves
- Boots

Persistent Equipment, not Tool/model presence, owns weapon-family authority.

Dungeon Equipment remains run-locked and non-mutable. The Dungeon deep-clones
the Equipment state brought into the run; newly looted or later-mutated source
Equipment cannot alter the active run without a new authoritative seed.

Mage identity, starter skills, loadout, Wand inventory/equipment and attributes
reuse the accepted schema-v5 persistence architecture. No profile schema bump
was introduced for 2C.D.

## Accepted evidence

Phase 2C.D was accepted after manual Dungeon play confirmed the requested Mage
combat behaviour:

- Spirit Orb basic attacks fired as projectiles and damaged enemies;
- the third basic attack used the larger AoE Orb;
- Wand basic attacks movement-locked the Mage during commitment;
- normal movement returned after the attack;
- Wind Strike visibly charged, fired and dealt damage;
- Block/Dodge cancelled the charged cast;
- Arcane Ward worked and exposed remaining shield;
- Mage Heal worked on the injured caster;
- the Apprentice Arcane Wand presentation was present;
- the faster Captain could close distance and the dungeon completed normally;
- TEMP Base and Dungeon Rojo builds succeeded before the accepted commit and
  again before the fast-forward merge;
- exact accepted gameplay boundary was 49 files;
- worktree remained clean through commit/push/merge;
- no Roblox place was published;
- no PROD / Robux / monetisation action occurred;
- the separate art worktree was not touched.

## Evidence qualification

The Studio run used for gameplay acceptance exposed a stale
`MageIdentityServiceTest` expectation from the earlier two-skill Mage prototype.
That expectation was corrected to the approved Wind Strike / Ward / Heal
loadout and Base/Dungeon rebuilt successfully afterward.

A fresh Roblox Studio runtime PASS for that corrected assertion was not
separately captured after the cleanup. Do not rewrite that qualification as a
runtime GREEN result.

The earlier Phase 2C.C qualifications also remain visible history: Arc Slash was
not manually exercised during the 2C.C acceptance run, and the new 2C.C Roblox
automated runtime family was not separately captured GREEN at that time.

The pre-player live legacy migration proof waiver is still not a PASS. A real
live migration proof remains mandatory before any release that must support real
existing profiles.

## Environment and safety

- Local primary repo:
  `C:\Users\Remko\Documents\Roblox\DungeonMMO`
- Phase 2C.D gameplay worktree:
  `C:\Users\Remko\Documents\Roblox\DungeonMMO_Phase2CD_v6`
- `base.project.json` = Starting Base.
- `default.project.json` = Test Dungeon.
- Environment: TEST.
- Live paid revives: disabled.
- No PROD / Robux / monetisation action is authorized by this closeout.
- `art/dungeon-environment-prototype` remains isolated and must not be mixed
  into gameplay work.

## Exact next engineering action

Phase 2C.D gameplay is closed at
`41ac374496f01a1685b62cfd6d6237d0a7e702ec`.

Roadmap v1.33 leaves Ranger as the remaining prototype starting archetype after
Fighter and Mage. The next engineering action is therefore a **Ranger design
gate**, not automatic source implementation. Do not infer or lock a numbered
Phase 2C.E implementation until the Ranger design is explicitly approved.

Preserve Fighter/Mage combat, race identity, equipment/run-lock,
progression/loadout/proficiency, revive/completion, TEST/PROD and art-isolation
contracts while designing Ranger.