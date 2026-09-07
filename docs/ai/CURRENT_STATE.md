# DungeonMMO Current Engineering State

**State date:** 7 September 2026
**Canonical roadmap:** Version 1.23
**Current phase:** Phase 2 - Vertical Slice
**Current gate:** Phase 2C - Race/base-class definitions and class-specific trainer catalogues
**Gate 2B.C status:** ACCEPTED
**Phase 2B status:** FUNCTIONALLY COMPLETE

## Accepted baselines

- Phase 1 combat: ACCEPTED.
- Phase 2A core Base-to-Dungeon slice: ACCEPTED.
- Phase 2B.A Progression Foundation: ACCEPTED.
- Phase 2B.B Gameplay + Base Progression: ACCEPTED.
- Phase 2B.C Persistence + Published Acceptance: ACCEPTED.
- Accepted Phase 2B.C code checkpoint:
  `4a82d7486e7455f7597a777e862393c5bbb56cfb`.
- Gate 2B.C acceptance documentation checkpoint:
  `cf67bb32f9643beca7875b5f35e82b4bbe1114ce`.
- Accepted gameplay baseline:
  `main` and `origin/main` at
  `8be005ff1ef87712bff8fde01d313fd2569771ac`.
- Archived Gate 2B.C branch:
  `origin/wip/phase-2b-c-published-persistence` at `cf67bb3`.

## Experience composition

- Local project:
  `C:\Users\Remko\Documents\Roblox\DungeonMMO`
- `default.project.json` = Test Dungeon.
- `base.project.json` = Starting Base.
- Universe ID: `10765241947`.
- Starting Base Place ID: `134132328219009`.
- Test Dungeon Place ID: `117293035754309`.
- Published environment: TEST.
- Live paid revives: disabled.

## Gate 2B.C accepted evidence

Published TEST acceptance passed the complete Phase 2B persistence proof:

- Base -> Dungeon -> Base -> leave -> rejoin preserves the accepted progression state;
- attributes, AP/SP allocation, ranks, proficiency, trainer learning, Arc Slash
  knowledge/loadout and independent respec state persist;
- the first-clear bound Arc Slash Skill Book remains exactly-once and survives
  the return to Base;
- Arc Slash learning consumes the book and 3 SP atomically and auto-fills the
  first free active slot;
- active Dungeon encounters reject loadout swaps and cleared-room windows accept them;
- first death performs the automatic approximately three-second free revive and
  later deaths use the normal paid/spectator boundary;
- published sword presentation works;
- one combat HUD/runtime presentation is shown;
- one Captain/boss runtime is spawned;
- the client-only camera-parented shield presentation remains visible;
- the shield arm remains behind the shield during Block and Shield Bash;
- swept-volume dodge clearance prevents the previously observed
  under-monster/floor fall-through regression.

Detailed acceptance evidence is stored in
`docs/testing/phase2b-gate-c-acceptance-record.md`.

## Separate environment-art branch

`art/dungeon-environment-prototype` is not the gameplay branch. Its preserved
art-side work/stash remains separate. Do not merge or pop that work into the
race/base-class gameplay branch.

## Exact next engineering action

Start the first real race/base-class slice from accepted `main`:

1. create a fresh gameplay branch from
   `8be005ff1ef87712bff8fde01d313fd2569771ac` or a later deliberate accepted
   `main`;
2. lock the first two prototype races and one shared starting archetype;
3. extend the existing class-definition interface into real race/base-class
   definitions with starter active/passive grants and one class-specific Base
   trainer catalogue;
4. prove that the shared starting archetype points to different first
   race-specific secondary-class advancement targets;
5. define a safe migration/default for existing accepted Prototype characters
   without losing or duplicating Phase 2B progression;
6. rerun Base and Dungeon regressions before any new published acceptance.

Do not enable Race Change monetisation, broad Phase 3 trees, or final class
balance in this first slice.
