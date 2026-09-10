# Phase 2C.D — Mage Base-Class + Support Foundation Design

**Date:** 10 September 2026
**Baseline:** `38feb4a3c15286c56a98ab686357b7cf30f2c693`
**Status:** Project-owner approved design, extended after v5 Studio playtest

## Purpose

Phase 2C.D adds Mage as the second selectable starting archetype while preserving the accepted Fighter, race, progression, equipment, dungeon, revive and completion contracts. The gate establishes reusable ranged-magic, Mana, healing, absorption-shield, charged-cast and anti-kiting foundations without expanding into a broad spell tree.

## Locked player-facing design

Human and Elf may both begin as Mage. Later class progression may diverge by race; that later progression is outside 2C.D.

Mage begins with:

- a free ranged **Spirit Orb** basic attack;
- **Wind Strike**, a charged Intellect-scaled ranged damage skill;
- **Arcane Ward**, a Spirit-scaled temporary absorption shield;
- **Mage Heal**, a stronger Spirit-scaled heal for self or aimed allies; and
- one automatically granted/equipped **Apprentice Arcane Wand**.

Spirit Orb is a **basic attack**, not a hotbar skill and not a Mana spender.

### Spirit Orb basic combo

The Mage basic attack uses the existing three-step combat cadence internally but changes delivery by authoritative weapon family:

1. normal Spirit Orb — ranged, single target;
2. normal Spirit Orb — ranged, single target;
3. visibly larger Spirit Orb — travels as a projectile, then bursts into a small server-authoritative AoE on collision or maximum range.

Orbs are real travelling projectiles. They do not home. The server determines origin, facing, travel, collision, range, legal targets and damage. Intellect is the primary damage stat.

While an `ArcaneWand` basic attack is in WindUp, Active or Recovery, the Mage is **fully movement-locked**: WalkSpeed is zero and jumping is disabled. Block or Dodge remains higher-priority and may cancel the committed attack. This intentionally creates a closing window for melee enemies and prevents permanent damage-while-kiting.

The accepted persistent Equipment snapshot, not a client Tool, determines whether the player has `ArcaneWand` authority.

### Wind Strike charged damage skill

Wind Strike is the Mage starter damage skill and establishes the reusable charged-cast contract for later spells.

Prototype Rank 1:

- 30 base magical damage before Intellect scaling;
- 25 Mana;
- 5 second cooldown;
- 1.0 second charge/wind-up;
- 0.08 second release window;
- 0.35 second recovery;
- 60 stud maximum range;
- fast visible ranged projectile;
- requires authoritative `ArcaneWand` equipment.

The Mage is fully movement-locked while charging, releasing and recovering. The character visibly builds magical energy around the Wand/hand during the charge so commitment is obvious.

**Block or Dodge may cancel Wind Strike during charge.** A cancelled charge:

- fires no projectile;
- deals no damage;
- consumes no Mana; and
- starts no Wind Strike cooldown.

Mana and cooldown commit only when the charge successfully reaches its release/Active phase. This preserves defensive responsiveness without making a cancelled cast doubly punitive.

Wind Strike does not home. Server authority owns facing, launch, travel, collision, target legality and damage.

### Unarmed fallback

If the authoritative Weapon slot is empty or has no supported weapon-family tag, the player retains a deliberately weak melee/fist basic attack so selling or removing a weapon cannot strand the character.

Unarmed attacks grant no weapon tags. Weapon-dependent skills remain unusable until the required authoritative Equipment is present again. Cosmetic/fake Tools never grant skill authority.

### Mage weapon direction

The 2C.D Mage weapon is a **one-handed Arcane Wand/Focus**, leaving OffHand available for later tomes, crystals, or support items.

A slower, harder-hitting two-handed Staff family is a future direction. Two-handed slot locking is explicitly outside this gate.

## Resource model

Stamina remains the universal physical exertion/defence resource used by dodge/block and Fighter active skills.

Mage additionally has runtime Mana:

- **Intellect** — primary magical damage; secondary Max Mana contribution.
- **Spirit** — primary Max Mana contribution, Mana regeneration, healing and Ward scaling.

Mana uses the existing diminishing-return/effective-point philosophy.

Prototype baseline values at Intellect 5 / Spirit 5:

- Max Mana: 100
- Mana regeneration: 8 per second
- regen delay after spend: 1 second
- Max Mana per effective Spirit delta: +6
- Max Mana per effective Intellect delta: +2
- Mana regeneration per effective Spirit delta: +0.5/s

Current Mana is runtime state and is not persisted between sessions. Persistent attributes determine the derived maximum/regeneration each run.

## Arcane Ward

Arcane Ward:

- costs Mana and has a cooldown;
- can target a valid aimed ally in range/line-of-sight;
- otherwise falls back to self;
- scales from Spirit;
- creates temporary absorption HP separate from Humanoid Health;
- consumes Ward HP before Health damage;
- does not absorb Stamina/guard damage;
- expires after a finite duration;
- does not stack with another Arcane Ward; recast replaces/refreshes it.

Prototype Rank 1:

- 25 Mana
- 8 second cooldown
- 30 base Ward HP before Spirit scaling
- 6 second duration
- 22 stud support range

The local player receives a visible Ward bar/number showing current and maximum shield HP.

## Mage Heal

Mage Heal:

- costs Mana and has a cooldown;
- requires the authoritative `ArcaneWand` tag;
- targets a valid injured ally the caster is aiming toward, subject to server range and line-of-sight checks;
- otherwise falls back to the caster if the caster is injured;
- rejects when neither an aimed injured ally nor the caster needs healing;
- scales from Spirit;
- clamps at MaxHealth.

Prototype Rank 1 total before Spirit scaling is 40 HP.

**Human Mage:** 80% immediate, 20% residual Heal-over-Time over 4 seconds.
**Elf Mage:** 30% immediate, 70% Heal-over-Time over 6 seconds.

The total baseline value is equivalent; the race changes delivery rather than creating a strictly stronger heal.

Prototype cost/cooldown:

- 30 Mana
- 6 second cooldown
- 22 stud support range

Same-family HoT on the target refreshes/replaces instead of layering unlimited copies.

## Fighter Mend change

Mend remains the weaker Fighter sustain skill but becomes **self-only**.

The accepted five-pulse / 2 second channel remains. In 2C.D it additionally costs 20 Stamina and retains its 8 second cooldown. Mend must never auto-select an injured ally.

## Boss pursuit / anti-kiting rule

The Marauder Captain is the first boss used to validate Mage positional commitment. Its prototype chase speed is raised from 11.5 studs/second to **17.5 studs/second**, intentionally slightly above ordinary 16-stud Roblox player movement.

Normal dungeon Marauders keep their accepted tuning in this gate. The Captain still stops at its existing attack range and keeps its existing attack timings/patterns; only chase speed changes.

The intended combat loop is therefore:

- running creates temporary distance;
- every Mage basic attack roots the caster and lets the boss close;
- Wind Strike creates a longer one-second closing window;
- Block/Dodge can cancel committed casts when survival matters; and
- simply holding distance while dealing uninterrupted damage is no longer sustainable against the boss.

## Server authority and data flow

The client sends only attack/skill intent. The server owns:

- class/race runtime identity;
- authoritative persistent Equipment tags;
- Mana/Stamina spending and cooldowns;
- movement lock during Wand attacks/charged damage skills;
- projectile launch/travel/collision/AoE;
- target legality;
- support targeting range/line of sight;
- Intellect/Spirit scaling;
- Ward absorption;
- healing amounts and HoT timing;
- Wind Strike cancellation and resource/cooldown commit timing.

`DamageService` remains the common Health-damage authority, with Ward absorption immediately before Humanoid damage.

The existing `Slash1`, `Slash2`, `Finisher` identifiers may remain internal timing/combo identifiers. For an authoritative `ArcaneWand`, those states deliver Spirit Orbs instead of sword melee and sword animation presentation is suppressed.

## Persistence

Fresh Mage class selection transactionally grants:

- `WindStrike` Rank 1 starter state;
- `ArcaneWard` Rank 1 starter state;
- `MageHeal` Rank 1 starter state;
- loadout slots 1, 2 and 3 for those skills in that order;
- exactly one Apprentice Arcane Wand in Inventory;
- the Wand in persistent Weapon Equipment.

Mage identity, starter skills, loadout, Inventory/Equipment and attributes persist through Base -> Dungeon -> Base -> rejoin using the accepted schema-v5 architecture.

Legacy pre-race profiles remain Fighter exactly as previously accepted.

## Regression cleanup observed in v5 Studio evidence

The v5 playtest log showed two independent legacy-test mismatches that must be corrected before 2C.D acceptance:

1. `CharacterCombatStatsTest` uses table-based fake Players without the `SetAttribute` method now required by accepted runtime equipment/presentation attributes. The test doubles must implement attribute storage rather than weakening production runtime publication.
2. `HotbarSkillDefinitionTest` still asserts the old Phase 1 rule that Mend costs zero Stamina. The test must be updated to the approved 2C.D self-only, 20-Stamina Mend contract.

These are test-fixture/expectation repairs, not production feature changes.

## Studio acceptance

Standalone Dungeon Studio may use a Studio-only Human Mage bootstrap for this gate because Studio uses the in-memory profile adapter. That bootstrap must never alter production persistence.

Dungeon Equipment remains run-locked. A production mid-run unequip control is not added merely for testing the unarmed fallback; unarmed authority is covered by focused tests and can later be exercised from Base/published handoff when appropriate.

## Out of scope

- Ranger
- secondary/advanced classes
- broad final spell progression
- final VFX/animation/UI polish
- two-handed Staff slot locking
- normal-Marauder retuning
- crafting/economy
- monetisation or Roblox publishing
