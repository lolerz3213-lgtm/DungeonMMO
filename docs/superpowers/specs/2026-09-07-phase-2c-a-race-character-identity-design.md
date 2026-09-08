# Phase 2C.A Design  -  Race + Character Identity Foundation

Date: 2026-09-07
Status: Approved design
Parent phase: Phase 2C  -  Race/Class Progression
Implementation gate: 2C.A only

## Purpose

Phase 2C.A introduces persistent race and base-class identity while preserving the accepted Phase 2B progression/persistence baseline. It leaves the game with two complete race identities  -  Human Fighter and Elf Fighter  -  and a data model ready for the later tutorial-before-class flow.

## Scope

Included: persistent identity, Human/Elf definitions, racial passives, racial starting attributes, signed attribute effects, crit foundation, racial basic-attack speed, race-aware AP/respec, legacy Phase 2B migration, new-character race->Fighter selection, unresolved-identity progression lock, Elf ears presentation, level cap 20, approved XP curve, Base/Dungeon persistence and regressions.

Excluded from 2C.A: tutorial battle, detailed race districts, trainer architecture, equipment restrictions, advanced classes, advancement quests, advanced-class actives/passives, trading/economy, race/class reset systems.

## Architecture

Use separate data-driven race and class definitions. Profiles persist IDs and progression state; balance values remain in definitions. Race owns inherent starting attributes/passive/visual marker. Base class owns starter skills and future equipment/trainer rules. Advanced class later owns specialization. Do not create combined IDs such as `ElfFighterRogue`.

## Persistent identity

Each character gains a dedicated identity block:

```text
Identity
  Version
  RaceId
  BaseClassId
  ClassId
  CreationStage
```

Completed Human/Elf Fighter:

```text
RaceId = "Human" or "Elf"
BaseClassId = "Fighter"
ClassId = "Fighter"
CreationStage = "Complete"
```

New unresolved character:

```text
RaceId = nil
BaseClassId = nil
ClassId = nil
CreationStage = "RaceSelection"
```

After race choice and before class choice:

```text
RaceId = chosen race
BaseClassId = nil
ClassId = nil
CreationStage = "ClassSelection"
```

Base-class choice is permanent during normal gameplay. Future race/class reset is a separate system.

## Future tutorial compatibility

2C.A flow:

```text
Choose Race -> Choose Fighter -> Enter Base
```

Later intended flow:

```text
Choose Race -> Tutorial Battle -> Choose Base Class -> Enter Base
```

Tutorial skills are temporary trial skills only: no permanent learning, proficiency, SP cost, or saved progression from using them.

## Race definitions

### Human

Starting attributes:

```text
STR 5 / DEX 4 / VIT 6 / INT 5 / SPI 5
```

Innate passive: **Human Resolve**

- Max Health multiplier: `1.08`
- Basic weapon attack-speed rate multiplier: `0.95`
- Critical-damage bonus: `+0.15`

Always active, no SP cost, no active slot, separate from normal learned skills. Human keeps the normal Roblox avatar presentation.

### Elf

Starting attributes:

```text
STR 5 / DEX 6 / VIT 4 / INT 5 / SPI 5
```

Innate passive: **Elven Grace**

- Max Health multiplier: `0.92`
- Basic weapon attack-speed rate multiplier: `1.08`
- Critical-chance bonus: `+0.05` (five percentage points)

Always active, no SP cost, no active slot, separate from normal learned skills. Elf preserves normal avatar customization and adds permanent elongated pointed ears as a race presentation layer, not equipment.

Only RaceId is persisted; balance values remain in definitions.

## Base class in 2C.A

`Fighter` is the only selectable base class in this gate, but selection must be data-driven.

Starter actives:
- Shield Bash
- Mend

Arc Slash remains learned through the accepted Phase 2B reward/book path.

Fresh profiles must not pre-seed Fighter starter skills before Fighter selection. Shield Bash and Mend are granted exactly once when Fighter selection commits. Existing Phase 2B characters keep their existing skill state.

## Attribute model

### Neutral reference vs racial baseline

Value `5` remains the neutral combat reference. The race definition supplies the unspent allocation baseline.

Example Elf DEX 8:

```text
racial baseline DEX = 6
current DEX = 8
earned investment = 2 AP
```

### Spending and respec

For each attribute:

```text
spent AP = current value - chosen racial baseline
```

Normal allocation cannot reduce below the racial baseline. Total spent AP cannot exceed persisted AttributePointEntitlement.

Respec returns to:

```text
Human: 5 / 4 / 6 / 5 / 5
Elf:   5 / 6 / 4 / 5 / 5
```

Only earned AP is refunded.

### Signed effects around neutral 5

Attributes below 5 create a real downside; attributes above 5 create a benefit. For Strength, Vitality and Spirit, preserve the current diminishing-return shape but make it signed around 5:

```text
delta = attributeValue - 5
signedEffectiveDelta = sign(delta) * effectiveInvestment(abs(delta))
```

Use that for physical damage (STR), Max Health contribution (VIT), and healing (SPI). Intellect remains plumbing-only in 2C.A. DEX affects crit chance below.

## Critical-hit model

Base crit chance: `5%`
Base crit damage: `150%`

DEX contribution:

```text
(Dexterity - 5) * 0.5 percentage points
```

Level-1 Human Fighter:

```text
Crit chance: 4.5%
Crit damage: 165%
```

Level-1 Elf Fighter:

```text
Crit chance: 10.5%
Crit damage: 150%
```

Crit chance is safety-clamped to a valid probability. Crit rolls and resulting damage are server-authoritative. Tests must be able to inject deterministic roll values.

## Max Health ordering

```text
base health
+ signed Vitality contribution
then racial Max Health multiplier
then future equipment/class/passive modifiers
```

Human Resolve and Elven Grace are the named containers for the racial modifiers; there is no hidden second racial bonus layer.

## Basic attack speed

Racial attack speed affects normal weapon basic attacks only. It does not affect Mend, skill cooldowns, dodge, movement speed, unrelated animations, or arbitrary class skills.

Attack-rate multipliers:

```text
Human = 0.95
Elf   = 1.08
```

Authoritative timing:

```text
adjusted duration = base duration / attackRateMultiplier
```

Matching attack animation playback stays synchronized. Extend the existing combat pipeline; do not create a parallel race-specific attack controller.

## Legacy Phase 2B migration

Existing Phase 2B characters are not silently assigned a race. On first Phase 2C.A login:

```text
RaceId = nil
BaseClassId = "Fighter"
ClassId = "Fighter"
CreationStage = "LegacyRaceSelection"
```

They choose Human or Elf once.

### Unresolved progression lock

Before race selection commits, block at minimum: dungeon entry, trainer use, AP spend, AP respec, SP spend, permanent proficiency gain, and any progression mutation dependent on race/class. Disconnecting before confirmation changes nothing.

### Attribute translation

For each stat:

```text
oldEarned = oldAttribute - 5
newAttribute = chosenRaceBaseline + oldEarned
```

Example:

```text
Old: 7 / 5 / 6 / 5 / 5
Earned: +2 STR, +1 VIT
Choose Elf base: 5 / 6 / 4 / 5 / 5
Result: 7 / 6 / 5 / 5 / 5
```

No AP is minted or lost.

### Preserved state

Preserve level, XP, Gold, inventory, DungeonProgress, RewardHistory, AP/SP entitlement, learned skills, ranks, proficiency, loadout, Arc Slash/book state, respec counters/history, and all other accepted Phase 2B progression.

### Atomic/idempotent

Legacy race choice is irreversible under normal 2C.A rules. Duplicate selection after commit is rejected. Translation runs only once for unresolved legacy identity. Identity selection and translation happen in one authoritative profile mutation; failure leaves the old unresolved state intact.

## New-character selection flow

1. load unresolved identity;
2. choose Human or Elf;
3. server validates/commits race;
4. move to class selection;
5. choose Fighter;
6. server validates;
7. grant Shield Bash + Mend exactly once;
8. set Fighter IDs and `CreationStage = "Complete"`;
9. enter normal Base gameplay.

## Identity gating

Normal progression systems require `CreationStage == "Complete"` unless explicitly part of creation/migration. Server enforcement is mandatory. Rejections use stable machine-readable reason codes.

## Race presentation

Human: no additional required geometry.

Elf: permanent pointed ears preserving avatar body/face/hair/clothing/customization; survives respawn, Base/Dungeon transfers and rejoin; not inventory/equipment.

The first ear asset may be functional rather than final art. Do not touch or merge the separate environment-art branch/work during 2C.A.

## Level cap and XP curve

Increase max level from 10 to 20.

```text
10 -> 11 : 1100 XP
11 -> 12 : 1325 XP
12 -> 13 : 1575 XP
13 -> 14 : 1850 XP
14 -> 15 : 2150 XP
15 -> 16 : 2475 XP
16 -> 17 : 2825 XP
17 -> 18 : 3200 XP
18 -> 19 : 3600 XP
19 -> 20 : 4025 XP
```

Entitlement remains `level - 1`, so Level 20 has 19 AP and 19 SP entitlement.

Existing Level-10 characters remain Level 10 with 0 XP toward Level 11. No retrospective XP is granted. Level 20 is a hard cap and does not bank invisible XP.

## Authority/data flow

Race selection:

```text
client UI -> request -> server validates stage/RaceId -> RaceDefinitions -> authoritative mutation -> runtime snapshot -> client
```

Class selection:

```text
client UI -> request -> server validates race/stage/ClassId -> class definition -> mutation + starter grant -> runtime snapshot -> complete state
```

Combat:

```text
profile/runtime identity -> race definitions -> derived stats -> server combat resolution -> replicated result/presentation
```

## Error handling

Fail closed. Reject unknown RaceId, unavailable ClassId, wrong creation stage, class-before-race, duplicate legacy choice, and gated progression attempts. Malformed persisted identity must sanitize/migrate to a safe unresolved state rather than inventing a race. Failed profile mutation leaves prior authoritative state intact. Presentation failure must never rewrite saved identity.

## Phase 2B compatibility

Preserve server-authoritative progression, persistence/lease behaviour, Shield Bash, Mend, Arc Slash reward path, skill ranks/proficiency/loadout, death/free revive, block/parry/dodge, and Base/Dungeon transfer state unless this spec explicitly changes them.

## Testing strategy

Pure/definition tests cover race definitions, baselines, passive values, signed attribute derivation, DEX crit contribution, crit derivation/clamping/deterministic rolls, attack-rate timing, XP table and Level-20 entitlement.

Attribute tests cover race-specific minimums, spending against racial baseline, below-baseline rejection, overspend rejection, Human/Elf respec and earned-only refund.

Migration tests cover unresolved legacy state, exact once-only translation, both races, preserved progression, no AP/SP duplication, disconnect-before-choice, and no remigration after rejoin.

Creation tests cover unresolved new profiles, no permanent Fighter skills before Fighter selection, valid/invalid race selection, class-before-race rejection, exactly-once starter grant and rejoin persistence.

Identity-gate tests prove unresolved characters cannot enter dungeon, use trainers, spend/respec AP, spend SP, or gain permanent proficiency.

Combat tests prove Human/Elf Max Health, attack cadence, synchronized hit windows, Human 4.5% crit/165% crit damage, Elf 10.5% crit/150% crit damage, client cannot force crit/damage, and Phase 2B combat regressions pass.

Presentation tests prove Elf ears attach and persist while preserving avatar customization.

Progression tests prove 10->11, multi-level XP carry, approved XP table, Level-20 cap, 19 AP/SP entitlement, and existing Level-10 migration starting at 0 XP.

Published acceptance requires both Base and Dungeon builds, temporary/recovery outputs only, TEST/published persistence rather than PROD, Base->Dungeon->Base->leave->rejoin for new and migrated characters, and relevant Phase 2B regressions. No PROD DataStore mutation, paid revive or Robux spend.

## 2C.A acceptance criteria

New Human and New Elf each complete race->Fighter selection, receive the correct baseline/passive/starter skills, derive correct combat stats, and survive rejoin. Elf ears persist.

Legacy Human and Legacy Elf each migrate exactly once, preserve earned allocation and all accepted Phase 2B state, avoid AP/SP duplication, and survive published TEST rejoin.

Respec returns to race baseline only. Combat racial health/attack-rate/crit effects are correct and server-authoritative. Levels 11-20 use the approved XP table and Level 20 has exactly 19 AP/SP entitlement.

## Later Phase 2C gates

### 2C.B  -  Equipment + Trainer Architecture
- weapon/armour categories;
- server-authoritative class restrictions;
- Human Quarter / Elven Enclave placeholders;
- race-specific Fighter trainers;
- advanced trainer placeholders;
- data-driven trainer catalogues.

### 2C.C  -  Class Advancement
- Barbarian / Guardian / Rogue / Warden definitions;
- temporary Level-10 advancement requirement;
- distinct trainer-led advancement quests;
- permanent advancement choice;
- safe incompatible-equipment unequip;
- invalid inherited-skill loadout cleanup.

### 2C.D  -  Advanced Class Combat Identity
- one unique active + one unique passive per advanced class;
- advancement grants passive + Rank-1 signature active;
- advanced trainers upgrade valid inherited + class skills;
- class-granted active has Rank-1 respec floor;
- class passive is not removable by normal skill respec;
- full advanced-class combat/equipment/persistence acceptance.

Working advanced identities:
- Human Fighter -> Barbarian: Rending Cleave + Blood Fury
- Human Fighter -> Guardian: Protector's Challenge + Iron Bulwark
- Elf Fighter -> Rogue: Shadowstep + Keen Edge
- Elf Fighter -> Warden: Warden's Blessing + Aegis of the Grove

These later gates must not be implemented as part of 2C.A.
