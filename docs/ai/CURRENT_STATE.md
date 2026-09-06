# DungeonMMO Current Engineering State

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
