# Phase 2C.B.A Equipment Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add schema-v5 persistent six-slot equipment with server-authoritative Base-only equip/unequip and migration-safe snapshots.

**Architecture:** Equipment remains item-ID based for this vertical slice. Shared equipment metadata lives in `ItemDefinitions`; `EquipmentSlots` owns the canonical six-slot contract; `EquipmentRules` performs pure identity/item eligibility checks; `EquipmentService` performs authoritative profile mutation. The Dungeon reads persisted equipment but cannot mutate it.

**Tech Stack:** Roblox Luau, Rojo, existing ProfileService/InMemoryProfileAdapter, RemoteEvents, Windows PowerShell 5.1 for local orchestration.

**Spec:** `docs/superpowers/specs/2026-09-09-phase-2c-b-equipment-trainer-architecture-design.md`

## Global Constraints

- Start only from `19f8c31284da80dc87cf5d44560d366e48427888`.
- Do not develop directly on `main`.
- Slots are exactly `Weapon`, `OffHand`, `Helmet`, `Body`, `Gloves`, `Boots`.
- Equipment mutation is Base-only.
- Server owns all equip/unequip authorization.
- No level/attribute requirements in Phase 2C.B.
- Do not consume inventory quantity when equipping.
- Do not change accepted combat sword/shield visual behaviour in this gate.
- No PROD, Robux, monetisation, publish or art-branch actions.
- Validation builds go to timestamped TEMP files.
- Tests are written and observed RED before production implementation.
- No automatic staging, commit, push or merge from patch/install scripts.

---

## File Structure

### Create
- `src/ReplicatedStorage/Core/Shared/EquipmentSlots.luau` — canonical six-slot order/validation.
- `src/ReplicatedStorage/Core/Shared/EquipmentRules.luau` — pure item/identity eligibility.
- `src/ServerScriptService/Core/Services/EquipmentService.luau` — authoritative persistent equip/unequip.
- `src/ServerScriptService/Core/Tests/EquipmentSlotsTest.server.luau`
- `src/ServerScriptService/Core/Tests/EquipmentRulesTest.server.luau`
- `src/ServerScriptService/Core/Tests/EquipmentServiceTest.server.luau`
- `src/ServerScriptService/Core/Tests/Phase2CBEquipmentMigrationTest.server.luau`

### Modify
- `src/ReplicatedStorage/Core/Shared/ItemDefinitions.luau`
- `src/ReplicatedStorage/Core/Shared/ProfileSchema.luau`
- `src/ServerScriptService/Core/Services/ProfileMigration.luau`
- `src/ServerScriptService/Core/Services/RuntimeServices.luau`
- `src/ReplicatedStorage/Core/Remotes.model.json`
- `src/ServerScriptService/Base/BaseRuntime.server.luau`
- `src/ServerScriptService/Dungeon/DungeonRuntime.server.luau`

---

### Task 1: Lock the six-slot/item-definition contract

**Files:**
- Create: `src/ReplicatedStorage/Core/Shared/EquipmentSlots.luau`
- Create: `src/ServerScriptService/Core/Tests/EquipmentSlotsTest.server.luau`
- Modify: `src/ReplicatedStorage/Core/Shared/ItemDefinitions.luau`

**Interfaces:**
- Produces: `EquipmentSlots.ORDER: {string}`
- Produces: `EquipmentSlots.is_valid(slot:any): boolean`
- Produces: `EquipmentSlots.empty(): {[string]: string?}`
- Existing: `ItemDefinitions.get(item_id:string): any?`
- Existing: `ItemDefinitions.all(): any`

- [ ] **Step 1: Write RED slot-contract test**

Test must require `EquipmentSlots` and assert exact ordered contents:
`Weapon`, `OffHand`, `Helmet`, `Body`, `Gloves`, `Boots`; reject `Ring`, empty string and nil; `empty()` exposes all six keys as nil/absent values without unexpected slot names.

- [ ] **Step 2: Build Base and verify RED**

Run:
```powershell
rojo build base.project.json -o "$env:TEMP\DungeonMMO_2CB_RED_slots_Base.rbxl"
```

Open the RED build in Studio once for the RED cycle. Expected output includes:
`[Equipment Slots Tests] RED: EquipmentSlots is missing.`
Do not implement production code until the failure is observed.

- [ ] **Step 3: Implement minimal slot module**

Create `EquipmentSlots.luau` with:
```luau
--!strict
local ORDER = table.freeze({
    "Weapon",
    "OffHand",
    "Helmet",
    "Body",
    "Gloves",
    "Boots",
})

local VALID = {}
for _, slot in ipairs(ORDER) do
    VALID[slot] = true
end

local EquipmentSlots = {
    ORDER = ORDER,
}

function EquipmentSlots.is_valid(slot: any): boolean
    return type(slot) == "string" and VALID[slot] == true
end

function EquipmentSlots.empty(): any
    return {
        Weapon = nil,
        OffHand = nil,
        Helmet = nil,
        Body = nil,
        Gloves = nil,
        Boots = nil,
    }
end

return table.freeze(EquipmentSlots)
```

- [ ] **Step 4: Extend item definitions minimally**

Keep all existing IDs unchanged. Add:
```luau
marauder_sword = {
    Id="marauder_sword", Name="Marauder Sword",
    Kind="Equipment", Slot="Weapon", Category="Sword",
    AllowedBaseClasses={"Fighter"}, Rarity="Basic", Stackable=false,
}
marauder_shield = {
    Id="marauder_shield", Name="Marauder Shield",
    Kind="Equipment", Slot="OffHand", Category="Shield",
    AllowedBaseClasses={"Fighter"}, Rarity="Basic", Stackable=false,
}
marauder_armor = {
    Id="marauder_armor", Name="Marauder Armour",
    Kind="Equipment", Slot="Body", Category="HeavyArmor",
    AllowedBaseClasses={"Fighter"}, Rarity="Basic", Stackable=false,
}
marauder_helmet = {
    Id="marauder_helmet", Name="Marauder Helmet",
    Kind="Equipment", Slot="Helmet", Category="HeavyArmor",
    AllowedBaseClasses={"Fighter"}, Rarity="Basic", Stackable=false,
}
marauder_gloves = {
    Id="marauder_gloves", Name="Marauder Gloves",
    Kind="Equipment", Slot="Gloves", Category="HeavyArmor",
    AllowedBaseClasses={"Fighter"}, Rarity="Basic", Stackable=false,
}
marauder_boots = {
    Id="marauder_boots", Name="Marauder Boots",
    Kind="Equipment", Slot="Boots", Category="HeavyArmor",
    AllowedBaseClasses={"Fighter"}, Rarity="Basic", Stackable=false,
}
test_elf_helmet = {
    Id="test_elf_helmet", Name="TEST Elven Helmet",
    Kind="Equipment", Slot="Helmet", Category="LightArmor",
    AllowedRaces={"Elf"}, AllowedBaseClasses={"Fighter"},
    Rarity="Basic", Stackable=false, TestOnly=true,
}
```
Retain `captain_emblem`, `skill_book_test`, and `arc_slash_book_bound` exactly in behaviour.

- [ ] **Step 5: Rebuild Base and verify GREEN**

Expected Studio output:
`[Equipment Slots Tests] PASS`
Existing inventory/core tests must remain green.

- [ ] **Step 6: Run `git diff --check`**

Expected: no output/error.

---

### Task 2: Add pure equipment eligibility rules

**Files:**
- Create: `src/ReplicatedStorage/Core/Shared/EquipmentRules.luau`
- Create: `src/ServerScriptService/Core/Tests/EquipmentRulesTest.server.luau`

**Interfaces:**
- Consumes: `EquipmentSlots.is_valid`
- Consumes: item definitions with `Kind`, `Slot`, `AllowedRaces`, `AllowedBaseClasses`, `AllowedClasses`
- Produces: `EquipmentRules.validate(character:any, item:any, requested_slot:any): any`
- Result shape: `{ok:boolean, reason:string?}`

- [ ] **Step 1: Write RED rules test**

Cover:
- complete Human/Fighter + Marauder Sword/Weapon => ok;
- complete Elf/Fighter + same => ok;
- wrong requested slot => `WrongSlot`;
- invalid slot => `UnknownEquipmentSlot`;
- Skill Book => `NotEquipment`;
- incomplete identity => `IdentityIncomplete`;
- Human + `test_elf_helmet` => `RaceRestricted`;
- Elf + `test_elf_helmet` => ok;
- incompatible base class table => `ClassRestricted`.

- [ ] **Step 2: Observe RED**

Expected missing module failure:
`[Equipment Rules Tests] RED: EquipmentRules is missing.`

- [ ] **Step 3: Implement minimal pure validator**

Algorithm order is locked:
1. validate requested slot;
2. validate character/complete identity;
3. validate item table and `Kind == "Equipment"`;
4. validate item slot;
5. validate race whitelist when present;
6. validate base-class/class whitelist when present;
7. return `{ok=true}`.

Use membership helper that treats missing restriction arrays as unrestricted.

- [ ] **Step 4: Verify GREEN**

Expected:
`[Equipment Rules Tests] PASS`

- [ ] **Step 5: Run `git diff --check`**

---

### Task 3: Advance profile schema to v5 and migrate equipment

**Files:**
- Modify: `src/ReplicatedStorage/Core/Shared/ProfileSchema.luau`
- Modify: `src/ServerScriptService/Core/Services/ProfileMigration.luau`
- Create: `src/ServerScriptService/Core/Tests/Phase2CBEquipmentMigrationTest.server.luau`
- Modify only if an existing assertion explicitly hard-codes v4: `src/ServerScriptService/Core/Tests/ProfileSchemaMigrationTest.server.luau`
- Modify only if needed for preserved-v4 semantics: `src/ServerScriptService/Core/Tests/Phase2CAProfileMigrationTest.server.luau`

**Interfaces:**
- `ProfileSchema.VERSION = 5`
- Character adds `Equipment`
- Migration normalizes each equipment slot to `string?`

- [ ] **Step 1: Write RED migration test**

Construct a real schema-v4 complete Human/Fighter profile with:
- level/xp/gold;
- inventory containing sword/book;
- attributes;
- AP/SP entitlement;
- skills/loadout/proficiency;
- respec counters;
- one-time reward;
- no Equipment table.

Assert after migration:
- schema = 5;
- all six equipment slots are empty;
- all listed v4 state is unchanged;
- repeated migration deep-equals the once-migrated equipment/state.

Also test malformed Equipment:
```luau
Equipment = {
    Weapon = 123,
    OffHand = "marauder_shield",
    Helmet = false,
    Body = "missing_item",
    Gloves = {},
    Boots = "marauder_boots",
}
```
Normalize invalid type/unknown/wrong-slot IDs to nil; preserve valid correctly slotted equipment IDs.

- [ ] **Step 2: Observe RED**

Expected schema/version/equipment assertions fail before production change.

- [ ] **Step 3: Implement v5 default**

In `ProfileSchema.create_default`, add:
```luau
Equipment = {
    Weapon = nil,
    OffHand = nil,
    Helmet = nil,
    Body = nil,
    Gloves = nil,
    Boots = nil,
},
```

- [ ] **Step 4: Implement migration sanitizer and preserve the Phase 2C.A v4 identity boundary**

Require `EquipmentSlots` and `ItemDefinitions`.

**Critical migration correction:** after bumping `ProfileSchema.VERSION` to 5, do **not** keep the old expression that treats every `raw_version < ProfileSchema.VERSION` as a legacy Phase 2B source. That would incorrectly classify accepted schema-v4 Phase 2C.A Human/Elf profiles as legacy. Lock the semantics to:

```luau
local legacy_source = (
    raw_is_table
    and (
        type(raw_version) ~= "number"
        or raw_version < 4
    )
)

local phase2ca_or_newer_source = (
    raw_is_table
    and type(raw_version) == "number"
    and raw_version >= 4
)
```

Use the existing v4 identity sanitizer for schema-v4 and schema-v5 identity data. Only pre-v4 profiles enter the one-time legacy Phase 2B race-selection migration path.

After Inventory normalization and before return, rebuild `slot1.Equipment` from six canonical slots. Preserve a value only when:
- it is a string;
- definition exists;
- definition `Kind == "Equipment"`;
- definition `Slot == slot`.

Do not infer/equip anything from inventory.

- [ ] **Step 5: Verify GREEN and regressions**

Expected new migration PASS plus existing:
- Profile Schema/Migration
- Phase 2C.A Profile Migration
- Identity Service
remain green.

- [ ] **Step 6: Run `git diff --check`**

---

### Task 4: Add server-authoritative EquipmentService

**Files:**
- Create: `src/ServerScriptService/Core/Services/EquipmentService.luau`
- Create: `src/ServerScriptService/Core/Tests/EquipmentServiceTest.server.luau`

**Interfaces:**
- Constructor: `EquipmentService.new(profile_service:any, context:string?): any`
- `:build_snapshot(user_id:number): any`
- `:equip(user_id:number, item_id:string, slot:string): any`
- `:unequip(user_id:number, slot:string): any`
- Snapshot:
```luau
{
    Slots = {
        Weapon = string?,
        OffHand = string?,
        Helmet = string?,
        Body = string?,
        Gloves = string?,
        Boots = string?,
    },
    Owned = {
        {ItemId=string, Quantity=number, Slot=string, Category=string?, Name=string}
    },
}
```

- [ ] **Step 1: Write RED service test**

Use actual `InMemoryProfileAdapter` + `ProfileService`.
Complete identity by mutating the profile to Human/Fighter.
Add representative items through InventoryService.

Assert:
- owned sword equips Weapon;
- equipment persists after save/release/reload;
- inventory sword count remains unchanged;
- re-equipping same sword succeeds idempotently;
- wrong slot rejected;
- unowned item rejected;
- skill book rejected;
- race restriction rejected/accepted;
- incomplete identity rejected;
- unknown slot rejected;
- unequip clears only target slot;
- service constructed with `"Dungeon"` rejects equip/unequip as `BaseOnlyAction`.

- [ ] **Step 2: Observe RED**

Expected missing `EquipmentService`.

- [ ] **Step 3: Implement inventory ownership helper**

Count inventory using existing `InventoryService.count_item(character,item_id)`; do not remove items.

- [ ] **Step 4: Implement equip mutation**

Before mutate, validate basic request types. Inside `ProfileService:mutate`, resolve selected character, run `EquipmentRules.validate`, confirm ownership, then assign `character.Equipment[slot] = item_id`.

Return:
```luau
{ok=true, slot=slot, item_id=item_id}
```

- [ ] **Step 5: Implement unequip and snapshot**

Unequip must be Base-only and canonical-slot-only.
Snapshot must expose only canonical equipment entries and Equipment-kind inventory items.

- [ ] **Step 6: Verify GREEN**

Expected:
`[Equipment Service Tests] PASS`

- [ ] **Step 7: Run full relevant Core regression and `git diff --check`**

---

### Task 5: Compose EquipmentService in runtime

**Files:**
- Modify: `src/ServerScriptService/Core/Services/RuntimeServices.luau`

**Interfaces:**
- New return member: `EquipmentService`

- [ ] **Step 1: Extend EquipmentService test with RuntimeServices contract RED assertion**

The test should require RuntimeServices only where safe in Studio and assert `runtime.EquipmentService` exists for Base and Dungeon composition.

- [ ] **Step 2: Observe RED**

- [ ] **Step 3: Require and instantiate**

Add:
```luau
local EquipmentService = require(Services:WaitForChild("EquipmentService"))
...
local equipment = EquipmentService.new(profiles, place_kind)
...
EquipmentService = equipment,
```

- [ ] **Step 4: Verify GREEN**

- [ ] **Step 5: `git diff --check`**

---

### Task 6: Add equipment remote contract and Base wiring

**Files:**
- Modify: `src/ReplicatedStorage/Core/Remotes.model.json`
- Modify: `src/ServerScriptService/Base/BaseRuntime.server.luau`
- Create: `src/ServerScriptService/Base/Tests/BaseEquipmentControllerTest.server.luau` only if a separate controller is introduced; otherwise service test + runtime contract test remains sufficient.

**Interfaces:**
Add RemoteEvents:
- `EquipmentSnapshot`
- `EquipmentEquipRequest`
- `EquipmentUnequipRequest`
- `EquipmentActionResult`

Payloads:
```luau
EquipmentEquipRequest:FireServer(item_id, slot)
EquipmentUnequipRequest:FireServer(slot)
EquipmentSnapshot:FireClient(player, snapshot)
EquipmentActionResult:FireClient(player, {
    action = "Equip" | "Unequip",
    ok = boolean,
    reason = string?,
    slot = string?,
    item_id = string?,
})
```

- [ ] **Step 1: Add RED remote contract assertion**

Extend Core config/remote contract test to look for all four events in built hierarchy or add a dedicated `EquipmentRemoteContractTest.server.luau`.

- [ ] **Step 2: Observe RED**

- [ ] **Step 3: Add remotes**

Append exactly the four RemoteEvents.

- [ ] **Step 4: Wire Base runtime**

Resolve `runtime.EquipmentService`.
Add `send_equipment(player)` and call it from `send_profile`.
Allow `EquipmentSnapshot` `"Request"` only for loaded users.
Equip handler requires string item/slot; invalid payload returns `InvalidEquipmentRequest`.
Unequip handler requires string slot.
After successful mutation, resend equipment + inventory/profile snapshot.

- [ ] **Step 5: Verify GREEN**

- [ ] **Step 6: Base build + `git diff --check`**

---

### Task 7: Enforce read-only Dungeon equipment state

**Files:**
- Modify: `src/ServerScriptService/Dungeon/DungeonRuntime.server.luau`

**Interfaces:**
- Dungeon may emit `EquipmentSnapshot`
- Dungeon does not connect equip/unequip request handlers
- EquipmentService constructed in Dungeon context still rejects mutations if invoked internally

- [ ] **Step 1: Add RED service assertion for Dungeon mutation rejection**
Already covered in Task 4; confirm it is present before runtime edit.

- [ ] **Step 2: Wire snapshot-only Dungeon path**

Resolve `EquipmentSnapshot`.
Resolve runtime `EquipmentService`.
Include `equipment_snapshot:FireClient(player, equipment:build_snapshot(player.UserId))` in `send_profile`.

Do not connect `EquipmentEquipRequest` or `EquipmentUnequipRequest`.

- [ ] **Step 3: Verify Base and Dungeon builds**

```powershell
rojo build base.project.json -o "$env:TEMP\DungeonMMO_2CBA_Base.rbxl"
rojo build default.project.json -o "$env:TEMP\DungeonMMO_2CBA_Dungeon.rbxl"
```

- [ ] **Step 4: `git diff --check`**

---

### Task 8: Phase 2C.B.A continuity checkpoint

**Files:**
- Modify: `AGENTS.md`
- Modify: `docs/ai/CURRENT_STATE.md`
- Modify: `docs/ai/HANDOFF.md`
- Modify: `docs/ai/TEST_MATRIX.md`
- Add approved spec: `docs/superpowers/specs/2026-09-09-phase-2c-b-equipment-trainer-architecture-design.md`
- Add both 2C.B implementation plans under `docs/superpowers/plans/`

**Interfaces:** Documentation only; no staging/commit/push from installer.

- [ ] **Step 1: Update stale accepted baseline**

Record:
- 2C.A ACCEPTED / MERGED / PUSHED;
- formal acceptance `ad3685be...`;
- canonical main/origin `19f8c312...`;
- 2C.B active;
- live migration waiver scope;
- Skill Book summary patch carried forward;
- art branch isolated.

- [ ] **Step 2: Record 2C.B.A implementation state**

Mark equipment foundation as implementation candidate, not accepted, until Studio evidence is observed.

- [ ] **Step 3: Run exact continuity grep checks and `git diff --check`**

Reject stale active statements that say 2C.A is unmerged or awaiting acceptance.

- [ ] **Step 4: Review exact diff**

Do not stage/commit automatically.
