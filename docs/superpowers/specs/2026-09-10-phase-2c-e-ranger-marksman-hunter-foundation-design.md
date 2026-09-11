# Phase 2C.E Ranger Marksman-Hunter Foundation Design

**Project:** DungeonMMO
**Date:** 10 September 2026
**Status:** APPROVED design direction; implementation candidate only until fresh Studio evidence
**Baseline:** `86d27228977dd6c98bd404f12086e93ad94fbe9a`
**Canonical roadmap:** DungeonMMO Roadmap v1.33

## 1. Purpose

Phase 2C.E proves Ranger as the remaining Phase 2 starting archetype without reopening accepted Fighter or Mage architecture. Human and Elf may start as Ranger, receive one Apprentice Longbow, use a server-authoritative held basic attack, and begin with Piercing Shot, Crippling Shot and Volley.

The gate deliberately proves five missing contracts: held ranged basics, Dexterity-led physical ranged scaling, race-modified Ranger skill behaviour, two-handed equipment slot reservation, and a server-owned slow respected by manually moved enemies.

## 2. Locked player-facing identity

Ranger is a marksman-hunter hybrid. It is more mobile than Mage while attacking, but does not receive a redundant Backstep because Dodge is already universal.

The starter kit is:

- free Longbow basic attacks;
- Piercing Shot: high-impact line penetration;
- Crippling Shot: damage plus movement slow;
- Volley: ground-targeted initial impact plus short arrow rain.

Ranger active skills use Stamina. Basic arrows consume no Stamina and no ammunition item.

## 3. Longbow basic attack

The server owns draw time and shot result. Client input communicates only `DrawStart`, `DrawRelease` and `DrawCancel` intent.

- short draw: normal arrow;
- Precision threshold: 0.45 s;
- Full Draw threshold: 0.80 s;
- longer holding grants no additional benefit;
- draw movement scale: 0.60;
- Dodge cancels draw with no shot;
- Block cancels draw with no shot;
- normal / Precision / Full damage multipliers: 1.00 / 1.25 / 1.50;
- normal / Precision / Full bonus critical chance: 0 / +5% / +10%;
- base damage: 16;
- projectile speed: 110 studs/s;
- max range: 80 studs.

The fixed 0.45/0.80 thresholds are not shortened by racial basic-attack rate. Accepted racial attack-rate scaling applies only to the brief release/recovery timing after the draw.

## 4. Ranger scaling and race differences

Ranged physical damage uses effective Dexterity with the same diminishing-return shape already used by accepted attributes. It does not replace Fighter Strength scaling.

The existing critical model still owns base/racial/equipment critical chance and Human critical-damage bonus. Precision/Full Draw adds temporary shot-specific critical chance on top, server-side.

Human and Elf use the same three Ranger skill IDs. Race modifies selected behaviour rather than creating separate skill trees in this gate:

- Human Piercing Shot retains 80% damage after each penetration;
- Elf/default Piercing Shot retains 70%;
- Human Crippling Shot applies a 30% slow for 3 s;
- Elf Crippling Shot applies a 40% slow for 4 s;
- Volley has no race-specific variant in this gate.

## 5. Starter skills

### Piercing Shot

- Stamina: 20;
- cooldown: 6 s;
- base damage: 28;
- range: 80 studs;
- projectile speed: 125 studs/s;
- maximum targets: 4;
- first target takes full damage;
- each later target uses multiplicative retention;
- no stagger or armour-break effect.

### Crippling Shot

- Stamina: 20;
- cooldown: 7 s;
- base damage: 18;
- range: 75 studs;
- projectile speed: 115 studs/s;
- server applies/refreshes one Ranger slow; it never multiplies with itself.

### Volley

- Stamina: 30;
- cooldown: 10 s;
- maximum target distance: 60 studs;
- radius: 10 studs;
- initial impact: 14 base damage;
- three follow-up pulses: 7 base damage each;
- pulse interval: 0.50 s;
- total stationary base damage: 35;
- Volley does not critically strike in this first gate;
- each pulse independently checks current occupants, so moving out is meaningful;
- client supplies only aim intent; server clamps range and resolves a valid ground point.

## 6. Two-handed equipment reservation

`apprentice_longbow` is a persistent Weapon item with `WeaponTags={"Longbow"}` and `ReservedSlots={"OffHand"}`.

Reservation is generic item metadata, not a Longbow special case. The accepted six-slot schema remains unchanged.

- equipping Longbow while OffHand is occupied rejects with `ReservedSlotOccupied`;
- equipping an OffHand item while Longbow reserves OffHand rejects with `SlotReserved`;
- swapping Weapon away from Longbow releases OffHand;
- no automatic silent unequip occurs;
- if malformed saved/runtime state contains Longbow plus OffHand, combat stat resolution ignores the reserved OffHand so malformed state fails neutral rather than granting extra effects.

## 7. Combat and movement authority

The visible bow/arrow never grants authority. Persistent Equipment and the Dungeon run snapshot own `Longbow` eligibility.

Ranger draw exists alongside the accepted combat state machine. While the player is otherwise in Locomotion and a server-authoritative Longbow is equipped, a held draw applies the 0.60 movement scale. Release enters a short server-owned WindUp/Active/Recovery sequence and fires from server-observed facing.

Skills are rejected while an unfinished draw exists. Block, Dodge, death, respawn and player removal clear draw state.

Normal Marauders and the Marauder Captain use manual movement rather than Humanoid WalkSpeed. Crippling Shot therefore writes a server-owned slow state read by both movement controllers. It does not temporarily overwrite a Humanoid speed that their AI would ignore.

## 8. Presentation scope

Functional only:

- simple Apprentice Longbow model;
- visible server-spawned arrow projectiles;
- small draw indicator with Normal / Precision / Full state;
- functional Volley ground marker/rain;
- Equipment UI shows OffHand as reserved/locked while Longbow is equipped;
- Ranger appears in class selection and trainer/loadout UI.

Final bow mesh, animations, arrow VFX, audio, HUD art and skill effects remain later art/polish work.

## 9. Persistence and compatibility

Ranger uses the accepted schema-v5 identity/progression/inventory/equipment structures. No schema bump is introduced. Fresh Human/Elf Ranger receives starter skills exactly once and one Apprentice Longbow through the existing IdentityService starter grant path.

Existing Fighter/Mage characters remain unchanged. No class switching, secondary advancement, ammunition inventory, quivers, crafting, special arrows, poisons or broad Ranger tree enters this gate.

## 10. Acceptance boundary

Candidate acceptance requires:

1. exact baseline/worktree and `git diff --check` verification;
2. fresh TEMP Base and Dungeon Rojo builds;
3. focused Ranger runtime tests where available;
4. Base Studio proof of Human/Elf Ranger selection, starter kit, Longbow equipment and OffHand reservation;
5. Dungeon Studio proof of normal/Precision/Full Draw, reduced draw movement, Dodge/Block cancel, Piercing penetration, Human retention, Crippling slow with stronger Elf version, Volley zoning and ordinary completion;
6. Fighter/Mage spot regressions remain intact;
7. no PROD, Robux, monetisation, publish or art-worktree action.

Until fresh Studio output is observed, the package is an implementation candidate and runtime GREEN must not be claimed.
