# DungeonMMO AI Continuity Design

**Date:** 2026-09-06
**Status:** Approved

## Goal

Create a single development workflow that can move between high-autonomy
Astra/Codex work and ordinary ChatGPT work without losing source state,
accepted design decisions, test evidence, or the exact next engineering
action.

## State architecture

- Git stores accepted checkpoints and explicit WIP recovery checkpoints.
- Roadmap v1.21 remains the canonical long-form design source.
- `docs/ai/CURRENT_STATE.md` stores concise active engineering state.
- `docs/ai/HANDOFF.md` stores latest-session transfer information.
- `docs/ai/TEST_MATRIX.md` stores accepted evidence and open gate checks.
- `docs/ai/AUTOMATION.md` stores tool permissions and automation boundaries.
- `AGENTS.md` tells autonomous agents how to operate safely.

## Git policy

`main` is an accepted-checkpoint branch. WIP work is preserved separately and
may be pushed for recovery without implying acceptance.

The current Gate 2B.B WIP is preserved on:

`wip/phase-2b-b-pre-ai-continuity`

at:

`c5e2a59`

## Automation policy

Roblox Studio's built-in MCP server is the preferred Studio control path.
Custom Roblox control infrastructure is deferred unless a concrete capability
gap is proven.

Blender automation is a later independent sub-project after continuity and
Studio automation are proven.

## Fallback requirement

Ordinary ChatGPT must be able to continue using repository-owned state without
the previous autonomous chat transcript.
