# Phase 2C.B — Equipment + Trainer Architecture Design

**Date:** 9 September 2026
**Status:** DESIGN APPROVED IN CHAT — WRITTEN SPEC AWAITING USER REVIEW
**Starting baseline:** `19f8c31284da80dc87cf5d44560d366e48427888`
**Accepted Phase 2C.A checkpoint:** `ad3685be4a507f00e0b08bf8d948a41ecfa80b47`

## 1. Purpose

Phase 2C.B establishes the first persistent, server-authoritative equipment system and replaces the temporary hard-coded progression trainer with data-driven trainer catalogues.

This gate proves architecture rather than attempting to build the final content catalogue. It must preserve all accepted Phase 1, Phase 2A, Phase 2B and Phase 2C.A behaviour.

The gate deliberately avoids pulling advanced classes, full gear balance, procedural item rolls, durability, trading/economy, monetisation, large-scale content production or final visual polish into scope.

## 2. Locked equipment slots

Phase 2C.B supports these six equipment slots:

- `Weapon`
- `OffHand`
- `Helmet`
- `Body`
- `Gloves`
- `Boots`

The currently existing `Weapon`, `OffHand`, and `Body` item definitions remain valid. `Helmet`, `Gloves`, and `Boots` are added as first-class equipment slots now so the persistent schema and service boundary do not need to be redesigned later.

## 3. Equipment eligibility model

Equipment definitions remain data-driven in `ItemDefinitions`.

For Phase 2C.B, an equipment item may define:

- `Kind = "Equipment"`
- `Slot`
- `Category`
- allowed base classes and/or classes
- optional allowed races
- rarity and existing inventory properties

Examples:

- Marauder Sword → `Weapon`, category `Sword`, allowed for Fighter
- Marauder Shield → `OffHand`, category `Shield`, allowed for Fighter
- Marauder Armour → `Body`, category `HeavyArmor`, allowed for Fighter
- representative Helmet / Gloves / Boots items → matching slot and Fighter-compatible armour category

Phase 2C.B does **not** add minimum level requirements or minimum attribute requirements. The eligibility API must be structured so these can be added later without changing its public contract.

The server is the sole authority on whether an item can be equipped.

## 4. Persistent profile model

The profile schema advances from v4 to v5.

Each character gains a persistent `Equipment` table with exactly the six supported slots:

```luau
Equipment = {
    Weapon = nil,
    OffHand = nil,
    Helmet = nil,
    Body = nil,
    Gloves = nil,
    Boots = nil,
}
```

Each slot stores the equipped `ItemId` for this vertical slice.

Existing v4 profiles migrate safely to v5 with empty equipment slots. No inventory item, progression value, race/class identity, skill state, AP/SP entitlement, reward history or dungeon progress is removed or altered by this migration.

Migration is idempotent.

Unique item instances, random affixes and durability are intentionally deferred. If later equipment requires unique instances, the profile representation may evolve through a future migration while retaining the Phase 2C.B service boundary.

## 5. Equipment service

Add a dedicated server-side `EquipmentService`.

Responsibilities:

- validate user/profile/character state;
- validate that the requested slot exists;
- validate that the item exists in `ItemDefinitions`;
- validate `Kind == "Equipment"`;
- validate the item's declared slot matches the requested slot;
- validate that the player owns at least one copy in Inventory;
- validate race/base-class/class eligibility;
- persist equip/unequip atomically through `ProfileService`;
- return stable failure reasons for client presentation;
- expose a sanitized equipment snapshot for UI/runtime use.

Representative failure reasons should include:

- `ProfileNotLoaded`
- `IdentityIncomplete`
- `UnknownEquipmentSlot`
- `UnknownItem`
- `NotEquipment`
- `WrongSlot`
- `ItemNotOwned`
- `RaceRestricted`
- `ClassRestricted`
- `BaseOnlyAction`

The client must never be able to equip an item by changing local UI state alone.

## 6. Where equipment can change

Equipment changes are Base-only for Phase 2C.B.

Players may:

- equip owned items in Base;
- unequip items in Base;
- enter a Dungeon with their currently persisted equipment.

Players may **not** equip or swap equipment during an active Dungeon run.

Dungeon rewards may still add equipment to Inventory, but newly looted equipment becomes usable only after return to Base.

This follows the existing dungeon-loadout philosophy and keeps dungeon combat state deterministic.

## 7. Runtime/combat boundary

Phase 2C.B proves equipment ownership, persistence and authority before replacing accepted combat presentation.

Therefore:

- the accepted prototype sword/shield combat presentation remains intact;
- actual equipped item meshes do not yet replace the accepted prototype visual pipeline;
- broad gear-stat balancing is not introduced;
- equipment-specific damage/defence formulas are not required to accept this gate.

The EquipmentService and snapshots must, however, expose sufficient information for later combat/stat integration without another architecture rewrite.

## 8. Trainer catalogue architecture

The current generic trainer and hard-coded `ArcSlash` teach boundary are replaced with data-driven trainer catalogues.

Add a shared trainer catalogue definition module with stable trainer IDs.

A trainer catalogue entry can declare:

- trainer ID;
- display name;
- allowed race(s), if any;
- allowed base class(es) / class(es);
- skills it can teach or rank;
- whether a skill requires an item such as the Arc Slash Skill Book;
- optional future metadata such as location/presentation identifiers.

Phase 2C.B should include at least a Fighter trainer catalogue that works for both current Human Fighter and Elf Fighter characters.

The catalogue architecture must support future race-specific trainers and advanced-class trainers without changing the client/server interaction contract.

## 9. Trainer authority

The server must determine trainer availability from:

1. the trainer ID being interacted with;
2. the player's persistent identity;
3. the trainer catalogue;
4. the existing skill progression state;
5. existing SP, proficiency and Skill Book requirements.

The trainer catalogue decides **what may be offered by that trainer**.

Existing progression services remain responsible for whether the character can actually purchase/learn/rank the skill.

The existing Arc Slash flow remains valid:

- Arc Slash requires the bound Arc Slash Skill Book;
- learning consumes the required book and SP atomically;
- existing knowledge/loadout persistence remains unchanged.

Hard-coded logic equivalent to “only ArcSlash is teachable here” must be removed from the Base controller boundary and replaced with catalogue-based authorization.

## 10. Trainer UI

The Base trainer UI becomes catalogue-driven.

It must no longer hard-code:

- `Mend`
- `ShieldBash`
- `ArcSlash`

as a fixed client list.

Instead, the client receives or derives the current trainer catalogue snapshot and renders the skills the server says this trainer may offer.

For the Phase 2C.B functional UI:

- trainer name is shown;
- eligible skills are shown;
- rank/proficiency/SP/book requirements remain visible;
- unavailable actions are visibly disabled;
- server rejection reasons are surfaced in the status text.

Final art/polish is not part of this gate.

## 11. Equipment UI

Add a functional Base-only equipment interface sufficient to prove the architecture.

It must show:

- the six equipment slots;
- the currently equipped item in each slot;
- owned compatible equipment available to equip;
- equip action;
- unequip action;
- a clear reason when an item is ineligible.

The first version may be utilitarian. It must be readable and usable, but final MMO-quality art is deferred.

This is the first point at which the user should be asked for a visual/manual check after automated work is green.

## 12. Representative item content

Phase 2C.B needs only enough items to prove all six slots and restriction logic.

Existing equipment remains:

- Marauder Sword
- Marauder Shield
- Marauder Armour

Add representative functional items for:

- Helmet
- Gloves
- Boots

At least one automated test item may be deliberately class- or race-restricted so rejection paths are proven without expanding the public content catalogue unnecessarily.

No large item-content pass is required.

## 13. Deferred Dungeon Completed Skill Book presentation bug

Carry forward the accepted non-blocking Phase 2C.A issue:

- Arc Slash Skill Book is correctly granted;
- it appears in Inventory;
- ownership/persistence passed;
- it is omitted from the Dungeon Completed reward summary.

Phase 2C.B includes a targeted presentation fix so the completion summary lists the Skill Book when it is awarded.

The reward grant logic must not be rewritten merely to fix this display issue.

## 14. Remotes and snapshots

Extend the existing Core remote boundary with explicit server-authoritative equipment actions.

Expected actions include:

- equipment snapshot/update;
- equip request;
- unequip request;
- equipment action result;
- trainer catalogue/snapshot if needed by the final implementation structure.

All remote requests are treated as untrusted input.

The server validates item ID, slot, trainer ID and all eligibility state.

## 15. Runtime composition

`RuntimeServices` gains the EquipmentService and any trainer catalogue/authorization service that requires server state.

Base runtime wires:

- EquipmentService;
- trainer catalogue authorization;
- equipment remotes;
- trainer catalogue remotes/UI state.

Dungeon runtime consumes equipment snapshots as read-only run state where needed, but does not permit equipment mutation.

## 16. Migration and compatibility

Required automated migration coverage:

- fresh v5 profile has all six empty equipment slots;
- v4 Phase 2C.A character migrates to v5;
- migration preserves RaceId/BaseClassId/ClassId;
- migration preserves racial attributes;
- migration preserves Level/XP/Gold;
- migration preserves Inventory;
- migration preserves skill knowledge/ranks/proficiency/loadout;
- migration preserves AP/SP entitlement;
- migration preserves one-time rewards;
- migration preserves respec counters;
- repeated migration is idempotent;
- malformed/missing Equipment data is normalized safely.

The existing pre-player legacy live-migration waiver remains exactly as previously accepted: it does not become a permanent waiver. A live migration proof is still required before a future release involving real existing player profiles.

## 17. Automated test requirements

Phase 2C.B should not wait for manual checking to discover backend failures.

Automated coverage should include:

### Equipment definitions
- all six slots accepted;
- invalid slot rejected;
- equipment definitions validate required fields;
- non-equipment items cannot be equipped.

### Equipment service
- owned compatible item equips;
- unequip works;
- wrong-slot equip rejected;
- unowned item rejected;
- class-restricted item rejected;
- race-restricted item rejected;
- incomplete identity rejected;
- Dungeon-context mutation rejected;
- persisted equipment survives profile reload;
- repeated equip is idempotent/no duplication;
- inventory quantity is not accidentally consumed by equip.

### Trainer catalogues
- Fighter trainer resolves for Human Fighter;
- Fighter trainer resolves for Elf Fighter;
- invalid trainer rejected;
- incompatible class/race catalogue rejected;
- catalogue lists expected skills;
- Arc Slash still respects book + SP requirement;
- rank purchases still respect proficiency/SP;
- client cannot teach an arbitrary skill outside the catalogue.

### Regression
- Phase 2C.A identity/race presentation;
- profile migration;
- attribute progression;
- skill progression;
- loadout;
- Base-to-Dungeon admission;
- core combat;
- dungeon completion/reward;
- free revive/defeat boundary;
- accepted sword/shield presentation contracts.

Both `base.project.json` and `default.project.json` must build to timestamped TEMP outputs.

`git diff --check` must remain clean.

## 18. Manual/visual acceptance checkpoint

The user is not required for backend micro-steps.

The first planned user check occurs only after:

- schema v5 migration is green;
- EquipmentService tests are green;
- trainer catalogue tests are green;
- Base/Dungeon regression families are green;
- both Rojo builds succeed;
- functional trainer UI is wired;
- functional equipment UI is wired.

The user then checks in Roblox Studio:

- six visible equipment slots;
- equip/unequip flow;
- clear rejected-item messaging;
- trainer shows catalogue-driven skills;
- Human Fighter trainer behaviour;
- Elf Fighter trainer behaviour;
- no obvious duplicate UI/runtime presentation;
- no red runtime errors.

Further manual checks are requested only if a behaviour cannot be proven reliably by automated tests.

## 19. Git and environment safety

Phase 2C.B development starts from:

`19f8c31284da80dc87cf5d44560d366e48427888`

The separate:

`art/dungeon-environment-prototype`

branch/worktree remains isolated and untouched.

Do not:

- develop directly on main;
- merge without explicit approval;
- push without explicit approval;
- publish Roblox without explicit approval;
- use PROD DataStores;
- enable live paid revives;
- spend Robux;
- alter monetisation;
- apply art-branch stash/work to gameplay.

Validation builds go to TEMP and must never overwrite the normal `DungeonMMO.rbxl`.

## 20. Repository continuity maintenance

Before Phase 2C.B source implementation, update the stale repository continuity documents so they match the real accepted baseline:

- `AGENTS.md`
- `docs/ai/CURRENT_STATE.md`
- `docs/ai/HANDOFF.md`
- `docs/ai/TEST_MATRIX.md`

They must record:

- Phase 2C.A accepted;
- acceptance checkpoint `ad3685be4a507f00e0b08bf8d948a41ecfa80b47`;
- merged/pushed main baseline `19f8c31284da80dc87cf5d44560d366e48427888`;
- Phase 2C.B as active next gate;
- legacy live-migration waiver scope;
- deferred Skill Book summary fix;
- separate art branch remains isolated.

The external Roadmap v1.30 remains the current long-form roadmap source until deliberately superseded.

## 21. Acceptance boundary

Phase 2C.B is ready for user acceptance only when:

- six-slot persistent equipment architecture is implemented;
- schema migration is green;
- server-authoritative equip/unequip is green;
- class/race/slot restrictions are enforced;
- Base-only equipment mutation is enforced;
- trainer catalogues replace hard-coded trainer skill lists;
- Human/Elf Fighter trainer paths work;
- functional equipment UI passes manual check;
- functional trainer UI passes manual check;
- Skill Book completion-summary presentation defect is fixed;
- Base and Dungeon builds pass;
- selected accepted regression families remain green;
- no PROD/Robux/monetisation path was used;
- explicit user acceptance is received.

Merge, push and any Roblox publishing remain separate explicit approvals.
