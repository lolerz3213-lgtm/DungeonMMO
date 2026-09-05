# Phase 1 Step 6A - Shield Bash Design

**Project:** DungeonMMO
**Date:** 4 September 2026
**Status:** Approved design, pending implementation-plan review
**Roadmap:** DungeonMMO Roadmap v1.8

## 1. Goal

Implement Shield Bash as the combat prototype's first active skill.

Shield Bash must prove a reusable, server-authoritative active-skill path
without building the final skill tree, progression system, hotbar UI, or
keybind settings screen prematurely.

The implementation must preserve the existing Phase 1 combat architecture
and all Step 1-5 behaviour.

## 2. Player Experience

Shield Bash is a short-range sword-and-shield control skill.

The intended feel is:

1. The player presses hotbar slot 1.
2. The character commits briefly to a forward shield strike.
3. A nearby valid target in front of the player is hit once.
4. Shield Bash deals low health damage but strong guard/stagger pressure.
5. The target gives clear impact and stagger feedback.
6. The player cannot immediately spam the skill because Stamina and cooldown
   are both server-authoritative.

Shield Bash is primarily a defensive/control tool rather than a damage
replacement for the normal sword combo.

## 3. Hotbar and Input Model

### 3.1 Locked default hotbar layout

The default keyboard hotbar uses the number row:

- Skill Slot 1: `1`
- Skill Slot 2: `2`
- Skill Slot 3: `3`
- Skill Slot 4: `4`
- Skill Slot 5: `5`
- Skill Slot 6: `6`
- Skill Slot 7: `7`
- Skill Slot 8: `8`

Shield Bash occupies **Skill Slot 1** for the Phase 1 prototype.

### 3.2 Logical actions, not hard-coded skill keys

Skill code must never depend directly on `Enum.KeyCode.One`.

Input is expressed through logical hotbar actions:

- `SkillSlot1`
- `SkillSlot2`
- `SkillSlot3`
- `SkillSlot4`
- `SkillSlot5`
- `SkillSlot6`
- `SkillSlot7`
- `SkillSlot8`

For Step 6A, only `SkillSlot1` needs to execute a real skill.

Its initial keyboard binding is:

```text
SkillSlot1 -> Enum.KeyCode.One
```

This separation is required so a future player keybinding setting can change
the physical key without modifying Shield Bash or other skill logic.

### 3.3 Scope guardrail

Step 6A does **not** build:

- the final hotbar UI;
- a keybind settings screen;
- persistent user keybind saves;
- all eight active skill implementations.

It establishes the input/action boundary required for those systems later.

The existing basic attack, block, dodge, and View Lock controls remain
separate combat actions.

## 4. Prototype Shield Bash Values

The first test values are:

| Property | Value |
| --- | ---: |
| Stamina cost | 20 |
| Cooldown | 4.0 seconds |
| Wind-up | 0.16 seconds |
| Reach | approximately 6 studs |
| Hit shape | 120-degree frontal cone, matching shield block |
| Maximum hits per target | 1 per bash |
| Primary purpose | stagger / guard pressure |
| Health damage | intentionally low |
| Forward commitment | short, collision-aware step |

The values are prototype tuning values. Shield Bash deliberately shares
the block system's 120-degree frontal cone while using a 6-stud
authoritative reach. The broad-phase query may be wider than the final cone so
targets near the cone edge can be discovered before authoritative arc,
range, legality, and obstruction checks are applied.

Other values may change after the Phase 1 combat acceptance pass without
changing the skill architecture.

## 5. Combat-State Rules

Shield Bash may begin only from normal Locomotion.

It cannot begin while the player is:

- performing a normal sword attack;
- dodging;
- Guard Broken;
- already using Shield Bash;
- otherwise in a combat state that does not permit a new active skill.

For the first implementation, holding Block does not cancel directly into
Shield Bash.

A future Block -> Shield Bash transition may be tested after the standalone
skill feels correct.

Shield Bash must not:

- advance the Slash1 -> Slash2 -> Finisher chain;
- reset the normal sword combo merely because the skill was used;
- refresh or manipulate normal sword attack cooldown/state data.

## 6. Server Authority

The client may request only logical skill intent.

Conceptually:

```text
SkillSlot1 pressed
    ->
client resolves equipped skill for slot 1
    ->
client requests use of Shield Bash
    ->
server validates and executes
```

The client must never supply:

- target instance;
- damage amount;
- Stamina cost;
- current Stamina;
- cooldown duration;
- stagger duration;
- successful hit result;
- hit position chosen as authoritative;
- guard damage result.

The server owns all validation, timing, hit delivery, damage, stagger, and
resource consequences.

## 7. Architecture

### 7.1 CombatService

`CombatService` remains the owner of legal player combat actions and combat
state transitions.

For Shield Bash it must:

- receive the active-skill request;
- confirm the player may begin the skill;
- confirm the requested skill is currently available to that slot/loadout;
- ask `StaminaService` to spend the required Stamina;
- ask the cooldown service to validate/start the cooldown;
- enter the Shield Bash WindUp, Active, and Recovery sequence;
- invoke server-owned hit delivery during the Active window;
- return the player to an appropriate normal state after Recovery.

`CombatService` must not absorb generic cooldown storage, hit geometry,
damage math, or stagger ownership.

### 7.2 StaminaService

`StaminaService` continues to own:

- authoritative current Stamina;
- affordability checks;
- Stamina spending;
- regeneration;
- replicated diagnostic/player-facing Stamina state.

Shield Bash requests a 20-Stamina spend through this service.

### 7.3 SkillCooldownService

Add a small reusable `SkillCooldownService`.

Its responsibility is only server-side active-skill cooldown state.

It must support operations equivalent to:

- checking whether a skill is ready;
- starting a cooldown;
- obtaining remaining cooldown time when useful for feedback;
- clearing player-owned runtime state when the player leaves or respawns.

Cooldown identity is skill-based, not physical-key-based.

Changing the key bound to Skill Slot 1 must not change or reset the Shield
Bash cooldown.

### 7.4 Skill definitions

Shield Bash should be represented by validated shared/server-readable skill
definition data rather than hard-coded values scattered through input and
combat scripts.

The definition should contain the prototype properties required for
execution, such as:

- skill ID;
- display name;
- Stamina cost;
- cooldown;
- timing;
- reach/hit-volume definition;
- low damage value or multiplier;
- stagger/guard-pressure values;
- movement commitment.

Only data required by Step 6A should be introduced.

Do not build the final skill-tree/proficiency data model in this step.

### 7.5 MeleeHitService

Reuse the existing server-authoritative melee acquisition pipeline wherever
its interfaces support the required Shield Bash geometry.

Shield Bash needs:

- frontal range checking;
- the same 120-degree frontal cone used by shield block;
- wall/solid-geometry obstruction;
- per-use target deduplication;
- NPC target legality through the existing target rules.

If the existing interface is too tightly tied to basic-attack definitions,
make the smallest reusable extension needed to accept a generic melee
delivery definition.

Do not duplicate melee hit acquisition into a separate Shield Bash hitbox
system.

### 7.6 DamageService

`DamageService` remains responsible for generic health damage application.

Shield Bash passes its validated server-owned damage context through this
service.

The skill's health damage is deliberately low because its gameplay identity
is control and guard pressure.

### 7.7 StaggerService

Add a focused reusable `StaggerService` for NPC stagger state.

It should own:

- whether a supported NPC is currently staggered;
- authoritative stagger duration;
- preventing compatible enemy attacks while staggered;
- stagger state/attribute feedback required by presentation;
- cleanup when the NPC dies or resets.

This service allows Shield Bash and successful parries against the Training
Marauder to share the same stagger mechanism rather than maintaining two
unrelated stun implementations.

It does not implement a complete future crowd-control/status-effect system.

### 7.8 Training Marauder

Step 6A extends the current deterministic Training Marauder only enough to
receive and visibly react to Shield Bash.

The full hostile combat loop belongs to Step 6B.

For Step 6A the Marauder must:

- remain a valid combat target;
- receive Shield Bash health damage;
- receive Shield Bash stagger;
- pause its current compatible test attack while staggered;
- show readable stagger feedback;
- recover cleanly.

Aggro selection, chasing, compact move-set AI, death/reset loop, and
multi-enemy combat pressure remain Step 6B unless a tiny dependency is
strictly necessary for Step 6A testing.

## 8. Networking

Add or extend the combat remotes so the client sends a skill-use request
containing only a server-recognised skill/action identity.

The server must reject:

- unknown skill IDs;
- skills not equipped/available for the requesting player's slot;
- requests while the combat state is illegal;
- requests during cooldown;
- requests without sufficient Stamina;
- impossible or malformed requests;
- request spam that arrives before the authoritative skill may be used again.

A duplicate network request must never produce a second hit or second skill
execution.

## 9. Presentation

Use the existing prototype animation/presentation approach.

Shield Bash needs:

- readable shield-forward movement;
- a short wind-up;
- a clear impact moment;
- visible target stagger feedback;
- clear rejection/feedback when unavailable where useful for testing.

The animation is prototype art.

Detailed final animation polish must not delay Step 6B.

The skill should feel weighty enough to match the existing sword combat but
short enough to read as a tactical control action.

## 10. Rebinding Compatibility

The Step 6A input design must allow this future flow without changing combat
logic:

```text
Default:
SkillSlot1 -> Keyboard 1 -> Shield Bash

After player rebind:
SkillSlot1 -> Keyboard Q -> Shield Bash
```

or:

```text
SkillSlot1 -> another supported input -> Shield Bash
```

Only the binding changes.

The logical slot and equipped skill remain the same.

Persistent keybind storage and settings UI are intentionally deferred.

## 11. Testing Strategy

Implementation follows test-driven development.

### 11.1 Skill definition tests

Verify:

- Shield Bash definition exists;
- expected Stamina cost is 20;
- expected cooldown is 4.0 seconds;
- timing and hit geometry are valid;
- invalid definitions fail validation where appropriate.

### 11.2 Hotbar/input-boundary tests

Verify:

- Slot 1 defaults to keyboard `1`;
- Shield Bash is assigned to Slot 1 for the prototype;
- skill execution code identifies the logical slot/skill rather than reading
  `Enum.KeyCode.One`;
- changing the binding does not alter skill identity.

### 11.3 Cooldown tests

Verify:

- first valid use is ready;
- cooldown starts server-side;
- repeated request inside four seconds is rejected;
- readiness returns after cooldown;
- one skill cooldown does not accidentally affect unrelated skill IDs;
- player cleanup removes stale runtime cooldown state.

### 11.4 Stamina tests

Verify:

- exactly 20 Stamina is spent on a valid activation;
- activation at less than 20 Stamina is rejected;
- rejected cooldown/state requests do not spend Stamina;
- duplicate requests cannot double-spend.

### 11.5 Combat-state tests

Verify:

- Locomotion -> Shield Bash is legal;
- normal attack -> Shield Bash request is rejected;
- Dodge -> Shield Bash request is rejected;
- Guard Break -> Shield Bash request is rejected;
- Shield Bash cannot recursively start another Shield Bash;
- completion returns to the expected normal combat state;
- sword combo data remains correct.

### 11.6 Hit-delivery tests

Verify:

- target inside valid frontal volume can be hit;
- target behind the player cannot be hit;
- target beyond reach cannot be hit;
- solid arena geometry blocks the hit;
- one target is affected at most once per bash;
- multiple overlap samples cannot duplicate damage;
- existing NPC target legality remains enforced.

### 11.7 Damage and stagger tests

Verify:

- health damage goes through `DamageService`;
- Marauder receives the intended stagger;
- stagger prevents compatible Marauder attack execution;
- stagger ends authoritatively;
- repeated overlapping stagger application follows one explicit rule and
  cannot create permanent stun.

For the prototype, refreshing to the greater remaining duration is preferred
over additive stacking.

### 11.8 Regression tests

All existing Step 1-5 tests must remain green, including:

- state rules;
- sword animation/presentation;
- prototype weapon;
- sword grip/carry;
- target rules;
- DamageService;
- melee hit acquisition;
- swept melee damage;
- finisher hit shape;
- StaminaService;
- DefenseService;
- defensive integration;
- dodge direction;
- defensive animation structure.

## 12. Manual Studio Acceptance

After automated/build checks pass, test in Roblox Studio.

Required observations:

1. Pressing `1` uses Shield Bash.
2. Mouse 1 still performs the normal sword combo.
3. RMB block still works.
4. Dodge and View Lock controls remain unchanged.
5. Shield Bash spends 20 Stamina.
6. A second immediate press does not execute the skill.
7. Shield Bash becomes available again after four seconds.
8. A frontal nearby Marauder is hit and visibly staggered.
9. A Marauder behind the player is not hit.
10. A Marauder behind solid geometry is not hit.
11. Shield Bash does not advance the normal three-hit sword combo.
12. Skill use feels like a short, weighty shield strike rather than a normal
    sword attack.
13. Existing block, parry, dodge, Guard Break, sword damage, and finisher
    shape behaviour still pass their Step 5 acceptance checks.

## 13. Installer / Change-Safety Requirements

The implementation package must follow the established guarded-patch workflow.

It must:

- expect project root
  `C:\Users\Remko\Documents\Roblox\DungeonMMO`;
- back up every modified source file;
- verify expected source anchors before patching;
- refuse unsafe partial edits;
- add new focused modules/tests rather than growing unrelated scripts;
- run `rojo build`;
- run `git diff --check`;
- not stage, commit, or push automatically;
- not modify `DungeonMMO.rbxl`;
- provide a clear Roblox Studio acceptance sequence after installation.

## 14. Explicit Non-Goals

Step 6A does not implement:

- the final eight-slot hotbar UI;
- keybind settings UI;
- persistent keybind saving;
- character levels or Skill Points;
- skillbooks;
- skill proficiency;
- skill ranks;
- final skill loadout management;
- race/class skill trees;
- final status-effect framework;
- complete Training Marauder AI;
- inventory/equipment skill assignment;
- final animation art.

Those systems remain in later roadmap phases.

## 15. Step 6A Exit Gate

Step 6A is complete when:

- Shield Bash reliably activates through logical Skill Slot 1;
- keyboard `1` is the default binding;
- the input design is rebind-compatible;
- Stamina and cooldown are server-authoritative;
- melee hit delivery remains server-authoritative and obstruction-aware;
- the Training Marauder receives clear Shield Bash stagger;
- all existing combat regression tests remain green;
- Studio acceptance confirms the skill feels readable and useful.

After this gate passes, continue immediately to **Phase 1 Step 6B: Training
Marauder hostile combat loop** rather than expanding the hotbar or polishing
cosmetics.
