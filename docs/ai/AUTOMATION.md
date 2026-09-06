# DungeonMMO AI Automation Boundary

**Automation status:** Continuity layer being installed. Studio MCP connection
has not yet been accepted as working in this repository workflow.

## Goal

Use higher-autonomy development when available without making the project
dependent on it. Ordinary ChatGPT must always be able to continue from the
repository handoff.

## Preferred Roblox control path

Use Roblox Studio's built-in MCP server with a trusted MCP-aware client such as
Codex CLI.

Do not build a custom Roblox HTTP/plugin control bridge unless the built-in MCP
server is proven to lack a required capability.

## Initial allowed actions

After the MCP connection is deliberately enabled and verified, an agent may:

- inspect the open Studio DataModel;
- read instances and properties;
- run DEV/TEST Luau;
- start and stop local playtests;
- inspect Studio output;
- capture viewport state;
- use test input/navigation;
- modify local repository source;
- run Rojo builds;
- update repository handoff/test documents;
- create deliberate WIP branches/commits after review.

## Initial prohibited actions

An agent must not autonomously:

- publish PROD;
- activate live paid revives;
- spend Robux;
- mutate production DataStores;
- modify production save data;
- alter monetisation;
- force-push;
- rewrite Git history;
- run destructive Git cleanup/reset commands;
- mark a roadmap gate accepted without its complete fresh acceptance evidence.

## First MCP acceptance milestone

Before using MCP to debug Gate 2B.B, prove this harmless loop:

1. Open the newest Base validation build.
2. Connect the trusted MCP client.
3. Read Studio state/DataModel.
4. Start Play.
5. Read Studio output.
6. Capture viewport state.
7. Stop Play.
8. Confirm no PROD publish or value-bearing mutation occurred.
9. Record observed results in `HANDOFF.md` and `TEST_MATRIX.md`.

Game source mutation is not required to pass this milestone.

## Build commands

Dungeon:

```powershell
rojo build default.project.json -o "$env:TEMP\DungeonMMO_AI_Dungeon.rbxl"
```

Starting Base:

```powershell
rojo build base.project.json -o "$env:TEMP\DungeonMMO_AI_Base.rbxl"
```

## Credit-exhaustion fallback

When higher-autonomy credits are unavailable:

1. Stop relying on the autonomous session transcript.
2. Use the current Git branch and commit.
3. Read `CURRENT_STATE.md`, `HANDOFF.md`, and `TEST_MATRIX.md`.
4. Continue through ordinary ChatGPT with manual Studio execution where
   required.
5. Update the same handoff files before returning to autonomous development.

There is one DungeonMMO project state, not separate "Astra" and "regular chat"
versions.
