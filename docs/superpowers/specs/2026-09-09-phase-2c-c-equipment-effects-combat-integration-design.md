# Phase 2C.C — Equipment Effects + Combat Integration Design

**Date:** 9 September 2026
**Status:** APPROVED DIRECTION — APPROACH A
**Canonical roadmap:** DungeonMMO Roadmap v1.31
**Starting server-main baseline:** `8587c1546aa1689b69606f860fb5c18a847de617`
**Accepted Phase 2C.B checkpoint:** `fd0d73df70b97efc4b3fb241e2fc6e5061a3ed47`
**Accepted Phase 2C.B gameplay merge:** `0edc542fafccd4a05c13a0a8940718575e536ab2`

## 1. Purpose

Phase 2C.C makes the accepted six-slot persistent equipment state materially
influence server-authoritative combat without creating a second equipment
system or destabilising accepted race, progression, skill, revive, dungeon or
completion behaviour.

The gate proves one reusable equipment-stat interpretation path. It does not
attempt final balance or large-scale content production.

## 2. Locked inputs

The only authoritative equipped-state source remains the Phase 2C.B character
`Equipment` table with these slots:

- `Weapon`
- `OffHand`
- `Helmet`
- `Body`
- `Gloves`
- `Boots`

Each slot continues storing an `ItemId`. No unique instances, affixes,
durability or enhancement are added.

## 3. Architectural choice

Use Approach A: runtime equipment snapshot plus one resolver.

Persistent profile equipment remains owned by `EquipmentService`. Combat does
not query inventory or persistence for every hit. Instead, the authoritative
character is snapshotted into `ProgressionRuntimeState`, including Equipment,
and a single pure equipment-stat resolver interprets the equipped item IDs.

The runtime layer remains the sole combat-facing source for resolved character
stats.

## 4. Equipment modifier model

Representative equipment definitions gain a small `CombatModifiers` table.
The first proof supports only:

- `PhysicalDamageBonus`: additive bonus applied to the existing physical
  multiplier after accepted Strength/race logic;
- `MaxHealthFlat`: flat addition after accepted Vitality/race max-health logic;
- `CriticalChanceBonus`: additive bonus before the existing critical-hit
  clamp/resolution.

No equipment modifier may silently replace racial baselines, attack-rate rules,
critical-damage rules or Spirit/Mend behaviour.

Empty equipment must resolve to neutral modifiers and reproduce the accepted
pre-2C.C combat values exactly.

## 5. EquipmentStatResolver

Add one pure shared module responsible for interpreting equipped item IDs.

Inputs:

- character Equipment table or equivalent six-slot snapshot.

Outputs:

- aggregate `PhysicalDamageBonus`;
- aggregate `MaxHealthFlat`;
- aggregate `CriticalChanceBonus`;
- authoritative weapon tags derived from the equipped Weapon definition;
- representative presentation IDs/categories needed by sword/shield
  presentation.

Rules:

- iterate only canonical EquipmentSlots.ORDER;
- unknown/malformed item IDs are ignored safely;
- only `Kind == "Equipment"` definitions contribute;
- item definition Slot must match the slot being resolved;
- non-finite/invalid modifier values are ignored;
- modifier aggregation is deterministic and order-independent;
- weapon tags come from item definition metadata, not client state or Tool
  existence.

The resolver has no Player, DataStore, RemoteEvent, Workspace or UI dependency.

## 6. Representative content

Use existing representative equipment only. Add effects to the Marauder set
sufficient to prove all accepted slots matter without claiming final balance.

Recommended working values:

- Marauder Sword: `PhysicalDamageBonus = 0.10`, weapon tag
  `OneHandedSword`;
- Marauder Shield: `MaxHealthFlat = 8`;
- Marauder Helmet: `MaxHealthFlat = 4`;
- Marauder Armour: `MaxHealthFlat = 10`;
- Marauder Gloves: `PhysicalDamageBonus = 0.03`,
  `CriticalChanceBonus = 0.01`;
- Marauder Boots: `MaxHealthFlat = 3`.

These are WORKING prototype values only. Final gear balance is explicitly
outside 2C.C.

The existing test-only Elf helmet may carry a harmless representative effect
for resolver coverage, but it remains test-only and must not expand public
content scope.

## 7. Runtime state

`ProgressionRuntimeState.set_character` expands its internal snapshot to retain
an authoritative deep-cloned Equipment table in addition to Identity and
Progression.

Resolved equipment effects are computed from that runtime snapshot.

Combat-facing getters become:

- existing physical multiplier, augmented by equipment physical bonus;
- existing critical chance, augmented by equipment critical bonus and clamped
  to 0..1;
- existing critical damage multiplier unchanged;
- existing basic attack rate unchanged;
- existing heal multiplier unchanged;
- existing max health plus equipment flat max health;
- authoritative weapon tags from the runtime equipment snapshot.

The accepted public `get_snapshot()` contract remains Progression-shaped for
compatibility; Equipment is internal runtime state unless exposed through a
purpose-built equipment/stat snapshot.

## 8. Base mutation and preview behaviour

Equipment remains mutable only in Base through `EquipmentService`.

After a successful equip/unequip action, Base must refresh
`ProgressionRuntimeState` from the latest authoritative profile character and
reapply runtime stats before sending refreshed snapshots.

This allows MaxHealth and stat previews to reflect equipment immediately in
Base without client-side authority.

## 9. Dungeon run locking

Dungeon admission already loads the authoritative profile character and seeds
`ProgressionRuntimeState`. Including Equipment in that deep-cloned snapshot
makes the run use the equipment brought into the Dungeon.

Equipment mutation remains rejected in Dungeon context.

Newly looted equipment can enter Inventory but must not alter the active
runtime equipment snapshot or active combat stats.

Reconnect may rebuild the runtime snapshot from the same persisted Equipment
because Dungeon code cannot mutate Equipment during the run. No duplicate
`RunEquipment` field is added to DungeonSessionService in this gate.

## 10. Skill/weapon requirements

Persistent Equipment becomes the authoritative source for weapon tags.

`ArcSlash` must continue requiring `OneHandedSword`, but the server should
resolve that tag from the runtime equipped Weapon definition rather than from
the existence of a prototype Tool.

Tool/model presentation is non-authoritative.

`ShieldBash` remains available under its accepted skill/loadout rules. This gate
does not introduce a new shield requirement unless a separate future design
explicitly approves it.

## 11. Prototype sword/shield presentation

Keep the accepted prototype presentation pipeline, but make representative
spawn/presentation equipment-aware where practical:

- current sword presentation is shown when the authoritative equipped Weapon
  is the representative one-handed sword;
- current shield presentation is shown when the authoritative OffHand is the
  representative shield;
- missing/unsupported equipment must not grant gameplay stats merely because a
  visual object exists;
- no generic armour visual system is added in 2C.C.

Presentation failure must not become a source of authoritative combat stats.

For standalone Dungeon Studio acceptance only, a narrowly scoped Studio-only
bootstrap may seed the existing representative Marauder loadout into the
in-memory Studio character. It must be guarded by `RunService:IsStudio()`, must
not run in published TEST/PROD, and must not change production equipment
authority or persistence rules.

## 12. Base equipment UI

The Base equipment panel must show meaningful effects rather than only names
and eligibility.

The server equipment snapshot should expose sanitized data sufficient to show:

- per-item modifier lines;
- aggregate currently equipped modifiers;
- a server-computed preview/delta for the selected candidate item in its slot.

The client renders these values but does not calculate authoritative totals.

Final MMO-quality UI art remains deferred.

## 13. Combat preservation boundary

Phase 2C.C must preserve:

- Human and Elf racial baselines/passives;
- existing crit roll and crit-damage rules;
- Human/Elf basic attack-rate behaviour;
- Strength physical scaling;
- Spirit/Mend scaling;
- Mend channel/cancellation and proficiency behaviour;
- Shield Bash behaviour;
- Arc Slash rank/loadout/proficiency behaviour;
- loadout persistence and mutation rules;
- death, revive and defeat behaviour;
- checkpoint/reconnect behaviour;
- completion eligibility/reward behaviour;
- Phase 2C.B ownership, eligibility and Base-only equipment mutation.

## 14. Deliberate non-goals

Do not add in Phase 2C.C:

- Mage/Ranger implementation;
- advanced classes or advancement quests;
- crafting/trading/economy;
- unique item instances;
- random affixes;
- durability;
- enhancement;
- final gear-stat balancing;
- large equipment-content production;
- Race Change/Robux systems;
- environment-art work;
- generic armour mitigation;
- block-efficiency/guard-efficiency item stats;
- status resistance or elemental resistance.

The latter defensive stat families can be introduced later through the same
resolver without redesigning this architecture.

## 15. Migration

No profile schema version bump is required solely for 2C.C because combat
metadata lives in item definitions and the accepted v5 Equipment table already
stores item IDs.

The previous legacy live-migration proof remains waived only for this
pre-player TEST project. That waiver is NOT a PASS. A real live migration proof
remains required before a future release involving existing player profiles.

## 16. Automated proof requirements

Automated coverage must prove at minimum:

### Resolver

- empty equipment resolves neutral modifiers;
- each supported modifier family aggregates correctly;
- wrong-slot, unknown, non-equipment and malformed entries do not contribute;
- weapon tags come from equipped Weapon metadata;
- unsupported modifier keys do not affect combat results.

### Runtime combat

- empty equipment produces accepted baseline physical damage, crit and health;
- Marauder Sword increases physical output without changing attack rate;
- armour/shield max-health additions stack deterministically;
- Gloves critical bonus composes with accepted Dexterity/race crit and remains
  clamped;
- Mend healing multiplier is unchanged by current representative gear;
- race critical-damage multiplier remains unchanged;
- runtime weapon tags drive Arc Slash eligibility.

### Dungeon lock

- runtime Equipment is deep-cloned;
- mutating the source character Equipment after `set_character` does not change
  active runtime stats;
- mutating Inventory/adding loot does not change active runtime stats;
- reseeding runtime state from authoritative character does update stats, which
  is allowed in Base and on legitimate run reconstruction.

### Base equipment snapshot/UI data

- snapshot includes sanitized item effects;
- current aggregate effects are server-resolved;
- candidate preview replaces only the selected slot when calculating delta;
- ineligible/unowned items do not gain authority through preview data.

### Presentation

- representative sword/shield presentation decisions follow authoritative
  runtime Equipment;
- visual absence/presence cannot create an authoritative weapon tag.

### Regression

Existing accepted race, progression, skill, combat, dungeon, revive,
completion and equipment-service test families remain green.

## 17. Build and repository checks

Before user gameplay/visual acceptance:

- observe each new RED before corresponding production implementation where the
  environment permits execution;
- keep changed-file boundaries limited to the approved 2C.C architecture;
- `git diff --check` equivalent must be clean;
- build both Base and Dungeon with Rojo to timestamped TEMP-only outputs;
- do not overwrite normal rbxl files;
- no PROD, paid revive activation, monetisation change or Robux spend;
- art/dungeon-environment-prototype remains untouched.

## 18. Manual acceptance boundary

User involvement is deferred until an actual Roblox Studio gameplay/visual
check is needed.

Expected final manual evidence includes:

- Base equipment panel clearly shows current item effects and candidate deltas;
- equipping/unequipping representative gear visibly changes the intended stats;
- sword/shield presentation follows equipped state;
- Dungeon combat uses the gear brought into the run;
- newly looted equipment does not alter the current run;
- accepted Mend, Shield Bash, Arc Slash, race behaviour, revive and completion
  still work with no obvious regressions.

RED-test output alone is not a reason to involve the user.

## 19. Git safety

Gameplay work must not be developed directly on `main`.

The separate `art/dungeon-environment-prototype` worktree/branch is strictly
off limits.

No repository commit, push, merge or Roblox publish occurs without the
appropriate explicit user approval gate.
