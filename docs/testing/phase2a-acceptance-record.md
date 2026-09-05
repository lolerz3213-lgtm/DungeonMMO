# Phase 2A Acceptance Record

**Project:** DungeonMMO
**Accepted:** 5 September 2026
**Status:** FUNCTIONALLY COMPLETE
**Roadmap:** v1.17

## Accepted runtime

Phase 2A proves the first real MMO loop across two Roblox Places:

`Starting Base -> reserved Test Dungeon -> combat/rewards -> Marauder Captain -> save -> Base`

The private published TEST established:

- Character Slot 1 profile load in Base with persistent Level, XP, Gold and Inventory.
- Real reserved-server teleport from Base into the Dungeon Place.
- Immediate monster XP/Gold banking and completion Gold/personal loot persistence.
- Room-start checkpoints: `Room1Start`, `Room2Start`, `BossRoomStart`.
- Exactly two death choices: Revive and Return to Lobby.
- One free revive per run; after it is consumed, the same Revive button becomes the current paid-revive offer.
- Free/paid revive boundary returns to the latest room-start checkpoint.
- View Lock turns off on every death state and on authoritative dungeon completion.
- Captain death completes the dungeon directly in the Boss Room; there is no standalone checkpoint room or completion room.
- Manual Return to Base and the 60-second automatic return both work.
- Return to Lobby from death abandons the unfinished run and does not route the player back into it.
- Reconnect finds the recoverable SessionId. If the original solo runtime disappeared, the active room encounter may reset; reconstruction uses the latest authoritative room-start checkpoint while banked rewards remain.
- TEST-only forced outbound teleport failure leaves the player/profile usable in Base.
- TEST-only forced return failure after completion preserves committed rewards and does not grant completion again after rejoin.

## Automated/service coverage

The accepted Studio suite includes the Phase 2A failure-path harness plus focused tests for profile persistence/migration, leases, sessions, teleport coordination, progression, rewards, inventory, checkpoints, death/revive, completion idempotency, return timing, duplicate PurchaseId handling, reconnect rules, UI state and TEST failure-switch isolation.

## Deliberately deferred

The following are not Phase 2A blockers:

- Live Developer Product activation for paid revives. Receipt-safe/duplicate handling is service-tested, but real monetisation remains disabled until its dedicated published receipt-policy test.
- Final Base/dungeon art, final HUD styling, polished death presentation, animation/VFX/audio and mobile-button sizing.
- Party invitations/matchmaking UI. The session contract is already 1-4-player-ready; Phase 2A exposes solo entry only.
- Attribute spending/respec, finite SP, skillbook learning, proficiency ranks and final skill-loadout management. These move into Phase 2B design.

## Accepted TEST safety state

Normal published TEST use must have these attributes false or absent:

- Base: `DungeonMMOForceOutboundTeleportFailure`
- Dungeon: `DungeonMMOForceReturnTeleportFailure`

Both switches are ignored outside `DungeonMMOEnvironment = TEST`, but keeping them disabled avoids accidental regression-mode behaviour.

## Next slice

**Phase 2B design - character progression + minimal Starting Base service shell.**

The next design pass should lock the smallest playable path for attribute spending/respec, finite character-wide SP, skillbook learning, valid-use proficiency/ranks and the 6-8-active-skill loadout, with functional trainer/service UI in the Starting Base.
