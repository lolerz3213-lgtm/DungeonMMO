# DungeonMMO Development Handoff

**Date:** 9 September 2026
**Active gate:** Phase 2C.C - Equipment Effects + Combat Integration
**Status:** ACCEPTED - MERGED / PUSHED

## Accepted gameplay boundary

- Phase 1: ACCEPTED.
- Phase 2A: ACCEPTED.
- Phase 2B.A/B/C: ACCEPTED; Phase 2B functionally complete.
- Phase 2C.A: ACCEPTED / merged / pushed.
- Phase 2C.B: ACCEPTED / merged / pushed.
- Phase 2C.B acceptance:
  `fd0d73df70b97efc4b3fb241e2fc6e5061a3ed47`.
- Phase 2C.B gameplay merge:
  `0edc542fafccd4a05c13a0a8940718575e536ab2`.
- Phase 2C.C: ACCEPTED / merged / pushed.
- Phase 2C.C accepted main checkpoint:
  `4f13a4c3868f9f36f09b7519f5e81ec947dbc9b8`.
- Phase 2C.C starting main baseline:
  `8587c1546aa1689b69606f860fb5c18a847de617`.
- Canonical long-form roadmap: external Roadmap v1.31.

Windows repository verification is complete: local `main`, `origin/main` and
GitHub server `main` matched
`8587c1546aa1689b69606f860fb5c18a847de617`. The accepted candidate is in
`DungeonMMO_Phase2CC_Recovery2` on
`wip/phase-2c-c-equipment-effects-recovery-2`.

## Phase 2C.C locked architecture

Approach A is approved:

1. Keep the Phase 2C.B six-slot persistent Equipment table.
2. Put representative combat metadata in `ItemDefinitions`.
3. Resolve it through one pure `EquipmentStatResolver`.
4. Deep-clone Equipment into `ProgressionRuntimeState` and cache resolved
   effects for the active authoritative runtime character.
5. Keep existing combat consumers on runtime getters.
6. Make runtime Equipment, not prototype Tools, authoritative for weapon tags.
7. Keep Dungeon Equipment non-mutable and let the runtime snapshot lock the
   gear brought into the run.
8. Send server-computed Equipment effects/previews/deltas to the Base UI; the
   client only formats them.
9. Make the current sword/shield presentation Equipment-aware where practical,
   without creating an armour-art system.

Working proof effects are limited to physical damage, flat MaxHealth and
critical chance. They are not final balance.

## Accepted Phase 2C.C responsibilities

### Shared Core

- `ItemDefinitions`: representative combat metadata only.
- `EquipmentStatResolver`: pure slot/item -> effect/tag resolution.
- `EquipmentEffectPresentation`: display formatting only.
- `EquipmentPresentationRules`: representative sword/shield display decisions.

### Server Core

- `ProgressionRuntimeState`: authoritative Equipment snapshot, final gear-aware
  combat getters and runtime weapon tags.
- `EquipmentService`: sanitized item/current/preview/delta effect snapshots.

### Base

- successful equip/unequip refreshes the runtime character before sending the
  refreshed snapshot;
- Equipment UI shows meaningful current effects and server-computed changes.

### Dungeon combat presentation

- prototype sword/shield scripts render according to server-owned equipped item
  attributes;
- the visual objects own no combat stats or skill eligibility;
- standalone Studio testing uses a `RunService:IsStudio()`-guarded in-memory
  representative-loadout bootstrap only so the visual gate can be exercised.

## Dungeon run-lock invariant

After `ProgressionRuntimeState.set_character`, later mutation of the source
Inventory or Equipment table cannot change active combat effects. Only a new
authoritative runtime seed can change the active Equipment snapshot.

This is sufficient for Phase 2C.C because Dungeon equipment mutation is already
rejected by the accepted Phase 2C.B EquipmentService boundary.

## Deferred scope

Do not add Mage/Ranger, advanced classes/quests, crafting, trading/economy,
unique item instances, random affixes, durability, enhancement, final gear
balance, large equipment-content production, Race Change/Robux or environment
art.

## Migration qualification

The previous live legacy migration proof was waived only for this pre-player
TEST project. It is not a PASS. A real live migration proof remains mandatory
before a future release involving existing player profiles.

## Art isolation

`art/dungeon-environment-prototype` is strictly separate. Do not switch to it,
merge it, reset/clean it, apply its stash, or copy from it during gameplay work.

## Evidence state and exact next action

Phase 2C.C is ACCEPTED / MERGED / PUSHED at
`4f13a4c3868f9f36f09b7519f5e81ec947dbc9b8`.

Accepted evidence retained:

- exact 27-file implementation boundary verified;
- `git diff --check` clean before the gameplay commit;
- TEMP Base and Dungeon Rojo builds succeeded;
- Base Equipment UI showed the full representative set and expected aggregate
  `+13% Physical Damage`, `+25 Max Health`, `+1% Critical Chance`;
- the current Equipment UI is accepted as a functional placeholder, with the
  large visual overhaul deferred;
- Dungeon manual play reported the requested equipment-aware sword/shield and
  normal combat/dungeon regression flow working;
- Arc Slash was not manually exercised in the 2C.C acceptance run because it
  was not unlocked/equipped; that limitation was explicitly accepted;
- Roblox automated runtime GREEN was not separately captured and is not claimed;
- no Roblox publish, PROD, Robux, monetisation or art-branch action occurred.

GitHub `main` was independently confirmed at the accepted checkpoint after the
fast-forward push.

No later Phase 2C sub-gate is named in the tracked repository. Before new source
work, read the canonical external Roadmap v1.31 and explicitly select/approve
the next roadmap gate. Do not infer a Phase 2C.D from numbering alone.

Preserve the older dirty recovery worktrees and the separate
`art/dungeon-environment-prototype` worktree unless a later explicit cleanup
decision says otherwise.
