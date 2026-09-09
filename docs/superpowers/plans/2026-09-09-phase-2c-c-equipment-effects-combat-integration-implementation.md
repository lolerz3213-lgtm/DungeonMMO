# Phase 2C.C Equipment Effects + Combat Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the accepted six-slot persistent Equipment state alter
server-authoritative combat through one data-driven resolver while locking the
Dungeon run to the gear brought into it.

**Architecture:** Extend ItemDefinitions with small combat metadata, resolve it
through one pure `EquipmentStatResolver`, and include Equipment in
`ProgressionRuntimeState`'s deep-cloned authoritative runtime snapshot. Existing
combat continues consuming runtime getters; Base refreshes runtime state after
equipment mutation, and prototype sword/shield presentation follows authoritative
equipped state without owning stats.

**Tech Stack:** Roblox Luau, Rojo 7.7.0, existing server-authoritative service
architecture and in-Studio server tests.

**Spec:**
`docs/superpowers/specs/2026-09-09-phase-2c-c-equipment-effects-combat-integration-design.md`

## Global Constraints

- Start from canonical server-main `8587c1546aa1689b69606f860fb5c18a847de617`.
- Preserve accepted Phase 1, 2A, 2B, 2C.A and 2C.B behaviour.
- Reuse the Phase 2C.B six-slot Equipment table; do not create another equipment system.
- Equipment mutation remains Base-only.
- Dungeon uses the equipment brought into the run; new loot cannot affect the active run.
- Client never owns authoritative gear stats.
- No Mage/Ranger, advanced classes, crafting, economy, unique instances, affixes,
  durability, enhancement, final balance, large content production, Robux/race-change,
  or environment-art work.
- `art/dungeon-environment-prototype` is strictly off limits.
- No stage/commit/push/merge/publish before the explicit user approval gate.
- TEMP-only validation outputs; no PROD or Robux spend.

---

### Task 1: Pure equipment stat resolver

**Files:**
- Create: `src/ReplicatedStorage/Core/Shared/EquipmentStatResolver.luau`
- Modify: `src/ReplicatedStorage/Core/Shared/ItemDefinitions.luau`
- Test: `src/ServerScriptService/Core/Tests/EquipmentStatResolverTest.server.luau`

**Interfaces:**
- Consumes: `EquipmentSlots.ORDER`, `ItemDefinitions.get(item_id)`.
- Produces:
  - `EquipmentStatResolver.resolve(equipment: any): any`
  - `EquipmentStatResolver.with_slot(equipment: any, slot: string, item_id: string?): any`
  - resolved fields `PhysicalDamageBonus`, `MaxHealthFlat`,
    `CriticalChanceBonus`, `WeaponTags`, `WeaponItemId`, `OffHandItemId`.

- [x] Write RED tests proving neutral empty equipment, aggregation, slot validation,
  malformed data handling and weapon-tag derivation.
- [x] Verify the RED contract targets missing resolver/metadata rather than accepted behaviour.
- [x] Add only the approved `CombatModifiers` and `WeaponTags` metadata to representative
  items.
- [x] Implement minimal deterministic resolver and candidate-slot helper.
- [ ] Re-run focused tests and refactor only after green.

### Task 2: Runtime equipment snapshot and combat getters

**Files:**
- Modify: `src/ServerScriptService/Core/Services/ProgressionRuntimeState.luau`
- Test: `src/ServerScriptService/Core/Tests/ProgressionRuntimeEquipmentTest.server.luau`
- Preserve/regress: `src/ServerScriptService/Core/Tests/CharacterCombatStatsTest.server.luau`

**Interfaces:**
- Consumes: `EquipmentStatResolver.resolve`.
- Produces:
  - internal `Equipment` runtime snapshot;
  - `get_equipment_effects(user_id: number): any`;
  - `get_weapon_tags(user_id: number): {[string]: boolean}`;
  - existing `get_physical_multiplier`, `get_critical_chance`, `get_max_health`
    composed with equipment;
  - accepted `get_heal_multiplier`, `get_critical_damage_multiplier`,
    `get_basic_attack_rate` semantics unchanged.

- [x] Write RED tests for sword physical bonus, stacked health, crit composition/clamp,
  unchanged attack rate/healing/crit damage, and deep-clone run locking.
- [ ] Verify source Equipment mutation after `set_character` does not yet satisfy the
  desired locked behaviour test.
- [x] Extend runtime state with a deep-cloned Equipment table and cached effects.
- [x] Compose approved equipment effects into existing getters without duplicating
  race/attribute formulas.
- [x] Add authoritative weapon-tag getter.
- [ ] Re-run focused and existing character-combat tests.

### Task 3: Authoritative weapon requirements

**Files:**
- Modify: `src/ServerScriptService/Core/Services/ProgressionRuntimeState.luau`
- Test: `src/ServerScriptService/Combat/Tests/EquipmentWeaponRequirementTest.server.luau`
- Regress: `src/ServerScriptService/Combat/Tests/ArcSlashIntegrationTest.server.luau`

**Interfaces:**
- Consumes: `ProgressionRuntimeState.get_weapon_tags(user_id)`.
- Produces: `is_skill_usable` that keeps its compatibility parameter but resolves
  authoritative weapon tags from the runtime Equipment snapshot instead of the
  prototype Tool.

- [x] Write RED test demonstrating that Arc Slash authority follows runtime equipped
  Weapon even when prototype visual state differs.
- [x] Keep CombatService unchanged and move authoritative tag selection into the
  existing runtime skill-usability boundary.
- [x] Preserve all existing SkillProgressionDefinitions weapon-tag checks.
- [ ] Re-run Arc Slash and relevant combat regressions in Roblox Studio.

### Task 4: Base equipment refresh and server preview snapshot

**Files:**
- Modify: `src/ServerScriptService/Core/Services/EquipmentService.luau`
- Modify: `src/ServerScriptService/Base/BaseRuntime.server.luau`
- Test: `src/ServerScriptService/Core/Tests/EquipmentServiceEffectsTest.server.luau`

**Interfaces:**
- Consumes: `EquipmentStatResolver.resolve`, `EquipmentStatResolver.with_slot`.
- Produces sanitized snapshot fields:
  - `Effects` on owned equipment rows;
  - `EquippedEffects` aggregate;
  - candidate `PreviewEffects` and `DeltaEffects` for each owned item or equivalent
    server-computed representation.

- [x] Write RED tests for sanitized per-item effects, aggregate equipped effects and
  replace-one-slot candidate preview.
- [x] Implement server snapshot calculations without granting authority to preview data.
- [x] Prepare the exact Base runtime patch so successful equip/unequip calls
  `refresh_runtime_character` before refreshed snapshots are sent.
- [ ] Prove ineligible/unowned rows cannot mutate equipment through preview paths.

### Task 5: Base equipment UI effects

**Files:**
- Modify: `src/StarterPlayerScripts/Base/EquipmentPanel.client.luau`
- Test: add a small pure presentation rules module/test only if needed to avoid embedding
  formatting logic in the large client script.

**Interfaces:**
- Consumes server snapshot effect/preview fields only.
- Produces readable current effects and selected-item delta display.

- [x] Add RED presentation contract test and extract pure formatting rules.
- [x] Render aggregate equipped effects and selected candidate deltas.
- [x] Keep all authoritative totals/deltas server-computed; client only formats them.
- [ ] Preserve all accepted equip/unequip/rejection flows.

### Task 6: Equipment-aware prototype sword/shield presentation

**Files:**
- Modify: `src/ServerScriptService/Combat/PrototypeWeaponService.server.luau`
- Modify: `src/ServerScriptService/Combat/PrototypeShieldService.server.luau`
- Optionally modify: `src/ServerScriptService/Combat/PrototypeWeaponFactory.luau`
- Create: `src/ReplicatedStorage/Core/Shared/EquipmentPresentationRules.luau`
- Test: `src/ServerScriptService/Core/Tests/EquipmentPresentationRulesTest.server.luau`

**Interfaces:**
- Consumes authoritative runtime Equipment item IDs/effects.
- Produces presentation decisions only; no stat authority.

- [x] Write RED tests for sword/shield shown only for corresponding authoritative
  equipment and absent when slot empty/unsupported.
- [x] Implement the smallest shared presentation-decision seam.
- [x] Make current prototype services obey server-owned presentation attributes.
- [ ] Preserve accepted sword/shield construction/animation contracts where presentation
  is active.

### Task 7: Dungeon run-lock regression proof

**Files:**
- Reuse: `src/ServerScriptService/Core/Tests/ProgressionRuntimeEquipmentTest.server.luau`
- Modify Dungeon runtime only if a later Roblox integration test exposes a real gap.

**Interfaces:**
- Consumes the existing Dungeon admission call to
  `ProgressionRuntimeState.set_character`.
- Produces proof that the authoritative runtime copy is isolated from later source
  Inventory/Equipment mutations.

- [x] Prove source Inventory mutation cannot alter runtime effects.
- [x] Prove source Equipment mutation cannot alter runtime effects until an explicit
  authoritative reseed.
- [x] Avoid a duplicate DungeonSession equipment store; the existing admission/runtime
  snapshot boundary is sufficient for this gate.
- [ ] Confirm the same invariant in the eventual Dungeon Studio regression run.
- [x] Add a strictly Studio-only representative-loadout bootstrap so standalone
  Dungeon Studio visual evidence can exercise equipment-aware presentation.
- [ ] Observe the Studio bootstrap test GREEN with the Dungeon regression run.

### Task 8: Continuity docs and acceptance checklist

**Files:**
- Modify: `AGENTS.md`
- Modify: `docs/ai/CURRENT_STATE.md`
- Modify: `docs/ai/HANDOFF.md`
- Modify: `docs/ai/TEST_MATRIX.md`
- Create: `docs/testing/phase2c-c-studio-checklist.md`

**Interfaces:** none.

- [x] Correct stale v1.30/2C.B-next continuity wording.
- [x] Record canonical 2C.B close-out and 2C.C active gate.
- [x] Record exact 2C.C architecture and run-lock invariants.
- [x] Preserve live-migration waiver wording as NOT PASS.
- [x] Preserve strict art-branch isolation.

### Task 9: Verification before approval gate

**Files:** no new production scope.

- [x] Review exact changed-file list against this plan.
- [x] Scan for out-of-scope features and accidental art changes.
- [x] Run available focused automated/static checks in the isolated environment.
- [x] Run `git diff --check` in the real recovery worktree.
- [ ] Capture Roblox automated runtime test GREEN in a capable runner.
- [x] TEMP-only Base and Dungeon Rojo builds succeeded before manual acceptance.
- [x] Keep repository writes deferred until the explicit commit approval gate.
- [x] Present the exact changed-file boundary and verification evidence at the
  explicit commit gate after the required Studio gameplay/visual evidence.

## Self-review

- Spec coverage: every approved 2C.C requirement maps to Tasks 1-8.
- No duplicate equipment system or DungeonSession RunEquipment field is planned.
- The client receives display data but never owns combat totals.
- Representative gear affects only physical damage, flat max health and crit chance.
- Attack rate, crit damage and Mend remain unchanged by representative gear.
- Weapon tags are moved from Tool authority to runtime Equipment authority.
- All deferred features remain out of scope.
- Local commit is approved; push, merge and publish remain deferred until explicit user approval.
