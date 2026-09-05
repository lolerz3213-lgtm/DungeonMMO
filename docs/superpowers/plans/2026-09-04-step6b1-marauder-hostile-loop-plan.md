# Training Marauder Hostile Loop Step 6B.1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add server-authoritative Marauder aggro, target retention, chase movement, attack-range stopping, and explicit hostile-loop states without changing the existing strike/defence mechanics.

**Architecture:** Add one pure `MarauderBehaviorRules` module for deterministic range/state/movement rules. Keep Roblox world queries, target retention, model movement, attack execution, stagger presentation, and death handling in `TrainingMarauderController.server.luau`.

**Tech Stack:** Roblox Studio, Luau, Rojo, Roblox `Players`, `Workspace:Raycast`, `Model:PivotTo`, `Humanoid`, existing `DefenseService`, `DamageService`, and `StaggerService`.

**Spec:** `docs/superpowers/specs/2026-09-04-step6b1-marauder-hostile-loop-design.md`

## Global Constraints

- Acquisition radius remains 12 studs.
- Retained-target release radius is 16 studs.
- Chase speed is 7 studs/second.
- Chase stops at 4.75 studs.
- Existing Marauder strike values remain unchanged.
- Stagger remains owned by `StaggerService`.
- NPC movement and targeting remain server-authoritative.
- No complex pathfinding, second attack, respawn/reset, or second Marauder in this substep.
- Existing Step 1-6A combat behaviour and tests must remain intact.

---

### Task 1: Deterministic hostile-loop rules

**Files:**
- Create: `src/ServerScriptService/Combat/MarauderBehaviorRules.luau`
- Create: `src/ServerScriptService/Combat/Tests/MarauderBehaviorRulesTest.server.luau`
- Modify: `src/ReplicatedStorage/Combat/Shared/CombatConfig.luau`

**Interfaces:**
- Consumes: `CombatConfig.TRAINING_MARAUDER`
- Produces:
  - `can_acquire(distance: number): boolean`
  - `can_retain(distance: number): boolean`
  - `get_range_state(distance: number): string`
  - `get_chase_step(distance: number, delta_seconds: number): number`

- [ ] Write the failing Studio test for acquisition, retention, state thresholds, and chase-step clamping.
- [ ] Verify RED because `MarauderBehaviorRules` and the new config values do not exist.
- [ ] Add `TARGET_LOST_RANGE_STUDS = 16`, `CHASE_SPEED_STUDS_PER_SECOND = 7`, `CHASE_STOP_RANGE_STUDS = 4.75`, and `AI_TICK_SECONDS = 0.05`.
- [ ] Implement the four pure rule functions with input validation and no world dependencies.
- [ ] Run the Studio test and verify `[Marauder Behavior Rules Tests] PASS`.

### Task 2: Runtime aggro and chase controller

**Files:**
- Modify: `src/ServerScriptService/Combat/TrainingMarauderController.server.luau`

**Interfaces:**
- Consumes: `MarauderBehaviorRules`, `StaggerService`, existing strike helpers.
- Produces runtime attributes:
  - `MarauderAIState: string`
  - `MarauderAggroTargetUserId: number`

- [ ] Add the hostile-loop integration assertions before changing controller behaviour.
- [ ] Verify RED because the controller does not expose the required states/aggro flow.
- [ ] Add retained-target ownership and release rules.
- [ ] Add collision-aware planar chase movement using `PivotTo`.
- [ ] Split state update, target update, and movement into focused helper functions.
- [ ] Keep the existing strike function and defence resolution intact.
- [ ] Make stagger/death force the appropriate state and suppress movement.
- [ ] Run Studio and verify the new hostile-loop tests pass with existing combat suites.

### Task 3: Integration coverage and manual acceptance

**Files:**
- Create: `src/ServerScriptService/Combat/Tests/MarauderHostileLoopIntegrationTest.server.luau`

**Interfaces:**
- Consumes: config, behavior module, runtime controller.
- Produces: `[Marauder Hostile Loop Tests] PASS` on valid structure/config.

- [ ] Verify exact acquisition, release, speed, stop-distance, tick, module, and controller requirements.
- [ ] Run all Studio tests and confirm no existing suite regresses.
- [ ] Perform manual chase/stop/reacquire/stagger/death acceptance sequence from the design.

### Task 4: Guarded delivery package

**Files:**
- Create delivery ZIP installer and manifest outside the repository.

**Interfaces:**
- Consumes exact hashes from the accepted Step 6A reach-tuned source.
- Produces an idempotent installer that backs up changed files, refuses unexpected source versions, runs `rojo build`, and runs `git -c core.whitespace=cr-at-eol diff --check`.

- [ ] Record exact old/new SHA-256 values for every packaged file.
- [ ] Build the guarded PowerShell installer with rollback-on-failure.
- [ ] Validate ZIP integrity and manifest/package hashes.
- [ ] Do not stage, commit, push, or modify `DungeonMMO.rbxl`.
