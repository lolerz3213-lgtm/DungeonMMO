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
**Current verified checkpoint:** `ebf9740`

### Confirmed current evidence

- HEAD `ebf9740` on `wip/phase-2b-b-pre-ai-continuity`, committed and pushed.
- Repository clean at task start (Git verified).
- HUD FIXED AND VERIFIED: user confirmed fresh Base Studio visuals, Level 10
  immediate update PASS, ProgressionHudRulesTest PASS, no red Studio errors,
  Base/Dungeon builds PASS and git diff --check PASS.
- Remaining active defect: six-slot loadout gap placement.

- [x] DEV/TEST Client Command Bar bridge reaches server-bound progression.
- [x] Level 10 mutation reports AP/SP entitlement 9/9.
- [x] Trainer reflects the Level 10 authoritative state.
- [x] Proficiency mutation route works.
- [x] Profile HUD immediately reflects Level 10 (user verified).
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
