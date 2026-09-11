# Phase 2C.E Ranger Marksman-Hunter Foundation Implementation Plan

> Use the existing DungeonMMO test-first and non-destructive worktree workflow. Runtime RED/GREEN that requires Roblox Studio must remain explicitly unclaimed until observed.

**Goal:** Add a Human/Elf Ranger vertical slice with Longbow held basics, Piercing Shot, Crippling Shot, Volley and generic two-handed slot reservation while preserving accepted Fighter/Mage behaviour.

**Architecture:** Extend existing data-driven class/progression/equipment contracts. Keep draw classification pure, server-own draw duration and projectile delivery, add generic equipment reservation, and make enemy slows explicit modifiers consumed by manual AI movement controllers.

**Baseline:** `86d27228977dd6c98bd404f12086e93ad94fbe9a`

**Branch/worktree:** `wip/phase-2c-e-ranger-foundation-v1` / `C:\Users\Remko\Documents\Roblox\DungeonMMO_Phase2CE_Ranger_v1`

## Task 1 - RED Ranger data and draw contracts

- Add focused tests for Ranger class/starter equipment/skills.
- Add pure `RangerDrawRules` tests for Normal/Precision/Full thresholds and bonuses.
- Add reservation tests for Longbow/OffHand rejection and malformed-state fail-neutral behaviour.
- Keep tests in the candidate even where Studio runtime execution is still pending.

## Task 2 - Ranger identity, items, trainer and persistence

- Add Ranger to `ClassProgressionDefinitions` for Human/Elf.
- Add `apprentice_longbow` with `Longbow` tag and `ReservedSlots={"OffHand"}`.
- Add Piercing Shot, Crippling Shot and Volley progression/skill definitions.
- Add Ranger trainer catalogue.
- Reuse generic IdentityService starter grant path and schema v5.

## Task 3 - Generic slot reservation

- Add `EquipmentReservationRules`.
- Validate cross-slot reservations both before and inside mutation.
- Add `Reservations` to snapshot UI data.
- Reject rather than silently unequip.
- Make `EquipmentStatResolver` ignore an occupied slot reserved by a valid equipped item.

## Task 4 - Dexterity ranged scaling and held basic attack

- Add ranged physical multiplier to AttributeConfig/ProgressionRuntimeState.
- Add `RangerDrawService` and `RangerDrawRules`.
- Change attack input to Begin/End semantics while non-Longbow weapons retain immediate click attacks.
- Server measures elapsed draw and fires a real swept Longbow projectile.
- Apply 0.60 movement while drawing and restore immediately on release/cancel.
- Keep 0.45/0.80 thresholds race-neutral; racial attack-rate only scales release/recovery.

## Task 5 - Ranger projectile skills

- `RangerProjectileService` handles first-hit and piercing physical projectiles.
- Piercing Shot uses max four targets and race-specific retention.
- Crippling Shot applies race-specific server-owned slow through `RangerSlowService`.
- Award existing damage/control progression through DungeonProgressionBridge.

## Task 6 - Volley

- Client sends centre-aim ground intent only for Volley.
- Server validates a finite Vector3, clamps range, raycasts to ground and owns pulse area queries.
- Apply initial 14 plus three 7-damage pulses at 0.5 s.
- No critical hits in this gate.

## Task 7 - Enemy slow integration

- Extend normal Marauder movement calculation with optional speed multiplier defaulting to 1.
- Read RangerSlowService multiplier in TrainingMarauderController.
- Apply the same multiplier to Captain manual chase speed.
- Do not change accepted base chase tuning.

## Task 8 - Functional presentation/UI

- Add simple PrototypeLongbow factory/presentation.
- Add Ranger draw-state indicator.
- Add Ranger to identity selection, Skills menu and trainer world object.
- Equipment panel renders OffHand reservation.
- Add Ranger standalone Dungeon Studio bootstrap.

## Task 9 - Verification gate

- Installer refuses any baseline mismatch or dirty/resumed worktree mismatch.
- Exact expected changed-file boundary only.
- `git diff --check` must pass.
- Build Base and Dungeon to timestamped TEMP `.rbxl` files.
- No add/commit/push/merge/publish.
- Stop for project-owner Studio gameplay/visual evidence.
