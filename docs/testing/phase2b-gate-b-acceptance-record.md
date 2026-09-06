# Phase 2B Gate B Acceptance Record

**Project:** DungeonMMO
**Accepted:** 6 September 2026
**Status:** ACCEPTED
**Accepted gameplay source candidate:**
`0d86755ccbbd70b3f3b2a8e124247cc4097a71df`

## Scope

Gate 2B.B combined Phase 2B Tasks 5-8 into one user-facing acceptance checkpoint:
Arc Slash combat/rank integration, the dynamic six-slot active loadout, the
Base Progression Trainer and Character -> Skills menu, Attribute/SP/rank/respec
interaction, the guaranteed one-time bound Arc Slash Skill Book from the
Marauder Captain, and the automatic three-second first free revive.

## Base evidence

The user ran a fresh Base build in Roblox Studio and confirmed the complete Base
combined checklist:

- DEV/TEST Level 10 mutation immediately refreshed the Profile HUD;
- Profile HUD and trainer agreed at Level 10 with AP/SP entitlement 9/9;
- multi-point Attribute preview cancelled without saving;
- Confirm committed the selected Attribute spend atomically;
- Shield Bash and Mend proficiency thresholds enabled their expected Rank 2
  purchases and SP costs;
- all six active slots worked with intentional empty gaps, later-slot placement,
  moves, replacement, uniqueness, no-op clicks without a selected skill and
  selection clearing after success;
- Attribute and Skill TEST respecs restored the correct point allocations,
  preserved the intended knowledge/proficiency state and incremented only their
  independent counters;
- no red runtime errors were reported.

The loadout-gap defect was traced to sparse numeric RemoteEvent array semantics.
The authoritative profile correctly contained the later slot, but the client
snapshot lost entries after an intentional nil. Shared `LoadoutSnapshot.encode`
now sends six dense wire entries using `false` for empty slots while persistent
profile state remains sparse.

## Dungeon evidence

The user then ran the fresh Dungeon build and confirmed:

- relevant Gate 2B.B and accepted regression families reported PASS;
- no red runtime errors were reported;
- first death automatically consumed the free revive and returned after about
  three seconds at the latest checkpoint with restored HP/Stamina;
- second death returned to the normal defeated/Studio simulated paid-revive flow;
- Marauder Captain first clear granted the one-time bound Arc Slash Skill Book;
- a fresh server progression snapshot printed:
  `ArcSlash BookOwned = true` and `ArcSlash FirstClear = true`.

The exactly-once Arc Slash reward behavior is also covered by the server
save/reload regression test.

## Result

Gate 2B.B is accepted. The gameplay source that passed the manual gate is commit
`0d86755ccbbd70b3f3b2a8e124247cc4097a71df` on
`wip/phase-2b-b-pre-ai-continuity`. The documentation close-out must be reviewed
and deliberately committed before `main` is fast-forwarded to this accepted
state.

The next engineering gate is Phase 2B.C / Task 9: published TEST cross-Place
progression persistence and final Phase 2B acceptance. Learning Arc Slash after
a real Dungeon return, preserving the complete progression state across Places,
leave/rejoin/reconnect and duplicate protection belong to Gate 2B.C.
