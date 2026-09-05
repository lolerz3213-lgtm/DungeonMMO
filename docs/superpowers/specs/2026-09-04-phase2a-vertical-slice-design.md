# Phase 2A Vertical Slice Design

**Project:** DungeonMMO
**Date:** 4 September 2026
**Status:** FUNCTIONALLY COMPLETE / ACCEPTED 5 September 2026
**Roadmap:** DungeonMMO Roadmap v1.17

## Acceptance note

Phase 2A passed its private published TEST gate on 5 September 2026. The accepted runtime proves the real Base -> reserved Dungeon -> Base loop, persistent XP/Gold/Inventory, room-start checkpoints, one free revive followed by the paid-revive interface, exactly two death choices, direct Boss-room completion, manual and 60-second return, abandon-to-Base, recoverable reconnect/reconstruction, and TEST-only outbound/return teleport failure recovery.

The active encounter may reset if the original solo reserved runtime disappeared before reconnect; reconstruction resumes from the latest authoritative room-start checkpoint and preserves already-banked rewards. TEST-only failure switches remain source-controlled for regression use but must be false or absent in normal published TEST play. Live Developer Product activation remains deferred; receipt duplicate protection is service-tested and will be revalidated when monetisation is explicitly enabled.

## 1. Purpose

Phase 2A proves the first real end-to-end MMORPG loop using the accepted Phase 1 combat foundation:

**Starting Base -> create dungeon session -> reserved/private Dungeon Place -> fight -> earn monster rewards -> checkpoint/revive -> boss completion -> completion rewards -> save -> return to Base -> rejoin later with progress intact.**

Phase 2A is an architectural vertical slice, not final content. The Base, dungeon rooms, boss visuals, UI, loot values and progression curve may remain prototype quality. The systems and data boundaries must be suitable for later parties, additional dungeons, classes, skills, professions and persistent progression.

## 2. Non-goals

Phase 2A does not implement:

- party invitations, matchmaking or party lobby UI;
- final Base art or full town services;
- vendors, bank, crafting, trainers or guild systems;
- final class/race progression;
- attribute spending or respec;
- Skill Book learning;
- skill proficiency progression;
- equipment upgrading or random stat rolls;
- trading or player market;
- procedural/modular dungeon generation;
- final animations, VFX, audio or production HUD art;
- live activation of paid-revive Developer Products before receipt edge-case policy and published-game testing are complete.

Existing Phase 1 combat remains the baseline. Phase 2A must not rebalance or redesign it unless real-content testing exposes a functional regression.

## 3. Place architecture

Phase 2A uses two real Roblox Places inside one Experience.

### 3.1 Starting Base Place

Responsibilities:

- player entry and return destination;
- load Character Slot 1;
- show functional Level, XP, Gold and Inventory UI;
- expose the Test Dungeon entrance;
- create a Dungeon Session;
- reserve a Dungeon server;
- save/handoff profile authority before teleport;
- recover safely from failed teleports;
- route reconnecting players back to an active dungeon session when eligible.

Phase 2A exposes solo entry only.

### 3.2 Dungeon Place

Responsibilities:

- verify the incoming Dungeon Session and player membership server-side;
- load/claim the same persistent character profile;
- run the test dungeon encounters;
- manage checkpoints, deaths, revives, spectating and wipe state;
- award monster XP/Gold;
- determine completion eligibility;
- grant completion Gold and personal loot exactly once;
- save before return;
- return players to the Base.

### 3.3 Party-ready boundary

Dungeon Session data supports **1-4 players** from the beginning. Phase 2A only creates one-player sessions from the Base UI. Later party UI supplies multiple player IDs to the same session-creation interface rather than replacing the dungeon architecture.

## 4. Source/project composition

The accepted Phase 1 source should remain intact as much as possible.

Recommended Rojo composition:

- current Phase 1 `src` remains the Dungeon combat/runtime source;
- a new shared source tree contains cross-Place services and data definitions;
- a new Base-specific source tree contains Base runtime/UI;
- Base and Dungeon use separate Rojo project files while sharing common modules;
- Place IDs, environment names and Developer Product IDs are deployment configuration, not hardcoded gameplay constants.

The implementation plan may refine folder names, but it must preserve this rule: **cross-Place services are shared modules; combat-specific server scripts do not need to run in the Base.**

## 5. Persistent profile architecture

Use one central, server-authoritative profile/save layer. Gameplay systems never call DataStore APIs directly.

### 5.1 Profile shape

One account profile is multi-character-ready while Phase 2A auto-loads Slot 1.

```text
PlayerProfile
├── SchemaVersion
├── Account
│   └── SelectedCharacterSlot = 1
└── Characters
    └── Slot1
        ├── Level
        ├── XP
        ├── Gold
        ├── Inventory
        ├── DungeonProgress
        ├── RewardHistory
        └── Future fields
            ├── Race
            ├── Class
            ├── Attributes
            ├── Equipment
            ├── Skills
            └── Proficiencies
```

`SchemaVersion` starts at 1. Future schema changes use explicit migration functions.

### 5.2 Inventory model

Phase 2A inventory must support both stackable and non-stackable future items without a redesign. Ownership records use an `ItemId` plus an ownership/instance identifier where required. Skill Books can be stored immediately but cannot be consumed/learned in Phase 2A.

### 5.3 Service boundary

Gameplay code uses services such as:

- `ProfileService` - load, mutate, save and migrate the authoritative profile;
- `ProgressionService` - grant XP and process level-ups;
- `RewardService` - grant Gold and orchestrate reward transactions;
- `InventoryService` - add/remove/query owned items.

Example: a Marauder does not write DataStore data. It reports death to encounter/reward logic, which calls the service layer.

### 5.4 Single-writer authority

A player profile must have only one authoritative server writer at a time.

Use a short-lived MemoryStore lease for profile authority. During Base <-> Dungeon teleport:

1. source server saves the profile;
2. source marks a transfer/handoff nonce;
3. destination verifies the handoff and claims the lease;
4. source stops authoritative mutation once transfer begins;
5. if teleport initialization fails, source cancels/reclaims the handoff and remains authoritative.

The exact lease interval is implementation configuration and must be renewed while the player is connected. Destination load retries must be bounded and fail safely to Base/retry UI rather than allowing two writers.

### 5.5 Environment isolation

Use separate DataStore namespaces for development/test/production, e.g.:

- `DEV_PlayerProfile_v1`
- `TEST_PlayerProfile_v1`
- `PROD_PlayerProfile_v1`

Studio and published test environments must not touch production save keys.

## 6. Dungeon Session architecture

Each dungeon run gets a cryptographically unpredictable/generated `SessionId`.

Temporary session data lives in MemoryStore and contains at minimum:

- SessionId;
- DungeonId and dungeon content/version identifier;
- reserved-server access/routing data;
- member UserIds (1-4);
- session state: `Creating`, `Active`, `Complete`, `Failed`, `Expired`;
- member runtime state: connected, alive, dead, spectating;
- last activated checkpoint;
- current room/encounter identifier;
- free revive used state;
- paid revive tier/count for the run;
- completion recipient snapshot when completed;
- creation/update timestamps and expiry.

Client-supplied TeleportData carries only routing hints such as `SessionId`/`DungeonId`. The Dungeon server must verify membership and state against server-side session data before admitting the player.

## 7. Reconnect and session expiry

### 7.1 Reconnect while the run still exists

A disconnected member remains associated with the session but is not active or reward-eligible while disconnected.

If they rejoin before authoritative completion/failure and the session is recoverable, the Base routes them back into that dungeon session.

If the original Dungeon server is still active, rejoin that server and continue the current run.

If all players disconnected and the original runtime disappeared but the session is still within its reconnect grace, recovery may reconstruct the run from the **last activated checkpoint**. The current encounter resets in this reconstruction case; already banked persistent monster XP/Gold is not removed.

### 7.2 Reconnect grace

When at least one member remains connected, the session stays alive and its MemoryStore TTL is refreshed.

When all members are disconnected from an unfinished run, retain the recoverable session for **10 minutes**. After that it becomes `Expired`.

An expired session routes the player to Base. It never grants completion rewards.

### 7.3 Disconnect before party completion

If Player A disconnects and Player B completes the dungeon before A rejoins:

- B can receive completion rewards if otherwise eligible;
- A is excluded from the completion recipient snapshot;
- A later returns to Base;
- A keeps monster XP/Gold already earned before disconnect;
- A receives no completion Gold and no completion loot.

## 8. Lives, death, spectating and revives

### 8.1 Lives per run

Each player begins a dungeon run with:

- starting life;
- **one free revive**.

After the free revive is consumed, further revives are paid tiers for that player in that run:

| Paid revive number | Price |
| --- | ---: |
| 1st | 9 Robux |
| 2nd | 49 Robux |
| 3rd | 99 Robux |
| 4th | 199 Robux |
| 5th+ | 399 Robux |

The paid-revive count resets when a new Dungeon Session starts.

### 8.2 Death state

A dead player is a session member but is not active for encounter/completion rewards while spectating.

A dead player can become active/reward-eligible again only by successfully reviving before dungeon completion.

### 8.3 Free revive

The free revive:

- is available once per player per run;
- respawns at the last activated checkpoint (or dungeon entrance if no checkpoint has been activated);
- restores full HP and Stamina;
- does not reset enemies merely because one player revived.

A free revive is chosen through the revive UI rather than silently consumed. During a full wipe/solo death, the same 30-second revive window applies.

### 8.4 Paid revive

A paid revive:

- is offered only after the free revive has been consumed;
- replaces the free-revive action in the same primary Revive button;
- uses the configured Developer Product for the player's current paid tier;
- restores full HP and Stamina;
- returns the player to the latest room-start checkpoint, exactly like the free revive;
- does not reset boss/enemy HP solely because the player revived.

The client cannot grant a paid revive. Production purchase granting is receipt-authoritative through `MarketplaceService.ProcessReceipt`, with duplicate protection by purchase/transaction ID.

Phase 2A implements and tests the receipt-safe interface and Studio simulated purchase path. Live Developer Product activation remains disabled until published-game receipt testing and the late-receipt policy are explicitly approved. This prevents an old receipt from accidentally reviving a later dungeon run.

### 8.5 Party continues when someone dies

If at least one party member is alive:

- the encounter continues;
- dead members spectate;
- dead members may revive;
- spectators are not completion-reward eligible;
- reviving before completion restores eligibility.

### 8.6 Full-party wipe / solo death

If every session member is dead/spectating at the same time:

- pause the encounter;
- open a **30-second revive window**;
- free or paid revives may be used as appropriate;
- if at least one player revives, resume the existing encounter state;
- if nobody revives before the timer expires, mark the run `Failed` and return players to Base;
- failed runs grant no completion Gold/loot;
- already-earned monster XP/Gold remains banked.

For solo Phase 2A, this same rule means the encounter pauses while the player chooses between exactly two actions: **Revive** or **Return to Lobby**. The Revive action is free until the one free revive is consumed, then becomes the current Robux revive offer. Return to Lobby abandons that player's unfinished run without completion rewards while preserving already-banked monster XP/Gold. Every local character death forces View Lock off immediately, including deaths after a paid/Robux revive; this reset is owned client-side by the camera lifecycle rather than relying only on server attribute replication.

## 9. Reward eligibility

Session membership does not automatically grant completion rewards.

At authoritative dungeon completion, the Dungeon server creates an immutable recipient snapshot. A player is included only if they are:

- connected to the active Dungeon server;
- a valid member of the SessionId;
- not spectating;
- active in the run/encounter.

A connected player who is merely dead/spectating at completion is not eligible. If they revive before completion, they may be eligible.

Players who reconnect after completion cannot be added to the snapshot.

## 10. Monster rewards

Monster rewards are independent of dungeon completion.

When a monster dies:

- XP is granted to every active, non-spectating party member participating in that encounter;
- Gold is rolled individually for each eligible player;
- rewards are applied immediately to each loaded profile;
- those rewards remain even if the run later fails or the player disconnects.

For party-readiness, encounter participation is server-owned. A member joins an encounter participation set when they enter/start that encounter and is removed when disconnected/spectating/invalid. Phase 2A solo entry uses the same interface.

Prototype values are tuning data, not locked economy values. Initial test defaults may use approximately:

- Standard Marauder: 10 XP and 3-6 Gold per eligible player;
- Marauder Captain: 40 XP and 15-25 Gold per eligible player.

## 11. Level progression

Phase 2A implements real persistent levels.

Initial test progression uses a simple configurable curve, beginning approximately:

- Level 1 -> 2: 100 XP;
- Level 2 -> 3: 150 XP;
- Level 3 -> 4: 225 XP.

The curve is data/configuration, not hardcoded into reward logic. Phase 2A does not yet award/spend attribute points or SP.

## 12. Dungeon completion rewards

On authoritative completion:

1. mark the session complete atomically/once;
2. create the immutable eligible-recipient snapshot;
3. grant each recipient the configured completion Gold bonus;
4. perform an independent personal loot roll for each recipient;
5. record the completion transaction/idempotency key;
6. save affected profiles;
7. expose Return to Base and start the 60-second boss-room return timer.

Monster XP/Gold has already been banked and is not re-granted here.

### 12.1 Prototype completion loot table

The test dungeon uses a tiny data-driven personal loot table with a real chance of receiving nothing. Initial testing defaults may be:

- 50%: nothing;
- 30%: basic equipment item;
- 15%: uncommon test item;
- 5%: Skill Book.

These percentages and specific item IDs are tuning data, not final economy balance.

Each eligible player rolls independently. There is no shared party chest/need-greed distribution in Phase 2A.

### 12.2 Skill Books

Skill Books can drop, enter inventory, save, teleport and survive rejoin. They cannot be consumed or learned until the dedicated skill/class progression system is implemented.

## 13. Duplicate/idempotency protection

Critical value-granting operations require unique transaction IDs.

At minimum:

- dungeon completion reward uses `SessionId + CharacterSlot`;
- Developer Product receipt uses Roblox PurchaseId;
- any retry must detect an already-applied transaction and return success without granting value twice.

`RewardHistory` is bounded/maintained so it cannot grow without limit. The implementation plan must define pruning that cannot remove an idempotency key while its source session/receipt can still legitimately retry.

## 14. Test Dungeon content

The first dungeon is a greybox/testing dungeon, approximately **8-12 minutes** when played at intended prototype pace.

Flow:

```text
Entrance
  -> Combat Room 1
  -> Combat Room 2
  -> Marauder Captain Boss
  -> Completion reward/return UI in the Boss Room
  -> Base
```

### 14.1 Combat Room 1

A small standard Marauder pack proving room start/clear and per-monster rewards.

### 14.2 Combat Room 2

A larger/harder standard Marauder composition proving multi-enemy pressure and encounter progression.

Exact pack counts remain data-driven test tuning and can change without altering architecture.

### 14.3 Room-start checkpoints

Every combat room has a checkpoint at its entrance. The active checkpoint advances as soon as the next room is unlocked: Room 1 starts at `Room1Start`; clearing Room 1 moves it to `Room2Start`; clearing Room 2 moves it to `BossRoomStart`. There is no separate checkpoint room. Free and paid revives both return to the latest active room-start checkpoint.

### 14.4 Marauder Captain

The Captain reuses the accepted Marauder/combat foundation with boss-specific configuration and at least three readable attack patterns/telegraphs. Exact HP, timings and animation polish are test tuning, not architectural decisions.

Boss death is the authoritative completion trigger only after server validation confirms the encounter is actually complete.

## 15. Boss-room completion and return

The Marauder Captain's validated death is the completion trigger. There is no separate Completion Room and players do not need to walk into another area to finish the dungeon.

After rewards are committed/saved:

- show a functional completion/reward summary in the Boss Room;
- force View Lock off when the client receives authoritative completion;
- expose a **Return to Base** UI action immediately;
- start a **60-second auto-return timer**;
- manual Return to Base returns immediately;
- timer expiry automatically returns remaining players.

If return teleport fails after rewards were committed, the rewards remain earned. Rejoin/recovery must not pay the completion again.

## 16. Failure flow

A run can fail because the full-party revive window expires or because the session becomes unrecoverable/expired before completion.

Failure:

- sets Session state to `Failed`/`Expired` as appropriate;
- never creates a completion-recipient snapshot;
- gives no completion Gold or completion loot;
- preserves already-earned monster XP/Gold;
- returns/reconnects players to Base safely.

## 17. Functional UI scope

Phase 2A UI is prototype/function-first.

Base:

- Level/XP/Gold display;
- basic Inventory view;
- Test Dungeon entry confirmation/status;
- load/save/teleport failure messaging.

Dungeon:

- checkpoint state feedback;
- boss health bar;
- death/spectator/revive screen;
- 30-second full-wipe/solo revive timer;
- exactly two death choices: Revive and Return to Lobby;
- Revive starts free and becomes the current Robux tier after the free use;
- dungeon completion reward summary;
- Return to Base action and 60-second auto-return timer.

Controller/mobile accessibility should use the shared logical-input architecture from Phase 1. Final styling and mobile sizing remain deferred polish.

## 18. Server authority and security

The server is authoritative for:

- profile mutation;
- session creation/membership;
- encounter state;
- enemy deaths;
- XP/Gold calculations;
- loot rolls;
- checkpoints;
- death/revive state;
- reward eligibility;
- completion/failure;
- Developer Product receipt processing.

Clients may request actions and render feedback but may not supply trusted reward amounts, loot outcomes, completion state or paid-revive approval.

Remote payloads must be type/range/state validated and rate-limited where spam can create server load or economic risk.

## 19. Studio/Test/Production strategy

### 19.1 Studio

Studio can test Base and Dungeon independently.

Dungeon Studio play uses a Studio-only generated test session when `RunService:IsStudio()` is true. This bypass is impossible in published servers.

Studio tests:

- profile schema/migration using DEV namespace/mock adapters;
- XP/Gold/level progression;
- inventory and loot rolls;
- checkpoint/revive/spectating;
- wipe timer;
- completion eligibility;
- idempotent rewards;
- simulated paid-revive approval/retry;
- disconnected/spectating eligibility rules;
- failure paths.

### 19.2 Published test Experience/version

Real end-to-end tests use a private/published test environment with TEST save namespace.

Test:

- Base -> reserved Dungeon teleport;
- Dungeon -> Base return;
- profile authority handoff;
- cross-Place persistence;
- reconnect routing;
- session expiry;
- teleport initialization failure recovery;
- return teleport failure after reward commit;
- real receipt path before any public monetization activation.

### 19.3 Production

Production uses PROD namespace and real deployment IDs. No Studio-only session bypass or simulated purchase path can execute outside Studio/test configuration.

## 20. Required failure-path tests

At minimum, automated/service tests and runtime checklists must cover:

1. player disconnects before boss completion;
2. friend completes while disconnected -> no completion reward for disconnected player;
3. player reconnects before completion -> can become active/eligible again;
4. player reconnects after completion -> cannot join reward snapshot;
5. player dies exactly as boss completes;
6. spectator does not receive completion reward;
7. free revive returns to checkpoint;
8. paid revive returns to the latest room-start checkpoint;
9. full party wipes and revives at second 29;
10. full party wipe timer expires -> failure/no completion reward;
11. duplicate completion processing -> no duplicate Gold/loot;
12. duplicate purchase receipt -> no duplicate revive;
13. profile save/lease retry;
14. outbound dungeon teleport fails;
15. return teleport fails after rewards are committed;
16. all players disconnect and reconnect within 10-minute grace;
17. all players reconnect after session expiry -> Base/no completion reward;
18. failed run retains monster XP/Gold;
19. Skill Book persists but cannot be used;
20. DEV/TEST/PROD namespaces remain isolated.

## 21. Phase 2A acceptance gate

Phase 2A is functionally complete only when a published test proves:

1. join Base;
2. load Character Slot 1;
3. see persistent Level/XP/Gold/Inventory;
4. create a solo Dungeon Session;
5. enter a real reserved Dungeon Place server;
6. kill monsters and bank XP/individual Gold;
7. activate the checkpoint;
8. exercise death/free revive and the paid-revive interface;
9. defeat the Marauder Captain;
10. generate an authoritative reward-eligibility snapshot;
11. grant completion Gold and a personal loot roll exactly once;
12. save;
13. return to Base manually or through the 60-second fallback;
14. rejoin later and retain the earned progression;
15. demonstrate the defined disconnect/spectator/wipe failure cases without duplicate or incorrect completion rewards.

## 22. Deferred/open items after Phase 2A

The following remain outside this implementation and must not block Phase 2A:

- final economy values and loot percentages;
- final dungeon/session-length targets beyond the test dungeon;
- live paid-revive activation and late-receipt compensation policy;
- party invitations/matchmaking;
- full class/race/attribute/SP/skill/proficiency systems;
- Skill Book learning;
- final equipment model/stats;
- crafting/professions;
- modular second dungeon and rare states;
- final Base/dungeon art and presentation polish.
