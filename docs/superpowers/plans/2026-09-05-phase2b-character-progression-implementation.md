# DungeonMMO Phase 2B Character Progression Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the approved Phase 2B persistent character-progression vertical slice on top of the accepted Phase 2A Base/Dungeon architecture, including attributes, finite AP/SP entitlement, skill learning/ranks/proficiency, six-slot loadouts, the one-time Arc Slash Skill Book proof loop, independent respecs, and the automatic three-second free revive.

**Architecture:** Extend the existing `ProfileSchema` and `ProfileService` instead of creating a parallel save layer. Keep permanent progression mutations in focused Core services used by Base; expose Dungeon combat to the loaded build through a server-only shared runtime-state bridge, while proficiency writes are routed back through the Dungeon's already-owned `ProfileService`. Keep progression definitions in `ReplicatedStorage/Core/Shared` so both Base and Dungeon can read the same data without making the Base load Combat code.

**Tech Stack:** Roblox Luau, Rojo, existing DataStore/MemoryStore profile architecture, RemoteEvents, server-only ModuleScript runtime bridge, existing Combat/Dungeon services, guarded PowerShell ZIP installers.

**Spec:** `docs/superpowers/specs/2026-09-05-phase2b-character-progression-design.md`

## Global Constraints

- Phase 2A remains the accepted baseline; do not redesign the Base -> reserved Dungeon -> Base handoff, profile lease, reward-idempotency or teleport-failure boundaries.
- Phase 2B is class-neutral. Mend and Shield Bash are prototype starter skills only; starter grants and trainer catalogues must come from a class-definition interface that can be replaced by real race/class data later.
- Temporary maximum level is 10. XP at Level 10 is not banked.
- Level 1 has 0 AP / 0 SP; each level after Level 1 grants +1 AP and +1 SP entitlement.
- Base attributes are Strength 5, Dexterity 5, Vitality 5, Intellect 5, Spirit 5.
- Never persist a mutable authoritative `UnspentSP`; available SP is entitlement minus current refundable allocations. Apply the same derived-balance rule to AP.
- Normal Skill/SP respec preserves consumed Skill Book knowledge and cumulative proficiency; it removes refundable purchased ranks and recomputes available SP.
- Attribute and Skill respec counters are independent.
- Proficiency gives no direct power. It only unlocks the next rank for SP purchase and caps at the next unpurchased threshold.
- Phase 2B active hotbar size is 6; storage/API shape must permit expansion to 8 later.
- Permanent progression changes are Base-only. Dungeon allows loadout changes only between cleared encounters.
- Strength scales basic melee and physical skills; Spirit scales Mend/heal/shield values; Vitality scales max HP. Dexterity and Intellect are persisted and exposed through the same stat boundary for future ranged/finesse and normal magic attacks.
- The one free revive is automatic: consume on first death, three-second `Reviving` state, latest checkpoint, full HP/Stamina; later deaths retain the paid/spectator flow.
- Live Robux respec, Skill Book refund and Race Change products are not enabled in Phase 2B. Persist the counters/state needed for their future contracts only.
- DEV/TEST `/prof` commands must be rejected in PROD.
- Every installer must validate exact baselines/anchors, back up every modified file, roll back on error, run both Rojo builds when both Places are affected, run `git diff --check`, and never stage/commit/push.
- Any commit commands shown below are reviewer checkpoints only. **Do not execute them unless the user explicitly requests commits.**

---

## User-Facing Acceptance Gates

Internal Tasks 1-9 remain separate engineering/TDD units, but the user installs and manually accepts only three cumulative checkpoints:

| Gate | Internal tasks | User-visible proof | Package |
|---|---|---|---|
| **2B.A - Progression Foundation** | Tasks 1-4 | Profile migration/entitlement, attributes/derived stats, finite SP/rank/respec services, proficiency eligibility/caps and DEV/TEST commands. One cumulative Studio check only. | `DungeonMMO_Phase2B_A_Progression_Foundation.zip` |
| **2B.B - Gameplay + Base Progression** | Tasks 5-8 | Arc Slash, dynamic six-slot loadout, trainer + Character -> Skills UI, first-clear book, automatic three-second free revive. One cumulative gameplay check only. | `DungeonMMO_Phase2B_B_Gameplay_Base_Progression.zip` |
| **2B.C - Persistence + Published Acceptance** | Task 9 | Full Base -> Dungeon -> Base persistence/reconnect/idempotency and published TEST acceptance. | `DungeonMMO_Phase2B_Progression_ACCEPTANCE_CANDIDATE.zip` |

Do not ask the user to manually accept Tasks 1, 2, 3, etc. separately. Internal task tests run underneath the cumulative gate.

## Locked File Structure

### Shared progression definitions

- Create `src/ReplicatedStorage/Core/Shared/AttributeConfig.luau` — base values, soft-cap math and derived multipliers/HP.
- Create `src/ReplicatedStorage/Core/Shared/SkillProgressionConfig.luau` — tier SP costs, tier thresholds, slot limits and proficiency caps.
- Create `src/ReplicatedStorage/Core/Shared/SkillProgressionDefinitions.luau` — Mend, Shield Bash and Arc Slash progression metadata.
- Create `src/ReplicatedStorage/Core/Shared/ClassProgressionDefinitions.luau` — temporary prototype class/trainer catalogue with class-defined starter skills.
- Modify `src/ReplicatedStorage/Core/Shared/ProfileSchema.luau` — add Phase 2B `Progression` state and bump schema version.
- Modify `src/ReplicatedStorage/Core/Shared/ProgressionConfig.luau` — explicit Level 1-10 XP table and cap.
- Modify `src/ReplicatedStorage/Core/Shared/ItemDefinitions.luau` — add the character-bound Arc Slash first-clear Skill Book item.
- Modify `src/ReplicatedStorage/Core/Remotes.model.json` — focused progression/loadout snapshot and mutation remotes.

### Core server services

- Modify `src/ServerScriptService/Core/Services/ProfileMigration.luau` — idempotent Phase 2A -> Phase 2B migration.
- Modify `src/ServerScriptService/Core/Services/ProgressionService.luau` — capped XP and AP/SP entitlement award.
- Create `src/ServerScriptService/Core/Services/AttributeService.luau` — atomic allocation/respec and derived-stat helpers.
- Create `src/ServerScriptService/Core/Services/SkillProgressionService.luau` — learn/rank/respec/SP accounting and one-time reward state.
- Create `src/ServerScriptService/Core/Services/LoadoutService.luau` — six-slot loadout validation/auto-fill.
- Create `src/ServerScriptService/Core/Services/ProficiencyService.luau` — cumulative capped proficiency grants.
- Create `src/ServerScriptService/Core/Services/ProgressionRuntimeState.luau` — server-only loaded build mirror for Combat access.
- Modify `src/ServerScriptService/Core/Services/RuntimeServices.luau` — compose the new services around the existing `ProfileService`.

### Base progression shell

- Create `src/ServerScriptService/Base/BaseProgressionController.luau` — Base-only remote validation and service calls.
- Modify `src/ServerScriptService/Base/BaseRuntime.server.luau` — wire controller, snapshots and runtime-state refresh.
- Modify `src/ServerScriptService/Base/BaseBuilder.server.luau` — add a simple generic Progression Trainer interaction point.
- Create `src/StarterPlayerScripts/Base/ProgressionTrainer.client.luau` — functional trainer panel.
- Create `src/StarterPlayerScripts/Core/SkillsMenu.client.luau` — Character -> Skills loadout menu shared by Base/Dungeon.
- Create `src/StarterPlayerScripts/Core/ProgressionClientState.luau` — read-only local snapshot cache used by trainer, skills menu and combat input.

### Combat / Dungeon integration

- Modify `src/ReplicatedStorage/Combat/Shared/SkillDefinitions.luau` — add Arc Slash combat definition and rank-aware base values where required.
- Modify `src/ReplicatedStorage/Combat/Shared/HotbarConfig.luau` — retain slot/action/key definitions but remove authoritative prototype skill ownership from server validation.
- Modify `src/StarterPlayerScripts/Combat/CombatInputActions.luau` — resolve the current skill from `ProgressionClientState` rather than the static prototype loadout.
- Modify `src/ServerScriptService/Combat/CombatService.server.luau` — validate equipped/known/rank/weapon state through `ProgressionRuntimeState`; apply Strength/Spirit/rank values; execute Arc Slash; send proficiency contribution events through the bridge.
- Modify `src/ServerScriptService/Combat/DamageService.luau` — expose applied damage cleanly to callers and retain the accepted validation boundary.
- Modify `src/ServerScriptService/Combat/MendService.luau` only if needed to accept a rank/stat-scaled pulse amount; do not move profile authority into this module.
- Modify `src/ServerScriptService/Dungeon/EncounterService.luau` — expose whether the current encounter is active/clear for loadout/proficiency rules.
- Create `src/ServerScriptService/Dungeon/DungeonProgressionBridge.luau` — bind Combat contribution/runtime queries to the Dungeon's loaded profile services and encounter eligibility.
- Modify `src/ServerScriptService/Dungeon/DungeonRuntime.server.luau` — initialize/refresh runtime progression state, wire loadout requests, award the Arc Slash first-clear book and send snapshots.
- Modify `src/ServerScriptService/Dungeon/DungeonDeathService.luau` — automatic three-second free revive state.
- Modify `src/ReplicatedStorage/Core/Shared/ReviveConfig.luau` — add `FREE_REVIVE_DELAY_SECONDS = 3`.
- Modify `src/StarterPlayerScripts/Dungeon/DungeonUi.client.luau` — replace the optional free-revive button state with `Reviving...` during the forced first revive.

### Tests

Create focused tests next to their owning services; do not put all Phase 2B assertions in one monolithic script:

- `Core/Tests/AttributeConfigTest.server.luau`
- `Core/Tests/Phase2BProfileMigrationTest.server.luau`
- `Core/Tests/Phase2BProgressionServiceTest.server.luau`
- `Core/Tests/AttributeServiceTest.server.luau`
- `Core/Tests/SkillProgressionServiceTest.server.luau`
- `Core/Tests/LoadoutServiceTest.server.luau`
- `Core/Tests/ProficiencyServiceTest.server.luau`
- `Combat/Tests/ProgressionDamageIntegrationTest.server.luau`
- `Combat/Tests/ArcSlashIntegrationTest.server.luau`
- `Combat/Tests/MendProgressionIntegrationTest.server.luau`
- `Dungeon/Tests/DungeonProgressionBridgeTest.server.luau`
- `Dungeon/Tests/ArcSlashFirstClearRewardTest.server.luau`
- `Dungeon/Tests/AutomaticFreeReviveTest.server.luau`
- `Base/Tests/BaseProgressionControllerTest.server.luau`

---

### Task 1: Phase 2B Schema, Config and Idempotent Entitlement Migration

**Files:**
- Create: `src/ReplicatedStorage/Core/Shared/AttributeConfig.luau`
- Create: `src/ReplicatedStorage/Core/Shared/SkillProgressionConfig.luau`
- Create: `src/ReplicatedStorage/Core/Shared/SkillProgressionDefinitions.luau`
- Create: `src/ReplicatedStorage/Core/Shared/ClassProgressionDefinitions.luau`
- Modify: `src/ReplicatedStorage/Core/Shared/ProfileSchema.luau`
- Modify: `src/ReplicatedStorage/Core/Shared/ProgressionConfig.luau`
- Modify: `src/ServerScriptService/Core/Services/ProfileMigration.luau`
- Modify: `src/ServerScriptService/Core/Services/ProgressionService.luau`
- Test: `src/ServerScriptService/Core/Tests/AttributeConfigTest.server.luau`
- Test: `src/ServerScriptService/Core/Tests/Phase2BProfileMigrationTest.server.luau`
- Test: `src/ServerScriptService/Core/Tests/Phase2BProgressionServiceTest.server.luau`

**Interfaces:**
- `AttributeConfig.BASE_VALUE == 5`
- `AttributeConfig.effective_investment(value: number): number`
- `AttributeConfig.physical_multiplier(strength: number): number`
- `AttributeConfig.heal_multiplier(spirit: number): number`
- `AttributeConfig.max_health(vitality: number): number`
- `ProgressionConfig.MAX_LEVEL == 10`
- `ProgressionConfig.get_required_xp(level: number): number?` returns nil at Level 10.
- `ProgressionConfig.level_entitlement(level: number): number` returns `clamp(level - 1, 0, 9)`.
- `SkillProgressionConfig.get_rank_cost(tier: string, rank: number): number?`
- `SkillProgressionConfig.get_threshold(tier: string, target_rank: number): number?`
- `ClassProgressionDefinitions.get("Prototype")` returns starter skills `{ "ShieldBash", "Mend" }` and teachable `{ "ArcSlash" }`.
- `ProgressionService.apply_xp_to_character(character, amount)` mutates XP/Level plus `Progression.AttributePointEntitlement` and `Progression.SkillPointEntitlement` exactly once per level gained.

- [ ] **Step 1: Write RED config/schema tests**

Use assertions equivalent to:

```lua
assert(AttributeConfig.BASE_VALUE == 5)
assert(AttributeConfig.physical_multiplier(5) == 1)
assert(AttributeConfig.effective_investment(20) > 15)
assert(AttributeConfig.effective_investment(20) < 20)
assert(ProgressionConfig.MAX_LEVEL == 10)
assert(ProgressionConfig.get_required_xp(1) == 100)
assert(ProgressionConfig.get_required_xp(9) == 900)
assert(ProgressionConfig.get_required_xp(10) == nil)
assert(ProgressionConfig.level_entitlement(1) == 0)
assert(ProgressionConfig.level_entitlement(10) == 9)
assert(SkillProgressionConfig.get_rank_cost("Rare", 1) == 3)
assert(SkillProgressionConfig.get_threshold("Rare", 2) == 200)
assert(SkillProgressionConfig.get_threshold("Rare", 3) == 500)
```

Migration test must start from a real Phase 2A-shaped character and assert after two migrations:

```lua
assert(first.Progression.AttributePointEntitlement == math.min(first.Characters.Slot1.Level - 1, 9))
assert(first.Progression.SkillPointEntitlement == math.min(first.Characters.Slot1.Level - 1, 9))
assert(first.Characters.Slot1.Progression.Attributes.Strength == 5)
assert(second.Characters.Slot1.Progression.AttributePointEntitlement == first.Characters.Slot1.Progression.AttributePointEntitlement)
assert(second.Characters.Slot1.Progression.SkillPointEntitlement == first.Characters.Slot1.Progression.SkillPointEntitlement)
```

- [ ] **Step 2: Verify RED state before production modules exist**

Run the package's static contract checker against the test files before adding the new modules. Expected failure: missing `AttributeConfig`, `SkillProgressionConfig`, or missing Phase 2B profile fields.

- [ ] **Step 3: Implement shared config and schema**

Use these locked prototype values in `ProgressionConfig`:

```lua
ProgressionConfig.MAX_LEVEL = 10
local XP_TO_NEXT_LEVEL = table.freeze({
    [1] = 100,
    [2] = 150,
    [3] = 200,
    [4] = 275,
    [5] = 350,
    [6] = 450,
    [7] = 575,
    [8] = 725,
    [9] = 900,
})
```

Use this soft-cap function exactly for Phase 2B:

```lua
local function effective_investment_from_points(points: number): number
    if points <= 15 then
        return points
    end
    local overflow = points - 15
    return 15 + overflow / (1 + overflow / 20)
end
```

The default `Progression` state must include the five attributes, entitlement values, starter skill records, six-slot loadout, separate respec counters and `OneTimeRewards.ArcSlashFirstClear = false`.

- [ ] **Step 4: Implement idempotent migration and capped XP award**

Migration must use `max(existing_valid_entitlement, ProgressionConfig.level_entitlement(level))`; never add `level - 1` repeatedly. XP processing must stop at Level 10 and discard excess XP once the cap is reached.

- [ ] **Step 5: Run Rojo build and Studio config/migration tests**

Run:

```powershell
rojo build default.project.json -o "$env:TEMP\DungeonMMO_Phase2B_1_Dungeon.rbxl"
rojo build base.project.json -o "$env:TEMP\DungeonMMO_Phase2B_1_Base.rbxl"
```

Expected Studio lines include:

```text
[Attribute Config Tests] PASS
[Phase 2B Profile Migration Tests] PASS
[Phase 2B Progression Service Tests] PASS
```

- [ ] **Step 6: Internal Gate 2B.A checkpoint A1**

Keep this change inside the cumulative 2B.A working tree. Run the listed automated tests, but do **not** create a user-facing package or request a separate manual acceptance yet.

Reviewer checkpoint only:

```bash
git add src/ReplicatedStorage/Core/Shared src/ServerScriptService/Core/Services/ProfileMigration.luau src/ServerScriptService/Core/Services/ProgressionService.luau src/ServerScriptService/Core/Tests
git commit -m "feat: add phase 2b profile progression entitlement"
```

---

### Task 2: Attribute Allocation, Derived Stats and Runtime Build Mirror

**Files:**
- Create: `src/ServerScriptService/Core/Services/AttributeService.luau`
- Create: `src/ServerScriptService/Core/Services/ProgressionRuntimeState.luau`
- Modify: `src/ServerScriptService/Core/Services/RuntimeServices.luau`
- Modify: `src/ServerScriptService/Base/BaseRuntime.server.luau`
- Modify: `src/ServerScriptService/Dungeon/DungeonRuntime.server.luau`
- Modify: `src/ServerScriptService/Combat/CombatService.server.luau`
- Modify: `src/ServerScriptService/Combat/MendService.luau`
- Test: `src/ServerScriptService/Core/Tests/AttributeServiceTest.server.luau`
- Test: `src/ServerScriptService/Combat/Tests/ProgressionDamageIntegrationTest.server.luau`
- Test: `src/ServerScriptService/Combat/Tests/MendProgressionIntegrationTest.server.luau`

**Interfaces:**
- `AttributeService.new(profile_service)`
- `AttributeService:preview(user_id, desired_attributes) -> result`
- `AttributeService:commit(user_id, desired_attributes) -> result`
- `AttributeService:respec(user_id) -> result`
- `AttributeService.get_available_points(character) -> number`
- `ProgressionRuntimeState.set_character(user_id, progression_snapshot)`
- `ProgressionRuntimeState.clear_character(user_id)`
- `ProgressionRuntimeState.get_attribute(user_id, name) -> number`
- `ProgressionRuntimeState.get_physical_multiplier(user_id) -> number`
- `ProgressionRuntimeState.get_heal_multiplier(user_id) -> number`
- `ProgressionRuntimeState.get_max_health(user_id) -> number`
- `ProgressionRuntimeState.apply_max_health(player)` sets MaxHealth from Vitality and clamps Health to the new maximum without adding bonus healing beyond the normal spawn/full-health path.

- [ ] **Step 1: Write RED AttributeService transaction tests**

Cover valid allocation, overspend, decrease-without-respec, malformed attribute names and full atomic rejection:

```lua
local result = service:commit(101, {
    Strength = 7, Dexterity = 5, Vitality = 5, Intellect = 5, Spirit = 5,
})
assert(result.ok == true)
assert(result.available_points == entitlement - 2)

local rejected = service:commit(101, {
    Strength = 99, Dexterity = 5, Vitality = 5, Intellect = 5, Spirit = 5,
})
assert(rejected.ok == false)
assert(profile_after_reject.Progression.Attributes.Strength == 7)
```

- [ ] **Step 2: Write RED combat scaling tests**

Test basic melee damage at Strength 5 vs 6 through the server multiplier boundary, Mend healing at Spirit 5 vs 6, and Vitality MaxHealth at 5 vs 6. Assert combat timing values from `CombatConfig` are unchanged.

- [ ] **Step 3: Implement AttributeService and runtime mirror**

`AttributeService` validates finite integer values, minimum 5, exact allowed keys, and total allocated AP <= entitlement. `ProgressionRuntimeState` stores only server-populated snapshots and provides base-value fallbacks if queried before profile load.

- [ ] **Step 4: Integrate Strength, Spirit and Vitality**

In `CombatService`, multiply basic melee `base_damage` and physical skill damage by `ProgressionRuntimeState.get_physical_multiplier(player.UserId)` server-side. Scale Mend pulse heal from the authoritative rank base value by `get_heal_multiplier`. Apply Vitality on character spawn/respawn in both Base and Dungeon after profile load; do not modify movement, attack durations, dodge i-frames or parry windows.

- [ ] **Step 5: Run both builds and Studio tests**

Expected lines:

```text
[Attribute Service Tests] PASS
[Progression Damage Integration Tests] PASS
[Mend Progression Integration Tests] PASS
```

Manual check: a TEST character with one extra Strength point does more server-confirmed sword damage than the same character at Strength 5; one extra Vitality point increases MaxHealth; one extra Spirit point increases effective Mend healing.

- [ ] **Step 6: Internal Gate 2B.A checkpoint A2**

Keep the attribute/runtime change inside the same cumulative 2B.A working tree. Automated regression only; no separate user package/manual gate.

---

### Task 3: Skill/SP Accounting, Learning, Rank Purchase and Independent Respec

**Files:**
- Create: `src/ServerScriptService/Core/Services/SkillProgressionService.luau`
- Create: `src/ServerScriptService/Core/Services/LoadoutService.luau`
- Modify: `src/ServerScriptService/Core/Services/RuntimeServices.luau`
- Modify: `src/ReplicatedStorage/Core/Shared/ItemDefinitions.luau`
- Modify: `src/ServerScriptService/Core/Services/InventoryService.luau` only if an atomic consume-by-item-id primitive is not already sufficient.
- Test: `src/ServerScriptService/Core/Tests/SkillProgressionServiceTest.server.luau`
- Test: `src/ServerScriptService/Core/Tests/LoadoutServiceTest.server.luau`

**Interfaces:**
- `SkillProgressionService.new(profile_service, inventory_service, loadout_service)`
- `SkillProgressionService.get_allocated_sp(character) -> number`
- `SkillProgressionService.get_available_sp(character) -> number`
- `SkillProgressionService:learn_skill(user_id, class_id, skill_id, source_item_id) -> result`
- `SkillProgressionService:purchase_rank(user_id, skill_id) -> result`
- `SkillProgressionService:respec_skills(user_id) -> result`
- `LoadoutService.auto_equip_first_free(character, skill_id) -> boolean`
- `LoadoutService.validate(character, requested_slots, max_slots) -> result`
- `LoadoutService:set(user_id, requested_slots, context) -> result` where `context` is `"Base"`, `"DungeonClear"`, or `"DungeonActive"`.

- [ ] **Step 1: Write RED SP-accounting tests**

Use a Level 10 character with 9 SP entitlement. Assert:

```lua
assert(service.get_available_sp(character) == 9)
-- Mend R1 and Shield Bash R1 are free starter grants.
-- Buy Mend R2 (1) + Shield Bash R2 (2) => 6 SP remain.
-- Repeating respec can never raise available SP above 9.
```

Test that a fully refunded Arc Slash with archived proficiency becomes unusable until Rank 1 is repurchased; starter Mend/Shield Bash Rank 1 survive the same respec.

- [ ] **Step 2: Write RED Skill Book atomicity tests**

Add item:

```lua
arc_slash_book_bound = {
    Id = "arc_slash_book_bound",
    Name = "Arc Slash Skill Book",
    Kind = "SkillBook",
    Rarity = "Rare",
    Stackable = false,
    Bound = true,
    Tradeable = false,
    SkillId = "ArcSlash",
}
```

Assert learning fails with no book, wrong book, insufficient SP or disallowed class catalogue; each failure leaves both inventory and SP allocation unchanged. Success consumes exactly one book, buys Rank 1 for 3 SP, marks knowledge known and auto-fills the first free hotbar slot.

- [ ] **Step 3: Implement SkillProgressionService using derived SP**

Do not persist `UnspentSP`. Compute cost from each skill definition and current purchased rank. `purchase_rank` requires known skill, previous rank, proficiency threshold for target rank, and sufficient derived available SP. Rank count comes from data.

- [ ] **Step 4: Implement LoadoutService validation**

Reject unknown skills, unpurchased skills, duplicates and more than six non-empty slots. Preserve the previous valid loadout on rejection. `auto_equip_first_free` fills the lowest empty slot and never overwrites.

- [ ] **Step 5: Implement independent respec counters**

`AttributeService:respec` increments only `RespecCounters.Attributes`; `SkillProgressionService:respec_skills` increments only `RespecCounters.Skills`. Phase 2B charge is zero in DEV/TEST, but the counter increments so future pricing can be layered without schema replacement.

- [ ] **Step 6: Run service tests and record internal Gate 2B.A checkpoint A3**

Expected lines:

```text
[Skill Progression Service Tests] PASS
[Loadout Service Tests] PASS
```

Do not package yet. These services ship together with Task 4 in cumulative Gate 2B.A.

---

### Task 4: Proficiency Engine and TEST Debug Commands

**Files:**
- Create: `src/ServerScriptService/Core/Services/ProficiencyService.luau`
- Create: `src/ServerScriptService/Core/ProgressionDebugCommands.server.luau`
- Create: `src/ServerScriptService/Dungeon/DungeonProgressionBridge.luau`
- Modify: `src/ServerScriptService/Dungeon/DungeonRuntime.server.luau`
- Modify: `src/ServerScriptService/Dungeon/EncounterService.luau`
- Test: `src/ServerScriptService/Core/Tests/ProficiencyServiceTest.server.luau`
- Test: `src/ServerScriptService/Dungeon/Tests/DungeonProgressionBridgeTest.server.luau`

**Interfaces:**
- `ProficiencyService.new(profile_service)`
- `ProficiencyService:grant(user_id, skill_id, contribution_units, context) -> result`
- `ProficiencyService:set_for_test(user_id, skill_id, mode_or_value, environment) -> result`
- `ProficiencyService.get_current_cap(character, skill_id) -> number`
- `DungeonProgressionBridge.bind({ proficiency_service, encounter_service, runtime_state })`
- `DungeonProgressionBridge.award_damage(player, skill_id, target_model, applied_damage, target_index)`
- `DungeonProgressionBridge.award_heal(player, skill_id, target_player, effective_heal)`
- `DungeonProgressionBridge.award_control(player, skill_id, target_model, control_kind, meaningful)`

- [ ] **Step 1: Write RED proficiency cap tests**

For Mend Common Rank 1:

```lua
-- rank 1 cap is Rank 2 threshold 100
assert(service:grant(user, "Mend", 90, ctx).new_value == 90)
assert(service:grant(user, "Mend", 20, ctx).new_value == 100)
assert(service:grant(user, "Mend", 20, ctx).granted == 0)
-- after Rank 2 purchase, same stored total can grow toward 300
```

Also assert proficiency survives Skill/SP respec and an unpurchased non-starter skill cannot gain more proficiency.

- [ ] **Step 2: Implement contribution eligibility**

Permanent combat proficiency requires the Dungeon bridge to confirm an active authored dungeon encounter. Training Dummy / training-arena targets do not carry accepted Dungeon encounter ownership and return zero. Arc Slash multi-target contribution uses diminishing weights, e.g. first valid target `1.0`, second `0.5`, third `0.25`, remaining targets `0.1`, then applies a configurable contribution cap. The bridge also enforces a per-encounter/per-skill proficiency ceiling so one encounter cannot be farmed indefinitely. Exact unit tuning remains config; eligibility, diminishing multi-target credit, per-encounter caps and threshold behavior are the acceptance boundary.

Mend awards only effective healing (`healed > 0`) while a dungeon encounter is active. The bridge rejects Base/training healing. Shield Bash gives base valid-hit contribution and one control bonus only when the control application meaningfully changes the target state; repeated bash against an already-disabled target receives no repeated control bonus.

- [ ] **Step 3: Implement `/prof` test command**

Support exact forms:

```text
/prof Mend 100
/prof ArcSlash next
/prof ShieldBash max
/prof Mend 0
```

The server resolves the issuing player's loaded character, validates the skill id and clamps to the configured prototype maximum. `EnvironmentConfig.get_environment()` must be `DEV` or `TEST`; `PROD` returns `CommandDisabledInProd` and logs the rejected attempt. The command changes proficiency only; it does not grant SP, knowledge or ranks.

- [ ] **Step 4: Run the full Gate 2B.A regression set and package cumulative Progression Foundation**

Expected lines:

```text
[Proficiency Service Tests] PASS
[Dungeon Progression Bridge Tests] PASS
```

Cumulative package name: `DungeonMMO_Phase2B_A_Progression_Foundation.zip`. This is the **only user-facing manual acceptance checkpoint for Tasks 1-4**.

---

### Task 5: Arc Slash Combat, Dynamic Six-Slot Hotbar and Rank-Aware Existing Skills

**Files:**
- Modify: `src/ReplicatedStorage/Combat/Shared/SkillDefinitions.luau`
- Modify: `src/ReplicatedStorage/Combat/Shared/HotbarConfig.luau`
- Modify: `src/StarterPlayerScripts/Combat/CombatInputActions.luau`
- Modify: `src/ServerScriptService/Combat/CombatService.server.luau`
- Modify: `src/ServerScriptService/Combat/DamageService.luau`
- Create: `src/StarterPlayerScripts/Core/ProgressionClientState.luau`
- Test: `src/ServerScriptService/Combat/Tests/ArcSlashIntegrationTest.server.luau`
- Test: update `src/ServerScriptService/Combat/Tests/HotbarSkillDefinitionTest.server.luau`

**Interfaces:**
- `ProgressionClientState.get_skill_for_slot(slot) -> string?`
- `ProgressionClientState.apply_snapshot(payload)`
- `ProgressionRuntimeState.get_skill_rank(user_id, skill_id) -> number`
- `ProgressionRuntimeState.is_skill_equipped(user_id, skill_id) -> boolean`
- `ProgressionRuntimeState.is_skill_usable(user_id, skill_id, weapon_tags) -> (boolean, reason)`

- [ ] **Step 1: Write RED Arc Slash tests**

Test authoritative definition exists, requires `OneHandedSword`, has a frontal multi-target melee hit shape, and cannot execute when unknown/unpurchased/not equipped/wrong weapon. Confirm Rank 1/2/3 values are read from progression data rather than from client parameters.

- [ ] **Step 2: Remove static prototype skill ownership from request path**

Keep `HotbarConfig.SLOT_COUNT = 8` for input mappings but expose `ACTIVE_SLOT_COUNT = 6` through progression config. `CombatInputActions.request_skill_slot(slot)` reads `ProgressionClientState`; the server ignores the client slot and validates the requested skill against `ProgressionRuntimeState`.

- [ ] **Step 3: Implement Arc Slash using existing melee active-window path**

Arc Slash should use the accepted facing-direction melee acquisition and brief commitment. It may hit multiple valid enemies once each per cast. Apply Strength server-side and send each accepted target to `DungeonProgressionBridge.award_damage` with diminishing target index. Do not add elemental identity or class requirements in Phase 2B.

- [ ] **Step 4: Make Mend and Shield Bash rank-aware**

Resolve skill rank server-side. Rank changes modify their configured effectiveness only; proficiency total alone must not change damage/healing. Preserve Shield Bash reach/cone and accepted defensive timing. Preserve Mend's committed channel/cancellation identity.

- [ ] **Step 5: Run Combat regression suite and record internal Gate 2B.B checkpoint B1**

At minimum verify existing basic attack, Shield Bash, Mend, dodge/block/parry and latency-validation tests still PASS alongside:

```text
[Arc Slash Integration Tests] PASS
[Hotbar Skill Definition Tests] PASS
[Progression Damage Integration Tests] PASS
[Mend Progression Integration Tests] PASS
```

Do not package yet. Keep this work in the cumulative 2B.B working tree.

---

### Task 6: Base Progression Trainer and Character -> Skills Menu

**Files:**
- Modify: `src/ReplicatedStorage/Core/Remotes.model.json`
- Create: `src/ServerScriptService/Base/BaseProgressionController.luau`
- Modify: `src/ServerScriptService/Base/BaseRuntime.server.luau`
- Modify: `src/ServerScriptService/Base/BaseBuilder.server.luau`
- Create: `src/StarterPlayerScripts/Base/ProgressionTrainer.client.luau`
- Create: `src/StarterPlayerScripts/Core/SkillsMenu.client.luau`
- Modify: `src/StarterPlayerScripts/Core/ProfileHud.client.luau`
- Modify: `src/ServerScriptService/Dungeon/DungeonRuntime.server.luau`
- Test: `src/ServerScriptService/Base/Tests/BaseProgressionControllerTest.server.luau`

**Interfaces / remotes:**

Add exact focused remotes:

```text
ProgressionSnapshot           server -> client; client may fire "Request" only
AttributeCommitRequest        client -> Base server
SkillLearnRequest             client -> Base server
SkillRankRequest              client -> Base server
AttributeRespecRequest        client -> Base server
SkillRespecRequest            client -> Base server
LoadoutRequest                client -> Base/Dungeon server
ProgressionActionResult       server -> client
```

`ProgressionSnapshot` payload contains presentation-only Level/XP/AP/SP/Attributes/Skills/Loadout/RespecCounters; clients never send it back as authority.

- [ ] **Step 1: Write RED Base controller tests**

Instantiate the controller with fake services. Assert every permanent mutation is accepted only in Base context and invalid requests return deterministic reasons while preserving prior profile state.

- [ ] **Step 2: Implement generic trainer service point**

`BaseBuilder` creates a simple source-controlled greybox trainer stand/model named `ProgressionTrainer` with a `ProximityPrompt`. It is a temporary service shell, not final NPC art. Trigger opens the trainer UI locally.

- [ ] **Step 3: Implement functional trainer UI**

The trainer panel must show:

- current Level, AP available and SP available;
- five attributes with current values and `+` preview controls;
- `Confirm` and `Cancel` for attribute preview;
- each known/teachable prototype skill with current rank, proficiency current/next threshold, next SP cost and status;
- Learn button for Arc Slash only when the book/requirements are met;
- Purchase Rank button only when eligible;
- Attribute Respec and Skill Respec actions with current independent count; Phase 2B displays `Free (TEST)` rather than live Robux/currency checkout.

- [ ] **Step 4: Implement Character -> Skills menu**

Show learned active skills and six active slots. Learning an active skill auto-fills the first free slot. Manual swapping sends the desired six-slot state through `LoadoutRequest`. Base accepts; Dungeon accepts only when `EncounterService` reports no active uncleared encounter. Never reset `SkillCooldownService` when the loadout changes.

- [ ] **Step 5: Send snapshots after every successful mutation**

After attribute commit/respec, learn/rank/respec or loadout update, refresh `ProgressionRuntimeState`, fire `ProgressionSnapshot`, and keep the existing Profile/Inventory HUD updates intact.

- [ ] **Step 6: Run Base + Dungeon UI/service tests and record internal Gate 2B.B checkpoint B2**

Do not package yet. Keep this work in the cumulative 2B.B working tree.

Manual Studio acceptance:

1. trainer opens in Base;
2. multi-point Attribute preview cancels without save;
3. Confirm commits atomically;
4. six-slot Skills menu swaps in Base;
5. Dungeon swap fails during Room 1 combat and succeeds after Room 1 clears.

---

### Task 7: Captain Arc Slash First-Clear Reward and Save/Reload Proof

**Files:**
- Modify: `src/ServerScriptService/Core/Services/RewardService.luau`
- Modify: `src/ServerScriptService/Dungeon/CompletionService.luau` if the cleanest exactly-once hook lives there; otherwise keep the hook in `DungeonRuntime.server.luau` immediately after successful authoritative completion reward commit.
- Modify: `src/ServerScriptService/Dungeon/DungeonRuntime.server.luau`
- Test: `src/ServerScriptService/Dungeon/Tests/ArcSlashFirstClearRewardTest.server.luau`

**Interfaces:**
- `SkillProgressionService:grant_arc_slash_first_clear(user_id, transaction_id) -> result`
- The result is idempotent from persistent `OneTimeRewards.ArcSlashFirstClear`; it inserts `arc_slash_book_bound` once and records the flag in the same profile mutation.

- [ ] **Step 1: Write RED exactly-once reward test**

Call the grant twice, save/reload, then call again. Assert inventory quantity is exactly one and the one-time flag is true after every repeat.

- [ ] **Step 2: Implement atomic persistent grant**

Do not use a runtime-only boolean. In one `ProfileService:mutate` call: check the persistent one-time flag, add the book if absent, set the flag, return `already_applied` on repeats.

- [ ] **Step 3: Integrate after validated Captain completion**

The first-clear book grant runs only for the same authoritative eligible completion recipients used by the accepted completion system. Save before return using the existing completion barrier. A forced return teleport failure must leave the book committed and must not re-grant it on Base join.

- [ ] **Step 4: Run reward regression tests and record internal Gate 2B.B checkpoint B3**

Expected:

```text
[Arc Slash First Clear Reward Tests] PASS
[Reward Service Tests] PASS
[Completion Service Tests] PASS
```

Do not package yet. Keep this work in the cumulative 2B.B working tree.

---

### Task 8: Automatic Three-Second Free Revive Correction

**Files:**
- Modify: `src/ReplicatedStorage/Core/Shared/ReviveConfig.luau`
- Modify: `src/ServerScriptService/Dungeon/DungeonDeathService.luau`
- Modify: `src/ServerScriptService/Dungeon/CompletionEligibilityRules.luau`
- Modify: `src/ServerScriptService/Dungeon/DungeonRuntime.server.luau`
- Modify: `src/StarterPlayerScripts/Dungeon/DungeonUi.client.luau`
- Test: `src/ServerScriptService/Dungeon/Tests/AutomaticFreeReviveTest.server.luau`
- Update: `src/ServerScriptService/Dungeon/Tests/DungeonDeathServiceTest.server.luau`
- Update: `src/ServerScriptService/Dungeon/Tests/CompletionEligibilityTest.server.luau`

**Interfaces / state:**
- `ReviveConfig.FREE_REVIVE_DELAY_SECONDS = 3`
- Add member mode `"Reviving"` as a forced, connected transition state.
- `DungeonDeathService:on_player_died` consumes the free revive atomically when available and schedules respawn; there is no client `Free` request for first death.
- `DungeonDeathService:request_free_revive` should be removed from the live path or return `AutomaticFreeRevive` so stale clients cannot create a second free revive.

- [ ] **Step 1: Write RED auto-revive tests with injected scheduler/clock**

Do not make tests sleep for real seconds. Inject `schedule(delay, callback)` through `DungeonDeathService.new(options)` and assert:

```lua
assert(member.FreeReviveUsed == true)
assert(member.Mode == "Reviving")
assert(scheduled_delay == 3)
assert(spawn_count == 0)
scheduled_callback()
assert(spawn_count == 1)
assert(member.Mode == "Active")
```

Test failed spawn falls to Spectating without restoring another free revive.

- [ ] **Step 2: Make wipe/eligibility rules Reviving-aware**

`all_members_inactive` must treat a connected `Reviving` member as pending return, not as a wipe-finalizing spectator. Completion eligibility must treat the forced Reviving state as eligible when the member was an eligible connected participant immediately before death; store the required pre-death eligibility bit server-side rather than trusting the client.

- [ ] **Step 3: Update UI**

When `member_mode == "Reviving"`, show a non-interactive `Reviving... 3`, `2`, `1` countdown and hide/disable the revive purchase button. After the free revive has been consumed, later Dead/Spectating payloads use the current paid offer + Return to Base flow.

- [ ] **Step 4: Run the full Gate 2B.B regression set and package cumulative Gameplay + Base Progression**

Expected:

```text
[Automatic Free Revive Tests] PASS
[Dungeon Death Service Tests] PASS
[Completion Eligibility Tests] PASS
[Return Portal Tests] PASS
```

Manual check: first death cannot be held indefinitely; exactly three seconds later the player returns at the latest checkpoint with full HP/Stamina.

Cumulative package name: `DungeonMMO_Phase2B_B_Gameplay_Base_Progression.zip`. This is the **only user-facing manual acceptance checkpoint for Tasks 5-8**.

---

### Task 9: Cross-Place Progression Persistence and Phase 2B Acceptance Gate

**Files:**
- Modify: `src/ServerScriptService/Base/BaseRuntime.server.luau`
- Modify: `src/ServerScriptService/Dungeon/DungeonRuntime.server.luau`
- Modify: `src/StarterPlayerScripts/Core/ProfileHud.client.luau`
- Create: `docs/testing/phase2b-published-test-checklist.md`
- Create/update: `docs/testing/phase2b-acceptance-record.md` only after user acceptance.
- Update roadmap after acceptance, not before.

**Interfaces:**
- Both Places call one helper to build the same sanitized `ProgressionSnapshot` from the selected character.
- Base saves before handing profile authority to Dungeon using the existing coordinator barrier.
- Dungeon saves progression changes before return using the existing completion/return barrier.

- [ ] **Step 1: Add the published TEST checklist**

Checklist must cover the exact accepted proof:

1. fresh/test Level 1 profile = 5/5/5/5/5, 0 AP/SP, Mend R1 + Shield Bash R1;
2. level gain = exactly +1 AP/+1 SP each level;
3. Strength changes basic sword damage;
4. Vitality changes MaxHealth;
5. Spirit changes Mend;
6. Mend/Shield Bash proficiency caps at next threshold;
7. `/prof ... next` moves only proficiency;
8. trainer rank purchase persists;
9. first Captain clear grants one bound Arc Slash book;
10. return to Base preserves book;
11. trainer consumes book + 3 SP atomically and learns Arc Slash;
12. Arc Slash auto-fills first free slot;
13. Character -> Skills swaps in Base;
14. active Dungeon encounter rejects swap; clear window accepts it;
15. Arc Slash requires one-handed sword and multi-target proficiency diminishes;
16. Attribute and Skill respec counters/allocations remain independent and cannot mint points;
17. first death auto-revives after three seconds at checkpoint;
18. later death uses paid/spectator flow;
19. Base -> Dungeon -> Base -> leave -> rejoin preserves the whole progression state.

- [ ] **Step 2: Run the complete Studio regression suite**

Build both Places and verify all existing Phase 1/2A tests plus all Phase 2B tests report PASS. `git diff --check` must be clean aside from Git's existing LF/CRLF warnings.

- [ ] **Step 3: Run published TEST cross-Place acceptance**

Use the existing Experience/Place setup and re-check `DungeonMMOEnvironment = TEST`, Dungeon Place ID on Base, and both forced teleport-failure switches false/absent. Live paid revives and live progression Robux products remain disabled.

- [ ] **Step 4: Package cumulative Phase 2B acceptance candidate**

Package name before user acceptance: `DungeonMMO_Phase2B_Progression_ACCEPTANCE_CANDIDATE.zip`.

It must include the approved Phase 2B spec, this implementation plan, published checklist, cumulative payload, guarded installer and manifest hashes. Do not mark Phase 2B functionally complete until the user confirms the manual acceptance proof.

- [ ] **Step 5: After user acceptance, freeze Phase 2B and update roadmap**

Create the final cumulative package `DungeonMMO_Phase2B_Progression_ACCEPTED.zip`, write the acceptance record, update the roadmap status to `Phase 2B - FUNCTIONALLY COMPLETE`, and set the next design slice to the first real race/base-class definitions and class-specific trainer catalogues.

---

## Recommended User-Facing Gate Order

The user performs only these three guarded install/test checkpoints:

1. **2B.A - Progression Foundation** — cumulative Tasks 1-4. Automated subtests cover schema/migration, Level/AP/SP, attributes, combat-stat integration, skill/SP/respec accounting, loadout service foundation, proficiency, encounter eligibility/caps and DEV/TEST commands. Manual burden: one Studio regression check for both generated Places.
2. **2B.B - Gameplay + Base Progression** — cumulative Tasks 5-8. Manual proof covers Arc Slash, the six-slot Skills menu/trainer loop, first-clear Skill Book and automatic three-second free revive.
3. **2B.C - Persistence + Published Acceptance** — Task 9. One real published TEST proof covers Base -> Dungeon -> Base, save/rejoin/reconnect and duplicate protection.

Do not ask the user to re-run unrelated combat acceptance after internal tasks. Each cumulative installer runs all prior automated regression tests in its validation builds.

## Plan Self-Review Result

- **Spec coverage:** Every Phase 2B design section maps to internal Tasks 1-9 and user-facing Gates 2B.A-2B.C: profile/migration, XP/AP/SP, attributes, skills/ranks, proficiency/debug commands, trainer/loadout, first-clear book, respec, combat scaling, revive correction, failure handling and cross-Place acceptance.
- **No placeholder implementation steps:** The plan uses exact file paths, module responsibilities, remote names, locked prototype numbers and explicit acceptance behavior. Final production tuning explicitly remains outside Phase 2B rather than being left as an implementation placeholder.
- **Type/interface consistency:** Base and Dungeon use the same `ProgressionRuntimeState`; permanent profile writes flow through service instances composed from the existing `ProfileService`; Base-only permanent mutations are separated from the shared loadout request; Combat never receives an independent DataStore/ProfileService instance.
- **Scope:** The plan does not add final races/classes, weapon mastery, crafting, party UI, final Base art or live Robux progression products. The nine internal engineering tasks are deliberately consolidated into three user-visible acceptance gates.
