# DungeonMMO Current Engineering State

## Active art branch reconciliation — 6 September 2026

- Current branch: `art/dungeon-environment-prototype`.
- Current HEAD: `ebf9740 fix: refresh progression HUD after authoritative mutations`.
- User confirms this branch was deliberately created from the last verified gameplay checkpoint for independent environment-art prototyping.
- Phase 1, Phase 2A and Gate 2B.A remain ACCEPTED. Gate 2B.B remains INSTALLED / NOT ACCEPTED; Gate 2B.C has not started. No gameplay acceptance evidence is changed by this reconciliation.
- Later gameplay/loadout WIP is not present on this branch and must not be merged into it. Art work must not modify gameplay systems.
- Earlier branch names, uncommitted-fix descriptions and next gameplay actions below are historical records from before this art branch, not the active working-tree state or instructions for this branch.
- Active next action: analyse all 12 art references, establish incremental reference cache and reusable Blender library, build and visually iterate TemplateCombatChamber_A, then validate in a disposable local Studio place. No commit, push or publish.

## Historical gameplay continuity (retained without changing acceptance)

**State date:** 6 September 2026
**Canonical roadmap:** Version 1.21
**Current phase:** Phase 2 - Vertical Slice
**Current gate:** Phase 2B.B - Gameplay + Base Progression
**Gate status:** INSTALLED / NOT ACCEPTED

## Accepted baseline

- Phase 1 combat: ACCEPTED.
- Phase 2A core Base-to-Dungeon slice: ACCEPTED.
- Phase 2B.A Progression Foundation: ACCEPTED.
- Accepted `main` checkpoint:
  `24dee751b87d831abe22cd046dd3b9934c566a56`.

## Current WIP checkpoint

- Branch: `wip/phase-2b-b-pre-ai-continuity`
- Repository HEAD before the uncommitted formatting fix: `8ca139d`
  (`chore: add AI development continuity layer`).
- WIP commit: `c5e2a59`
- Commit purpose:
  `wip: preserve Phase 2B.B before AI continuity setup`
- This WIP checkpoint is a recovery point only. It does NOT mean Gate 2B.B is
  accepted.

## Experience composition

- Local project:
  `C:\Users\Remko\Documents\Roblox\DungeonMMO`
- `default.project.json` = Test Dungeon.
- `base.project.json` = Starting Base.
- Universe ID: `10765241947`.
- Starting Base Place ID: `134132328219009`.
- Test Dungeon Place ID: `117293035754309`.
- Published environment: TEST.
- Live paid revives: disabled.

## Working Gate 2B.B content

Gate 2B.B adds:

- Arc Slash as a real rank-aware physical skill;
- six active skill slots;
- Character -> Skills loadout management;
- generic Base Progression Trainer;
- Attribute/SP/rank/respec interaction;
- Captain first-clear bound Arc Slash Skill Book;
- DEV/TEST progression command bridge;
- first-death automatic three-second free revive.

## Confirmed temporary test route

The current validation build reports LegacyChatService. Do not spend time
trying to make `/level` or `/prof` TextChatCommand routes work for this gate.

Use the DEV/TEST Client Command Bar bridge while Play is running.

Level 10:

```lua
game:GetService("ReplicatedStorage").Core.Remotes.ProgressionDebugRequest:FireServer(
    "level",
    10
)
```

Shield Bash proficiency Rank 2 threshold:

```lua
game:GetService("ReplicatedStorage").Core.Remotes.ProgressionDebugRequest:FireServer(
    "prof",
    "ShieldBash",
    150
)
```

Mend proficiency Rank 2 threshold:

```lua
game:GetService("ReplicatedStorage").Core.Remotes.ProgressionDebugRequest:FireServer(
    "prof",
    "Mend",
    100
)
```

## Open defects

### Controlled formatting fix checkpoint

The prior Base Studio smoke test failed ProgressionHudRulesTest with
"level cap must show XP MAX without formatting nil." Source inspection confirmed
an extra `xp` argument in the XP MAX branch shifted Gold/AP/SP values. The
uncommitted fix removes only that argument; the existing test is unchanged.
Both Rojo projects build successfully. Fresh Studio runtime verification is
pending manual opening of the new Base build:
`C:\Users\Remko\AppData\Local\Temp\DungeonMMO_ProgressionHudFix_20260906_122919\Base.rbxl`.
The older open build is not evidence for the fix. Studio was confirmed in Edit.
Gate 2B.B remains NOT ACCEPTED. After verifying this fix, the next major target
remains the stale Profile HUD, followed by six-slot gap placement.

### 1. Profile HUD refresh

After the Level 10 DEV/TEST mutation, the generic Progression Trainer shows
Level 10 and AP/SP entitlement 9/9, but the normal top-left Profile HUD remains
at Level 1 until the trainer is opened.

Required behaviour: the Profile HUD refreshes immediately from authoritative
progression state. Opening the trainer must not be the refresh mechanism.

### 2. Six-slot gap placement

Reproduction:

- Slot 1 occupied.
- Slot 2 intentionally empty.
- Select a learned skill.
- Click target Slot 3.

Current result: the selected skill is not reliably placed into Slot 3.

Required temporary UX:

- click a learned skill to select it;
- click any target Slot 1-6;
- move the selected skill from any previous slot;
- replace/remove the destination occupant;
- never duplicate the selected skill;
- preserve intentional empty slots;
- do nothing when a slot is clicked without a selected skill;
- clear selection after successful placement;
- refresh immediately.

## Exact next engineering actions

1. Keep the WIP branch/checkpoint recoverable.
2. Reproduce and diagnose the Profile HUD refresh path:
   server progression mutation -> client snapshot/event -> ProfileHud.
3. Fix the authoritative refresh boundary.
4. Re-run the Base HUD/trainer agreement check.
5. Reproduce the exact loadout gap case.
6. Diagnose slot data/serialization without compacting empty slots.
7. Fix exact-target-slot placement.
8. Run the full Base portion of Gate 2B.B.
9. Only when Base is clean, run the Dungeon portion of Gate 2B.B.
10. Mark 2B.B accepted only when the complete gate passes.
11. Update the roadmap and create a new accepted Git checkpoint.
12. Begin Gate 2B.C only after step 11.

## Profile HUD stale-state fix checkpoint (6 September 2026)

- Branch: `wip/phase-2b-b-pre-ai-continuity`; HEAD: `8ca139d`.
  All changes remain uncommitted; Gate 2B.B remains NOT ACCEPTED.
- Preserved all pre-existing changes: four docs/ai files and the XP MAX
  formatting fix in ProgressionHudRules.luau.
- Reproduced in connected DungeonMMO_AI_Continuity_Base.rbxl before editing:
  DEV level command reported Level 10 and AP/SP 9/9 on the server while
  ProfileHud.Summary and the captured viewport still displayed Level 1/AP 0/SP 0.
- Root cause: ProgressionService:set_level_for_test mutates the profile and
  ProgressionRuntimeState but never notifies the Place snapshot publisher.
  Trainer opening requests ProgressionSnapshot, masking the missing push.
  ProfileHud already applies received snapshots to ProgressionClientState and
  renders the authoritative Level/XP/Gold/AP/SP payload correctly.
- Added a per-service change callback after successful level/XP mutations.
  BaseRuntime and DungeonRuntime connect it to their existing send_progression
  publisher for the affected loaded player. No client polling or Trainer change.
- Source files changed: Core/Services/ProgressionService.luau,
  Base/BaseRuntime.server.luau, Dungeon/DungeonRuntime.server.luau, and
  Core/Tests/Phase2BProgressionServiceTest.server.luau under ServerScriptService.
  Regression assertions cover post-mutation notification, rejection without
  notification, and XP notification. New assertions have NOT run in Studio yet.
- Fresh Base and Dungeon Rojo builds succeeded in
  `C:\Users\Remko\AppData\Local\Temp\DungeonMMO_ProfileHud_20260906_125733`.
- Fresh runtime verification is PENDING. Launching the fresh Base file did not
  expose it through MCP. Computer-use input was rejected by automatic approval
  review: "Computer Use was not approved to use Roblox Studio". MCP provides no
  local-file opening command. No fresh-build visual PASS is claimed.
- Pre-fix Output contained the known ProgressionHudRulesTest XP MAX error;
  the other reported Base test families passed. Fresh-build red errors unknown.
- Play was stopped through MCP. No commit, push, publish, DataStore or
  monetisation changes were performed. Source git diff --check passed.
- Exact next action: open the fresh Base.rbxl from the directory above and
  connect it to Studio MCP; verify loaded source, start Play, fire DEV level 10,
  verify Profile HUD Level 10/AP 9/SP 9 immediately with Trainer closed, inspect
  Output and regression results, stop Play, and update this evidence.
  Six-slot gap placement remains untouched; full gate acceptance remains pending.
