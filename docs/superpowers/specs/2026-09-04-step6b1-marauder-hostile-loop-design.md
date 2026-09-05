# Phase 1 Step 6B.1 - Training Marauder Hostile Loop Design

**Project:** DungeonMMO
**Date:** 4 September 2026
**Status:** Approved implementation scope
**Roadmap:** DungeonMMO Roadmap v1.8

## Goal

Upgrade the Training Marauder from a stationary defence tester into the first
small hostile combat loop. This substep adds target acquisition, aggro
retention, chase movement, attack-range stopping, facing, and explicit runtime
AI states while preserving the existing readable strike, parry/stagger, Shield
Bash, and server-authoritative damage/defence pipeline.

## Scope

Step 6B.1 includes:

- acquire the nearest living player inside 12 studs;
- retain an acquired target until it dies/disappears or exceeds 16 studs;
- chase a retained target at 7 studs/second;
- stop chasing at 4.75 studs so the existing 5.5-stud strike can connect;
- face the target while chasing and before the strike locks;
- expose a small server-owned AI state for debugging/readability;
- stop movement and attack execution while staggered;
- resume pursuit after stagger expires;
- stop all hostile behaviour after death;
- preserve the existing slow strike, defence resolution, parry stagger,
  Shield Bash stagger, and obstruction checks.

Step 6B.1 does not add the second/heavy attack, pathfinding around complex
obstacles, respawn/reset, a second Marauder, multi-enemy coordination, loot,
or final animation art. Those remain subsequent Step 6B work.

## Runtime states

The prototype uses these server-owned states:

- `Idle`: no valid retained target;
- `Chasing`: valid target is farther than chase stop distance;
- `Ready`: target is within chase stop distance and attack cooldown allows
  normal attack consideration;
- `Attacking`: strike wind-up/lock/resolve sequence owns the Marauder;
- `Staggered`: parry or Shield Bash temporarily suppresses movement/attacks;
- `Dead`: Humanoid is dead and hostile behaviour is disabled.

The model exposes the current state through `MarauderAIState` and the retained
player through `MarauderAggroTargetUserId` for prototype inspection.

## Architecture

### MarauderBehaviorRules

Add a pure shared server module that owns deterministic hostile-loop rules.
It must not read Players, Workspace, or mutate Instances.

It provides:

- acquire-range validation;
- retained-target range validation;
- chase/ready state selection from target distance;
- maximum planar movement distance for one AI tick.

This keeps tuning and state decisions independently testable and prevents the
runtime controller from becoming one large procedural script.

### TrainingMarauderController

The controller remains responsible for Roblox runtime work:

- finding living players;
- retaining/releasing the current target;
- moving the anchored prototype model with `PivotTo`;
- collision-checking a proposed chase step;
- facing the target;
- starting the existing strike when in range;
- responding to stagger and death signals;
- updating debug attributes/presentation.

The client does not participate in NPC target choice or movement.

## Movement

The current prototype Marauder consists of anchored parts, so Step 6B.1 keeps
that asset and moves the full Model with server-side `PivotTo` rather than
rebuilding it as an unanchored production NPC rig.

Each AI tick:

1. calculate planar target distance;
2. if outside 4.75 studs, calculate a movement step capped by
   `7 * delta_seconds`;
3. raycast the proposed horizontal movement while excluding the Marauder and
   target character;
4. if blocked by collidable level geometry, do not advance through it;
5. otherwise move and face the target.

Complex obstacle navigation is deliberately deferred until a real authored
dungeon room requires it.

## Targeting

When no target is retained, choose the nearest living player inside the
12-stud acquisition radius.

Once acquired, keep that player while they remain living and within 16 studs.
This hysteresis prevents target flicker near the 12-stud acquisition boundary.
If the retained target becomes invalid, release it and immediately allow a new
nearest player to be acquired.

## Attack interaction

The existing Training Marauder strike remains unchanged in Step 6B.1:

- 0.8-second readable wind-up;
- direction refresh before the final 0.2-second lock;
- 5.5-stud attack reach;
- 80-degree attack arc;
- 20 health damage on an undefended hit;
- 30 Stamina damage on a valid block;
- parry routes through `StaggerService`;
- obstruction is checked before resolving the strike.

The Marauder does not move during the attack sequence. If the target moves out
of range after the direction locks, the strike misses normally.

## Stagger and death

`StaggerService` remains the single stagger source for both Shield Bash and
parry. A stagger cancels an active strike presentation, suppresses chase, and
puts the AI state into `Staggered`. Pursuit can resume after the stagger ends.

Humanoid death clears stagger, releases aggro, clears the telegraph, and sets
`Dead`. Respawn/reset is intentionally the next Step 6B substep.

## Tests

Add deterministic `MarauderBehaviorRules` tests for:

- 12 studs is acquirable and beyond 12 is not;
- a retained target is kept through 16 studs and released beyond it;
- a target farther than 4.75 studs produces `Chasing`;
- a target at or inside 4.75 studs produces `Ready`;
- movement is capped by speed times delta;
- movement never steps past the stop distance;
- zero/negative delta produces no movement.

Add a hostile-loop integration test that verifies the expected config values,
module/controller presence, and debug attribute names.

All existing Step 1-6A tests must remain green in Studio.

## Manual acceptance

After installation:

1. Enter Play with the Marauder nearby.
2. The Marauder acquires the player and visibly walks/chases toward them.
3. It stops at melee distance instead of overlapping the player.
4. It faces the player while approaching.
5. It uses the existing readable strike when ready.
6. Moving away makes it chase again.
7. Moving beyond the retained-target range causes it to drop aggro.
8. Re-entering acquisition range causes reacquisition.
9. Shield Bash during chase/telegraph staggers it and stops movement/attack.
10. Successful parry also staggers it and pursuit resumes after recovery.
11. Killing it stops hostile behaviour.
12. Existing sword, block, parry, dodge, Guard Break, and Shield Bash behaviour
    remain unchanged.
