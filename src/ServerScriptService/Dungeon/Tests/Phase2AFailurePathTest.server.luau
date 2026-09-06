--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Core = ServerScriptService:WaitForChild("Core")
local Adapters = Core:WaitForChild("Adapters")
local Services = Core:WaitForChild("Services")
local Dungeon = ServerScriptService:WaitForChild("Dungeon")
local Shared = ReplicatedStorage:WaitForChild("Core"):WaitForChild("Shared")

local InMemoryMapAdapter = require(
    Adapters:WaitForChild("InMemoryMapAdapter")
)
local InMemoryProfileAdapter = require(
    Adapters:WaitForChild("InMemoryProfileAdapter")
)
local DungeonSessionService = require(
    Services:WaitForChild("DungeonSessionService")
)
local ProfileLeaseService = require(
    Services:WaitForChild("ProfileLeaseService")
)
local ProfileService = require(Services:WaitForChild("ProfileService"))
local ProgressionService = require(
    Services:WaitForChild("ProgressionService")
)
local InventoryService = require(Services:WaitForChild("InventoryService"))
local RewardService = require(Services:WaitForChild("RewardService"))
local TeleportCoordinator = require(
    Services:WaitForChild("TeleportCoordinator")
)
local CompletionEligibilityRules = require(
    Dungeon:WaitForChild("CompletionEligibilityRules")
)
local CompletionService = require(Dungeon:WaitForChild("CompletionService"))
local DungeonDeathService = require(
    Dungeon:WaitForChild("DungeonDeathService")
)
local ReturnPortalService = require(
    Dungeon:WaitForChild("ReturnPortalService")
)
local EnvironmentConfig = require(Shared:WaitForChild("EnvironmentConfig"))
local DungeonDefinitions = require(Shared:WaitForChild("DungeonDefinitions"))

local assertions = 0
local function check(condition: boolean, message: string)
    assertions += 1
    if not condition then
        error("[Phase2A Failure Path Tests] " .. message, 2)
    end
end

local eligibility_session = {
    SessionId = "eligibility",
    State = "Active",
    MemberUserIds = {101, 102, 103, 104},
    Members = {
        ["101"] = {UserId = 101, Connected = true, Mode = "Active"},
        ["102"] = {UserId = 102, Connected = false, Mode = "Active"},
        ["103"] = {
            UserId = 103,
            Connected = true,
            Mode = "Spectating",
        },
        ["104"] = {UserId = 104, Connected = true, Mode = "Dead"},
    },
}

local disconnected_snapshot = CompletionEligibilityRules.build_snapshot(
    eligibility_session,
    {101, 102, 103, 104}
)
check(
    #disconnected_snapshot == 1 and disconnected_snapshot[1] == 101,
    "Disconnected, spectating and dead members must be excluded."
)

eligibility_session.Members["102"].Connected = true
local reconnected_snapshot = CompletionEligibilityRules.build_snapshot(
    eligibility_session,
    {101, 102, 103, 104}
)
check(
    #reconnected_snapshot == 2 and reconnected_snapshot[2] == 102,
    "Reconnect before completion must restore Active eligibility."
)

eligibility_session.Members["101"].Mode = "Dead"
local death_boundary_snapshot = CompletionEligibilityRules.build_snapshot(
    eligibility_session,
    {101, 102, 103, 104}
)
check(
    #death_boundary_snapshot == 1 and death_boundary_snapshot[1] == 102,
    "Death at completion must follow authoritative member mode."
)

eligibility_session.State = "Complete"
eligibility_session.CompletionRecipients = {102}
eligibility_session.Members["101"].Mode = "Active"
local immutable_snapshot = CompletionEligibilityRules.build_snapshot(
    eligibility_session,
    {101, 102, 103, 104}
)
check(
    #immutable_snapshot == 1 and immutable_snapshot[1] == 102,
    "Reconnect after completion must not alter the stored reward snapshot."
)

local now = 1000
local death_session = {
    SessionId = "death",
    State = "Active",
    Members = {
        ["201"] = {
            UserId = 201,
            Connected = true,
            Mode = "Active",
            FreeReviveUsed = false,
            PaidReviveCount = 0,
        },
    },
}
local death_sessions: any = {}
function death_sessions:get(_session_id: string): any
    return death_session
end
function death_sessions:set_member_mode(
    _session_id: string,
    user_id: number,
    mode: string
): any
    death_session.Members[tostring(user_id)].Mode = mode
    return {ok = true, session = death_session}
end
function death_sessions:consume_free_revive(
    _session_id: string,
    user_id: number
): any
    local member = death_session.Members[tostring(user_id)]
    if member.FreeReviveUsed then
        return {ok = false, reason = "FreeReviveAlreadyUsed"}
    end
    member.FreeReviveUsed = true
    member.Mode = "Reviving"
    death_session.WipeDecisionEndsAt = nil
    return {ok = true, session = death_session}
end
function death_sessions:set_wipe_deadline(
    _session_id: string,
    deadline: number?
): any
    death_session.WipeDecisionEndsAt = deadline
    return {ok = true, session = death_session}
end
function death_sessions:mark_failed(
    _session_id: string,
    reason: string
): any
    death_session.State = "Failed"
    death_session.FailureReason = reason
    return {ok = true, session = death_session}
end

local latest_checkpoint = {
    Id = "Room2Start",
    Sequence = 2,
    CFrame = CFrame.new(0, 3, -112),
}
local checkpoint_service: any = {}
function checkpoint_service:get_active_checkpoint(): any
    return latest_checkpoint
end

local spawned = {}
local scheduled_delay: number? = nil
local scheduled_callback: (() -> ())? = nil
local death_service = DungeonDeathService.new(
    death_sessions,
    checkpoint_service,
    death_session.SessionId,
    {
        clock = function()
            return now
        end,
        schedule = function(delay_seconds: number, callback: () -> ())
            scheduled_delay = delay_seconds
            scheduled_callback = callback
        end,
        spawn_player = function(_player: any, cframe: CFrame): boolean
            table.insert(spawned, cframe)
            return true
        end,
        paid_offer_provider = function(_user_id: number): any
            return {price = 9, paid_number = 1}
        end,
    }
)
local death_player: any = {UserId = 201}
local first_death = death_service:on_player_died(death_player, CFrame.new())
check(
    first_death.ok
        and death_session.Members["201"].Mode == "Reviving"
        and death_session.Members["201"].FreeReviveUsed == true,
    "First death must atomically consume the free revive and enter forced Reviving."
)
check(
    scheduled_delay == 3 and scheduled_callback ~= nil,
    "First death must schedule its automatic checkpoint respawn after three seconds."
)
local auto_callback = scheduled_callback
if not auto_callback then error("[Phase2A Failure Path Tests] Automatic revive callback was not scheduled.") end
auto_callback()
check(
    #spawned == 1
        and spawned[1].Position == latest_checkpoint.CFrame.Position
        and death_session.Members["201"].Mode == "Active",
    "Automatic free revive must use the latest room-start checkpoint."
)
check(
    death_service:on_player_died(death_player, CFrame.new()).ok,
    "Second death must enter the paid revive flow."
)
check(
    death_service:complete_paid_revive(death_player).ok,
    "Granted paid revive must succeed."
)
check(
    #spawned == 2
        and spawned[2].Position == latest_checkpoint.CFrame.Position,
    "Paid revive must use the same latest room-start checkpoint."
)
check(
    death_service:on_player_died(death_player, CFrame.new()).ok,
    "A later death must reopen the wipe decision flow."
)
now = 1058
check(
    death_service:tick(now).failed == false,
    "Wipe timer must remain recoverable before its deadline."
)
now = 1059
check(
    death_service:tick(now).failed == true,
    "Wipe timeout must fail the run with no completion flow."
)

local profile_adapter = InMemoryProfileAdapter.new()
local profiles = ProfileService.new(profile_adapter)
assert(profiles:load(301))
local progression = ProgressionService.new(profiles)
local inventory = InventoryService.new(profiles)
local rng: any = {}
function rng:NextNumber(_minimum: number?, _maximum: number?): number
    return 97
end
function rng:NextInteger(minimum: number, _maximum: number): number
    return minimum
end
local rewards = RewardService.new(
    profiles,
    progression,
    inventory,
    nil,
    rng,
    function()
        return 5000
    end
)

local completion_session = {
    SessionId = "completion",
    State = "Complete",
    CompletionRecipients = {301},
    CompletionRewardsCommitted = false,
}
local completion_sessions: any = {}
function completion_sessions:get(_session_id: string): any
    return completion_session
end
function completion_sessions:mark_completion_rewards_committed(
    _session_id: string,
    summary: any
): any
    completion_session.CompletionRewardsCommitted = true
    completion_session.CompletionRewardSummary = summary
    return {ok = true, session = completion_session}
end
local completion_service = CompletionService.new(
    completion_sessions,
    rewards,
    profiles,
    DungeonDefinitions.TEST_DUNGEON.CompletionReward
)
local first_completion = completion_service:commit("completion")
local gold_after_first = assert(profiles:get_character(301, 1)).Gold
local repeated_completion = completion_service:commit("completion")
check(
    first_completion.ok
        and repeated_completion.ok
        and repeated_completion.already_applied == true
        and assert(profiles:get_character(301, 1)).Gold == gold_after_first,
    "Duplicate completion processing must not duplicate Gold or loot."
)

local session_now = 2000
local map = InMemoryMapAdapter.new(function()
    return session_now
end)
local sessions = DungeonSessionService.new(map, function()
    return session_now
end)
local paid_session = assert(
    sessions:create("TestDungeon", {401}, 100, "reserved-paid")
)
assert(sessions:mark_connected(paid_session.SessionId, 401).ok)
assert(sessions:set_member_mode(paid_session.SessionId, 401, "Dead").ok)
assert(sessions:consume_free_revive(paid_session.SessionId, 401).ok)
assert(sessions:set_member_mode(paid_session.SessionId, 401, "Spectating").ok)
local paid_once = sessions:grant_paid_revive_once(
    paid_session.SessionId,
    401,
    "purchase-401"
)
assert(sessions:set_member_mode(paid_session.SessionId, 401, "Spectating").ok)
local paid_repeat = sessions:grant_paid_revive_once(
    paid_session.SessionId,
    401,
    "purchase-401"
)
check(
    paid_once.ok
        and paid_repeat.ok
        and paid_repeat.already_applied == true
        and paid_repeat.session.Members["401"].PaidReviveCount == 1,
    "Duplicate PurchaseId must grant one paid revive only."
)

local lease_map = InMemoryMapAdapter.new(function()
    return session_now
end)
local lease = ProfileLeaseService.new(
    lease_map,
    "FailurePathServer",
    function()
        return session_now
    end
)
check(
    lease:claim(501).ok and lease:renew(501).ok,
    "Profile lease claim/renew retry path must remain usable."
)
assert(lease:begin_handoff(501, "return-501", "Base").ok)
check(
    lease:cancel_handoff(501, "return-501").ok and lease:renew(501).ok,
    "Cancelled handoff must restore source lease authority."
)

local failed_lease: any = {cancelled = false}
function failed_lease:begin_handoff(
    _user_id: number,
    _nonce: string,
    _destination: string
): any
    return {ok = true}
end
function failed_lease:cancel_handoff(
    _user_id: number,
    _nonce: string
): any
    self.cancelled = true
    return {ok = true}
end
local failed_profile: any = {}
function failed_profile:save(_user_id: number, _reason: string)
    return true, nil
end
local failed_sessions: any = {failed = false}
function failed_sessions:get_for_user(_user_id: number)
    return nil
end
function failed_sessions:create(
    dungeon_id: string,
    members: {number},
    return_place_id: number,
    reserved_code: string
): (any, nil)
    return {
        SessionId = "outbound-failure",
        DungeonId = dungeon_id,
        MemberUserIds = members,
        ReturnPlaceId = return_place_id,
        ReservedAccessCode = reserved_code,
        State = "Creating",
        Members = {
            ["601"] = {
                UserId = 601,
                Connected = false,
                Mode = "Active",
            },
        },
    }, nil
end
function failed_sessions:set_handoff_nonce(
    _session_id: string,
    _user_id: number,
    _nonce: string
): any
    return {ok = true}
end
function failed_sessions:mark_failed(
    _session_id: string,
    _reason: string
): any
    self.failed = true
    return {ok = true}
end
local failing_adapter: any = {}
function failing_adapter:reserve_server(_place_id: number)
    return true, "reserved-failure"
end
function failing_adapter:teleport(
    _place_id: number,
    _players: {any},
    _reserved_code: string?,
    _teleport_data: any
)
    return false, "ForcedTeleportFailure"
end
function failing_adapter:connect_init_failed(_handler: (...any) -> ())
    return nil
end
local failed_coordinator = TeleportCoordinator.new(
    failing_adapter,
    failed_profile,
    failed_lease,
    failed_sessions
)
local outbound = failed_coordinator:start_dungeon(
    {{UserId = 601}},
    "TestDungeon",
    987654
)
check(
    outbound.ok == false
        and failed_lease.cancelled == true
        and failed_sessions.failed == true,
    "Outbound teleport failure must reclaim source authority and fail the run."
)

local committed_return_session = {
    SessionId = "return-failure",
    State = "Complete",
    CompletionRewardsCommitted = true,
    ReturnPlaceId = 123,
}
local return_sessions: any = {}
function return_sessions:get(_session_id: string)
    return committed_return_session
end
local return_coordinator: any = {}
function return_coordinator:return_to_base(
    _players: {any},
    _session: any
): any
    return {ok = false, reason = "ForcedReturnFailure"}
end
local return_service = ReturnPortalService.new(
    return_sessions,
    return_coordinator,
    {is_studio = false}
)
assert(return_service:open("return-failure", {ok = true}).ok)
local failed_return = return_service:request_return(
    "return-failure",
    {{UserId = 701}}
)
check(
    failed_return.ok == false
        and committed_return_session.CompletionRewardsCommitted == true,
    "Return failure after reward commit must not revoke earned rewards."
)

local reconnect_session = assert(
    sessions:create("TestDungeon", {801, 802}, 100, "reserved-reconnect")
)
assert(sessions:mark_connected(reconnect_session.SessionId, 801).ok)
assert(sessions:mark_connected(reconnect_session.SessionId, 802).ok)
assert(sessions:mark_disconnected(reconnect_session.SessionId, 801).ok)
assert(sessions:mark_disconnected(reconnect_session.SessionId, 802).ok)
local reconnect_deadline = assert(
    sessions:get(reconnect_session.SessionId)
).ExpiresAt
session_now = reconnect_deadline - 1
check(
    sessions:mark_connected(reconnect_session.SessionId, 801).ok,
    "All-disconnected session must reconnect inside the 10-minute grace."
)

local expired_session = assert(
    sessions:create("TestDungeon", {803}, 100, "reserved-expired")
)
assert(sessions:mark_connected(expired_session.SessionId, 803).ok)
assert(sessions:mark_disconnected(expired_session.SessionId, 803).ok)
local expiry = assert(sessions:get(expired_session.SessionId)).ExpiresAt
session_now = expiry
assert(sessions:expire_if_stale(expired_session.SessionId).ok)
check(
    not sessions:mark_connected(expired_session.SessionId, 803).ok,
    "Reconnect after expiry must stay out of the dungeon."
)
assert(profiles:load(302))
local monster_reward = rewards:grant_monster_reward(
    {302},
    {XP = 10, GoldMin = 3, GoldMax = 3},
    "failed-run:monster:1"
)
local earned_before_failure = assert(profiles:get_character(302, 1))
check(
    monster_reward.ok,
    "Monster reward must be banked before a later failure."
)
local failed_run = assert(
    sessions:create("TestDungeon", {804}, 100, "reserved-failed-reward")
)
assert(sessions:mark_connected(failed_run.SessionId, 804).ok)
assert(sessions:mark_failed(failed_run.SessionId, "TestFailure").ok)
local earned_after_failure = assert(profiles:get_character(302, 1))
check(
    earned_after_failure.XP == earned_before_failure.XP
        and earned_after_failure.Gold == earned_before_failure.Gold,
    "Failing a run must not roll back already-banked monster XP/Gold."
)

assert(profiles:save(301, "SkillBookPersistence"))
assert(profiles:release(301, "SkillBookPersistence"))
assert(profiles:load(301))
local book_found = false
for _, entry in ipairs(assert(profiles:get_character(301, 1)).Inventory) do
    if entry.ItemId == "skill_book_test" and entry.Quantity > 0 then
        book_found = true
        break
    end
end
check(
    book_found and (InventoryService :: any).learn_skill == nil,
    "Skill Book must persist while exposing no learn API in Phase 2A."
)

local dev_store = EnvironmentConfig.get_profile_store_name_for("DEV")
local test_store = EnvironmentConfig.get_profile_store_name_for("TEST")
local prod_store = EnvironmentConfig.get_profile_store_name_for("PROD")
local dev_memory = EnvironmentConfig.get_memory_prefix_for("DEV")
local test_memory = EnvironmentConfig.get_memory_prefix_for("TEST")
local prod_memory = EnvironmentConfig.get_memory_prefix_for("PROD")
check(
    dev_store ~= test_store
        and test_store ~= prod_store
        and dev_store ~= prod_store
        and dev_memory ~= test_memory
        and test_memory ~= prod_memory
        and dev_memory ~= prod_memory,
    "DEV/TEST/PROD profile and MemoryStore namespaces must remain isolated."
)

print(
    string.format(
        "[Phase2A Failure Path Tests] PASS: %d assertions.",
        assertions
    )
)
