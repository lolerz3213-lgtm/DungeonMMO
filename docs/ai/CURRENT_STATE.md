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

## Current verified checkpoint

- Branch: `wip/phase-2b-b-pre-ai-continuity`.
- HEAD: `ebf9740` (`fix: refresh progression HUD after authoritative mutations`).
- Committed and pushed; repository clean at the start of this task (Git verified).
- HUD defect: FIXED AND VERIFIED in a fresh Base build, visually confirmed in
  Studio by the user. Level 10 immediate update PASS; ProgressionHudRulesTest
  PASS; no red Studio errors; Base and Dungeon builds PASS; diff check PASS.
- Gate 2B.B remains NOT ACCEPTED. Gate 2B.C has not started.

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

### Six-slot gap placement

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

## Exact next engineering action

Reproduce six-slot gap placement in Studio, trace the authoritative ownership
boundary, add regression coverage, apply the smallest fix, and validate all six
slots, moves, replacement, uniqueness, gaps and invalid requests. Build both
Places and visually verify a fresh Base build and Output. Keep changes uncommitted.
Do not publish, accept Gate 2B.B, or start Gate 2B.C.

## Six-slot gap placement WIP (6 September 2026)

- Branch `wip/phase-2b-b-pre-ai-continuity`; HEAD remains `ebf9740`.
  Task started clean. Reconciliation and loadout changes are uncommitted.
- Pre-fix Studio reproduction PASS: Skills -> Mend -> Slot 3 reported success,
  but Slot 3 displayed empty while Slot 2 was empty. A temporary server probe
  confirmed authoritative Slot 1 ShieldBash / Slot 3 Mend; a real client snapshot
  listener received only Slot 1. Sparse numeric RemoteEvent arrays lost the tail.
- Regression RED before fix: Base snapshot's empty Slot 2 was nil instead of an
  explicit wire entry, despite authoritative Mend at Slot 3.
- Fix: shared LoadoutSnapshot.encode produces six dense wire entries, using false
  for empty slots. Base controller and Dungeon snapshot builder use it. Persisted
  profiles and service mutations retain sparse nil slots; existing client rendering
  already treats false as empty. No client optimism or service rewrite.
- Dungeon's legacy-only loadout handler now dispatches skill ID + target slot to
  move_to_slot, retaining the encounter lock and legacy table validation.
- Changed source: ReplicatedStorage/Core/Shared/LoadoutSnapshot.luau (new);
  ServerScriptService/Base/BaseProgressionController.luau;
  ServerScriptService/Dungeon/DungeonRuntime.server.luau;
  Base/Tests/BaseProgressionControllerTest.server.luau and
  Core/Tests/LoadoutServiceTest.server.luau under ServerScriptService.
- Studio source regression PASS: Base controller 16 assertions; loadout service
  28 assertions. Includes slots 1-6, move/replace/no duplicates, Slot 3 after empty
  Slot 2, invalid 0/-1/7/fraction/string/boolean/infinities/NaN/nil, DungeonClear
  moves and DungeonActive rejection. New source was executed in a temporary Play
  session; this is not fresh-build visual evidence. Play stopped afterwards.
- Fresh Base and Dungeon Rojo builds PASS:
  `C:\Users\Remko\AppData\Local\Temp\DungeonMMO_Loadout_20260906_135433`.
- Fresh Base Studio visuals and fresh Output: PENDING. File launch did not change
  the MCP-connected older Base. User asked to open the fresh Base and connect MCP.
- Exact next action: verify new LoadoutSnapshot exists in fresh Base Edit model,
  start Play, run actual Skills clicks and inspect snapshots for all six slots,
  moves/replacement/selection clearing/invalid requests; capture visual evidence
  and inspect fresh Output, stop Play, then final diff check and Git status.
- Gate 2B.B remains NOT ACCEPTED; Gate 2B.C not started. No commit/push/publish.
- Final source/diff review and git diff --check PASS. Final status: eight modified
  tracked files (four continuity docs, two runtime/controller files, two tests)
  and one untracked LoadoutSnapshot.luau. No staging, commit or push.
- No red errors observed in the temporary Studio source-test session Output;
  fresh-build Output remains unverified. MCP confirmed the older Base still had
  no LoadoutSnapshot in Edit after the file-launch attempt and handoff request.
