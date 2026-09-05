# Step 5 Defensive Combat Architecture

**Date:** 2026-09-03
**Project:** DungeonMMO
**Milestone:** Phase 1, Step 5 - Defensive Combat
**Status:** Approved direction awaiting implementation

## Goal

Add a server-authoritative defensive combat layer for the sword-and-shield
prototype, including stamina, blocking, parrying, forward-roll dodging,
i-frames, guard break, a prototype shield, a stamina HUD, and a stationary
Training Marauder that can exercise all defensive mechanics in Studio.

The implementation will be delivered as one installation package rather than
as separate block/parry/dodge patches.

## Locked Player Controls

- Left Click: free basic three-hit sword combo.
- Right Mouse Button:
  - press starts block;
  - first 0.18 seconds are the parry window;
  - continuing to hold becomes ordinary block;
  - release lowers block.
- Left Shift: committed forward-roll dodge.
- Left Ctrl: View/Screen Lock.

The previous Left Shift View Lock binding is replaced by Left Ctrl.

## Combat States

`CombatService` remains the authoritative combat-state owner.

The existing attack states remain:

- `Locomotion`
- `WindUp`
- `Active`
- `Recovery`

Step 5 adds:

- `Blocking`
- `Dodging`
- `GuardBreak`

Parry is not a separate state. It is a short timestamped window at the start
of `Blocking`.

### Transition principles

- Block may begin only from a legal neutral/locomotion state.
- Dodge may begin only from a legal neutral/locomotion state.
- Basic attacks cannot start while blocking, dodging, or guard-broken.
- Block cannot animation-cancel an attack.
- Dodge cannot animation-cancel an attack.
- Guard Break disables attack, block, parry, and dodge for its duration.
- The server rejects illegal or spammed defensive requests.

## Stamina

A single general Stamina resource is used for defensive movement and future
heavy/special abilities.

### Prototype values

- Maximum Stamina: 100
- Starting Stamina: 100
- Basic light attacks: 0 Stamina
- Dodge cost: 25
- Holding block: 0 passive Stamina cost
- Holding block: completely pauses Stamina regeneration
- Normal regeneration delay after spending Stamina: 1.0 seconds
- Regeneration rate: 25 Stamina/second
- Guard Break regeneration delay: 1.5 seconds

All values live in `CombatConfig` and are expected to be tuned later.

### Stamina ownership

`StaminaService` owns the authoritative Stamina value and regeneration rules.

The server replicates read-only combat attributes for presentation, including
current and maximum Stamina. Clients may display those values but never
choose or award Stamina.

## Blocking

A shield block:

- uses a 120-degree frontal cone;
- prevents 100% of ordinary blockable physical HP damage;
- consumes Stamina only when an attack is actually blocked;
- does not regenerate Stamina while held;
- does not protect attacks outside the frontal cone;
- does not protect attacks explicitly marked unblockable.

Incoming attacks provide their own `stamina_damage` value.

The direction check uses the defender character's facing direction and the
incoming attack/source position.

## Guard Break

If a valid blocked hit consumes the defender's remaining Stamina:

- the triggering hit still deals 0 HP damage;
- Stamina becomes 0;
- block immediately drops;
- the defender enters `GuardBreak`;
- Guard Break lasts 0.8 seconds;
- attack, block, parry, and dodge are disabled;
- Stamina regeneration uses the longer Guard Break recovery delay.

Subsequent attacks during Guard Break are not blocked.

## Parry

The first 0.18 seconds after block begins are the perfect-parry window.

A valid parry:

- negates the incoming hit;
- costs 0 Stamina in the prototype;
- does not Guard Break the defender;
- reports a successful parry result to the incoming attack system;
- requests an attacker stagger/counter-opening duration.

Prototype attacker stagger after parry: 1.0 second.

If the parry window expires while RMB remains held, the player naturally
continues in ordinary `Blocking`.

Only attacks marked `parryable` may be parried.

## Dodge

Left Shift performs a committed forward roll.

### Prototype values

- Stamina cost: 25
- Roll distance: 9 studs
- Total dodge/roll state: approximately 0.55 seconds
- Invulnerability window: approximately first 0.22 seconds
- Direction: character facing at the instant the dodge begins
- Direction cannot curve after the roll starts

The roll must stop short of solid geometry rather than forcing the character
through walls.

If Stamina is below 25, the server rejects the dodge.

During the i-frame window, incoming attacks resolve as `Dodged` and deal no
damage.

## Defence Resolution

`DefenseService` owns defensive outcome resolution. It does not own normal
health damage calculation.

Conceptual flow:

```text
Incoming server-authoritative attack
        |
        v
DefenseService.resolve(...)
        |
        +-- active dodge i-frames? ------> Dodged
        |
        +-- inside parry window? --------> Parried
        |                                  attacker stagger result
        |
        +-- valid frontal block? --------> Blocked
        |                                  spend Stamina
        |                                  possible GuardBreak
        |
        +-- otherwise -------------------> Hit
                                           |
                                           v
                                      DamageService
                                           |
                                           v
                                      Humanoid.Health
```

This keeps `DamageService` generic and allows later enemy melee, projectiles,
boss attacks, and other server-authoritative damage sources to share the same
defence boundary.

## Defence Context

Initial conceptual input:

```lua
export type DefenseContext = {
    attacker: Model?,
    target_player: Player,
    target_character: Model,
    source_kind: string,
    source_id: string,
    attack_position: Vector3?,
    stamina_damage: number,
    blockable: boolean,
    parryable: boolean,
}
```

Conceptual result:

```lua
export type DefenseResult = {
    outcome: string,
    stamina_spent: number,
    attacker_stagger_seconds: number,
}
```

Initial outcome values:

- `Hit`
- `Blocked`
- `Parried`
- `Dodged`
- `GuardBroken`

## Architecture

```text
InputController
    |
    | AttackRequest / DefenseRequest
    v
CombatService
    |
    +---------------------> StateRules
    |
    +---------------------> StaminaService
    |
    +---------------------> DefenseService
                               |
                               | incoming hit outcome
                               v
                          DamageService
```

`CombatService` remains responsible for legal player action/state changes.

`StaminaService` remains responsible only for Stamina values, spending, regen,
and replication.

`DefenseService` remains responsible only for deciding the defensive outcome
of an incoming attack and applying defensive Stamina consequences.

## Networking and Security

The client may send only defensive intent:

- `BlockStart`
- `BlockEnd`
- `Dodge`

The client never sends:

- Stamina values;
- parry success;
- i-frame success;
- Guard Break decisions;
- attacker stagger duration;
- health damage;
- enemy targets.

The server owns all timing and results.

## View Lock

`CameraController` moves the View/Screen Lock toggle from Left Shift to
Left Ctrl.

The dodge direction uses character facing, so View Lock naturally gives the
player precise control over roll direction when enabled.

## Prototype Shield

Step 5 adds a simple prototype shield attached to the left hand.

It is a temporary greybox/prototype asset whose purpose is to:

- make block direction readable;
- make the block pose visually understandable;
- provide immediate feedback while testing parry and block.

Final shield art is outside Step 5.

## Defensive Animation and Feedback

The prototype adds:

- shield-raised blocking pose;
- forward-roll dodge animation;
- Guard Break/stagger feedback;
- parry feedback;
- visible Stamina HUD.

The forward roll must visually align with the authoritative dodge state and
i-frame timing.

The implementation should reuse the project's existing prototype animation
pipeline where practical rather than requiring a new external animation
asset.

## Stamina HUD

A simple prototype Stamina bar is shown to the player.

It reads replicated server attributes only.

It should make these states easy to test:

- Dodge spends 25.
- Blocked attacks spend Stamina.
- Block held pauses regen.
- Releasing block allows regen when the delay has elapsed.
- Guard Break reaches zero and visibly recovers afterward.

Final UI art is outside Step 5.

## Training Marauder

A deterministic stationary `TrainingMarauder` is added to the greybox arena.

Its purpose is mechanical testing, not full enemy AI.

### Prototype behaviour

- Detect a nearby player in a short test radius.
- Face the chosen player before attacking.
- Telegraph a slow, readable melee strike.
- Lock the strike direction near the end of the wind-up.
- Use a server-owned attack volume.
- Repeat slowly enough to test block, parry, and dodge deliberately.
- Respect parry stagger before attacking again.

### Prototype attack values

- Wind-up/telegraph: 0.8 seconds
- Attack interval: approximately 2.4 seconds
- HP damage on an undefended hit: 20
- Stamina damage on a normal block: 30
- Blockable: yes
- Parryable: yes

These values are test values and remain tunable.

The Marauder does not pathfind, chase, loot, grant XP, or represent final
enemy AI.

## Expected Manual Behaviour

### Block

1. Hold RMB while facing the Marauder.
2. Incoming frontal strike deals 0 HP.
3. Stamina drops by 30.
4. Stamina does not regenerate while RMB remains held.
5. Rear/side strike outside the 120-degree cone bypasses block.

### Parry

1. Press RMB immediately before the strike.
2. Strike lands inside the 0.18-second parry window.
3. Player loses 0 HP and 0 Stamina.
4. Marauder is staggered for approximately 1 second.

### Guard Break

1. Repeatedly block attacks without recovering enough Stamina.
2. The hit that exhausts Stamina deals 0 HP.
3. Block drops.
4. Player is locked for approximately 0.8 seconds.
5. Later attacks during Guard Break are not automatically blocked.

### Dodge

1. Face toward the desired roll direction.
2. Press Left Shift.
3. 25 Stamina is spent.
4. Character rolls forward approximately 9 studs.
5. An attack intersecting during the first approximately 0.22 seconds is
   avoided.
6. The roll direction does not curve if the camera moves.
7. Roll stops at solid geometry.

### View Lock

- Left Ctrl toggles View/Screen Lock.
- Left Shift no longer toggles camera lock.

## Tests

The one Step 5 package will add automated coverage for at least:

- Stamina starts at 100.
- Basic attacks do not spend Stamina.
- Dodge spends exactly 25.
- Dodge fails below required Stamina.
- Stamina regenerates after the configured delay.
- Blocking pauses regeneration.
- Frontal 120-degree attack blocks.
- Rear attack bypasses block.
- Blocked hit spends configured Stamina damage.
- Exhausting Stamina causes Guard Break.
- Guard Break locks defensive actions.
- Parry succeeds only during the configured opening window.
- Parry spends no Stamina.
- Dodge i-frames return `Dodged`.
- Same incoming hit is not both dodged/parried/blocked.
- View Lock key is Left Ctrl.
- Dodge key is Left Shift.
- Existing attack, animation, melee-hit, damage, and target tests remain green.

## One-Package Implementation

The user-facing implementation will be delivered as one install package.

Expected areas touched include:

```text
ReplicatedStorage/Combat/Shared
    CombatConfig
    CombatTypes
    StateRules
    Remotes.model.json

ServerScriptService/Combat
    CombatService
    StaminaService
    DefenseService
    TrainingMarauderBuilder / controller
    tests

StarterPlayerScripts/Combat
    InputController
    CameraController
    FeedbackController
    Stamina HUD / defensive presentation
```

Existing modules should remain focused. Stamina and defensive resolution must
not be folded into a single oversized `CombatService`.

## Non-Goals

Step 5 does not include:

- full enemy navigation/pathfinding;
- final enemy AI;
- heavy attacks;
- final skill costs;
- equipment stats that modify Stamina;
- multiple shield types;
- perfect final animations or VFX;
- PvP defence;
- ranged enemy attacks;
- boss unblockable mechanics beyond support for future flags;
- final mobile/gamepad defensive UI.

## Acceptance Gate

Step 5 is complete when:

- Left Ctrl controls View Lock.
- Left Shift performs the forward roll.
- Stamina is server-authoritative and visible.
- Block, parry, dodge, and Guard Break behave as specified.
- The Training Marauder can manually exercise all three defence choices.
- Defensive results flow through `DefenseService` before health damage.
- Clients cannot authorize defensive success or change Stamina.
- Existing sword attack behaviour remains intact.
- All Studio tests pass.
- Rojo build succeeds.
- Git diff checks are clean.
