# Phase 2B Gate B — Combined Studio Acceptance Checklist

**Project:** DungeonMMO
**Gate:** 2B.B — Gameplay + Base Progression
**User-facing checks:** One combined checkpoint only

## Base validation

1. Play the Base validation Place and confirm the new Gate 2B.B test families report PASS with no red runtime exception.
2. Use the DEV/TEST `!level 10` command so the prototype character has the full Level 10 entitlement without grinding.
3. Interact with the Progression Trainer. Preview and confirm at least one Attribute Point spend, then verify the displayed available AP changes only after confirmation.
4. Use DEV/TEST `!prof ShieldBash 150`, reopen/refresh the trainer and buy Shield Bash Rank 2 with SP. Repeat with `!prof Mend 100` and buy Mend Rank 2.
5. Open Character -> Skills and verify the active loadout has six slots, learned starter skills can be rearranged, duplicate/unknown slot requests are not accepted, and no seventh/eighth active button is presented.
6. Exercise Attribute and Skill/SP respec once and verify the appropriate points become available again without deleting proficiency.

## Dungeon validation

1. Play the Dungeon validation Place and confirm Gate 2B.B plus existing regression test families report PASS with no red runtime exception.
2. On the first death, confirm there is no optional free-revive button: a three-second `Reviving...` countdown begins automatically and the character returns at the latest checkpoint with full HP/Stamina.
3. Die again after the free revive has been consumed and confirm the normal defeated/spectating flow returns instead of another automatic free revive.
4. Complete the Captain once and confirm the one-time bound Arc Slash Skill Book reward is granted; repeated first-clear reward logic is covered by the server test and must not generate a duplicate.

## Gate boundary

Gate 2B.B does not require a published cross-Place persistence proof. Learning the Captain book in Base after a real Dungeon return, preserving that knowledge/loadout across Places, reconnect/idempotency and the final Arc Slash cross-Place gameplay loop belong to Gate 2B.C.
