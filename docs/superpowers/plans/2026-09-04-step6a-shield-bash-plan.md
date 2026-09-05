# Phase 1 Step 6A Shield Bash Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Shield Bash as the first server-authoritative active skill on logical hotbar Slot 1, default-bound to keyboard `1`, with Stamina, cooldown, melee hit delivery, stagger, prototype presentation, and regression coverage.

**Architecture:** Keep `CombatService` as the authoritative action/state owner. Add focused shared hotbar/skill definitions plus server-only cooldown and stagger services; extend `MeleeHitService` with an optional server callback so Shield Bash can reuse acquisition without coupling melee geometry to stagger logic. Reuse the existing `WindUp -> Active -> Recovery` state graph, track `current_skill_id` separately from `current_attack_id`, and extend shield presentation only enough to show the bash.

**Tech Stack:** Roblox Studio, Luau, Rojo 7.7.0-rc.1, ContextActionService, RemoteEvent, Humanoid, Workspace overlap/raycast APIs, existing Rojo + Git guarded installer workflow.

**Spec:** `docs/superpowers/specs/2026-09-04-step6a-shield-bash-design.md`

## Global Constraints

- Project root is `C:\Users\Remko\Documents\Roblox\DungeonMMO`.
- Default hotbar uses keyboard number row `1` through `8`; Shield Bash occupies Slot 1.
- Combat code binds to logical slots, not permanently to physical keys.
- Shield Bash prototype values: 20 Stamina, 4.0-second cooldown, 0.16-second wind-up, approximately 6-stud reach, the same 120-degree frontal cone as block, low health damage, strong stagger/guard pressure.
- Shield Bash begins from Locomotion only; no Block -> Bash cancel in Step 6A.
- Client sends intent only. Server owns state, Stamina, cooldown, hit delivery, damage, and stagger.
- Basic attacks remain free and keep their Slash1 -> Slash2 -> Finisher combo state.
- Equipment/progression/hotbar settings UI/persistent rebind saves remain out of scope.
- Existing Step 1-5 tests and combat behaviour must remain green.
- Installer backs up every modified file, validates exact source hashes, runs `rojo build` and `git diff --check`, never stages/commits/pushes, and never edits `DungeonMMO.rbxl`.

---

## File Structure

### Create

- `src/ReplicatedStorage/Combat/Shared/HotbarConfig.luau`
  - Logical slot names, default keys 1-8, prototype slot-to-skill mapping.
- `src/ReplicatedStorage/Combat/Shared/SkillDefinitions.luau`
  - Validated Shield Bash data and lookup API.
- `src/ServerScriptService/Combat/SkillCooldownService.luau`
  - Server runtime cooldown ownership by player + skill id.
- `src/ServerScriptService/Combat/StaggerService.luau`
  - Server runtime NPC stagger ownership with max-remaining refresh rule.
- `src/ServerScriptService/Combat/Tests/HotbarSkillDefinitionTest.server.luau`
- `src/ServerScriptService/Combat/Tests/SkillCooldownServiceTest.server.luau`
- `src/ServerScriptService/Combat/Tests/StaggerServiceTest.server.luau`
- `src/ServerScriptService/Combat/Tests/ShieldBashIntegrationTest.server.luau`

### Modify

- `src/ReplicatedStorage/Combat/Remotes.model.json`
  - Add `SkillRequest` RemoteEvent.
- `src/ReplicatedStorage/Combat/Shared/CombatConfig.luau`
  - Add remote name and Shield Bash presentation offsets only.
- `src/ServerScriptService/Combat/MeleeHitService.luau`
  - Add optional `on_target` callback and optional source metadata while preserving basic-attack behaviour.
- `src/ServerScriptService/Combat/CombatService.server.luau`
  - Add `current_skill_id`, skill request validation/execution, Stamina + cooldown transaction, Shield Bash active window, and cleanup.
- `src/ServerScriptService/Combat/TrainingMarauderController.server.luau`
  - Replace private stagger ownership with `StaggerService`, observe stagger attribute for feedback, and cancel compatible wind-up when staggered.
- `src/StarterPlayerScripts/Combat/InputController.client.luau`
  - Bind logical Skill Slot 1 to default key `1` and fire `SkillRequest` with the server-recognised skill id.
- `src/StarterPlayerScripts/Combat/ClientCombatController.luau`
  - Mirror authoritative skill states without disturbing predicted basic-attack flow.
- `src/StarterPlayerScripts/Combat/DefensePresentation.client.luau`
  - Track current action id and render the Shield Bash shield/IK pose during WindUp, Active, and Recovery.
- `src/StarterPlayerScripts/Combat/FeedbackController.client.luau`
  - Keep sword animation/trail presentation limited to basic attacks so Shield Bash does not trigger sword clips.

---

### Task 1: Shared hotbar and skill definitions

**Files:**
- Create: `src/ReplicatedStorage/Combat/Shared/HotbarConfig.luau`
- Create: `src/ReplicatedStorage/Combat/Shared/SkillDefinitions.luau`
- Create/Test: `src/ServerScriptService/Combat/Tests/HotbarSkillDefinitionTest.server.luau`

**Interfaces:**
- Produces: `HotbarConfig.SLOT_COUNT`, `HotbarConfig.DEFAULT_KEYS`, `HotbarConfig.ACTION_NAMES`, `HotbarConfig.PROTOTYPE_LOADOUT`, `HotbarConfig.get_skill_for_slot(slot)`.
- Produces: `SkillDefinitions.get(skill_id)`, `SkillDefinitions.is_valid(skill_id)`.

- [ ] **Step 1: Write the failing shared-definition test**

```lua
assert_true(HotbarConfig.SLOT_COUNT == 8, "Hotbar must expose eight slots.")
assert_true(HotbarConfig.DEFAULT_KEYS[1] == Enum.KeyCode.One, "Slot 1 must default to 1.")
assert_true(HotbarConfig.PROTOTYPE_LOADOUT[1] == "ShieldBash", "Slot 1 must equip Shield Bash.")
local shield_bash = SkillDefinitions.get("ShieldBash")
assert_true(shield_bash.STAMINA_COST == 20, "Shield Bash must cost 20 Stamina.")
assert_true(shield_bash.COOLDOWN_SECONDS == 4.0, "Shield Bash cooldown must be 4 seconds.")
assert_true(shield_bash.WIND_UP_SECONDS == 0.16, "Shield Bash wind-up must be 0.16 seconds.")
assert_true(shield_bash.REACH_STUDS == 6.0, "Shield Bash reach must be 6 studs.")
```

- [ ] **Step 2: Confirm RED in Studio**

Run Play with test scripts enabled. Expected: test errors because the shared modules are missing.

- [ ] **Step 3: Implement focused shared modules**

```lua
local HotbarConfig = table.freeze({
    SLOT_COUNT = 8,
    DEFAULT_KEYS = table.freeze({
        Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three,
        Enum.KeyCode.Four, Enum.KeyCode.Five, Enum.KeyCode.Six,
        Enum.KeyCode.Seven, Enum.KeyCode.Eight,
    }),
    PROTOTYPE_LOADOUT = table.freeze({ [1] = "ShieldBash" }),
})
```

`SkillDefinitions` defines one `ShieldBash` record with timing, hitbox, low damage, forward step, movement scaling, and stagger duration. Definitions are frozen and validated when the module loads.

- [ ] **Step 4: Confirm GREEN and run existing shared/config tests**
- [ ] **Step 5: Commit task when working in the real repository**

```bash
git add src/ReplicatedStorage/Combat/Shared src/ServerScriptService/Combat/Tests/HotbarSkillDefinitionTest.server.luau
git commit -m "feat: define shield bash hotbar slot"
```

### Task 2: Server cooldown service

**Files:**
- Create: `src/ServerScriptService/Combat/SkillCooldownService.luau`
- Create/Test: `src/ServerScriptService/Combat/Tests/SkillCooldownServiceTest.server.luau`

**Interfaces:**
- Produces: `is_ready(owner: Instance, skill_id: string, now: number?): boolean`.
- Produces: `start(owner: Instance, skill_id: string, duration: number, now: number?): number` returning cooldown expiry.
- Produces: `get_remaining(owner: Instance, skill_id: string, now: number?): number`.
- Produces: `remove_owner(owner: Instance)`.

- [ ] **Step 1: Write failing cooldown tests**

```lua
assert_true(service.is_ready(owner, "ShieldBash", 10), "Fresh skill must be ready.")
service.start(owner, "ShieldBash", 4, 10)
assert_true(not service.is_ready(owner, "ShieldBash", 12), "Cooldown must reject early use.")
assert_close(service.get_remaining(owner, "ShieldBash", 12), 2, 0.001, "Remaining cooldown is wrong.")
assert_true(service.is_ready(owner, "ShieldBash", 14), "Skill must become ready at expiry.")
```

- [ ] **Step 2: Confirm RED**
- [ ] **Step 3: Implement per-owner/per-skill expiry table with optional deterministic `now` for tests**
- [ ] **Step 4: Confirm GREEN**
- [ ] **Step 5: Commit**

```bash
git add src/ServerScriptService/Combat/SkillCooldownService.luau src/ServerScriptService/Combat/Tests/SkillCooldownServiceTest.server.luau
git commit -m "feat: add active skill cooldown service"
```

### Task 3: Shared NPC stagger service and Marauder integration

**Files:**
- Create: `src/ServerScriptService/Combat/StaggerService.luau`
- Create/Test: `src/ServerScriptService/Combat/Tests/StaggerServiceTest.server.luau`
- Modify: `src/ServerScriptService/Combat/TrainingMarauderController.server.luau`

**Interfaces:**
- Produces: `apply(target: Model, duration: number, now: number?): number`.
- Produces: `is_staggered(target: Model, now: number?): boolean`.
- Produces: `get_remaining(target: Model, now: number?): number`.
- Produces: `clear(target: Model)`.
- Uses attribute: `CombatStaggeredUntil`.

- [ ] **Step 1: Write failing stagger tests**

```lua
local expiry = service.apply(target, 1.0, 10)
assert_close(expiry, 11, 0.001, "First expiry is wrong.")
service.apply(target, 0.25, 10.2)
assert_close(service.get_remaining(target, 10.2), 0.8, 0.001, "Shorter stagger must not reduce remaining duration.")
service.apply(target, 1.0, 10.5)
assert_close(service.get_remaining(target, 10.5), 1.0, 0.001, "Longer stagger may refresh to the greater remaining duration.")
```

- [ ] **Step 2: Confirm RED**
- [ ] **Step 3: Implement service and replace Marauder local `staggered_until` ownership**
- [ ] **Step 4: Ensure a stagger during Marauder wind-up cancels the pending strike before damage resolution**
- [ ] **Step 5: Confirm GREEN plus existing DefenseService tests**
- [ ] **Step 6: Commit**

```bash
git add src/ServerScriptService/Combat/StaggerService.luau src/ServerScriptService/Combat/TrainingMarauderController.server.luau src/ServerScriptService/Combat/Tests/StaggerServiceTest.server.luau
git commit -m "feat: share marauder stagger state"
```

### Task 4: Reusable melee target callback

**Files:**
- Modify: `src/ServerScriptService/Combat/MeleeHitService.luau`
- Modify/Test: `src/ServerScriptService/Combat/Tests/MeleeHitServiceTest.server.luau`

**Interfaces:**
- Extends `MeleeSwingContext` with optional `on_target: ((Model) -> ())?`, `source_kind: string?`, and `source_id: string?`.
- Existing basic-attack callers remain source-compatible.

- [ ] **Step 1: Add failing callback/deduplication test**

```lua
local callback_count = 0
local callback_context = table.clone(context)
callback_context.on_target = function(_target)
    callback_count += 1
end
MeleeHitService.begin_active_window(callback_context)
task.wait(attack_definition.ACTIVE_SECONDS + 0.05)
assert_true(callback_count == 3, "Each accepted target must invoke callback once across swept samples.")
```

- [ ] **Step 2: Confirm RED because callbacks are ignored**
- [ ] **Step 3: In `process_sample`, call `on_target` when provided; otherwise keep the exact existing `DamageService.apply_damage` path**
- [ ] **Step 4: Confirm callback GREEN and all existing melee/swept tests GREEN**
- [ ] **Step 5: Commit**

```bash
git add src/ServerScriptService/Combat/MeleeHitService.luau src/ServerScriptService/Combat/Tests/MeleeHitServiceTest.server.luau
git commit -m "refactor: reuse melee acquisition for active skills"
```

### Task 5: Authoritative Shield Bash execution

**Files:**
- Modify: `src/ReplicatedStorage/Combat/Remotes.model.json`
- Modify: `src/ReplicatedStorage/Combat/Shared/CombatConfig.luau`
- Modify: `src/ServerScriptService/Combat/CombatService.server.luau`
- Create/Test: `src/ServerScriptService/Combat/Tests/ShieldBashIntegrationTest.server.luau`

**Interfaces:**
- Adds remote: `CombatConfig.REMOTES.SKILL_REQUEST = "SkillRequest"`.
- `PlayerCombatState` gains `current_skill_id: string?`.
- Shield Bash request carries only server-recognised skill id `"ShieldBash"`; server validates it equals the prototype skill equipped in Slot 1.

- [ ] **Step 1: Write failing integration assertions for remote, services, config, skill state fields/attributes, and free basic attacks**
- [ ] **Step 2: Confirm RED**
- [ ] **Step 3: Add transaction validation in this order: state is Locomotion -> known/equipped skill -> cooldown ready -> Stamina spend -> cooldown start -> enter WindUp**
- [ ] **Step 4: Implement Shield Bash active window using `MeleeHitService.begin_active_window` with `on_target` that calls `DamageService.apply_damage` and `StaggerService.apply`**

```lua
on_target = function(target: Model)
    DamageService.apply_damage({
        attacker = player,
        attacker_character = character,
        target = target,
        source_kind = "Skill",
        source_id = "ShieldBash",
        attack_id = nil,
        base_damage = shield_bash.BASE_DAMAGE,
        multiplier = 1,
    })
    StaggerService.apply(target, shield_bash.STAGGER_SECONDS)
end
```

- [ ] **Step 5: Preserve combo fields unchanged across Shield Bash and clear only `current_skill_id` after recovery**
- [ ] **Step 6: Clean cooldown state on player removal; clear skill state on respawn**
- [ ] **Step 7: Confirm integration and all existing server combat tests GREEN**
- [ ] **Step 8: Commit**

```bash
git add src/ReplicatedStorage/Combat src/ServerScriptService/Combat
git commit -m "feat: execute shield bash server side"
```

### Task 6: Slot-1 input and Shield Bash presentation

**Files:**
- Modify: `src/StarterPlayerScripts/Combat/InputController.client.luau`
- Modify: `src/StarterPlayerScripts/Combat/ClientCombatController.luau`
- Modify: `src/StarterPlayerScripts/Combat/DefensePresentation.client.luau`
- Modify: `src/StarterPlayerScripts/Combat/FeedbackController.client.luau`
- Modify/Test: `src/ServerScriptService/Combat/Tests/ShieldBashIntegrationTest.server.luau`

**Interfaces:**
- Input binds `HotbarConfig.ACTION_NAMES[1]` to `HotbarConfig.DEFAULT_KEYS[1]`.
- Client sends `SkillRequest:FireServer("ShieldBash")`.
- Server state remote continues to use the existing second string field; for active skills it carries `current_skill_id` when no basic attack id is active.

- [ ] **Step 1: Add failing static/runtime assertions that Slot 1 is bound through `HotbarConfig`, not a Shield-Bash-specific physical-key constant**
- [ ] **Step 2: Confirm RED**
- [ ] **Step 3: Bind Slot 1 and send only the skill id**
- [ ] **Step 4: Mirror server `WindUp/Active/Recovery` for recognised skill ids in `ClientCombatController` without altering predicted basic attacks**
- [ ] **Step 5: Track `current_action_id` in `DefensePresentation` and render Shield Bash by interpolating idle -> forward bash pose -> idle using state timing**
- [ ] **Step 6: Update `FeedbackController` so recognised skills do not enable the sword trail or request a sword animation clip**
- [ ] **Step 7: Confirm the existing defense presentation paths are unchanged for Blocking, Dodging, GuardBreak, and ordinary Locomotion**
- [ ] **Step 8: Confirm tests GREEN**
- [ ] **Step 9: Commit**

```bash
git add src/StarterPlayerScripts/Combat src/ServerScriptService/Combat/Tests/ShieldBashIntegrationTest.server.luau
git commit -m "feat: bind shield bash to skill slot one"
```

### Task 7: Guarded installer and final verification

**Files:**
- Create package installer: `01_install_step6a_shield_bash.ps1`
- Create package README: `README.txt`
- Include approved spec and this implementation plan under `files/docs/superpowers/...`.

- [ ] **Step 1: Compute exact SHA-256 hashes for every modified V11 source file and every packaged replacement**
- [ ] **Step 2: Installer preflights project root, `default.project.json`, package integrity, and exact current hashes before changing anything**
- [ ] **Step 3: Installer backs up every replaced file and records newly created files so an unsafe partial patch cannot proceed**
- [ ] **Step 4: Installer copies all files, runs `rojo build`, runs `git diff --check`, prints `git status --short`, and never stages/commits/pushes**
- [ ] **Step 5: Run package-local integrity validation and ZIP listing inspection**
- [ ] **Step 6: Manual Studio acceptance after user installs**

```text
1 = Shield Bash
20 Stamina spent
Immediate repeat rejected
Available again after 4 seconds
Nearby frontal Marauder takes low damage and staggers
Behind/out-of-range/obstructed target is not hit
Mouse1 combo remains Slash1 -> Slash2 -> Finisher
RMB block, Shift dodge, Ctrl View Lock and Guard Break remain unchanged
All Step 1-5 and new Step 6A Studio tests print PASS
```

---

## Plan Self-Review

### Spec coverage

Covered: slots 1-8 defaults, Slot 1 Shield Bash, rebind-ready logical boundary, server authority, 20 Stamina, 4-second cooldown, 0.16-second wind-up, 6-stud reach, block-matched 120-degree frontal cone, obstruction/deduplication, low damage, stagger, Locomotion-only start, no block cancel, combo preservation, Marauder interruption/feedback, prototype presentation, regression tests, guarded installer, and Step 6A scope exclusions.

### Placeholder scan

No `TBD`, `TODO`, or unspecified implementation work remains.

### Type consistency

The same `ShieldBash` skill id, `SkillRequest` remote, `current_skill_id` field, `CombatStaggeredUntil` attribute, and cooldown/stagger service signatures are used throughout all tasks.
