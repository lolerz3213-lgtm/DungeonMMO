# DungeonMMO AI Continuity Layer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking.

**Goal:** Install repository-owned continuity state before connecting Roblox
Studio to autonomous tooling.

**Architecture:** Preserve WIP first, install continuity documents second,
prove a read-only/non-destructive Studio MCP loop third, then use the shared
workflow on Gate 2B.B.

**Tech Stack:** Git, GitHub, PowerShell, Rojo, Roblox Studio, Studio MCP,
Codex CLI, Luau.

**Spec:** `docs/superpowers/specs/2026-09-06-ai-continuity-design.md`

## Global Constraints

- Keep Gate 2B.B NOT ACCEPTED until the complete acceptance gate passes.
- Preserve accepted `main` checkpoint `24dee751...`.
- Preserve WIP recovery checkpoint `c5e2a59`.
- Do not begin Gate 2B.C early.
- Do not publish PROD automatically.
- Keep paid revives live-disabled.
- Build both Rojo Places after repository setup changes.

---

### Task 1: Preserve Gate 2B.B WIP

- [x] Create local timestamped recovery snapshot.
- [x] Confirm accepted 2B.A commit is an ancestor of current HEAD.
- [x] Create `wip/phase-2b-b-pre-ai-continuity`.
- [x] Commit complete current WIP as `c5e2a59`.
- [x] Push the WIP branch to GitHub.

### Task 2: Install AI continuity documents

- [ ] Add canonical Roadmap v1.21 under `docs/roadmap/`.
- [ ] Add `AGENTS.md`.
- [ ] Add `CURRENT_STATE.md`.
- [ ] Add `HANDOFF.md`.
- [ ] Add `TEST_MATRIX.md`.
- [ ] Add `AUTOMATION.md`.
- [ ] Add approved continuity spec and plan.
- [ ] Run `git diff --check`.
- [ ] Build Dungeon with Rojo.
- [ ] Build Starting Base with Rojo.
- [ ] Review the diff before deliberate commit.

### Task 3: Connect Studio MCP

- [ ] Enable Studio as MCP server.
- [ ] Connect Codex CLI using the Studio-supported local MCP route.
- [ ] Verify read-only Studio inspection.
- [ ] Record exact working connection method.

### Task 4: Prove harmless automation smoke test

- [ ] Read DataModel.
- [ ] Start local Play.
- [ ] Read output.
- [ ] Capture viewport state.
- [ ] Stop Play.
- [ ] Record evidence.

### Task 5: Continue Gate 2B.B

- [ ] Reproduce and fix Profile HUD refresh defect.
- [ ] Reproduce and fix exact target-slot gap-placement defect.
- [ ] Complete Base acceptance.
- [ ] Complete Dungeon acceptance.
- [ ] Update roadmap and accepted checkpoint only when the gate is green.

### Task 6: Prove ordinary ChatGPT fallback

- [ ] Continue from repository-owned state without relying on the preceding
      autonomous transcript.
