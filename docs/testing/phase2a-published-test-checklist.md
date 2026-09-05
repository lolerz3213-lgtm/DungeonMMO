# Phase 2A Published TEST Acceptance Checklist

**Status:** ACCEPTED - 5 September 2026
**Result:** Phase 2A functionally complete.
**Safety:** `DungeonMMOForceOutboundTeleportFailure` and `DungeonMMOForceReturnTeleportFailure` must be false/absent during normal play. Live paid-revive products remain disabled.

Use this checklist only in the private/published TEST Experience. Keep live
paid-revive products disabled until the receipt boundary has separately passed.

## 1. Deployment prerequisites

- Base and Dungeon are two Places inside the same Roblox Experience.
- `ServerScriptService.DungeonMMOEnvironment` is `TEST` in both Places.
- The Base has `DungeonMMODungeonPlaceId` set to the published Dungeon Place ID.
- The profile store resolves to `TEST_PlayerProfile_v1`.
- Paid revives remain non-live for this acceptance pass.
- Run `tools/phase2a_build_both.ps1` and confirm both clean Rojo builds succeed.

## 2. Normal solo run

1. Join the Base and confirm Character Slot 1 Level, XP, Gold and Inventory load.
2. Enter the Test Dungeon from the Base.
3. Confirm the transfer uses a real reserved Dungeon server.
4. At dungeon admission, Room 1 start is the active revive checkpoint.
5. Clear Room 1 and confirm monster XP/Gold are banked immediately.
6. Confirm Room 2 unlocks and the checkpoint moves to Room 2 start immediately.
7. Die in Room 2 with View Lock enabled.
8. Confirm View Lock switches off immediately on death.
9. Confirm the death panel has exactly two choices:
   - `Free Revive`;
   - `Return to Lobby`.
10. Use Free Revive and confirm respawn at Room 2 start with full HP/Stamina.
11. Turn View Lock on again, then die a second time. Confirm View Lock switches
    off immediately on this Robux-revive death as well. Confirm the same first
    button is now the current Robux revive offer, while `Return to Lobby` remains
    the second button.
12. Exercise the non-live/simulated paid boundary and confirm the revive returns
    to the latest room-start checkpoint.
13. Clear Room 2 and confirm the boss unlocks and checkpoint moves to Boss Room
    start immediately.
14. Turn View Lock on, then defeat the Marauder Captain.
15. Confirm completion triggers at Captain death with no completion room and
    View Lock switches off as soon as the Complete state is received.
16. Confirm completion Gold/personal loot are committed exactly once before
    return becomes available.
17. Confirm the completion UI offers immediate Return to Base.
18. Return manually and confirm Base admission succeeds.
19. Rejoin later and confirm Level, XP, Gold and Inventory persist.

## 3. Auto-return

1. Complete another run.
2. Do not press Return to Base.
3. Confirm the 60-second fallback returns the player to Base.
4. Confirm the committed reward remains exactly once after rejoin.

## 4. Return to Lobby from death

1. Start a new run and earn at least one monster reward.
2. Die before dungeon completion.
3. Press `Return to Lobby`.
4. Confirm the unfinished solo session becomes Failed and grants no completion
   reward.
5. Confirm already-earned monster XP/Gold remain saved.
6. Confirm Base does not route the player back into the abandoned session.
7. Confirm the player can start a fresh dungeon session normally.

## 5. Reconnect and eligibility

- Disconnect before Captain completion: no completion reward while absent.
- Reconnect before Captain completion and become Active: eligibility can return.
- If the original reserved runtime still exists, rejoin the live encounter state.
- If every player disconnected and that runtime disappeared, reconstruct from the
  **last activated room-start checkpoint**. The current encounter may reset, but
  already-banked monster XP/Gold must not be removed or granted twice.
- After Room 1 has cleared, disconnect/reconnect and confirm recovery starts at
  `Room2Start` with Room 1 still cleared/unlocked.
- After Room 2 has cleared, disconnect/reconnect and confirm recovery starts at
  `BossRoomStart` with both combat rooms still cleared/unlocked.
- Reconnect after authoritative completion: never join the stored snapshot.
- Die at the completion boundary: authoritative member mode decides eligibility.
- Spectating at Captain death: no completion Gold or personal loot.
- Disconnect every player, reconnect within 10 minutes: session is recoverable.
- Reconnect after session expiry: remain in Base with no completion reward.

## 6. Wipe behaviour

- Full solo/party wipe opens the 30-second decision window.
- Revive at second 29: run resumes.
- Let the timer expire: session becomes Failed and grants no completion reward.
- A living party member prevents a global wipe timeout.

## 7. Duplicate/value safety

- Re-run completion processing: no duplicate Gold or loot.
- Retry the same simulated/TEST PurchaseId: no duplicate paid revive.
- Verify Skill Book inventory can persist through save/return/rejoin but has no
  learn/consume path yet.
- Verify DEV, TEST and PROD profile/MemoryStore namespaces remain distinct.

## 8. Forced teleport failures

### Outbound failure

Force one TEST-only outbound teleport initialization failure. Confirm:

- the source profile/lease authority is reclaimed;
- the fresh dungeon session is failed or safely recoverable as designed;
- the player remains usable in Base;
- no value is duplicated.

### Return failure after completion

Force one TEST-only Base-return initialization failure after completion rewards
have committed. Confirm:

- earned rewards remain saved;
- completion is not granted again on retry/rejoin;
- a later valid return/rejoin leaves the player in Base.

Disable the failure switch after this test.

### Exact TEST switch procedure

The failure switches below are read only when `DungeonMMOEnvironment = TEST`.
`DEV` and `PROD` ignore them even if an attribute is accidentally present.

**Outbound failure:** on the published **Base** Place, add Boolean attribute
`ServerScriptService.DungeonMMOForceOutboundTeleportFailure = true`, publish,
join a fresh Base server and press Enter Dungeon. The teleport must fail while
leaving the player usable in Base. Remove the attribute (or set it false),
publish again, leave the old Base server and rejoin before continuing.

**Return failure:** on the published **Dungeon** Place, add Boolean attribute
`ServerScriptService.DungeonMMOForceReturnTeleportFailure = true`, publish, then
start a fresh run from Base and complete the Captain. Note Gold/XP/Inventory,
press Return to Base and confirm the forced return fails while the completion
reward remains committed. Leave Roblox, remove/set the switch false and publish
the Dungeon again, then rejoin the Base and verify the same rewards persist with
no duplicate completion grant.

## Acceptance result

**ACCEPTED.** The published TEST confirmed the normal Base -> reserved Dungeon -> Base loop with persistent XP/Gold/Inventory, manual return, 60-second auto-return, Return to Lobby/abandon, recoverable reconnect/reconstruction and the two deliberate teleport-failure paths. The active encounter reset on reconstruction is accepted by design when the original solo runtime has disappeared. Duplicate completion/purchase protection and the remaining deterministic edge cases passed the automated service suite. Live Robux revive activation remains deferred.
