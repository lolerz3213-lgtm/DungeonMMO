# Phase 2B Gate C Acceptance Record

**Gate:** 2B.C — Persistence + Published Acceptance
**Accepted:** 7 September 2026
**Accepted code checkpoint:** `4a82d7486e7455f7597a777e862393c5bbb56cfb`
**Branch:** `wip/phase-2b-c-published-persistence`

## Published TEST targets

- Base Place: `134132328219009`
- Dungeon Place: `117293035754309`
- Universe: `10765241947`
- Published environment: `TEST`
- PROD progression stores and live paid revive products were not used.

## Acceptance evidence

The user completed the Phase 2B.C published TEST acceptance and confirmed the following behavior in the live Roblox client:

- Base -> Dungeon -> Base handoff works.
- Leaving and rejoining preserves the accepted Phase 2B character progression state.
- Attribute/AP/SP progression persists.
- Skill ranks and proficiency state persist.
- Trainer learning and Arc Slash knowledge/loadout state persist.
- The Captain first-clear Arc Slash Skill Book flow remains idempotent.
- Attribute and Skill respec state remains independent and persists.
- Automatic first-death free revive remains functional.
- Published Dungeon admission no longer remains stuck on `Dungeon loading...` once the TEST environment attribute is present.
- Only one combat HUD/runtime presentation is shown.
- Published sword attack presentation works.
- Only one Captain/boss runtime is spawned.
- Shield presentation remains visible in published play.
- The shield arm remains behind the shield during Block and Shield Bash.
- Swept-volume dodge clearance prevents the previously observed under-monster/floor fall-through regression.

## Regression fixes included in the accepted checkpoint

- Publish-safe Rojo compositions exclude runtime tests and the retired duplicate Dungeon UI.
- Published sword animation fallback.
- Dungeon boss spawn guard.
- Client-only camera-parented shield visual, independent of streamed Workspace/server grip lifetime.
- Shield arm coverage offsets for Block and Shield Bash.
- Swept-volume dodge clearance using overlap/blockcast safety rules.

## Gate result

**2B.C ACCEPTED.**

Phase 2B persistent character progression is accepted as the new gameplay baseline, subject to normal future regression testing. Phase 2B.A and 2B.B remain accepted and are not reopened by this record.
