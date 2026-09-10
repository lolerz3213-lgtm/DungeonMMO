# Phase 2C.D Mage Anti-Kiting + Charged Damage Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extend the accepted Phase 2C.D Mage candidate with a cancellable charged Wind Strike damage skill, full movement commitment for Wand damage actions, and slightly faster boss pursuit while preserving Fighter and existing Mage support behaviour.

**Architecture:** Keep the accepted server-owned combat state machine and persistent Equipment authority. Route Wand basic attacks through the existing Spirit Orb service with server-side rooting, add a focused WindStrikeService for projectile delivery, and use character attributes only for replicated charge presentation. Wind Strike Mana/cooldown commit occurs at successful Active entry so Block/Dodge cancellation during WindUp is free of spell cost.

**Tech Stack:** Roblox Luau, Rojo 7.7.0-rc.1, Windows PowerShell 5.1 installer, existing DungeonMMO combat/progression services.

**Spec:** `docs/superpowers/specs/2026-09-10-phase-2c-d-mage-base-class-support-foundation-design.md`

## Global Constraints

- Accepted baseline remains exactly `38feb4a3c15286c56a98ab686357b7cf30f2c693`.
- Work only in isolated branch `wip/phase-2c-d-mage-foundation-v6` / worktree `C:\Users\Remko\Documents\Roblox\DungeonMMO_Phase2CD_v6`.
- Never touch `C:\Users\Remko\Documents\Roblox\DungeonMMO_Art` or `art/dungeon-environment-prototype`.
- Never clean/reset/delete the v5 or recovery worktrees.
- No staging, commit, push, merge or Roblox publish in the candidate installer.
- Spirit Orb remains a free basic attack; Wind Strike is the new Mana damage skill.
- Wand basic attacks and Wind Strike are fully movement/jump locked while committed.
- Block/Dodge may cancel Wind Strike during WindUp; cancelled charge consumes no Mana and starts no cooldown.
- Captain chase speed is 17.5 studs/second; normal Marauders remain unchanged.
- Existing Fighter, Ward, Mage Heal, Mana, progression, revive and completion contracts remain regression gates.

---

### Task 1: Starter damage-skill data contract

**Files:**
- Modify: `src/ReplicatedStorage/Combat/Shared/SkillDefinitions.luau`
- Modify: `src/ReplicatedStorage/Core/Shared/SkillProgressionDefinitions.luau`
- Modify: `src/ReplicatedStorage/Core/Shared/ClassProgressionDefinitions.luau`
- Modify: `src/ReplicatedStorage/Core/Shared/TrainerCatalogues.luau`
- Modify: `src/ServerScriptService/Core/Tests/MageDefinitionsTest.server.luau`

**Interfaces:**
- Produces: `SkillDefinitions.get("WindStrike")` with `KIND="MagicProjectile"`, 25 Mana, 5s cooldown, 1.0s WindUp, 30 base damage, 60-stud range and zero movement scales.
- Produces: Mage starter order `WindStrike`, `ArcaneWard`, `MageHeal` and Mage trainer rank support for all three.

- [ ] **Step 1: Write the failing definition contract**

Add assertions to `MageDefinitionsTest.server.luau` that Wind Strike exists, requires `ArcaneWand`, is a Mage starter, has Rank 1 damage 30, Mana 25, cooldown 5, charge 1.0 and movement scales all zero.

- [ ] **Step 2: Verify RED through the package contract**

Run the local static candidate regression and confirm it fails because `WindStrike` is absent from the v5 payload.

- [ ] **Step 3: Implement minimal data definitions**

Add `MagicProjectileSkillDefinition`, Wind Strike Rank 1-3 damage values `30/36/42`, its progression definition, starter position 1, and Mage trainer rank entry.

- [ ] **Step 4: Re-run the focused package contract**

Expected: Wind Strike definition/start/trainer assertions pass.

### Task 2: Root Wand damage actions without weakening defensive priority

**Files:**
- Modify by installer patch: `src/ServerScriptService/Combat/CombatService.server.luau`
- Test by installer patch: `src/ServerScriptService/Combat/Tests/HotbarSkillDefinitionTest.server.luau`

**Interfaces:**
- Consumes: `ProgressionRuntimeState.get_weapon_tags(user_id)` and the existing StateRules Block/Dodge priority transitions.
- Produces: zero WalkSpeed and disabled jumping for Wand basic attacks and Wind Strike while their attack/skill state is committed.

- [ ] **Step 1: Write static assertions for root/cancel semantics**

The contract must require an `ArcaneWand` basic-attack movement-lock branch and must preserve StateRules transitions from `WindUp` to `Blocking`/`Dodging`.

- [ ] **Step 2: Verify RED**

Confirm the v5 installer does not contain Wand-specific movement locking.

- [ ] **Step 3: Implement the minimal movement lock**

In `apply_movement_scale`, force `scale=0` whenever `record.current_attack_id` is active and authoritative weapon tags include `ArcaneWand`; otherwise retain existing timing scales. Disable Jumping whenever the resolved movement scale is zero or state is MENDING/DEAD. No StateRules graph change is needed because WindUp already accepts Block and Dodge.

- [ ] **Step 4: Update the old Mend test expectation**

Change `HotbarSkillDefinitionTest` from `Mend.STAMINA_COST == 0` to `== 20`, with Phase 2C.D wording.

### Task 3: Charged Wind Strike server path and presentation

**Files:**
- Create: `src/ServerScriptService/Combat/WindStrikeService.luau`
- Create: `src/ServerScriptService/Combat/Tests/WindStrikeServiceTest.server.luau`
- Modify by installer patch: `src/ServerScriptService/Combat/CombatService.server.luau`
- Modify: `src/StarterPlayerScripts/Combat/MagePresentation.client.luau`
- Modify by installer patch: `src/StarterPlayerScripts/Core/SkillsMenu.client.luau`

**Interfaces:**
- `WindStrikeService.fire(context) -> boolean` consumes attacker, character, skill definition, magical/critical multipliers and sequence ID; server owns a swept-Raycast projectile and calls DamageService once on the first legal target.
- CombatService replicates `WindStrikeCharging:boolean` and `WindStrikeChargeEndsAt:number` on the caster character.

- [ ] **Step 1: Write RED service/contract tests**

Require server-travelled projectile configuration, first-legal-target damage, 60-stud finite range, and no homing/target position from the client.

- [ ] **Step 2: Implement WindStrikeService**

Create an anchored Neon projectile, launch from the caster facing, advance by Heartbeat with swept Raycast, resolve the first humanoid Model, validate with `CombatTargetRules.is_damageable`, then call `DamageService.apply_damage` with source `MagicSkill`, source/attack ID `WindStrike`, `BASE_DAMAGE * magical_multiplier` and critical inputs.

- [ ] **Step 3: Implement deferred resource/cooldown commit**

At request time, reject Wind Strike if current Mana is below 25 but do not spend it. `start_skill` sets the charge attributes. When `enter_skill_active` confirms the sequence is still in WindUp, call `ManaService.try_spend`; only on success start Wind Strike cooldown, clear the charge attribute, then fire the projectile. Other skills retain their existing request-time cost/cooldown semantics.

- [ ] **Step 4: Clear charge on every cancellation/lifecycle path**

Clear `WindStrikeCharging`/`WindStrikeChargeEndsAt` when Block or Dodge cancels the sequence, on death, on player removal, and when release succeeds. Delayed callbacks are already guarded by `sequence_is_current`, so a cancelled cast cannot later fire.

- [ ] **Step 5: Add placeholder charge presentation**

`MagePresentation.client.luau` listens to the replicated charge attributes and displays a growing/pulsing Neon energy sphere around the Wand/hand for the charge duration, destroying it immediately when cancellation/release clears the flag.

- [ ] **Step 6: Add Wind Strike to the Skills menu**

Expose it alongside Arcane Ward and Mage Heal so the three starter skills can be slotted/reordered using the existing generic loadout UI.

### Task 4: Captain pursuit and regression-fixture cleanup

**Files:**
- Modify by installer patch: `src/ServerScriptService/Dungeon/MarauderCaptainController.server.luau`
- Modify by installer patch: `src/ServerScriptService/Core/Tests/CharacterCombatStatsTest.server.luau`

**Interfaces:**
- Produces: `CHASE_SPEED = 17.5` only for the Captain.
- Produces: fake Player test doubles with `SetAttribute`/`GetAttribute` storage compatible with accepted runtime presentation publication.

- [ ] **Step 1: Write RED contract assertions**

Require Captain 17.5 chase speed and forbid changes to normal Marauder chase tuning. Require CharacterCombatStats test doubles to support Player attributes.

- [ ] **Step 2: Implement Captain speed change**

Replace only `local CHASE_SPEED = 11.5` with `local CHASE_SPEED = 17.5` in the Captain controller.

- [ ] **Step 3: Repair the stale CharacterCombatStats test doubles**

Add a local helper that creates table Players with `UserId`, `Character`, private attribute map, `SetAttribute` and `GetAttribute`; use it for the Human and Elf runtime-stat cases. Production `ProgressionRuntimeState.apply_runtime_stats` remains unchanged.

### Task 5: Full candidate verification and Studio gate

**Files:**
- Modify: `install_phase2cd_antikite_v6.ps1`
- Modify: package static regression/audit scripts

**Interfaces:**
- Installer creates/resumes only the clean v6 worktree at accepted baseline and applies the exact candidate payload/patch boundary.

- [ ] **Step 1: Update exact changed-file boundary**

Include WindStrike service/test, Captain controller, HotbarSkillDefinitionTest and CharacterCombatStatsTest plus all existing v5 Phase 2C.D files. Reject all unexpected files.

- [ ] **Step 2: Run package-side regressions fresh**

Expected: parser, Git-stderr, installer, migration, trainer, Mage bootstrap, Skills menu, Wand presentation, v5 repair contract and new v6 anti-kiting contract all exit 0.

- [ ] **Step 3: ZIP and test archive integrity**

Build `DungeonMMO_Phase2CD_MageFoundation_AntiKite_v6.zip` containing only the installer, spec, plan, payload and package QA scripts required for reproducibility. `zipfile.testzip()` must return `None`.

- [ ] **Step 4: Windows verification gate**

User runs the safe installer. Required evidence before any acceptance claim: exact Rojo version printed, Base TEMP build succeeds, Dungeon TEMP build succeeds, and the installer confirms no staging/commit/push/merge/publish.

- [ ] **Step 5: Project-owner Studio evidence**

Meaningful checks: Mage basic attacks visibly root the player; Wind Strike visibly charges, roots, damages, and can be cancelled by Block/Dodge without Mana/cooldown loss; Captain gradually gains on a continuously fleeing player; Ward/Heal still work; Fighter spot check has no obvious regression.
