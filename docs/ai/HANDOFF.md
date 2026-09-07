# DungeonMMO Development Handoff

**Date:** 7 September 2026

## Current accepted gameplay boundary

- Phase 1 combat: ACCEPTED.
- Phase 2A - Core Base-to-Dungeon slice: ACCEPTED.
- Phase 2B.A - Progression Foundation: ACCEPTED.
- Phase 2B.B - Gameplay + Base Progression: ACCEPTED.
- Phase 2B.C - Persistence + Published Acceptance: ACCEPTED.
- Phase 2B: FUNCTIONALLY COMPLETE.
- Accepted Gate 2B.C code checkpoint:
  `4a82d7486e7455f7597a777e862393c5bbb56cfb`.
- Accepted merged gameplay baseline:
  `main` / `origin/main` at
  `8be005ff1ef87712bff8fde01d313fd2569771ac`.
- Archived Gate 2B.C branch:
  `origin/wip/phase-2b-c-published-persistence` at
  `cf67bb32f9643beca7875b5f35e82b4bbe1114ce`.
- Canonical roadmap:
  `docs/roadmap/DungeonMMO_Roadmap_v1_23.docx`.

## Gate 2B.C published acceptance

The user completed and accepted the published TEST Base -> Dungeon -> Base ->
leave -> rejoin proof. The complete Phase 2B progression state persisted across
Places and reconnect without duplicate reward or point-minting regressions.

Targeted published regressions are also closed:

- duplicate HUD/runtime presentation: fixed;
- published sword attack presentation: fixed;
- duplicate Captain/boss runtime: fixed;
- shield disappearing in published play: fixed through the independent
  camera-parented client visual;
- left arm appearing in front of the shield during Block/Shield Bash: fixed;
- dodge pushing the player under a monster/floor: fixed with swept-volume
  clearance rules.

The Gate C acceptance record is
`docs/testing/phase2b-gate-c-acceptance-record.md`.

## Separate art work

`art/dungeon-environment-prototype` remains separate. Do not do gameplay work
there, merge it into the next race/class slice, or pop the preserved art-side
stash onto the gameplay branch.

## Exact next action

The next gameplay slice is Phase 2C: first real race/base-class definitions and
class-specific trainer catalogues.

1. branch from accepted `main` at
   `8be005ff1ef87712bff8fde01d313fd2569771ac`;
2. lock two prototype races and one shared starting archetype;
3. replace the temporary class-neutral Prototype catalogue with real
   race/base-class definitions while reusing the accepted Phase 2B
   profile/progression/loadout/proficiency services;
4. add one class-specific Base trainer catalogue;
5. prove different race-specific first secondary-class advancement targets for
   the shared archetype;
6. define safe migration/default behaviour for existing Prototype characters;
7. rerun Base and Dungeon regression builds before any published acceptance.

Do not begin Race Change monetisation, broad Phase 3 class trees, or final class
balance in this first slice.
