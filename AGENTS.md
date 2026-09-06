# DungeonMMO Agent Operating Rules

These rules apply to autonomous or semi-autonomous development agents working
in this repository.

## Startup sequence

Before modifying source:

1. Read `docs/ai/CURRENT_STATE.md`.
2. Read `docs/ai/HANDOFF.md`.
3. Read `docs/ai/TEST_MATRIX.md`.
4. Read `docs/ai/AUTOMATION.md`.
5. Treat `docs/roadmap/DungeonMMO_Roadmap_v1_22.docx` as the canonical
   long-form design source for version 1.22.
6. Inspect:
   - `git branch --show-current`
   - `git log -1 --oneline`
   - `git status --short`
   - `git diff --check`

If these disagree with `CURRENT_STATE.md`, stop source modification and report
the mismatch. Do not guess which state is correct.

## Current accepted boundary

- Phase 1 combat: ACCEPTED.
- Phase 2A: ACCEPTED.
- Phase 2B Gate 2B.A: ACCEPTED.
- Phase 2B Gate 2B.B: ACCEPTED.
- Gate 2B.C is the active and final Phase 2B gate.

Do not reopen accepted architecture merely for cosmetic polish unless a real
regression or readability blocker is demonstrated.

## Git safety

- `main` is for deliberately accepted checkpoints.
- Do not develop directly on `main` unless the user explicitly requests it.
- Never run `git reset --hard`, `git clean`, destructive checkout, force push,
  history rewrite, or any operation that discards local work without explicit
  user approval.
- A WIP/recovery commit does not imply acceptance until the complete gate has
  passed; Gate 2B.B has now passed its complete acceptance check.
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
- Gate 2B.C acceptance requires the published TEST cross-Place proof in the
  canonical Task 9 checklist, not only Studio-local evidence.

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

The active gameplay work is Gate 2B.C / Task 9: Cross-Place Progression
Persistence and final Phase 2B acceptance.

Exact scope:

1. add the published TEST progression checklist;
2. run fresh Base and Dungeon regression builds;
3. run the private published TEST Base -> Dungeon -> Base -> leave -> rejoin
   progression proof;
4. verify reconnect/idempotency and duplicate protection;
5. freeze Phase 2B only after user acceptance.

Do not begin the first real race/base-class definitions before Gate 2B.C is
accepted.

`art/dungeon-environment-prototype` is a separate environment-art branch. Do
not perform gameplay/progression work there, merge it into Gate 2B.C, or pop
its preserved stash onto the gameplay branch.

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
