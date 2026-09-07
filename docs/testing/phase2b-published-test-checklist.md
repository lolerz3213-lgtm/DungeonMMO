# Phase 2B.C Published TEST Acceptance Checklis

**Project:** DungeonMMO
**Gate:** Phase 2B.C - Persistence + Published Acceptance
**Task:** Task 9 - Cross-Place Progression Persistence and final Phase 2B acceptance
**Environment:** Published TEST only
**Accepted starting checkpoint:** `ac9546c73d3f2f57221ae71b2f1e7a6ebcd35137

This checklist is the final Phase 2B user-facing acceptance proof. Studio-only
evidence is necessary but is not sufficient for this gate.

## 1. Safety and published TEST configuration

Before publishing or entering either Place:

- [ ] Current Git branch is `wip/phase-2b-c-published-persistence`.
- [ ] Working tree contains only the reviewed Gate 2B.C candidate changes.
- [ ] Both fresh Rojo validation builds pass.
- [ ] `git diff --check` passes.
- [ ] Starting Base Place ID is `134132328219009`.
- [ ] Test Dungeon Place ID is `117293035754309`.
- [ ] Base `ServerScriptService.DungeonMMOEnvironment` is exactly `TEST`.
- [ ] Dungeon `ServerScriptService.DungeonMMOEnvironment` is exactly `TEST`.
- [ ] Base `ServerScriptService.DungeonMMODungeonPlaceId` is exactly `117293035754309`.
- [ ] Base `DungeonMMOForceOutboundTeleportFailure` is absent or `false`.
- [ ] Dungeon `DungeonMMOForceReturnTeleportFailure` is absent or `false`.
- [ ] Live paid-revive products remain disabled.
- [ ] Live progression/Robux products remain disabled.
- [ ] No PROD DataStore or PROD Place is used for this proof.

`EnvironmentConfig` intentionally resolves Studio to `DEV`; the `TEST` attribute
is therefore a published-server check, not a Studio-local environment check.

For the fresh-profile item below, use a Roblox account/profile that has no
existing `TEST_PlayerProfile_v1` character data. Do not delete or alter PROD
data. If no fresh TEST identity is available, leave the fresh-profile item open
rather than treating an already-progressed TEST profile as equivalent.

## 2. Fresh profile and entitlement proof

- [ ] Fresh TEST character starts at Level 1.
- [ ] Strength / Dexterity / Vitality / Intellect / Spirit are exactly `5/5/5/5/5`.
- [ ] Available AP = `0`.
- [ ] Available SP = `0`.
- [ ] Mend is known at Rank 1.
- [ ] Shield Bash is known at Rank 1.
- [ ] Gaining each level grants exactly `+1 AP` and `+1 SP`.

## 3. Attribute and existing-skill persistence

- [ ] Spend at least one Strength point and verify basic one-handed-sword damage changes.
- [ ] Spend at least one Vitality point and verify MaxHealth changes.
- [ ] Spend at least one Spirit point and verify Mend effectiveness changes.
- [ ] Set/use Mend proficiency and confirm it caps at the next unpurchased threshold.
- [ ] Set/use Shield Bash proficiency and confirm it caps at the next unpurchased threshold.
- [ ] DEV/TEST proficiency mutation changes proficiency only; it does not grant rank, SP or skill knowledge.
- [ ] Purchase at least one eligible skill rank at the Base trainer.
- [ ] Leave/re-enter the relevant UI and confirm the purchased rank remains authoritative.

## 4. Captain first-clear book and Arc Slash learning

- [ ] Enter the published Test Dungeon from the Base portal.
- [ ] Complete the dungeon and defeat the Marauder Captain.
- [ ] First eligible Captain clear grants exactly one bound Arc Slash Skill Book.
- [ ] Return to Base through the real published handoff.
- [ ] Bound Arc Slash book is still present after the real Dungeon -> Base return.
- [ ] Base trainer learns Arc Slash only when the book and 3 SP are available.
- [ ] Learning consumes the bound book and exactly 3 SP atomically.
- [ ] Arc Slash becomes known at Rank 1.
- [ ] Arc Slash auto-fills the first free active slot.
- [ ] A repeated/replayed first-clear reward path does not create a duplicate book.

## 5. Six-slot loadout and Dungeon restrictions

- [ ] Character -> Skills can rearrange the six active slots in Base.
- [ ] Intentional empty gaps survive the authoritative snapshot.
- [ ] Enter an active uncleared Dungeon encounter and attempt a loadout swap.
- [ ] Active encounter rejects the swap.
- [ ] Clear the encounter and retry during the clear window.
- [ ] Clear-window swap succeeds.
- [ ] Arc Slash remains usable only with the required one-handed-sword family.
- [ ] Arc Slash multi-target proficiency uses the accepted diminishing-credit rules.

## 6. Respec accounting

- [ ] Attribute respec refunds only Attribute allocation.
- [ ] Attribute respec counter increments independently.
- [ ] Skill/SP respec refunds only Skill/SP allocation.
- [ ] Skill respec counter increments independently.
- [ ] Skill respec preserves consumed-book knowledge.
- [ ] Skill respec preserves saved proficiency.
- [ ] Repeated respecs cannot mint AP or SP beyond entitlement.

## 7. Death / revive persistence

- [ ] First Dungeon death automatically enters forced Reviving.
- [ ] Automatic free revive occurs after approximately three seconds.
- [ ] Player returns at the latest checkpoint with restored HP/Stamina.
- [ ] A later death does not grant another free automatic revive.
- [ ] Later death returns to the normal paid/spectator/defeated flow.

## 8. Full cross-Place and rejoin proof

After establishing a distinctive progression state (attributes, purchased rank,
Arc Slash knowledge, proficiency and a non-default six-slot arrangement):

- [ ] Base -> Dungeon preserves the complete progression snapshot.
- [ ] Dungeon -> Base preserves the complete progression snapshot.
- [ ] Leave the Experience completely.
- [ ] Rejoin the published Starting Base.
- [ ] Level/XP/Gold persist.
- [ ] AP/SP entitlement and spent allocation persist.
- [ ] All five attributes persist.
- [ ] Mend / Shield Bash / Arc Slash known state and purchased ranks persist.
- [ ] Saved proficiency persists.
- [ ] Six-slot loadout including intentional gaps persists.
- [ ] Respec counters persist.
- [ ] `ArcSlashFirstClear` persists.
- [ ] No duplicate Arc Slash book appears.
- [ ] Recoverable-session reconnect routes correctly without duplicating rewards or progression.
- [ ] Exactly-once/idempotency protections remain intact.

## 9. Regression evidence

Fresh validation must also show:

- [ ] Base Gate 2B.C regression families PASS.
- [ ] Dungeon Gate 2B.C regression families PASS.
- [ ] Existing Phase 1 regressions remain green.
- [ ] Existing Phase 2A regressions remain green.
- [ ] Existing Phase 2B.A regressions remain green.
- [ ] Existing Phase 2B.B regressions remain green.
- [ ] No red runtime exception is present in Base Output.
- [ ] No red runtime exception is present in Dungeon Output.

## Gate resul

Do not mark Phase 2B functionally complete until every required published TES
item above is satisfied and the user explicitly accepts Gate 2B.C.
