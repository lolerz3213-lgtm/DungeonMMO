# DungeonMMO Phase 2B — Character Progression Vertical Slice Design

**Project:** DungeonMMO

**Date:** 5 September 2026

**Status:** APPROVED / DESIGN LOCKED

**Baseline:** Phase 2A Vertical Slice — FUNCTIONALLY COMPLETE / ACCEPTED

**Roadmap baseline:** DungeonMMO Roadmap v1.18

## 1. Purpose

Phase 2B proves the first persistent character-build progression loop on top of the accepted two-Place Phase 2A architecture.

The playable proof is:

**gain XP -> level -> receive Attribute Point + Skill Point entitlement -> spend attributes at Base -> earn skill proficiency in meaningful combat -> purchase eligible skill ranks with SP -> clear the Captain -> receive the one-time Arc Slash Skill Book -> return to Base -> consume the book + spend SP -> learn Arc Slash -> manage the six-slot active loadout -> respec safely -> leave/rejoin with the entire build preserved.**

Phase 2B is deliberately **class-neutral**. Mend and Shield Bash are temporary prototype starter skills. Real starter skills, trainers and skill catalogues become class-defined when the race/class slice begins after this progression foundation is proven.

This phase also corrects the accepted dungeon revive flow so the run's one free revive is automatic after a three-second countdown rather than optional.

## 2. Non-goals

Phase 2B does **not** implement:

- final races, classes, class advancement or race-specific trees;
- final class trainer NPCs or final Base art;
- a large production skill tree;
- weapon mastery;
- final equipment requirements/stat rolls/upgrading;
- crafting, professions, trading UI, bank, market or guild systems;
- live Robux respec products;
- live Robux Skill Book refund products;
- live Race Change products;
- final respec currency prices or price-growth formula;
- final XP curve, final level cap or final attribute balance;
- final skill rarity/drop tuning;
- final animations, VFX, audio or production UI art.

Phase 1 combat timing and defensive readability remain accepted unless Phase 2B integration exposes a functional regression.

## 3. Architectural principles

1. **Server authority.** XP, levels, attributes, AP/SP accounting, learned skills, ranks, proficiency, one-time rewards, respecs and loadout validation are server-authoritative.
2. **One persistent character profile.** Phase 2B extends the existing Phase 2A `ProfileSchema`/`ProfileService`; it does not create a second save system.
3. **No loose SP wallet mutations.** Available SP is derived from lifetime entitlement minus the SP cost of the currently purchased refundable skill ranks.
4. **Permanent mastery, reversible build allocation.** Skill Book knowledge and earned proficiency survive ordinary Skill/SP respecs; current SP investment does not.
5. **Base-only permanent progression.** Learning books, purchasing ranks, spending/refunding attributes and permanent respecs happen only through Base progression services.
6. **Run tests the build brought in.** Dungeon hotbar changes are limited to cleared-room windows; permanent progression cannot be changed during a run.
7. **Data-driven growth.** Skill rank count, tier, SP costs, proficiency thresholds, weapon requirements and rank effects are definitions/configuration rather than hardcoded assumptions.
8. **Prototype values are replaceable.** Level 10, the test XP curve and the initial attribute/rank numbers are Phase 2B tuning, not final MMO balance.

## 4. Existing Phase 2A integration

Phase 2B extends the accepted boundaries already present in the project:

- `ProfileSchema` / `ProfileMigration` — canonical persistent data and migrations;
- `ProfileService` — loaded-profile mutation boundary;
- `ProgressionService` — XP and level processing;
- `InventoryService` — persistent item mutation;
- `RewardService` / completion flow — idempotent persistent rewards;
- Base and Dungeon runtimes — real two-Place profile handoff;
- Combat server services — authoritative damage/hit/skill execution;
- Dungeon encounter/checkpoint/death services — run state and revive boundaries.

The Phase 2B schema revision should bump the profile schema from the accepted Phase 2A version and migrate existing TEST/DEV profiles idempotently.

## 5. Persistent character data

The selected character slot gains a `Progression` structure conceptually equivalent to:

```text
Progression
  Attributes
    Strength = 5
    Dexterity = 5
    Vitality = 5
    Intellect = 5
    Spirit = 5
  AttributePointEntitlement = 0
  Skills
    <SkillId>
      Known
      PurchasedRank
      Proficiency
      KnowledgeSourceItemId
      Archived
  SkillPointEntitlement = 0
  ActiveSkillLoadout = [up to 6 skill ids]
  RespecCounters
    Attributes = 0
    Skills = 0
  OneTimeRewards
    ArcSlashFirstClear = false
```

The exact field names may follow existing code conventions, but these semantics are required.

### 5.1 Derived balances

Do not persist a mutable authoritative `UnspentSP` value.

```text
Allocated SP = sum(cost of every currently purchased refundable skill rank)
Available SP = SkillPointEntitlement - Allocated SP
```

Likewise, unspent Attribute Points are derived from the character's entitlement and allocation above the immutable base values:

```text
Allocated AP = sum(max(0, AttributeValue - 5))
Available AP = AttributePointEntitlement - Allocated AP
```

Every server mutation validates that allocated totals can never exceed their entitlement.

### 5.2 Starter knowledge

For the Phase 2B prototype only:

- Mend Rank 1 is known/granted free;
- Shield Bash Rank 1 is known/granted free;
- neither free Rank 1 grant consumes SP;
- an ordinary Skill/SP respec cannot remove these free Rank 1 grants;
- their Rank 2+ purchases are refundable normally.

After Phase 2B, free starter skills come from the active class definition. Mend and Shield Bash are not universal permanent starter skills.

## 6. Levels, XP, AP and SP

### 6.1 Temporary level cap

Phase 2B uses a temporary maximum level of **10**.

A new Level 1 character has:

- 0 earned Attribute Points;
- 0 earned Skill Points.

Each level gained after Level 1 grants entitlement to:

- **+1 Attribute Point**;
- **+1 Skill Point**.

Therefore Level 10 implies lifetime level entitlement of **9 AP and 9 SP**, excluding future milestone bonuses.

At the temporary cap, further XP does not generate more levels/AP/SP and is not banked for a future cap increase.

### 6.2 Phase 2B XP table

Use an explicit table, not an extrapolating permanent formula:

| Transition | XP required |
|---|---:|
| 1 -> 2 | 100 |
| 2 -> 3 | 150 |
| 3 -> 4 | 200 |
| 4 -> 5 | 275 |
| 5 -> 6 | 350 |
| 6 -> 7 | 450 |
| 7 -> 8 | 575 |
| 8 -> 9 | 725 |
| 9 -> 10 | 900 |

These are test values and remain configuration.

### 6.3 Existing-profile entitlement migration

Existing Phase 2A characters receive missing AP/SP entitlement retroactively from their current level.

For each entitlement:

```text
minimum level entitlement = clamp(Level - 1, 0, 9)
new entitlement = max(existing valid entitlement, minimum level entitlement)
```

The migration is idempotent: running it repeatedly cannot mint additional points.

## 7. Attributes and derived combat stats

All five attributes start at **5**.

### 7.1 Phase 2B primary effects

- **Strength** — physical damage family: basic melee attacks and physical skills such as Shield Bash and Arc Slash.
- **Dexterity** — persisted/scaled through the shared attribute system; later drives finesse/ranged normal attacks and appropriate skills.
- **Vitality** — maximum HP.
- **Intellect** — persisted/scaled through the shared attribute system; later drives magic normal attacks and magical skills/effect potency.
- **Spirit** — healing and shielding effectiveness, including Mend.

Attributes must not alter movement speed, authored attack animation speed, dodge invulnerability duration or parry timing.

### 7.2 Phase 2B scaling values

Let `x` be points invested above the base value of 5.

Use this continuous soft-cap helper for Phase 2B:

```text
if x <= 15:
    effectiveInvestment = x
else:
    overflow = x - 15
    effectiveInvestment = 15 + overflow / (1 + overflow / 20)
```

This keeps the early investment linear and progressively reduces marginal gain after 15 invested points without a hard cap.

Prototype effects:

- Strength physical-damage multiplier = `1 + 0.02 * effectiveInvestment`;
- Spirit heal/shield multiplier = `1 + 0.02 * effectiveInvestment`;
- Vitality max HP = `100 + 5 * effectiveInvestment`;
- Dexterity and Intellect compute the same effective investment now, but Phase 2B does not invent placeholder ranged/magic attacks solely to consume those values.

These constants are configuration and may be tuned after playtesting.

### 7.3 Attribute spend transaction

Attribute UI uses **preview -> confirm**.

The client may stage several `+` changes locally. Confirm sends the desired allocation as one request. The server validates the complete resulting allocation and either commits all changes atomically or commits nothing.

## 8. Skill tiers, ranks and SP costs

Skill rank count is data-defined. The Phase 2B representative skills each expose three ranks only to prove the system.

| Tier | Rank 1 learn cost | Each normal rank-up |
|---|---:|---:|
| Common | 1 SP | 1 SP |
| Uncommon | 2 SP | 2 SP |
| Rare | 3 SP | 3 SP |
| Epic | 4 SP | 4 SP |
| Legendary | 5 SP | 5 SP |

A skill may override its tier default when a future design explicitly requires it.

### 8.1 Representative skills

**Mend**

- tier: Common;
- Phase 2B Rank 1: free starter grant;
- Rank 2/3 cost: 1 SP each;
- support/healing proficiency rules;
- normal ranks improve healing effectiveness while retaining the same core skill identity.

**Shield Bash**

- tier: Uncommon;
- Phase 2B Rank 1: free starter grant;
- Rank 2/3 cost: 2 SP each;
- physical/control proficiency rules;
- normal ranks improve damage/guard/stagger/control effectiveness without widening the frontal cone or making defensive timing easier.

**Arc Slash**

- tier: Rare;
- not known initially;
- Rank 1 requires the matching Skill Book + 3 SP;
- Rank 2/3 cost: 3 SP each;
- requires a `OneHandedSword`-compatible equipped weapon to activate;
- short committed frontal melee cleave;
- normal ranks improve physical damage/cleave effectiveness while keeping the same fundamental attack.

Normal ranks improve the existing ability. Major alternative behaviours/evolutions remain reserved for rare/hidden books or future augment systems.

## 9. Proficiency

### 9.1 Core rule

Proficiency is permanent, cumulative mastery data but **does not directly increase power**.

It only unlocks eligibility to buy the next normal rank with SP.

Flow:

```text
use skill meaningfully
-> earn proficiency
-> reach next threshold
-> proficiency caps
-> visit Base trainer
-> spend required SP
-> next rank becomes active
-> proficiency can continue toward the following threshold
```

### 9.2 Shared thresholds

| Tier | Rank 2 eligibility | Rank 3 eligibility |
|---|---:|---:|
| Common | 100 | 300 |
| Uncommon | 150 | 400 |
| Rare | 200 | 500 |
| Epic | 300 | 700 |
| Legendary | 400 | 900 |

Skills may override these values in their data definition.

Threshold totals are cumulative. Buying a rank does not reset proficiency to zero.

### 9.3 Cap behaviour

If the player reaches the next threshold but has not purchased that rank, proficiency remains exactly at that threshold and further use grants zero additional proficiency until the rank is purchased.

If a skill is fully refunded through an ordinary Skill/SP respec:

- earned proficiency is retained;
- the skill cannot gain further proficiency while unpurchased/inactive;
- relearning/repurchasing the skill immediately restores eligibility for any historical threshold already reached;
- every required rank must still be repurchased sequentially with SP.

### 9.4 Meaningful-contribution rules

Permanent proficiency is granted only by the server for eligible meaningful combat contribution.

**Mend**

- credit only actual missing HP restored;
- overheal provides zero credit;
- empty/self-manufactured/friendly-collusion loops provide zero or rejected credit;
- healing outside meaningful eligible combat provides no normal permanent proficiency.

**Shield Bash**

- valid hit on an eligible hostile grants base contribution;
- a meaningful interrupt, stagger, guard-break/guard-pressure or comparable threat prevention can grant a configured bonus;
- repeatedly striking an already-disabled target gives no repeated control bonus;
- bosses may award meaningful guard/stagger contribution even when immune to full stun.

**Arc Slash**

- only valid server-confirmed damage to eligible hostile targets contributes;
- first valid target receives full configured contribution;
- additional targets contribute diminishing configured amounts;
- multi-target positioning is rewarded but never linearly multiplied by enemy count.

### 9.5 Anti-farm controls

- Training dummies/Training Marauders used for safe testing are not permanent-proficiency sources.
- Dungeon Marauders and the Captain are Phase 2B eligible enemies.
- Eligibility is explicit server data/tagging rather than inferred from client state.
- Per-encounter/per-skill contribution caps and diminishing-repeat rules are configuration so one manufactured encounter cannot be farmed indefinitely.
- When later enemy-level scaling exists, trivial enemies can supply zero or sharply reduced permanent proficiency.

The exact contribution-unit tuning is not an acceptance gate; the eligibility, caps, threshold behaviour and exploit protections are.

### 9.6 DEV/TEST proficiency commands

Provide a server-authoritative test command surface for at least:

```text
/prof <SkillId> <non-negative value>
/prof <SkillId> next
/prof <SkillId> max
```

Requirements:

- enabled only in Studio/DEV/TEST;
- disabled in PROD regardless of client input;
- validates the skill ID/value;
- cannot grant SP or purchase a rank;
- respects the skill's maximum configured proficiency for the prototype;
- logs every test mutation clearly.

## 10. Trainer and Character Skills menu

### 10.1 Progression trainer

Phase 2B uses a temporary generic Base **Progression Trainer** implementing the service contract future class trainers will use.

The trainer handles permanent progression only:

- view/spend Attribute Points;
- view known/unlearned eligible skills;
- learn eligible Skill Books;
- view current rank, proficiency, next threshold and SP cost;
- purchase eligible skill ranks;
- Attribute respec;
- Skill/SP respec.

After the class/race system exists, every class has one main trainer with its own class/tree catalogue. Starter skills and teachable skills come from that class definition rather than hardcoded universal lists.

A Skill Book can only be consumed when the current trainer/catalogue and character requirements allow that skill.

### 10.2 Character -> Skills menu

Loadout management does **not** belong to the trainer.

The Character -> Skills menu:

- shows learned active skills;
- exposes six active-skill slots in Phase 2B;
- architecture must permit expansion to eight later;
- lets the player swap learned skills freely in Base;
- permits tactical swaps in a Dungeon only between cleared encounters;
- rejects swaps while an encounter is active;
- never permits unknown skills or duplicate invalid slot state.

Passives, when introduced, apply automatically after purchase and do not consume active slots unless a future design explicitly adds passive slots.

### 10.3 Auto-equip on learn

When a new active skill is learned:

- if a slot is empty, place it in the first empty slot automatically;
- if all six are occupied, do not overwrite anything;
- the player can later rearrange it through Character -> Skills.

Mend and Shield Bash keep their prototype default hotbar ordering unless the player changes it.

Cooldown ownership belongs to the skill, not the slot. Unequipping/re-equipping cannot refresh a cooldown.

## 11. Skill Book learning and Arc Slash first-clear proof

### 11.1 General Skill Book rule

Picking up a Skill Book does not automatically learn it.

Normal flow:

```text
own book
-> meet trainer/class/tree/other requirements
-> spend required SP
-> consume book atomically
-> mark skill known at Rank 1
-> auto-equip only if a hotbar slot is free
```

Normal Skill/SP respec does not return consumed books.

### 11.2 Bound Arc Slash test book

Phase 2B adds a character-bound Arc Slash Skill Book definition distinct from any future tradeable Arc Slash book. The item points to the same `ArcSlash` skill ID but carries its own binding/trade policy.

The Test Dungeon Captain grants this bound book as a **guaranteed one-time first-clear reward**.

The one-time flag and item grant must be one authoritative idempotent profile transaction. Replaying completion, reconnecting, failing a return teleport or clearing again cannot grant another guaranteed copy.

This guaranteed book is independent from ordinary/random completion loot and exists to prove the progression loop without RNG.

## 12. Respec model

### 12.1 Phase 2B testing policy

In DEV/TEST during Phase 2B, Attribute and Skill/SP respecs are free so builds can be exercised repeatedly. Their separate counters are still persisted and tested.

Live production pricing is not enabled in this phase.

### 12.2 Separate counters

- Attribute respecs increment only `RespecCounters.Attributes`.
- Skill/SP respecs increment only `RespecCounters.Skills`.
- A future combined `Both` action performs both operations and increments both counters.

Later live policy:

- first respec in each category is free;
- second and later uses of that category offer an increasing in-game currency price or a flat **49 Robux** option;
- choosing Both costs the sum of both in-game prices or **98 Robux**;
- a Robux-paid respec still increments that category's counter.

The exact in-game currency curve is deliberately deferred.

### 12.3 Attribute respec

Reset all five attributes to their immutable base value of 5. Because Available AP is derived from entitlement minus allocation, the points automatically become available again without minting new entitlement.

### 12.4 Skill/SP respec

For ordinary refundable skills:

- remove purchased refundable ranks;
- return the allocation implicitly by recalculating Available SP;
- keep consumed Skill Book knowledge;
- keep all earned proficiency;
- keep Phase 2B free starter Rank 1 access for Mend/Shield Bash;
- remove any now-unpurchased book skill from the active hotbar.

There is no direct `UnspentSP += refund` operation.

### 12.5 Future Robux Skill Book refund contract

Not activated in Phase 2B, but the data model must not block this later operation:

- genuinely unlearn the selected eligible Skill Book skill;
- remove all its purchased ranks;
- return the associated SP allocation by recomputation;
- remove it from the loadout;
- return the original consumed Skill Book item ID with its original binding/trade rules;
- archive proficiency permanently;
- relearning later restores archived proficiency but requires the book and every SP purchase again.

The player therefore cannot keep both learned knowledge and the returned sellable book.

### 12.6 Future Race Change contract

Race Change does not manufacture Skill Books. Incompatible race/class skill knowledge and proficiency are archived/deactivated. Returning to that race can restore archived knowledge/proficiency, while SP must be reinvested according to the then-valid build.

Race Change itself is outside Phase 2B implementation.

## 13. Combat integration

### 13.1 Strength

Strength must scale authoritative physical damage for:

- existing basic one-handed-sword melee attacks;
- Shield Bash health damage where classified physical;
- Arc Slash.

The Strength multiplier is applied server-side before final damage is committed. Client display may preview the result but never supplies authoritative damage values.

### 13.2 Spirit and Vitality

- Spirit scales authoritative Mend healing/shield-family values.
- Vitality changes authoritative character maximum HP and must be applied consistently on spawn/respawn without creating heal/HP duplication exploits.

### 13.3 Future Dexterity/Intellect hooks

Dexterity and Intellect are real persisted attributes from this phase. Future normal finesse/ranged attacks and normal magic attacks respectively use these same derived-stat boundaries rather than introducing parallel stat systems.

## 14. Automatic free revive correction

The accepted Phase 2A free revive changes from optional to automatic.

On a dungeon death while the member still owns the run's free revive:

1. consume the free revive atomically server-side at death;
2. enter a non-interactive **Reviving** state;
3. show a **3-second `Reviving...` countdown**;
4. do not show the optional free-revive button;
5. after three seconds, respawn at the latest activated checkpoint;
6. restore full HP and Stamina;
7. return the member to Active mode.

While an automatic free revive is pending, the player cannot intentionally remain dead to be carried through content. A full-party wipe must not fail the run while one or more valid automatic free revives are still pending. The forced `Reviving` state remains completion-reward eligible if the player was an eligible connected participant immediately before the death; the three-second forced transition must not make a player lose a completion reward if the encounter ends during that countdown.

After the free revive has been consumed, later deaths use the existing normal dead/spectating flow with paid-revive offer/Return to Base behaviour.

If the automatic respawn itself fails, fall back safely to the existing spectator/paid-revive boundary; never consume another free revive.

## 15. Remotes and mutation boundaries

Phase 2B adds focused remotes/interfaces rather than one unrestricted progression command.

Conceptual request boundaries:

- Attribute preview data is client-side only; confirmed allocation is validated server-side.
- `LearnSkillBook` — trainer/Base only.
- `PurchaseSkillRank` — trainer/Base only.
- `RespecAttributes` — trainer/Base only.
- `RespecSkills` — trainer/Base only.
- `SetActiveSkillLoadout` / slot swap — Base or Dungeon clear-window only.
- profile/progression snapshots are server -> client presentation data.

Every mutation returns a deterministic success/failure reason. Invalid requests preserve the previous valid profile state.

## 16. Failure and exploit handling

Required conservative behaviour:

- invalid AP allocation -> reject entire transaction;
- AP allocation above entitlement -> reject;
- insufficient SP -> no change;
- SP accounting inconsistency -> reject and log; never repair by granting loose SP;
- missing/wrong/duplicate Skill Book request -> no consumption/no skill grant;
- wrong trainer/class/tree requirement -> no learning;
- wrong weapon requirement -> learned skill remains known but activation fails;
- rank purchase below proficiency threshold -> reject;
- skipping a required earlier rank -> reject;
- proficiency at threshold without purchased rank -> stays capped;
- proficiency request from client -> never authoritative;
- duplicate one-time Captain Arc Slash grant -> no second item;
- repeated profile migration -> no duplicate AP/SP;
- invalid hotbar request -> keep previous valid loadout;
- encounter-active hotbar swap -> reject;
- DEV/TEST command in PROD -> reject/log;
- progression save/handoff failure before Dungeon teleport -> retain/reclaim Base authority using the accepted Phase 2A barrier;
- return teleport failure after saved progression -> progression remains committed and is not re-granted on Base join.

## 17. Testing requirements

Implementation follows the existing test-first guarded-patch workflow.

Automated coverage must include at least:

### Profile/migration/accounting

- new default profile has 5/5/5/5/5;
- Level 1 entitlement is 0 AP / 0 SP;
- Level 10 entitlement is 9 AP / 9 SP;
- Phase 2A profile migration adds missing Phase 2B fields;
- repeated migration is idempotent;
- XP cannot level beyond the temporary cap;
- Available SP can never exceed entitlement or be manufactured by respec;
- Available AP can never exceed entitlement.

### Attributes

- atomic preview/confirm validation;
- Strength affects basic melee and physical skills server-side;
- Vitality affects max HP;
- Spirit affects Mend;
- soft-cap helper is continuous and marginal gain diminishes after 15 invested points;
- movement/attack timing/dodge/parry windows remain unchanged.

### Skills and proficiency

- Mend/Shield Bash Rank 1 starter access is free and survives Skill/SP respec;
- tier SP costs resolve correctly;
- rank purchase requires previous rank + threshold + enough SP;
- proficiency does not change combat power by itself;
- proficiency caps at the next unpurchased threshold;
- buying a rank opens the following proficiency band without resetting total;
- proficiency survives ordinary respec;
- refunded skill ranks must be repurchased sequentially;
- Mend overheal gives no proficiency;
- Shield Bash control bonus cannot be repeated against already-disabled targets;
- Arc Slash multi-target proficiency diminishes after the first target;
- training targets grant no permanent proficiency;
- DEV/TEST proficiency commands work and PROD rejects them.

### Skill Book / reward / loadout

- Captain guaranteed Arc Slash book applies exactly once per character;
- reward survives save/reload/return failure;
- book consumption + SP spend is atomic;
- learning auto-equips into first free slot;
- full hotbar is never overwritten automatically;
- unknown/duplicate invalid hotbar states are rejected;
- swaps work in Base;
- swaps work between cleared Dungeon encounters;
- swaps fail during active encounters;
- cooldown cannot be reset by slot swapping.

### Respec

- Attribute and Skill respec counters are independent;
- each operation increments only its correct counter;
- Skill/SP respec does not return Skill Books;
- Skill/SP respec does not erase proficiency;
- starter Rank 1 grants remain;
- respec cannot create SP/AP.

### Automatic free revive

- first death consumes free revive exactly once;
- no optional free-revive request is required;
- three-second pending state precedes respawn;
- pending auto-revive prevents premature wipe failure;
- respawn uses latest checkpoint and full HP/Stamina;
- later death uses the existing paid/spectator flow;
- failed auto-respawn does not restore another free revive.

## 18. Manual Studio / published acceptance

Phase 2B is functionally accepted only after the following proof succeeds.

1. A fresh/test character starts Level 1 with 5/5/5/5/5, Mend Rank 1 and Shield Bash Rank 1.
2. XP gain produces exactly one AP + one SP entitlement per level.
3. Strength spending visibly increases authoritative basic sword damage.
4. Vitality spending increases max HP.
5. Spirit spending increases Mend healing.
6. Mend/Shield Bash gain valid proficiency and stop at their next unpurchased threshold.
7. DEV/TEST command can move proficiency to a test threshold without granting SP/rank.
8. Trainer can purchase an eligible next rank and persisted rank survives leave/rejoin.
9. Captain grants the bound Arc Slash Skill Book once.
10. Return to Base preserves the book.
11. Trainer consumes the book + 3 SP atomically and learns Arc Slash Rank 1.
12. Arc Slash auto-fills the first free active slot.
13. Character -> Skills can rearrange the six-slot loadout in Base.
14. Dungeon loadout swapping is blocked during an encounter and permitted after a room clears.
15. Arc Slash requires a compatible one-handed sword and gains diminishing multi-target proficiency.
16. Attribute and Skill/SP respecs work independently without creating AP/SP or erasing proficiency.
17. First dungeon death automatically enters a three-second revive countdown and returns to the latest checkpoint at full HP/Stamina.
18. Later death uses the post-free-revive defeated/spectating flow.
19. Complete Base -> Dungeon -> Base -> leave -> rejoin and confirm Level, XP, attributes, entitlement, ranks, proficiency, book/known-skill state, hotbar and respec counters are identical to the saved state.

A short published TEST pass is required for the cross-Place persistence/handoff portions; Studio remains the primary functional test environment for individual progression services and UI behaviour.

## 19. Phase 2B completion boundary

Phase 2B is complete when the acceptance proof above is green and the progression architecture is ready for real class/race definitions without schema replacement.

The next design slice can then choose the first real races/base classes and replace the temporary prototype starter/trainer catalogue with class-defined data.
