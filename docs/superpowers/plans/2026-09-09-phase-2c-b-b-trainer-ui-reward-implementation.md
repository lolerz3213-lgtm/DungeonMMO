# Phase 2C.B.B Trainer Catalogue, Equipment UI and Reward Summary Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the hard-coded progression trainer with server-authorized catalogues, add the functional six-slot Base equipment UI, and fix the deferred Arc Slash Skill Book completion-summary presentation.

**Architecture:** `TrainerCatalogues` is a pure shared definition/authorization layer; BaseProgressionController accepts a trainer ID for teach/rank operations; Base runtime supplies catalogue snapshots; the trainer client renders catalogue-provided skill IDs. A separate Base equipment client renders six slots and compatible owned gear from authoritative EquipmentSnapshot. The Dungeon completion UI reads the already-existing `completion.arc_slash_book` result and displays the book only when newly awarded.

**Tech Stack:** Roblox Luau, RemoteEvents, existing ProgressionClientState, Rojo, Studio embedded test scripts.

**Spec:** `docs/superpowers/specs/2026-09-09-phase-2c-b-equipment-trainer-architecture-design.md`

## Global Constraints

- Depends on Phase 2C.B.A equipment foundation in the same isolated worktree.
- Fighter trainer must work for both Human Fighter and Elf Fighter.
- Catalogue controls what trainer may offer; existing skill service still controls knowledge/SP/proficiency/book rules.
- No advanced classes or large skill catalogue.
- Equipment UI is functional, not final art.
- Do not replace accepted sword/shield combat visuals.
- Skill Book grant/persistence behaviour must not be rewritten for the summary fix.
- No PROD, Robux, monetisation, publish, merge, push or art-branch action.
- Tests before production code for every behavioural change.

---

## File Structure

### Create
- `src/ReplicatedStorage/Core/Shared/TrainerCatalogues.luau`
- `src/ServerScriptService/Core/Tests/TrainerCataloguesTest.server.luau`
- `src/StarterPlayerScripts/Base/EquipmentPanel.client.luau`
- `src/ReplicatedStorage/Core/Shared/CompletionRewardPresentation.luau`
- `src/ServerScriptService/Core/Tests/CompletionRewardPresentationTest.server.luau`

### Modify
- `src/ServerScriptService/Base/BaseProgressionController.luau`
- `src/ServerScriptService/Base/Tests/BaseProgressionControllerTest.server.luau`
- `src/ReplicatedStorage/Core/Remotes.model.json`
- `src/ServerScriptService/Base/BaseRuntime.server.luau`
- `src/ServerScriptService/Base/BaseBuilder.server.luau`
- `src/StarterPlayerScripts/Base/ProgressionTrainer.client.luau`
- `src/StarterPlayerScripts/Dungeon/DungeonUi.client.luau`
- continuity docs from 2C.B.A

---

### Task 1: Add TrainerCatalogues pure definition/eligibility

**Files:**
- Create: `src/ReplicatedStorage/Core/Shared/TrainerCatalogues.luau`
- Create: `src/ServerScriptService/Core/Tests/TrainerCataloguesTest.server.luau`

**Interfaces:**
- `TrainerCatalogues.get(trainer_id:string): any?`
- `TrainerCatalogues.resolve_for_character(trainer_id:string, character:any): any`
- `TrainerCatalogues.can_offer(trainer_id:string, character:any, skill_id:string): any`
- Fighter trainer ID: `FighterTrainer`
- Fighter skill order: `ShieldBash`, `Mend`, `ArcSlash`

Definition:
```luau
FighterTrainer = {
    Id = "FighterTrainer",
    DisplayName = "Fighter Trainer",
    AllowedBaseClasses = {"Fighter"},
    Skills = {
        {SkillId="ShieldBash", Mode="Rank"},
        {SkillId="Mend", Mode="Rank"},
        {SkillId="ArcSlash", Mode="LearnOrRank", SourceItemId="arc_slash_book_bound"},
    },
}
```

- [ ] **Step 1: Write RED catalogue test**

Assert:
- Human/Fighter resolves;
- Elf/Fighter resolves;
- incomplete identity rejected;
- wrong base class rejected;
- missing trainer rejected;
- Fighter trainer offers exactly three locked skills in order;
- arbitrary `FakeSkill` rejected;
- ArcSlash entry exposes bound book source item.

- [ ] **Step 2: Observe RED**

Expected missing module.

- [ ] **Step 3: Implement minimal catalogue**

Use CharacterIdentityRules complete state and whitelist helpers. Return sanitized clone/snapshot, not mutable canonical tables.

- [ ] **Step 4: Verify GREEN and `git diff --check`**

---

### Task 2: Replace hard-coded Base trainer authorization

**Files:**
- Modify: `src/ServerScriptService/Base/BaseProgressionController.luau`
- Modify: `src/ServerScriptService/Base/Tests/BaseProgressionControllerTest.server.luau`

**Interfaces:**
Change:
```luau
learn_skill(user_id, skill_id)
purchase_rank(user_id, skill_id)
```
to:
```luau
learn_skill(user_id, trainer_id, skill_id)
purchase_rank(user_id, trainer_id, skill_id)
```
or preserve backwards-compatible wrapper only inside tests if required. Production remote path must always provide trainer ID.

- [ ] **Step 1: Extend controller test RED**

Add:
- valid FighterTrainer + ArcSlash delegates to skill service with `arc_slash_book_bound`;
- valid FighterTrainer + Mend rank delegates to purchase;
- fake trainer rejected `UnknownTrainer`;
- skill outside catalogue rejected `SkillNotTeachableHere`;
- incomplete identity remains rejected;
- Base-only boundary remains unchanged.

- [ ] **Step 2: Observe RED against old signatures/hard-coded ArcSlash**

- [ ] **Step 3: Implement catalogue authorization**

Require `TrainerCatalogues`.
For learn:
1. Base-only;
2. identity complete;
3. `TrainerCatalogues.can_offer`;
4. require entry mode allowing learn;
5. require non-empty `SourceItemId`;
6. call existing `SkillProgressionService:learn_skill`.

For rank:
1. same gates;
2. offer must exist;
3. call existing `purchase_rank`.

- [ ] **Step 4: Verify GREEN**

Existing Base progression controller tests plus new assertions pass.

---

### Task 3: Add authoritative trainer snapshot remote

**Files:**
- Modify: `src/ReplicatedStorage/Core/Remotes.model.json`
- Modify: `src/ServerScriptService/Base/BaseRuntime.server.luau`

**Interfaces:**
Add:
- `TrainerSnapshot` RemoteEvent
- `TrainerSnapshotRequest` RemoteEvent

Request:
```luau
TrainerSnapshotRequest:FireServer("FighterTrainer")
```

Response:
```luau
{
    ok = true,
    TrainerId = "FighterTrainer",
    DisplayName = "Fighter Trainer",
    Skills = {...},
}
```
or:
```luau
{ok=false, reason="UnknownTrainer"|"TrainerRestricted"}
```

Skill learn/rank RemoteEvent payload changes to:
```luau
SkillLearnRequest:FireServer("FighterTrainer", skill_id)
SkillRankRequest:FireServer("FighterTrainer", skill_id)
```

- [ ] **Step 1: RED remote/controller transport assertions**

- [ ] **Step 2: Add remote definitions**

- [ ] **Step 3: Wire Base runtime**

Validate trainer ID and skill ID strings before controller call.
Send current progression after successful action.
Trainer snapshot request must resolve against current persistent character.

- [ ] **Step 4: Verify build/test GREEN**

---

### Task 4: Convert trainer UI to catalogue-driven rendering

**Files:**
- Modify: `src/StarterPlayerScripts/Base/ProgressionTrainer.client.luau`
- Modify: `src/ServerScriptService/Base/BaseBuilder.server.luau`

**Interfaces:**
- BaseBuilder sets trainer attribute `TrainerId = "FighterTrainer"`.
- Prompt name remains `ProgressionTrainerPrompt`.
- Client requests TrainerSnapshot when prompt opens.
- UI builds skill rows from `snapshot.Skills`.

- [ ] **Step 1: Add pure client-render helper if needed before production edit**

If dynamic row formatting cannot be reasonably tested in LocalScript, extract a pure shared helper `TrainerPresentationRules.luau` with a server test. The helper produces button text/enabled state from progression state + catalogue entry.

- [ ] **Step 2: Remove fixed `skill_ids` table**

No production client list may hard-code the three skills as the rendering source.

- [ ] **Step 3: Preserve existing attributes/respec UI**

Only the skill-column source changes. Attribute preview/respec stays functionally unchanged.

- [ ] **Step 4: Use trainer identity in requests**

Buttons send active `TrainerId` with learn/rank.

- [ ] **Step 5: Build Base**

No syntax/build errors.

---

### Task 5: Add functional six-slot EquipmentPanel

**Files:**
- Create: `src/StarterPlayerScripts/Base/EquipmentPanel.client.luau`
- Modify: `src/ServerScriptService/Base/BaseBuilder.server.luau`

**Interfaces:**
- Add Base part `EquipmentManager`
- Add prompt `EquipmentManagerPrompt`
- Prompt object text `Equipment`
- Client consumes `EquipmentSnapshot` and `EquipmentActionResult`

UI requirements:
- six fixed slot rows in canonical order;
- current item name or `Empty`;
- compatible owned items list;
- selection;
- Equip button;
- Unequip selected-slot button;
- status/reason text;
- close button.

- [ ] **Step 1: Create functional UI shell with panel initially hidden**

No equipment action occurs locally without remote response.

- [ ] **Step 2: Open on equipment prompt and request snapshot**

- [ ] **Step 3: Render six slots**

The client may use the canonical shared `EquipmentSlots.ORDER`.

- [ ] **Step 4: Render owned equipment**

Use server-provided `Owned`; filter by selected slot only for convenience. Do not infer authorization from client filtering.

- [ ] **Step 5: Wire Equip/Unequip requests**

Server remains authority; on action result show status and request new snapshot.

- [ ] **Step 6: Build Base**

The UI itself is reserved for the later user visual checkpoint.

---

### Task 6: Fix completion Skill Book summary presentation with a pure helper

**Files:**
- Create: `src/ReplicatedStorage/Core/Shared/CompletionRewardPresentation.luau`
- Create: `src/ServerScriptService/Core/Tests/CompletionRewardPresentationTest.server.luau`
- Modify: `src/StarterPlayerScripts/Dungeon/DungeonUi.client.luau`

**Interfaces:**
- `CompletionRewardPresentation.lines(completion:any): {string}`
- `CompletionRewardPresentation.text(completion:any): string`

Rules:
- always show completion gold;
- show personal loot `completion.item_id` or Nothing;
- if `completion.arc_slash_book.ok == true` and `already_applied ~= true`, add `Arc Slash Skill Book`;
- if already applied, do not falsely claim a newly awarded book.

- [ ] **Step 1: Write RED presentation test**

Cover new book, already-applied book, no book and nil completion.

- [ ] **Step 2: Observe RED**

- [ ] **Step 3: Implement pure helper**

Do not change CompletionService or SkillProgressionService grant logic.

- [ ] **Step 4: Replace DungeonUi inline two-line string with helper**

- [ ] **Step 5: Verify GREEN**

---

### Task 7: Full local-green build/regression preparation

**Files:** no new production files unless a test exposes a defect.

- [ ] **Step 1: Run `git diff --check`**

- [ ] **Step 2: Build Base and Dungeon to timestamped TEMP**

```powershell
rojo build base.project.json -o "$env:TEMP\DungeonMMO_Phase2CB_Base_<timestamp>.rbxl"
rojo build default.project.json -o "$env:TEMP\DungeonMMO_Phase2CB_Dungeon_<timestamp>.rbxl"
```

- [ ] **Step 3: Verify exact changed-file boundary**

Must include only approved 2C.B source/tests/docs plus no `DungeonMMO.rbxl` modification.

- [ ] **Step 4: Update continuity docs to `IMPLEMENTATION CANDIDATE - AWAITING STUDIO GREEN`**

Record all new test families as pending until actual Studio output is observed. Do not claim PASS from build success alone.

- [ ] **Step 5: Stop for first user visual/runtime check**

This is the planned user interruption:
- open generated Base candidate in Studio;
- verify automated test output;
- visually inspect six-slot Equipment panel;
- equip/unequip representative items;
- inspect catalogue-driven Fighter trainer;
- check Human and Elf Fighter;
- report red runtime errors if any.

Dungeon visual check follows only after Base is green, primarily to verify preserved combat and completion reward summary.
