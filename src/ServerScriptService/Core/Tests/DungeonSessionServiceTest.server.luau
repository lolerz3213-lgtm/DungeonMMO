--!strict
local ServerScriptService = game:GetService("ServerScriptService")

local Core = ServerScriptService:WaitForChild("Core")
local Adapters = Core:WaitForChild("Adapters")
local Services = Core:WaitForChild("Services")

local InMemoryMapAdapter = require(Adapters:WaitForChild("InMemoryMapAdapter"))
local DungeonSessionService = require(Services:WaitForChild("DungeonSessionService"))

local now = 2000
local function clock(): number
    return now
end

local fake_map = InMemoryMapAdapter.new(clock)
local sessions = DungeonSessionService.new(fake_map, clock)

local empty, empty_error = sessions:create("TestDungeon", {}, 100, "reserved-a")
assert(empty == nil and empty_error == "MemberCountOutOfRange", "Zero-member sessions must be rejected.")

local too_many, too_many_error = sessions:create("TestDungeon", {1, 2, 3, 4, 5}, 100, "reserved-b")
assert(too_many == nil and too_many_error == "MemberCountOutOfRange", "Sessions above four members must be rejected.")

local duplicate, duplicate_error = sessions:create("TestDungeon", {1, 1}, 100, "reserved-c")
assert(duplicate == nil and duplicate_error == "DuplicateMember", "Duplicate user IDs must be rejected.")

local solo = assert(sessions:create("TestDungeon", {42}, 100, "reserved-solo"))
local party = assert(sessions:create("TestDungeon", {43, 44, 45, 46}, 100, "reserved-party"))
assert(solo.SessionId ~= "" and party.SessionId ~= "", "Generated session IDs must be non-empty.")
assert(solo.SessionId ~= party.SessionId, "Generated session IDs must be unique.")
assert(solo.State == "Creating", "New session must begin in Creating state.")
assert(solo.Members["42"].FreeReviveUsed == false)
assert(solo.Members["42"].PaidReviveCount == 0)

local indexed_solo = sessions:get_for_user(42)
assert(indexed_solo ~= nil and indexed_solo.SessionId == solo.SessionId, "Session creation must index each member for reconnect routing.")
assert(sessions:set_handoff_nonce(solo.SessionId, 42, "nonce-42-a").ok, "Session must store a server-authoritative handoff nonce.")
assert(sessions:get_handoff_nonce(solo.SessionId, 42) == "nonce-42-a", "Stored handoff nonce must be retrievable server-side.")
assert(not sessions:set_handoff_nonce(solo.SessionId, 999, "bad").ok, "Non-member handoff nonce must be rejected.")

assert(sessions:mark_connected(solo.SessionId, 42).ok)
local connected = assert(sessions:get(solo.SessionId))
assert(connected.State == "Active", "First connection must activate a creating session.")
assert(connected.Members["42"].Connected == true)
local connected_expiry = connected.ExpiresAt

now += 10
assert(sessions:refresh(solo.SessionId).ok)
local refreshed = assert(sessions:get(solo.SessionId))
assert(refreshed.ExpiresAt > connected_expiry, "Connected session refresh must extend expiry.")

assert(sessions:set_member_mode(solo.SessionId, 42, "Dead").ok)
local free_revive = sessions:consume_free_revive(solo.SessionId, 42)
assert(free_revive.ok and free_revive.session.Members["42"].FreeReviveUsed == true, "Free revive must be consumed atomically once.")
assert(free_revive.session.Members["42"].Mode == "Active", "Free revive consumption must restore Active member mode.")
assert(sessions:set_member_mode(solo.SessionId, 42, "Spectating").ok)
assert(not sessions:consume_free_revive(solo.SessionId, 42).ok, "Free revive cannot be consumed twice.")
local paid_once = sessions:grant_paid_revive_once(solo.SessionId, 42, "purchase-a")
assert(paid_once.ok and paid_once.already_applied == false, "First paid PurchaseId must grant once.")
assert(paid_once.session.Members["42"].PaidReviveCount == 1 and paid_once.session.Members["42"].Mode == "Active")
assert(sessions:set_member_mode(solo.SessionId, 42, "Spectating").ok)
local paid_duplicate = sessions:grant_paid_revive_once(solo.SessionId, 42, "purchase-a")
assert(paid_duplicate.ok and paid_duplicate.already_applied == true, "Duplicate paid PurchaseId must be idempotent.")
assert(paid_duplicate.session.Members["42"].PaidReviveCount == 1, "Duplicate paid PurchaseId cannot increment count twice.")
assert(not sessions:set_member_mode(solo.SessionId, 42, "Invalid").ok)
assert(sessions:set_wipe_deadline(solo.SessionId, now + 30).ok, "Active session must store a wipe decision deadline.")
assert(assert(sessions:get(solo.SessionId)).WipeDecisionEndsAt == now + 30)
assert(sessions:set_wipe_deadline(solo.SessionId, nil).ok, "Successful revive must be able to clear wipe deadline.")

assert(sessions:activate_checkpoint(solo.SessionId, "Checkpoint1", 1).ok)
assert(sessions:set_runtime_progress(solo.SessionId, "CombatRoom2", "CombatRoom2").ok, "Dungeon runtime must persist current room/encounter IDs for recovery.")
local checkpointed = assert(sessions:get(solo.SessionId))
assert(checkpointed.CurrentRoomId == "CombatRoom2" and checkpointed.CurrentEncounterId == "CombatRoom2")
assert(checkpointed.Checkpoint.Id == "Checkpoint1")
assert(checkpointed.Checkpoint.Sequence == 1)

assert(sessions:mark_disconnected(solo.SessionId, 42).ok)
local disconnected = assert(sessions:get(solo.SessionId))
assert(disconnected.Members["42"].Connected == false, "Disconnected member must become inactive for eligibility.")
local recover_until = disconnected.ExpiresAt
assert(recover_until == now + 600, "All-disconnected recovery window must be exactly 600 seconds.")

now = recover_until - 1
assert(sessions:expire_if_stale(solo.SessionId).ok)
assert(assert(sessions:get(solo.SessionId)).State == "Active", "Session must remain recoverable before grace expires.")

now = recover_until
assert(sessions:expire_if_stale(solo.SessionId).ok)
local expired = assert(sessions:get(solo.SessionId))
assert(expired.State == "Expired", "All-disconnected session must expire at the grace boundary.")
assert(not sessions:mark_connected(solo.SessionId, 42).ok, "Expired session cannot be reopened.")

assert(sessions:mark_connected(party.SessionId, 43).ok)
assert(sessions:set_member_mode(party.SessionId, 43, "Active").ok)
local complete_snapshot = {43}
assert(sessions:mark_complete(party.SessionId, complete_snapshot).ok, "Active session must complete once.")
complete_snapshot[1] = 999
local completed = assert(sessions:get(party.SessionId))
assert(completed.State == "Complete")
assert(completed.CompletionRecipients[1] == 43, "Completion snapshot must be copied when committed.")
assert(not sessions:mark_complete(party.SessionId, {44}).ok, "Completed session cannot be completed twice.")
assert(sessions:mark_completion_rewards_committed(party.SessionId, {["43"] = {gold_granted = 50}}).ok, "Completed session must accept a completion-reward commit marker.")
local committed_session = assert(sessions:get(party.SessionId))
assert(committed_session.CompletionRewardsCommitted == true, "Completion reward commit marker must persist in session state.")
assert(committed_session.CompletionRewardSummary["43"].gold_granted == 50, "Completion reward summary must persist for idempotent return/UI reconstruction.")
assert(not sessions:mark_failed(party.SessionId, "LateFailure").ok, "Completed session cannot transition backward to Failed.")


-- Abandoning must clear reconnect routing for the leaving member. A solo
-- abandon fails the run; a party abandon leaves the remaining party active.
local solo_abandon = assert(
    sessions:create("TestDungeon", {47}, 100, "reserved-abandon-solo")
)
assert(sessions:mark_connected(solo_abandon.SessionId, 47).ok)
assert(sessions:set_member_mode(solo_abandon.SessionId, 47, "Dead").ok)
local solo_abandoned = sessions:abandon_member(solo_abandon.SessionId, 47)
assert(solo_abandoned.ok, "Solo member must be able to abandon the dungeon.")
assert(
    solo_abandoned.session.State == "Failed",
    "Solo abandon must fail the unfinished run without a completion reward."
)
assert(
    solo_abandoned.session.Members["47"].Abandoned == true,
    "Abandoned member state must be persisted."
)
assert(
    sessions:get_for_user(47) == nil,
    "Abandoning must clear the member reconnect index."
)

local party_abandon = assert(
    sessions:create("TestDungeon", {50, 51}, 100, "reserved-abandon-party")
)
assert(sessions:mark_connected(party_abandon.SessionId, 50).ok)
assert(sessions:mark_connected(party_abandon.SessionId, 51).ok)
assert(sessions:set_member_mode(party_abandon.SessionId, 50, "Spectating").ok)
local member_abandoned = sessions:abandon_member(party_abandon.SessionId, 50)
assert(
    member_abandoned.ok,
    "One party member must be able to return to lobby."
)
assert(
    member_abandoned.session.State == "Active",
    "Remaining party members must keep the dungeon session active."
)
assert(
    member_abandoned.session.Members["50"].Abandoned == true,
    "Leaving party member must be marked abandoned."
)
assert(
    sessions:get_for_user(50) == nil,
    "Leaving party member must not reconnect into the abandoned dungeon."
)
assert(
    sessions:get_for_user(51) ~= nil,
    "Remaining party member must keep the active session index."
)

print("[Dungeon Session Tests] PASS")
