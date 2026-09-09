# DungeonMMO Current Engineering State

**State date:** 9 September 2026
**Canonical long-form roadmap:** external Roadmap v1.30
**Current phase:** Phase 2C
**Current gate:** Phase 2C.B - Equipment + Trainer Architecture
**Phase 2C.B status:** ACCEPTED - MERGED LOCALLY / PUSH PENDING
**Phase 2C.A status:** ACCEPTED / MERGED / PUSHED
**Phase 2B status:** FUNCTIONALLY COMPLETE

## Accepted baseline

- Phase 1 combat: ACCEPTED.
- Phase 2A Base-to-Dungeon vertical slice: ACCEPTED.
- Phase 2B.A/B/C: ACCEPTED.
- Phase 2B functionally complete.
- Phase 2C.A Race + Character Identity Foundation: ACCEPTED.
- Formal Phase 2C.A acceptance checkpoint:
  `ad3685be4a507f00e0b08bf8d948a41ecfa80b47`.
- Accepted Phase 2C.A merge / current `main` and `origin/main`:
  `19f8c31284da80dc87cf5d44560d366e48427888`
  (`merge: accept phase 2c.a race identity foundation`).
- Local main, origin/main and GitHub server main ref were verified equal at
  that commit with 0/0 ahead-behind.

## Phase 2C.A accepted evidence retained

Published TEST acceptance passed for both fresh Human/Fighter and Elf/Fighter
through Base -> Dungeon -> Base -> leave -> rejoin, including identity,
racial baseline/passive, starter skills, progression persistence, and Elf race
presentation. Sensitive runtime regressions also passed: one combat HUD,
published sword, one Marauder Captain, shield presentation/arm position,
swept Dodge clearance, first free revive, later defeated boundary, and Arc
Slash Skill Book inventory/learning/loadout/rejoin persistence.

Detailed acceptance record:
`docs/testing/phase2c-a-acceptance-record.md`.

## Accepted qualification carried forward

The live published Phase 2B legacy-character migration proof was explicitly
waived only for the pre-player TEST gate. Automated migration coverage remains
green. A live migration proof is still mandatory before any release involving
real existing player profiles.

## Deferred patch item carried into Phase 2C.B

The Arc Slash Skill Book is correctly awarded, appears in Inventory and
persists, but is omitted from the Dungeon Completed reward summary. Phase 2C.B
fixes only that presentation path; reward grant/persistence logic remains
accepted.

## Phase 2C.B approved design

The project owner approved Phase 2C.B on 9 September 2026.

Locked equipment slots:

- Weapon
- OffHand
- Helmet
- Body
- Gloves
- Boots

The approved gate establishes schema-v5 persistent equipment,
server-authoritative Base-only equip/unequip, race/class/slot eligibility,
data-driven trainer catalogues, Human/Elf Fighter trainer proof, functional
equipment/trainer UI, and the deferred completion-summary fix.

No level/attribute equipment requirements, unique rolled item instances,
durability, full gear-stat balance, advanced classes, economy/trading or
combat-visual replacement are part of this gate.

Approved design:
`docs/superpowers/specs/2026-09-09-phase-2c-b-equipment-trainer-architecture-design.md`.

Implementation plans:
- `docs/superpowers/plans/2026-09-09-phase-2c-b-a-equipment-foundation-implementation.md`
- `docs/superpowers/plans/2026-09-09-phase-2c-b-b-trainer-ui-reward-implementation.md`

## Important schema-v5 migration guard

When ProfileSchema advances from v4 to v5, accepted schema-v4 Phase 2C.A
profiles MUST NOT be reclassified as legacy Phase 2B profiles.

Only pre-v4 profiles use the one-time legacy race-selection path.
Schema-v4/v5 identities use the accepted v4 identity sanitizer.

## Experience composition / safety

- Local primary repo:
  `C:\Users\Remko\Documents\Roblox\DungeonMMO`
- `base.project.json` = Starting Base.
- `default.project.json` = Test Dungeon.
- Universe: `10765241947`.
- Starting Base: `134132328219009`.
- Dungeon: `117293035754309`.
- Environment: TEST.
- Live paid revives: disabled.
- No PROD / Robux / monetisation action is authorized by this gate.

## Separate art work

`art/dungeon-environment-prototype` remains isolated and untouched. Never
switch to, merge, reset, clean, pop/apply stash from, or copy it into gameplay.

## Exact next engineering action

Create isolated branch/worktree:

`wip/phase-2c-b-equipment-trainers`

from exact accepted baseline:

`19f8c31284da80dc87cf5d44560d366e48427888`.

Install the approved spec/plans and RED contract tests only. Build a TEMP Base
candidate and observe the expected RED failures in Roblox Studio before writing
Phase 2C.B production code.

Do not claim Phase 2C.B implementation green or accepted yet.
## Phase 2C.B implementation candidate

The current uncommitted worktree contains schema-v5 six-slot equipment,
Base-only server-authoritative equip/unequip, race/class/slot restrictions,
read-only Dungeon equipment snapshots, the FighterTrainer catalogue,
catalogue-driven trainer UI, functional Equipment UI, and the targeted
Dungeon Completed Arc Slash Skill Book summary presentation fix.

No GREEN or acceptance claim is made until fresh Studio evidence is reviewed.
## Phase 2C.B GREEN evidence

Fresh Base and Dungeon Studio validation completed on 9 September 2026.

Base evidence:
- all eight Phase 2C.B RED contract families moved to GREEN;
- schema-v5 migration remained green alongside Phase 2B and Phase 2C.A migration;
- Equipment Slots, Equipment Rules and Equipment Service passed;
- trainer catalogue, trainer authority and remote contracts passed;
- Completion Reward Presentation passed;
- accepted progression, inventory, identity, race-presentation and combat-stat regressions remained green;
- Human/Fighter functional equipment and Fighter Trainer checks passed;
- Human TEST Elven Helmet correctly rejected with RaceRestricted;
- Elf/Fighter functional equipment and Fighter Trainer checks passed;
- Elf TEST Elven Helmet was eligible/equippable;
- Elf race presentation remained correct.

Dungeon evidence:
- existing combat, shield, dodge, Mend, Marauder, Captain, revive, reward,
  progression and dungeon-session regression families remained green;
- live Studio playthrough completed through Marauder Captain defeat;
- completion rewards committed and the return window opened normally;
- the newly awarded Arc Slash Skill Book was shown in the Dungeon Completed
  reward summary;
- no equipment mutation was added to the Dungeon.

This is a GREEN candidate, not yet the formal accepted Git checkpoint.

The pre-player-only live legacy migration waiver still applies. A real
migration proof remains mandatory before any release involving existing live
player profiles.
## Phase 2C.B acceptance

The project owner explicitly accepted Phase 2C.B on 9 September 2026 after the
fresh Base and Dungeon GREEN evidence and manual functional/visual checks.

Accepted scope:
- schema-v5 persistent equipment;
- Weapon / OffHand / Helmet / Body / Gloves / Boots;
- safe schema-v4 Phase 2C.A identity migration;
- Base-only server-authoritative equip/unequip;
- data-driven race/class/slot equipment eligibility;
- read-only Dungeon equipment state;
- FighterTrainer catalogue authority;
- catalogue-driven trainer UI;
- functional six-slot Base equipment UI;
- Dungeon Completed Arc Slash Skill Book summary presentation fix.

The live legacy-profile proof remains waived only for this pre-player TEST
stage. A real legacy migration proof remains mandatory before any future
release involving existing live player profiles.

This acceptance does not authorize merge, push, Roblox publish, PROD or Robux
actions. Those remain separate deliberate gates.
## Phase 2C.B local merge

The accepted Phase 2C.B checkpoint
`fd0d73df70b97efc4b3fb241e2fc6e5061a3ed47` has been deliberately merged
into local `main` from the accepted Phase 2C.A baseline
`19f8c31284da80dc87cf5d44560d366e48427888`.

Gameplay/source content is unchanged relative to the accepted Phase 2C.B
checkpoint. Only continuity documents record the new local integration state.

Push remains a separate explicit gate. No Roblox publish, PROD, Robux,
monetisation or art-branch action is part of this local merge.
