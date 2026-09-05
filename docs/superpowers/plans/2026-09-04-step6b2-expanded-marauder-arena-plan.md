# Step 6B.2 Expanded Marauder Arena Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a larger repeatable four-Marauder combat arena with an independent Normal/Normal/Heavy move loop and 3-second enemy respawn.

**Architecture:** Keep attack choice pure in `MarauderAttackRules`, keep chase math in `MarauderBehaviorRules`, and move single-enemy controller globals into one `MarauderRuntime` per configured model. The builder creates deterministic enemy instances/spawns and the controller owns only runtime AI/state transitions.

**Tech Stack:** Roblox Luau, Rojo, PowerShell guarded installer.

**Spec:** `docs/superpowers/specs/2026-09-04-step6b2-expanded-marauder-arena-design.md`

## Global Constraints

- Arena floor is exactly 120x120 studs with four configured pillars.
- Exactly four prototype Training Marauders are created.
- Training Marauder base movement speed remains exactly 14 studs/second.
- Room-wide aggro remains true.
- Pattern is exactly Normal -> Normal -> Heavy -> repeat.
- Heavy wind-up is 0.75 seconds, damage is 32 HP / 45 Stamina, and arc is 55 degrees.
- Respawn delay is exactly 3 seconds.
- Existing Block/Dodge priority behaviour must not change.
- No commit, stage, or push is performed by the installer.

---

### Task 1: Arena and enemy data definitions

**Files:**
- Modify: `src/ReplicatedStorage/Combat/Shared/CombatConfig.luau`
- Modify: `src/ServerScriptService/Combat/ArenaBuilder.server.luau`
- Test: `src/ServerScriptService/Combat/Tests/ExpandedArenaConfigTest.server.luau`

**Interfaces:**
- Produces `TRAINING_MARAUDER.MODEL_NAMES`, `SPAWN_POSITIONS`, `ATTACK_PATTERN`, `ATTACKS`, and `RESPAWN_SECONDS`.
- ArenaBuilder consumes only `CombatConfig.ARENA`.

- [ ] Write a failing config test asserting 120x120 floor, four pillars, four names/spawns, fixed speed 14, and 3-second respawn.
- [ ] Verify the test fails against the Step 6B.1 baseline.
- [ ] Add the arena and Marauder data definitions and update marker/spawn positions.
- [ ] Verify the config contract is satisfied.

### Task 2: Deterministic Marauder attack rules

**Files:**
- Create: `src/ServerScriptService/Combat/MarauderAttackRules.luau`
- Create: `src/ServerScriptService/Combat/Tests/MarauderAttackRulesTest.server.luau`

**Interfaces:**
- Produces `get_attack_name(pattern_index) -> string`, `get_attack_definition(attack_name) -> table`, and `get_next_pattern_index(pattern_index) -> number`.
- Controller consumes these functions without owning pattern data.

- [ ] Write tests for Normal, Normal, Heavy, wraparound, and Heavy values.
- [ ] Verify module is absent/failing in the baseline.
- [ ] Implement the minimal pure rules module.
- [ ] Verify all attack-rule contracts are satisfied.

### Task 3: Four-Marauder builder

**Files:**
- Modify: `src/ServerScriptService/Combat/TrainingMarauderBuilder.server.luau`
- Test: `src/ServerScriptService/Combat/Tests/MultiMarauderBuilderTest.server.luau`

**Interfaces:**
- Consumes `MODEL_NAMES`, `SPAWN_POSITIONS`, `MAX_HEALTH`.
- Produces four tagged Workspace models with matching configured names and stable spawn attributes.

- [ ] Write a runtime test that waits for all four models and checks Humanoid health/tagging.
- [ ] Refactor builder into reusable `create_marauder(name, spawn_position)` and create all four models.
- [ ] Store each configured spawn position on the model for debugging and respawn verification.

### Task 4: Per-Marauder controller runtime and heavy attack

**Files:**
- Modify: `src/ServerScriptService/Combat/TrainingMarauderController.server.luau`
- Modify: `src/ServerScriptService/Combat/Tests/MarauderHostileLoopIntegrationTest.server.luau`
- Create: `src/ServerScriptService/Combat/Tests/MultiMarauderRuntimeTest.server.luau`

**Interfaces:**
- Consumes `MarauderBehaviorRules`, `MarauderAttackRules`, `DamageService`, `DefenseService`, `StaggerService`.
- Produces independent `MarauderAIState`, `MarauderAggroTargetUserId`, and `MarauderAttackName` attributes per model.

- [ ] Update runtime tests to require four independently initialised Marauders.
- [ ] Replace single global Marauder state with `MarauderRuntime` records.
- [ ] Parameterise targeting, chase, telegraph, hit checks, strike resolution, and attack execution by runtime.
- [ ] Use `MarauderAttackRules` to run Normal -> Normal -> Heavy independently for each runtime.
- [ ] Preserve room-wide aggro, speed 14, stagger interrupts, parry, block, and obstruction checks.

### Task 5: Death and 3-second respawn

**Files:**
- Modify: `src/ServerScriptService/Combat/TrainingMarauderController.server.luau`
- Create: `src/ServerScriptService/Combat/Tests/MarauderRespawnContractTest.server.luau`

**Interfaces:**
- Death clears target, stagger, attack and telegraph state.
- Respawn replaces the Humanoid, restores 200 HP, original spawn, Idle state and Normal pattern.

- [ ] Add a contract test for respawn configuration and runtime reset attributes.
- [ ] Add per-runtime `Died` handling with a life-sequence guard.
- [ ] Replace the dead Humanoid after exactly 3 seconds and reconnect `Died`.
- [ ] Restore body presentation, model spawn, attack pattern, aggro and timers.

### Task 6: Package and guarded installer

**Files:**
- Create package `DungeonMMO_Step6B2_Expanded_Multi_Marauder_Arena.zip`
- Create installer `01_install_step6b2_expanded_multi_marauder_arena.ps1`

**Interfaces:**
- Installer accepts only exact Step 6B.1 Fixed Speed + Instant Block hashes for every modified existing file.
- Installer creates a timestamped backup, copies payload, runs `rojo build`, verifies `git diff --check`, and rolls back modified files on failure.

- [ ] Compute exact baseline hashes from the approved Step 6B.1 package/reconstructed source.
- [ ] Package only changed/new files plus design/plan docs and Studio tests.
- [ ] Run ZIP integrity, manifest/hash and static contract verification.
- [ ] Provide one copy-paste PowerShell extraction/install block.
