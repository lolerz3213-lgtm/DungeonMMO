# DungeonMMO dungeon style guide

Last scan: 2026-09-06T15:08:28Z. Total references: 12. New/changed this batch: 12.
All 12 individually visually inspected, not just the contact sheet. First batch.
Source names are those in REFERENCE_MANIFEST.json; numbering follows sorted paths.

## Recurring / high-confidence traits

- Stylised fantasy, readable large shapes, bevelled stone and tactile timber.
  Texture detail supports the form rather than supplying all architectural depth.
- Frame focal landmarks with foreground posts, intermediate stairs/platforms,
  then a taller background silhouette. References 1–6 and 8–12 show this clearly.
- Thick foundations, stepped plinths, shaped capitals, nested arch profiles,
  deep jambs and projecting cornices separate several scales of detail.
- Strong vertical accents contrast broad, navigable horizontal ground planes.
  Ground is visually textured but circulation space stays mostly open.
- Materials have medium-scale variation and readable seams: stone slabs,
  timber grain, bands of darker stone/metal; avoid uniform flat grey blocks.
- Warm amber fire/windows against cool stone, blue magic or cooler distance.
  Local luminous accents guide attention; distance haze separates planes.
- Dressing concentrates at edges and landmarks. Centre space is quieter.
- Clean/pristine construction is valid. Damage/grime is not the quality target.

## Optional motifs (not required in every room)

Pointed/gothic arches; cyan crystal lights; amber braziers; ornamental gold;
massive timber braces; indigo/teal cloth; sculptural hero landmark; restrained
faceted rubble; high-level galleries. Outdoor vegetation/water, horned forge,
winged warrior statue and bright player auras are not mandatory dungeon traits.
Do not copy the statue, forge or leaderboard arrangement.

## Newest batch: individual observations

| Ref | Distinct useful observation |
|---|---|
|01 / 164432996|Harbour hub: large clear plaza, irregular inset ground slabs, raised cyan portal, heavy foreground timber, tiered buildings/cliffs.|
|02 / 164510110|Long approach to ceremonial stone frames; slim tall paired uprights, curved shoulder profiles, bright centre and darker peripheral boards.|
|03 / 164513256|Closer view confirms multi-layer arch mouldings, gold edges, stepped platform and strong relative height above characters.|
|04 / 164557846|Deep shop doorway, projected eaves, uneven roof silhouette, restrained turquoise panel ornament; short broad stairs anchor entrances.|
|05 / 164605485|Forge has substantial diagonal beams and overlapping roofs; sculptural horns break silhouette. Stone monument has planar carved relief and substantial pedestal.|
|06 / 164613852|Ascending broad slabs and side braziers establish axis to very tall cold gothic landmark; warm/cool contrast and repeated nested lancets.|
|07 / 164652304|Only cavern/combat reference: broad clear sandy floor, perimeter rock masses/crystals, timber shelter and warm torch, dark enclosure with cool fill.|
|08 / 164733953|Dock approach: foreground grain and posts, middle jetty, hazed distant castle. Warm light creates depth without grime.|
|09 / 164737002|Rope/post repetition varies in perspective; distant elevated house framed by layered trees/cliff. Warm windows carry focus.|
|10 / 164739452|Layered settlement, curved awning, chunky framing, dense perimeter vegetation, readable walkway.|
|11 / 164742019|Closer timber/rope quality benchmark: chamfered posts, iron collars, longitudinal grain, wall footing and diagonal bracing.|
|12 / Statue.jpg|Hero silhouette is almost symmetrical but layered: pointed crown, broad wings, deep negative gaps and central vertical gesture. Translate hierarchy, not literal figure.|

## Original chamber direction: the Aster Reliquary

22 x 30 m chamber with 12 m crown; approximately 1.8 m character. Central clear
combat area, lateral arcades, pale carved mouldings over blue-grey stone,
dark teal recessed panels, restrained brass inlay, warm edge braziers and a
cool suspended astrolabe/seal in a deeply framed apse. Original abstract hero
geometry replaces the reference statue. Strong entrance portal and ceiling
ribs provide depth. Room floor remains level except a peripheral focal dais.
Use 1 Blender metre = 3 Roblox studs for the prototype; record import transform.

## Permanent incremental workflow

For ordinary work run `python art/scripts/references/scan_references.py` and
read this cached guide. Do not reopen unchanged screenshots.

Instruction **"Rescan for new dungeon references"** means:
1. Run `python art/scripts/references/scan_references.py --rescan`.
2. Visually inspect only `pending_analysis` in the manifest (new/changed hashes).
3. Retain established observations, append a dated newest-batch section and
   update last scan / total / new-changed counts. Do not infer visual traits by filename.
4. Run `python art/scripts/references/scan_references.py --accept-analysis`.
   This records analysis separately from scanning and refuses a changed inventory.
5. Contact sheet rebuild is automatic only if inventory/content changed or missing.
   Removed references are reported; retain historical observations with provenance.

The script detects inventory changes, not visual meaning. Agent visual inspection
and incremental guide editing are intentionally required before marking analysed.
