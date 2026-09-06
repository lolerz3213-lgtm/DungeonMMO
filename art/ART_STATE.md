# DungeonMMO Art Pipeline State

## Current branch
art/dungeon-environment-prototype

## Base gameplay checkpoint
ebf9740 - fix: refresh progression HUD after authoritative mutations

Gameplay acceptance state is unchanged.
Gate 2B.B remains NOT ACCEPTED.
This branch is environment-art work only.

## Completed

### Blender capability
Blender 5.0:
C:\Program Files\Blender Foundation\Blender 5.0\blender.exe

Blender automation has been proven working.

Smoke-test asset created:
- art/generated/blender_smoke_test/FantasyStonePillar.blend
- art/generated/blender_smoke_test/FantasyStonePillar.glb
- art/generated/blender_smoke_test/FantasyStonePillar_preview.png

### Reference system
12 Iron Soul Dungeon reference images were found and analysed.

Completed:
- art/references/REFERENCE_MANIFEST.json
- art/references/DUNGEON_STYLE_GUIDE.md
- art/references/reference_contact_sheet.jpg
- art/references/analysis/01.jpg through 12.jpg
- art/scripts/references/scan_references.py

The 12 existing references MUST NOT be re-analysed during normal future runs.

Future reference workflow:
- scan for NEW or CHANGED images;
- analyse only those;
- update manifest/style guide/contact sheet incrementally.

### Reusable library
Created:
- art/library/ASSET_CATALOG.md

The permanent reuse-first rule applies:
1. read ASSET_CATALOG.md;
2. reuse existing assets;
3. create variants when suitable;
4. create new assets only when required;
5. add reusable new assets back to the catalogue/library.

## NOT YET COMPLETED

The Codex run hit its usage limit BEFORE dungeon modelling began.

These DO NOT exist yet:
- Dungeon_Master_Kit.blend
- TemplateCombatChamber_A.blend
- reusable dungeon architecture GLBs
- TemplateCombatChamber_A room exports
- combat chamber preview renders
- Roblox Studio import
- Roblox lighting/VFX pass
- Roblox Play-mode visual review

DO NOT restart reference analysis.
DO NOT recreate the Blender smoke test.

## NEXT ACTION

Resume directly with Blender environment creation.

First:
1. read art/references/DUNGEON_STYLE_GUIDE.md;
2. read art/library/ASSET_CATALOG.md;
3. verify the reference manifest reports the existing 12 references as unchanged;
4. continue with Dungeon_Master_Kit.blend.

Then create reusable architecture including appropriate:
- pillars;
- arches;
- walls;
- floor modules;
- stairs;
- door frames;
- wooden beams/supports;
- ceiling structures;
- props/details.

Then assemble:
TemplateCombatChamber_A

Render:
- entrance;
- centre;
- reverse;
- elevated overview.

Perform at least one visual iteration.

Only after the Blender room reaches a worthwhile quality level:
- export sensible architectural chunks;
- import into a safe Roblox Studio place;
- add lighting/atmosphere/VFX;
- visually test at player eye level.

## Quality target

The Iron Soul Dungeon screenshots are a QUALITY and LOOK benchmark.

Create original DungeonMMO art.

Prioritise:
- architectural richness;
- silhouettes;
- proportions;
- layering;
- composition;
- depth;
- premium visual appeal;
- strong environmental presentation.

A pristine/template dungeon is acceptable.
Weathering/damage is optional, not the main quality criterion.

## Restrictions

Do not:
- modify gameplay source;
- work on gameplay bugs;
- alter Gate 2B.B acceptance;
- publish Roblox places;
- merge gameplay WIP into this branch.

## Resume rule

Future AI sessions MUST continue from this file.

Completed stages should only be repeated if:
- their required files are missing/broken; or
- the user explicitly requests a rebuild/full rescan.

Otherwise continue from NEXT ACTION.
