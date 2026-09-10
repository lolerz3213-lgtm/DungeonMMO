# DungeonMMO Development Handoff

**Date:** 10 September 2026
**Active gate:** Phase 2C.D - Mage Base-Class + Support Foundation
**Status:** ACCEPTED - GAMEPLAY MERGED / PUSHED
**Canonical external roadmap:** DungeonMMO Roadmap v1.33

## Accepted gameplay boundary

- Phase 1: ACCEPTED.
- Phase 2A: ACCEPTED.
- Phase 2B.A/B/C: ACCEPTED; Phase 2B functionally complete.
- Phase 2C.A: ACCEPTED / merged / pushed.
- Phase 2C.B: ACCEPTED / merged / pushed.
- Phase 2C.C: ACCEPTED / merged / pushed.
- Phase 2C.D: ACCEPTED; gameplay merged/pushed.
- Phase 2C.D accepted gameplay checkpoint:
  `41ac374496f01a1685b62cfd6d6237d0a7e702ec`.
- Phase 2C.D parent / prior canonical main:
  `38feb4a3c15286c56a98ab686357b7cf30f2c693`.

GitHub `main` was independently confirmed at the 2C.D gameplay checkpoint after
the approved fast-forward. No Roblox publish occurred.

## Phase 2C.D locked player-facing behaviour

Human and Elf can select Mage.

Mage starts with:

1. Apprentice Arcane Wand in persistent Weapon Equipment.
2. Spirit Orb as the free ranged basic attack.
3. Wind Strike in starter skill slot 1.
4. Arcane Ward in starter skill slot 2.
5. Mage Heal in starter skill slot 3.

Spirit Orb uses the existing three-step combo timing internally but presents as
Orb -> Orb -> larger AoE Orb for an authoritative ArcaneWand.

Wand basic attacks movement-lock the Mage during WindUp/Active/Recovery.
Block/Dodge can cancel them.

Wind Strike is a charged Intellect-scaled ranged spell. Prototype Rank 1 uses
30 base damage, 25 Mana, 5 second cooldown and 1.0 second charge. Block/Dodge
can cancel before release; cancelled charge fires nothing, spends no Mana and
starts no Wind Strike cooldown.

Arcane Ward is a Spirit-scaled replace-not-stack absorption shield and exposes
current/max shield values to the local Ward HUD.

Mage Heal is Spirit-scaled, supports injured aimed allies or injured self, and
uses different Human/Elf immediate-vs-HoT delivery while preserving comparable
baseline total.

Fighter Mend is self-only and costs 20 Stamina.

The Marauder Captain prototype chase speed is 17.5 studs/second. Normal
Marauder tuning is unchanged by this gate.

## Authority and persistence

Server authority owns:

- race/base-class runtime identity;
- persistent Equipment and weapon tags;
- Mana/Stamina spending and cooldowns;
- Wand/offensive-cast movement lock;
- projectile travel/collision/AoE;
- target legality;
- Intellect/Spirit scaling;
- Ward absorption;
- healing/HoT timing;
- charged-cast cancellation and commit timing.

Persistent Equipment, not client Tool presence, owns weapon-family authority.

Dungeon Equipment remains Base-selected, read-only and run-locked. Mage uses the
accepted schema-v5 identity/progression/inventory/equipment structures with no
new profile schema version.

## Accepted evidence

Project-owner gameplay acceptance was received after the v6 Dungeon build was
played successfully.

Observed/accepted behaviour included:

- Spirit Orb projectile basic chain and damage;
- larger third-hit AoE Orb;
- attack movement lock and restoration;
- Wind Strike charge/release/damage;
- Block/Dodge cancellation of charged casting;
- working Arcane Ward with remaining-shield display;
- working Mage self-heal when injured;
- Wand presentation;
- faster Captain pursuit;
- normal dungeon completion.

The accepted gameplay commit changed exactly 49 files. Fresh Base and Dungeon
Rojo builds succeeded before commit and again before the remote fast-forward.
The gameplay worktree remained clean. No Roblox publish, PROD, Robux,
monetisation or art-branch action occurred.

## Qualification that must remain visible

The acceptance Studio run showed one stale Mage identity test assertion still
expecting the older Ward/Heal-only loadout. The test expectation was corrected
afterward and Base/Dungeon rebuilt, but a fresh Studio runtime PASS for that
corrected assertion was not separately captured. Do not report it as observed
runtime GREEN.

Carry the earlier 2C.C evidence qualifications as historical notes: Arc Slash
was not manually exercised in the 2C.C acceptance run, and the newly authored
2C.C automated Roblox runtime tests were not separately observed GREEN then.

The pre-player legacy migration waiver is not a migration PASS and must be
revalidated before a release involving real existing player profiles.

## Safety / worktrees

Primary repository:
`C:\Users\Remko\Documents\Roblox\DungeonMMO`

Accepted 2C.D worktree:
`C:\Users\Remko\Documents\Roblox\DungeonMMO_Phase2CD_v6`

Do not reset, clean, switch into, merge, copy from or otherwise disturb
`art/dungeon-environment-prototype`.

Preserve older dirty recovery worktrees unless a later explicit cleanup decision
says otherwise.

## Exact next action

The external Roadmap v1.33 identifies Ranger as the remaining prototype
starting archetype after Fighter and Mage.

Next action: design the Ranger base-class foundation while preserving all
accepted Fighter/Mage/race/progression/equipment/dungeon contracts.

Do **not** start Ranger source implementation or assign a numbered Phase 2C.E
gate until its design has been explicitly approved.