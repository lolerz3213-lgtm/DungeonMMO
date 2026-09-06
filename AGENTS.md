# DungeonMMO Agent Operating Rules

These rules apply to autonomous or semi-autonomous development agents working
in this repository.

## Startup sequence

Before modifying source:

1. Read `docs/ai/CURRENT_STATE.md`.
2. Read `docs/ai/HANDOFF.md`.
3. Read `docs/ai/TEST_MATRIX.md`.
4. Read `docs/ai/AUTOMATION.md`.
5. Treat `docs/roadmap/DungeonMMO_Roadmap_v1_21.docx` as the canonical
   long-form design source for version 1.21.
6. Inspect:
   - `git branch --show-current`
   - `git log -1 --oneline`
   - `git status --short`
   - `git diff --check`

If these disagree with `CURRENT_STATE.md`, stop source modification and report
the mismatch. Do not guess which state is correct.

## Current accepted boundary

- Phase 1 combat is accepted.
- Phase 2A is accepted.
- Phase 2B Gate 2B.A is accepted.
- Phase 2B Gate 2B.B is installed but NOT accepted.
- Gate 2B.C has not started.

Do not reopen accepted architecture merely for cosmetic polish unless a real
regression or readability blocker is demonstrated.

## Git safety

- `main` is for deliberately accepted checkpoints.
- Do not develop directly on `main` unless the user explicitly requests it.
- Never run `git reset --hard`, `git clean`, destructive checkout, force push,
  history rewrite, or any operation that discards local work without explicit
  user approval.
- A WIP/recovery commit does not mean a gameplay gate is accepted.
- Installers and patches must not stage, commit, or push automatically.
- Review exact diffs before deliberate commits.

## Build and validation rules

- `default.project.json` builds the Dungeon Place.
- `base.project.json` builds the Starting Base Place.
- When shared/Core/Base/Dungeon composition changes, build both Places.
- Write validation `.rbxl` files to a temporary or timestamped validation
  location. Never overwrite the normal user project file.
- Run `git diff --check` after source changes.
- LF-to-CRLF Git warnings on Windows are informational unless Git reports an
  actual whitespace error.
- Preserve and run relevant accepted regression families.
- Gate 2B.B may be marked accepted only after its complete Base + Dungeon
  acceptance checklist passes.

## Roblox authority and environment rules

Combat results, progression, inventory, rewards, saves, handoff state, and
other value-bearing systems remain server-authoritative.

Do not autonomously:

- publish PROD;
- enable live paid-revive Developer Products;
- spend Robux;
- mutate production DataStores;
- alter monetisation;
- bypass TEST/PROD environment guards.

TEST-only debug hooks must remain rejected or disabled in PROD.

## Scope discipline

The active work is Gate 2B.B. The only known current defects are:

1. The top-left Profile HUD does not immediately reflect the DEV/TEST level
   mutation until the Progression Trainer is opened.
2. Character -> Skills placement fails when placing a selected skill into a
   later slot after an intentional empty gap.

Fix those at their real ownership boundaries. Do not begin 2B.C or unrelated
presentation work first.

## Handoff discipline

At every meaningful WIP checkpoint:

- update `docs/ai/CURRENT_STATE.md`;
- update `docs/ai/HANDOFF.md`;
- update `docs/ai/TEST_MATRIX.md` when test evidence changes;
- record the Git branch and checkpoint;
- record known defects and the exact next engineering action.

At an accepted gate, also update the canonical roadmap/version through the
normal roadmap maintenance workflow.

No critical implementation knowledge may exist only in an agent chat.
