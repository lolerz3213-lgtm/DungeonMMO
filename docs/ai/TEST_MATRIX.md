# DungeonMMO Test and Acceptance Matrix

This file records accepted evidence and current gate status. It is not a
replacement for fresh test output when claiming a new result.

## Phase 1 - Combat prototype

**Roadmap status:** ACCEPTED

Previously accepted runtime coverage includes:

- basic attack / swept melee behaviour;
- blocking;
- parry;
- Guard Break;
- dodge invulnerability;
- Shield Bash;
- Mend channel and cancellation;
- four-Marauder pressure;
- death/respawn lifecycle;
- controller/mobile emulation;
- approximately 150 ms simulated round-trip latency diagnostics.

Presentation remains placeholder quality and is intentionally deferred.

## Phase 2A - Core Base-to-Dungeon slice

**Roadmap status:** ACCEPTED

Previously accepted coverage includes:

- separate Base and Dungeon Rojo builds;
- profile/save layer;
- DEV/TEST/PROD namespaces;
- profile leases and handoff;
- 1-4-player dungeon session contract;
- reconnect/reconstruction;
- persisted monster XP and Gold;
- room-start checkpoints;
- one free revive + later revive boundary;
- spectating and wipe window;
- Marauder Captain;
- immutable completion eligibility;
- exactly-once completion rewards;
- save-before-return;
- Base/Dungeon UI;
- reserved-server teleport;
- Base -> Dungeon -> Base persistence;
- 60-second auto-return;
- abandon-to-Base;
- deliberate TEST teleport-failure recovery.

Live paid-revive activation remains disabled.

## Phase 2B.A - Progression Foundation

**Roadmap status:** ACCEPTED
**Accepted Git checkpoint:** `24dee751b87d831abe22cd046dd3b9934c566a56`

Previously accepted PASS families include:

- profile migration;
- Level/AP/SP entitlement;
- Attribute Config/Service;
- Skill Progression;
- Loadout;
- Proficiency;
- Progression Damage;
- Mend Progression;
- Dungeon Progression Bridge;
- existing Phase 1/2A regression families.

## Phase 2B.B - Gameplay + Base Progression

**Status:** NOT ACCEPTED
**Current WIP checkpoint:** `c5e2a59`

### Confirmed current evidence

- Prior Base smoke test (user-reported): Studio MCP read-only inspection,
  Play start, console inspection, viewport inspection, and Play stop/return to
  Edit verified. Local EnvironmentConfig resolving to DEV is expected.
- Prior RED: ProgressionHudRulesTest, "level cap must show XP MAX without
  formatting nil." Extra XP MAX format argument confirmed and removed in source;
  existing assertions unchanged. Pre-fix repository HEAD: `8ca139d`.
- Fresh Dungeon and Base Rojo builds: PASS, output directory
  `C:\Users\Remko\AppData\Local\Temp\DungeonMMO_ProgressionHudFix_20260906_122919`.
- Fresh ProgressionHudRulesTest runtime result: PENDING manual opening of
  `Base.rbxl` from that directory. Additional runtime errors/warnings: not
  assessed against the fresh build. Old open Studio build remains in Edit.
- Gate remains NOT ACCEPTED; stale Profile HUD remains the next major defect,
  followed by six-slot gap placement.

- [x] DEV/TEST Client Command Bar bridge reaches server-bound progression.
- [x] Level 10 mutation reports AP/SP entitlement 9/9.
- [x] Trainer reflects the Level 10 authoritative state.
- [x] Proficiency mutation route works.
- [ ] Profile HUD immediately reflects Level 10.
- [ ] Exact selected-skill placement into Slot 3 with Slot 2 empty.
- [ ] Full Base combined acceptance check.
- [ ] Full Dungeon combined acceptance check.

### Base combined acceptance requirements

- [ ] Level 10 Profile HUD/trainer agreement.
- [ ] Attribute spend flow.
- [ ] proficiency/rank purchase flow.
- [ ] six-slot rearrangement including intentional empty gaps.
- [ ] Attribute TEST respec.
- [ ] Skill TEST respec.

### Dungeon combined acceptance requirements

Run only after Base is clean.

- [ ] Arc Slash integration/PASS family.
- [ ] first-clear Arc Slash reward/PASS family.
- [ ] automatic-free-revive/PASS family.
- [ ] first death performs forced three-second free revive.
- [ ] second death uses normal defeated flow.
- [ ] Captain first-clear awards the bound Arc Slash Skill Book.
- [ ] relevant Phase 1/2A/2B.A regression families remain green.
- [ ] no red runtime errors.

## Phase 2B.C

**Status:** NOT STARTED

Published Base -> Dungeon -> Base persistence/rejoin/reconnect/idempotency
acceptance begins only after Gate 2B.B is accepted.

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
