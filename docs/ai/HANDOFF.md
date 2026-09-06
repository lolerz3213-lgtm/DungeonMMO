# DungeonMMO Development Handoff

**Handoff date:** 6 September 2026
**Development mode:** Shared Astra/Codex + regular ChatGPT workflow

## Most recent preservation work

Before adding AI automation, the newer local Phase 2B.B working tree was
preserved in two ways:

1. A timestamped local recovery snapshot was created under
   `C:\Users\Remko\Documents\Roblox\DungeonMMO_Recovery`.
2. The complete Gate 2B.B WIP was deliberately committed and pushed to:
   `wip/phase-2b-b-pre-ai-continuity`.

WIP checkpoint:

`c5e2a59 wip: preserve Phase 2B.B before AI continuity setup`

The accepted `main` baseline remains the Phase 2A + Phase 2B.A checkpoint:

`24dee751b87d831abe22cd046dd3b9934c566a56`

## Current gameplay status

### Controlled formatting fix (6 September 2026)

- Branch: `wip/phase-2b-b-pre-ai-continuity`; repository HEAD before this
  uncommitted fix: `8ca139d chore: add AI development continuity layer`.
- Prior Base smoke evidence supplied by the user: Roblox Studio MCP connection
  and read-only DataModel inspection verified; local Play start, console
  inspection, viewport inspection, and Play stop/return to Edit verified; Git
  stayed clean. Local Studio resolving EnvironmentConfig to DEV is expected.
- That smoke test exposed ProgressionHudRulesTest failure:
  "level cap must show XP MAX without formatting nil."
- Confirmed root cause: XP MAX has four numeric placeholders but five arguments;
  `xp` shifts Gold/AP/SP. Removed only `xp` from that branch in
  `src/ReplicatedStorage/Core/Shared/ProgressionHudRules.luau`. Test unchanged.
- Both Rojo builds succeeded under
  `C:\Users\Remko\AppData\Local\Temp\DungeonMMO_ProgressionHudFix_20260906_122919`:
  `Dungeon.rbxl` from `default.project.json`, `Base.rbxl` from `base.project.json`.
- Fresh runtime result: NOT VERIFIED. MCP exposes no local-file opening command.
  The connected `DungeonMMO_AI_Continuity_Base.rbxl` predates the fix and was
  confirmed in Edit mode. No Play was started during this task. Fresh Output
  errors/warnings have not been assessed.
- Source-change `git diff --check` passed; only informational LF/CRLF warning.
- Continuity changes are limited to these four `docs/ai` files. No commit/push.
- Immediate next step: manually open the fresh `Base.rbxl` above, verify loaded
  source, run ProgressionHudRulesTest in local Play, inspect Output, then stop
  Play and confirm Edit. Do not claim PASS before fresh evidence.
- Gate 2B.B remains NOT ACCEPTED. Next major engineering action is tracing
  server progression mutation -> client snapshot/event -> ProfileHud to fix
  stale HUD refresh; six-slot gap placement follows.

Gate 2B.B is NOT accepted.

Confirmed working:

- DEV/TEST Client Command Bar progression bridge.
- Level 10 mutation reaches authoritative server progression.
- Progression Trainer reads Level 10 and AP/SP entitlement 9/9.
- Proficiency debug mutation route works.

Current blockers:

1. Profile HUD stale until trainer open.
2. Exact loadout placement after an empty slot gap fails.

Do not broaden debugging until those two defects are resolved.

## Next-session startup

A new autonomous or regular ChatGPT session should:

1. Read `AGENTS.md`.
2. Read `docs/ai/CURRENT_STATE.md`.
3. Read this file.
4. Read `docs/ai/TEST_MATRIX.md`.
5. Inspect the current Git branch, HEAD, status, and diff.
6. If working on current Gate 2B.B, preserve the WIP branch and continue with
   the two listed defects.

## Regular ChatGPT fallback

If higher-autonomy credits are exhausted, continue in ordinary ChatGPT using
the same repository state.

Provide or make available:

- `docs/roadmap/DungeonMMO_Roadmap_v1_21.docx`;
- `docs/ai/CURRENT_STATE.md`;
- `docs/ai/HANDOFF.md`;
- the current `git status --short`;
- the current `git log -1 --oneline`;
- relevant Studio output/screenshots.

Suggested continuation request:

> Continue DungeonMMO from the repository handoff. Read Roadmap v1.21,
> CURRENT_STATE.md and HANDOFF.md first. Preserve all LOCKED decisions and the
> current WIP branch. Gate 2B.B is not accepted. Continue from the exact next
> engineering action recorded in CURRENT_STATE.md.

This fallback must not depend on the preceding Astra/Codex transcript.

## End-of-session rule

Before an autonomous session ends after meaningful work, update this file with:

- files changed;
- reason for each change;
- tests/builds actually run;
- results actually observed;
- active branch and checkpoint;
- remaining defect;
- exact next action.

Do not write "PASS" or "accepted" without fresh evidence.

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
