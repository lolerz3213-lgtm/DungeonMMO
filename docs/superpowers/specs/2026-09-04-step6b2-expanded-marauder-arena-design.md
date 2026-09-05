# Step 6B.2 Expanded Marauder Arena Design

**Date:** 2026-09-04
**Project:** DungeonMMO
**Milestone:** Phase 1, Step 6B - hostile combat loop
**Status:** Approved for implementation

## Goal

Turn the Phase 1 greybox into a repeatable multi-enemy combat test by enlarging
the arena, running four independent Training Marauders, adding one readable
heavy attack, and resetting dead Marauders without restarting Studio.

## Locked Scope

- Arena floor expands from 80x80 to 120x120 studs.
- Four pillars replace the previous two-pillar layout.
- Player reset spawn moves to the near edge of the larger floor.
- Four Training Marauders are distributed around the room.
- Every Marauder keeps fixed base movement speed 14 studs/second.
- Room-wide persistent aggro remains active.
- Every Marauder owns independent target, attack timer, attack pattern,
  stagger state, death state, and respawn sequence.
- Attack pattern is deterministic: Normal -> Normal -> Heavy -> repeat.
- Normal attack keeps the accepted 0.45-second wind-up, 20 HP damage,
  30 Stamina damage, 5.5-stud reach, and 80-degree arc.
- Heavy Overhead uses a 0.75-second wind-up, 32 HP damage,
  45 Stamina damage, 5.5-stud reach, and a narrower 55-degree arc.
- Heavy is blockable and parryable in this prototype.
- Heavy uses a distinct amber/yellow telegraph; Normal keeps the red telegraph.
- Dead Marauders stop AI immediately, release target/stagger/telegraph state,
  and respawn after 3 seconds at their own original spawn with full 200 HP.
- The full dungeon-room activation system remains out of scope; the current
  greybox is treated as one active combat room.

## Architecture

`TrainingMarauderBuilder.server.luau` creates four tagged models from configured
names and spawn positions. `TrainingMarauderController.server.luau` manages a
`MarauderRuntime` record per model rather than one set of globals. A new pure
`MarauderAttackRules.luau` module owns deterministic attack selection and attack
definition lookup.

Existing `MarauderBehaviorRules`, `DefenseService`, `DamageService`, and
`StaggerService` remain shared boundaries. Enemy-vs-player damage still goes
through the existing defence resolution path before HP damage is applied.

## Multi-enemy Behaviour

Each Marauder selects and retains its own nearest living player. Marauders do
not share cooldowns or attack-pattern counters. A stagger on one Marauder does
not pause another. Chase obstruction ignores the other Marauder models but
continues to respect collidable arena geometry such as pillars.

## Death and Respawn

The prototype models remain in Workspace when dead. On `Humanoid.Died`, the
runtime is marked Dead, attack and telegraph state are cleared, target is
released, and stagger is removed. After three seconds, the dead Humanoid is
replaced with a fresh Humanoid, the model is pivoted back to its configured
spawn CFrame, body presentation is restored, and the attack pattern returns to
Normal.

## Acceptance

Studio should show four independently active Marauders in a 120x120 arena.
Their Normal/Normal/Heavy patterns should be readable, individual parries and
Shield Bashes should only stagger the struck enemy, killing one enemy should
not stop the others, and the dead enemy should return at its own spawn after
three seconds.
