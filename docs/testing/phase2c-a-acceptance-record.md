# Phase 2C.A - Race + Character Identity Foundation

## Published TEST acceptance evidence

**Evidence date:** 9 September 2026

**Status:** ACCEPTED

**Branch:** `wip/phase-2c-a-race-identity`

**Reviewed local-green checkpoint:**

`d13c5b8f834ab9642b0fb3f629bf05f46616e543`

`docs: record phase 2c.a local green checkpoint`

## Published TEST targets

- Universe: `10765241947`
- Starting Base Place: `134132328219009`
- Dungeon Place: `117293035754309`
- Environment: `TEST`
- TEST profile store: `TEST_PlayerProfile_v1`
- Live paid revives: disabled
- PROD profile/DataStore path: not used
- Robux spend: none
- Task 13 monetisation changes: none

Both reviewed Task 13 Rojo candidates were published deliberately to the
existing TEST Base and Dungeon Places.

## New Elf published persistence proof

A fresh TEST profile was used for the Elf proof.

Observed published behaviour passed:

- mandatory race selection appeared;
- Elf was selected;
- Fighter was selected;
- character started at Level 1;
- baseline attributes were STR 5 / DEX 6 / VIT 4 / INT 5 / SPI 5;
- Elven Grace was present;
- Shield Bash was available;
- Mend was available;
- permanent pointed ears were visible in Base;
- published Base -> Dungeon teleport succeeded;
- Elf ears remained present in Dungeon;
- normal basic sword combat worked;
- Elf basic attack-rate behaviour worked;
- Block/parry worked;
- Dodge worked;
- Shield Bash worked;
- Mend worked;
- Dungeon completion and normal return to Base worked;
- Elf / Fighter identity remained correct after returning to Base;
- Elf baseline attributes remained correct after returning to Base;
- ears remained present after returning to Base;
- the player left the Experience completely;
- the player rejoined the published Starting Base;
- Elf / Fighter identity persisted;
- Elf baseline attributes persisted;
- Elven Grace persisted;
- ears persisted;
- Shield Bash and Mend persisted;
- earned progression persisted across Dungeon, Base return and rejoin.

Result:

**PASS**

## New Human published persistence proof

The TEST profile was reset after the Elf proof and reused as a genuinely fresh
TEST identity for the Human proof.

Observed published behaviour passed:

- mandatory race selection appeared;
- Human was selected;
- Fighter was selected;
- character started at Level 1;
- baseline attributes were STR 5 / DEX 4 / VIT 6 / INT 5 / SPI 5;
- Human Resolve was present;
- Shield Bash was available;
- Mend was available;
- published Base -> Dungeon teleport succeeded;
- normal basic sword combat worked;
- Human basic attack-rate behaviour worked;
- Block/parry worked;
- Dodge worked;
- Shield Bash worked;
- Mend worked;
- Dungeon completion and normal return to Base worked;
- Human / Fighter identity remained correct after returning to Base;
- Human baseline attributes remained correct after returning to Base;
- the player left the Experience completely;
- the player rejoined the published Starting Base;
- Human / Fighter identity persisted;
- Human baseline attributes persisted;
- Human Resolve persisted;
- Shield Bash and Mend persisted;
- earned progression persisted across Dungeon, Base return and rejoin.

Result:

**PASS**

## Sensitive published regression proof

A final published Dungeon regression pass was completed.

Observed behaviour passed:

- only one combat HUD/runtime presentation was present;
- published sword presentation and normal sword behaviour worked;
- only one Marauder Captain runtime appeared;
- the camera/view shield presentation remained visible;
- the character arm remained behind the shield during Block;
- the character arm remained behind the shield during Shield Bash;
- swept Dodge did not place the character under the floor;
- swept Dodge did not place the character inside a monster;
- the first death used the one free revive correctly;
- the second death returned to the normal defeated boundary;
- live paid revive remained unavailable/disabled;
- Return to Base remained available;
- the Arc Slash Skill Book appeared in Inventory;
- Arc Slash could be learned;
- Arc Slash could be placed in the loadout;
- Arc Slash knowledge/loadout persisted after leave and rejoin.

Result:

**PASS**

## Legacy Phase 2B published migration proof

The implementation plan originally requested one existing accepted Phase 2B
legacy character to be migrated in the published TEST environment.

The project owner deliberately waived that live proof for this gate because the
game is still pre-release, has no real players, and the TEST profiles contain
only disposable developer/test data.

This waiver does not remove the migration implementation or automated coverage.

Existing local automated coverage passed before publishing, including:

- Profile Schema/Migration - PASS: 43 assertions;
- Phase 2C.A Profile Migration - PASS: 38 assertions;
- Phase 2C.A Identity Service - PASS: 58 assertions;
- Attribute Service - PASS: 30 assertions;
- Character Combat Stats - PASS: 32 assertions.

The live legacy migration path must be revalidated before any future release
where existing real player profiles may require migration.

This is a deliberate acceptance-plan deviation, not evidence that the live
legacy migration path was exercised.

## Known non-blocking issue deferred to next patch

During the published Elf Dungeon run, the Arc Slash Skill Book was correctly
awarded and appeared in Inventory.

However, the Dungeon Completed reward summary did not list the Skill Book.

The project owner explicitly chose not to interrupt the Phase 2C.A acceptance
run for this presentation issue.

Deferred patch item:

- include awarded Skill Books in the Dungeon Completed reward summary.

Reward ownership/persistence itself passed; the defect is limited to the
completion-summary presentation observed in this run.

## Acceptance boundary

The following are green:

- local Phase 2C.A automated regression;
- local Base manual regression;
- local Dungeon manual regression;
- new Elf published TEST persistence;
- new Human published TEST persistence;
- Base -> Dungeon -> Base -> leave -> rejoin;
- published race presentation;
- published combat/runtime regressions;
- published death/free-revive boundary;
- Arc Slash inventory/learning/loadout persistence.

The following qualification is explicit:

- published legacy Phase 2B live migration proof was waived by the project owner
  for this pre-player TEST gate.

The following non-blocking patch item is explicit:

- Skill Book reward is omitted from the Dungeon Completed summary despite being
  correctly awarded to Inventory.

## Final acceptance

**ACCEPTED - 9 September 2026**

The project owner explicitly accepted Phase 2C.A after reviewing the local and
published TEST evidence.

Explicit acceptance statement:

`I accept Phase 2C.A`

The accepted gate includes the deliberate waiver of the published live Phase 2B
legacy-character migration proof for this pre-player TEST phase.

That waiver is limited to the current developer-only environment and does not
remove the requirement to perform a live migration proof before any future
release where real existing player profiles require migration.

The accepted gate also includes deferral of the known non-blocking Dungeon
Completed presentation issue:

- the Arc Slash Skill Book is correctly awarded;
- the Skill Book is present in Inventory;
- reward ownership/persistence works;
- the Dungeon Completed reward summary currently omits the Skill Book;
- that presentation defect is deferred to the next patch.

Phase 2C.A - Race + Character Identity Foundation is **ACCEPTED**.

Merge to `main` remains a separate deliberate action.

Push remains a separate deliberate action.
