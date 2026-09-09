# Phase 2C.C Studio Acceptance Checklist

**Gate:** Phase 2C.C - Equipment Effects + Combat Integration
**Environment:** TEST only
**Purpose:** Manual evidence that cannot be replaced by source/static tests.

Do not use this checklist until automated runtime tests and TEMP Base/Dungeon
builds are green.

## Base equipment UI

- [ ] Equipment panel still opens from the Equipment Manager.
- [ ] All six accepted slots remain visible.
- [ ] Equipped items remain correct after close/reopen.
- [ ] Current aggregate equipment effects are readable.
- [ ] Selecting an owned item shows its own effects.
- [ ] Selecting an owned item shows the server-computed change if equipped.
- [ ] Race/class rejection messages still appear correctly.
- [ ] Equip and unequip still work without duplicate inventory consumption.
- [ ] Equipping/unequipping does not create duplicate UI or presentation objects.

## Dungeon equipment lock and combat

Published TEST later uses the actual loadout prepared in Base. For the
standalone TEMP Dungeon Studio evidence in this gate, the in-memory Studio-only
bootstrap seeds the representative Marauder set automatically.

- [ ] Studio output reports the representative equipment bootstrap without error.
- [ ] The equipped Marauder Sword is presented in the Dungeon.
- [ ] The equipped Marauder Shield is presented in the Dungeon.
- [ ] Removing Weapon in Base before entry results in no authoritative sword
      weapon tag in the run.
- [ ] Arc Slash works when the Marauder Sword is the brought-in Weapon.
- [ ] Arc Slash does not become usable merely because a prototype Tool exists.
- [ ] Representative gear visibly changes the expected combat numbers/effects.
- [ ] Newly awarded equipment/inventory content does not change active-run stats.
- [ ] There is no in-Dungeon equip/unequip path.

## Accepted combat regression

- [ ] Human racial baseline/passive still behaves correctly.
- [ ] Elf racial baseline/passive still behaves correctly.
- [ ] Basic sword combo and attack buffering still work.
- [ ] Crit behaviour still works.
- [ ] Human/Elf attack-rate differences remain intact.
- [ ] Block/parry/Guard Break remain intact.
- [ ] Dodge remains intact.
- [ ] Shield Bash remains intact.
- [ ] Mend remains intact.
- [ ] Arc Slash rank/loadout/proficiency behaviour remains intact.
- [ ] Death/free revive/later defeated behaviour remains intact.
- [ ] Marauder Captain completion and Return to Base remain intact.

## Presentation regression

- [ ] No duplicate sword appears.
- [ ] No duplicate shield appears.
- [ ] Shield arm/block presentation remains acceptable.
- [ ] Existing sword attack animation/presentation remains acceptable.
- [ ] No new obvious visual attachment or replication defects appear.

## Safety

- [ ] TEST environment only.
- [ ] No PROD DataStore path used.
- [ ] Live paid revives remain disabled.
- [ ] No Robux spent.
- [ ] No monetisation activation/change.
- [ ] `art/dungeon-environment-prototype` was not touched.

## Migration qualification

- [ ] Do **not** mark the historical live legacy migration proof PASS.

The live legacy migration proof remains waived only for the current pre-player
TEST stage and is still required before a future release involving existing
player profiles.

## Recorded 9 September 2026 manual evidence

This gate used the TEMP Base and Dungeon builds created from
`DungeonMMO_Phase2CC_Recovery2`.

- Base: the Equipment Manager opened, all six Marauder slots were equipped, and
  the visible aggregate matched `+13% Physical Damage`, `+25 Max Health`,
  `+1% Critical Chance`.
- The project owner accepted the current Equipment UI as a functional
  placeholder and deferred the large visual overhaul.
- Dungeon: the project owner reported the requested equipment-aware
  sword/shield presentation and normal combat/dungeon regression flow working.
- Arc Slash was not manually exercised because it was not unlocked/equipped.
  The project owner accepted that limitation for this commit gate.
- Automated Roblox runtime GREEN was not separately captured.
- No PROD, Robux, monetisation or art-branch action was performed.
