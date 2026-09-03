# Step 4 Combat Hit and Damage Architecture

**Date:** 2026-09-03  
**Project:** DungeonMMO  
**Status:** Approved design awaiting implementation  
**Milestone:** Phase 1, Step 4 - Server-authoritative hit detection and damage

## Goal

Add the first real combat-result pipeline to DungeonMMO: server-authoritative
melee hit detection, target validation, and damage application against NPCs,
while keeping the architecture open for future projectiles, area-of-effect
attacks, PvP areas, attributes, proficiency, buffs, defence, critical hits,
and other combat modifiers.

## Design Principles

- The client may request an attack, but never tells the server what it hit.
- Combat state and attack timing remain server-authoritative.
- Hit delivery is separate from target legality and damage calculation.
- Melee, projectile, and AoE attacks must be able to share the same target
  validation and damage pipeline.
- PvP is not enabled in this milestone.
- Player targets are rejected for now, but PvP-area rules can be added later
  without rewriting melee or damage systems.
- Health uses `Humanoid.Health` for both NPCs and future player characters.
- Damage math remains simple in this milestone:
  `weapon base damage * attack multiplier`.

## Architecture

```text
CombatService
    |
    | enters an authoritative attack Active window
    v
MeleeHitService
    |
    | finds candidate targets using swept server overlap volumes
    v
CombatTargetRules
    |
    | confirms target is legal for this combat context
    v
DamageService
    |
    | calculates final prototype damage
    v
Humanoid.Health


Future delivery systems:

ProjectileService -----------\
AreaEffectService ------------> CombatTargetRules -> DamageService
EnemyAttackService ----------/
Trap/EnvironmentService -----/
```

`MeleeHitService` is deliberately melee-specific. Future ranged or AoE
delivery systems do not need to understand sword reach, sword active windows,
or melee overlap sampling.

## Shared Damage Context

Damage delivery systems should pass structured context rather than use a
melee-specific function signature.

Initial conceptual data:

```lua
export type DamageContext = {
    attacker: Player?,
    attacker_character: Model?,
    target: Model,
    source_kind: string,
    source_id: string,
    attack_id: string?,
    base_damage: number,
    multiplier: number,
}
```

Examples of future `source_kind` values may include:

- `Melee`
- `Projectile`
- `AreaEffect`
- `EnemyMelee`
- `Trap`
- `DamageOverTime`

The first implementation only requires `Melee`, but the shared damage service
must not depend on melee geometry.

## CombatTargetRules

`CombatTargetRules` determines whether a candidate model is legally
damageable in the supplied combat context.

For Step 4, a target is valid when:

- it is a Model;
- it has a living Humanoid;
- it is not the attacker's own character;
- it is registered/tagged as an NPC combat target;
- it is not a player character.

This service is intentionally separate from `MeleeHitService`.

Future rules can extend this boundary with:

- PvP-zone checks;
- teams/factions;
- friendly fire;
- safe zones;
- invulnerability states;
- summoned creatures;
- ownership;
- neutral NPC behaviour.

## MeleeHitService

`MeleeHitService` performs server-side melee target acquisition.

### Behaviour

For each authoritative attack Active window:

1. Read the attacker character's server `HumanoidRootPart`.
2. Read attack hit-volume configuration from `CombatConfig`.
3. Sample a configured box multiple times throughout the Active duration.
4. Query overlapping parts on the server.
5. Resolve overlapping parts to candidate character/NPC Models.
6. Reject candidates through `CombatTargetRules`.
7. Perform an obstruction raycast from attacker toward the candidate.
8. Reject candidates blocked by solid level geometry.
9. Deduplicate accepted targets for the current swing.
10. Send each accepted target to `DamageService` exactly once.

### Cleave

One melee swing may damage multiple valid NPCs.

The same NPC can never take damage more than once from one attack, even if it
appears in several overlap samples.

### Geometry

Melee hit volumes are based on the attacker's server-facing direction and
configured attack dimensions. They do not follow the visual prototype sword.

This keeps gameplay deterministic and independent from cosmetic animation
timing.

### Attack Configuration

Hit volumes belong in `CombatConfig`, not hardcoded in the service.

Each basic sword attack should define enough information for the service to
construct its volume, for example:

```lua
HITBOX = {
    SIZE = Vector3.new(...),
    FORWARD_OFFSET = ...,
    SAMPLE_COUNT = ...,
}
```

Existing reach and arc values remain combat design data and can guide the
chosen box dimensions.

Different future melee weapons can use different dimensions without changing
`MeleeHitService`.

## DamageService

`DamageService` receives an already validated target plus damage context.

For Step 4:

```text
Prototype sword base damage = 10

Slash1:
10 * 1.00 = 10

Slash2:
10 * 1.05 = 10.5

Finisher:
10 * 1.35 = 13.5
```

Damage is not rounded internally.

The service applies the result to the target Humanoid.

The damage service must not:

- search for targets;
- perform overlap queries;
- know sword hitbox dimensions;
- trust client-provided target information;
- contain PvP-zone geometry logic.

Future damage modifiers can be added inside or around this boundary:

```text
Base damage
    -> attack/skill multiplier
    -> Strength/Dexterity/Magic
    -> weapon or skill proficiency
    -> buffs/debuffs
    -> target defence/resistance
    -> critical modifiers
    -> final damage
```

Those systems are explicitly outside Step 4.

## Training Dummy

Add a stationary Training Dummy to the greybox arena.

The dummy must:

- be identifiable as an NPC combat target;
- contain a Humanoid;
- have enough health to survive multiple sword attacks;
- be excluded from player controls;
- provide clear development diagnostics when damaged;
- be positioned so front, edge, range, behind-wall, and multi-target tests
  are practical.

The implementation may create more than one dummy when debug/testing mode is
enabled if that materially improves cleave and obstruction testing.

## Ranged and AoE Compatibility

Future ranged attacks should use their own delivery system.

Examples:

```text
Bow:
ProjectileService detects arrow impact
    -> CombatTargetRules
    -> DamageService

Fireball direct impact:
ProjectileService detects impact
    -> CombatTargetRules
    -> DamageService

Fireball explosion:
AreaEffectService queries targets inside explosion radius
    -> CombatTargetRules for each candidate
    -> DamageService for each accepted target
```

An AoE may damage multiple legal targets, just like melee cleave, but its
target acquisition is based on an area/radius rather than a sword swing.

Per-source deduplication remains the responsibility of the delivery system.
For example, one explosion should not damage the same target twice unless its
specific design explicitly says otherwise.

## Security

The client never supplies:

- hit target;
- damage amount;
- final hit position used to authorize damage;
- list of enemies hit.

The existing attack request remains an intent request.

The server:

- validates attack state;
- owns the Active window;
- owns target acquisition;
- owns target legality;
- owns damage calculation;
- owns health mutation.

Malformed/spammed attack requests therefore cannot directly create arbitrary
damage events.

## Debugging

Add combat debug configuration that can enable:

- melee volume visualization;
- accepted/rejected target diagnostics;
- damage diagnostics.

Example development output:

```text
[MeleeHit] Slash1 sample 2/4
[MeleeHit] TrainingDummy accepted
[Damage] TrainingDummy -10.0 HP
```

Debug presentation must be optional and removable by configuration rather
than requiring code deletion.

## Test Requirements

Automated and/or deterministic tests must cover:

1. Target directly in front is accepted.
2. Target beyond reach is not hit.
3. Target behind the attacker is not hit.
4. Target at the valid edge can be hit.
5. Two NPCs in one swing can both be hit.
6. One NPC detected in several Active samples is damaged once.
7. Solid geometry between attacker and target blocks the hit.
8. A dead NPC is rejected.
9. A player character is rejected.
10. The attacker cannot hit themselves.
11. Repeated client attack requests cannot create extra independent damage
    windows outside valid server combat state.
12. Slash1 uses multiplier 1.00.
13. Slash2 uses multiplier 1.05.
14. Finisher uses multiplier 1.35.
15. DamageService accepts a generic damage context rather than melee geometry.
16. Existing combat, animation, weapon, and one-handed sword tests remain
    green.

## Step 4 Scope

Included:

- `CombatTargetRules`
- `MeleeHitService`
- `DamageService`
- Training Dummy
- sword base damage
- sword hit-volume configuration
- swept Active-window sampling
- melee cleave
- per-swing deduplication
- geometry obstruction
- server-side debug diagnostics
- tests

Not included:

- PvP
- PvP areas
- player-versus-player damage
- attributes
- Strength/Dexterity/Magic scaling
- skill proficiency
- armour/defence
- resistances
- critical hits
- status effects
- knockback tuning
- projectiles
- AoE implementation
- ranged weapons
- spells

Those future systems are explicitly supported by the boundaries above but are
not implemented in Step 4.
