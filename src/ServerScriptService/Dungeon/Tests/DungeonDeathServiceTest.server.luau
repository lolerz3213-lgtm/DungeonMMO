--!strict
local ServerScriptService = game:GetService("ServerScriptService")

local Dungeon = ServerScriptService:WaitForChild("Dungeon")
local module = Dungeon:FindFirstChild("DungeonDeathService")
if not module then
    error("[Dungeon Death/Revive Tests] RED: DungeonDeathService is missing.")
end
local DungeonDeathService = require(module)

local assertions = 0
local function check(condition: boolean, message: string)
    assertions += 1
    if not condition then
        error("[Dungeon Death/Revive Tests] " .. message, 2)
    end
end

local now = 1000
local session = {
    SessionId = "session-death",
    State = "Active",
    Members = {
        ["101"] = {UserId = 101, Connected = true, Mode = "Active", FreeReviveUsed = false, PaidReviveCount = 0},
    },
}
local fake_sessions: any = {}
function fake_sessions:get(_session_id: string): any return session end
function fake_sessions:set_member_mode(_session_id: string, user_id: number, mode: string): any
    session.Members[tostring(user_id)].Mode = mode
    return {ok = true, session = session}
end
function fake_sessions:set_member_completion_eligibility(_session_id: string, user_id: number, eligible: boolean): any
    session.Members[tostring(user_id)].CompletionEligibleBeforeDeath = eligible
    return {ok = true, session = session}
end
function fake_sessions:consume_free_revive(_session_id: string, user_id: number): any
    local member = session.Members[tostring(user_id)]
    if member.FreeReviveUsed then return {ok = false, reason = "FreeReviveAlreadyUsed", session = session} end
    if member.Mode ~= "Dead" and member.Mode ~= "Spectating" then return {ok = false, reason = "MemberNotDead", session = session} end
    member.FreeReviveUsed = true
    member.Mode = "Reviving"
    session.WipeDecisionEndsAt = nil
    return {ok = true, session = session}
end
function fake_sessions:set_wipe_deadline(_session_id: string, deadline: number?): any
    session.WipeDecisionEndsAt = deadline
    return {ok = true, session = session}
end
function fake_sessions:mark_failed(_session_id: string, reason: string): any
    session.State = "Failed"
    session.FailureReason = reason
    return {ok = true, session = session}
end

local fake_checkpoint: any = {}
function fake_checkpoint:get_active_checkpoint(): any
    return {Id = "Room2Start", Sequence = 2, CFrame = CFrame.new(5, 3, -112)}
end

local spawns = {}
local function spawn_player(player: any, cframe: CFrame)
    table.insert(spawns, {user_id = player.UserId, cframe = cframe})
    return true
end
local states = {}
local function emit_state(user_id: number, state_payload: any)
    states[user_id] = state_payload
end
local scheduled_delay: number? = nil
local scheduled_callback: (() -> ())? = nil
local function schedule(delay_seconds: number, callback: () -> ())
    scheduled_delay = delay_seconds
    scheduled_callback = callback
end

local player: any = {UserId = 101, Name = "Solo"}
local deaths = DungeonDeathService.new(
    fake_sessions,
    fake_checkpoint,
    "session-death",
    {
        clock = function() return now end,
        schedule = schedule,
        spawn_player = spawn_player,
        emit_state = emit_state,
        paid_offer_provider = function(_user_id: number) return {price = 9, paid_number = 1} end,
    }
)

local died = deaths:on_player_died(player, CFrame.new(12, 3, -20))
check(died.ok == true and died.automatic_free_revive == true, "First death must enter the automatic free-revive flow.")
check(session.Members["101"].FreeReviveUsed == true, "First death must consume the free revive immediately.")
check(session.Members["101"].Mode == "Reviving", "First death with free revive remaining must enter Reviving mode.")
check(session.Members["101"].CompletionEligibleBeforeDeath == true, "Forced Reviving must remember pre-death completion eligibility.")
check(session.WipeDecisionEndsAt == nil, "Forced Reviving must not open the wipe deadline while the revive is pending.")
check(states[101].free_available == false, "A consumed automatic free revive must no longer be presented as available.")
check(states[101].revive_at == now + 3, "Reviving presentation must expose the three-second revive deadline.")
check(scheduled_delay == 3 and scheduled_callback ~= nil, "Automatic revive must schedule exactly one three-second callback.")
local stale_free = deaths:request_free_revive(player)
check(stale_free.ok == false and stale_free.reason == "AutomaticFreeRevive", "Manual free-revive requests must be rejected after auto-consumption.")

local callback = scheduled_callback
if not callback then error("[Dungeon Death/Revive Tests] Automatic revive callback was not scheduled.") end
callback()
check(session.Members["101"].Mode == "Active", "Automatic free revive must restore Active mode after the countdown.")
check(
    #spawns == 1 and spawns[1].cframe.Position == Vector3.new(5, 3, -112),
    "Automatic free revive must return to the active checkpoint."
)
check(session.WipeDecisionEndsAt == nil, "Successful automatic revive must leave the wipe deadline clear.")

local second_death = deaths:on_player_died(player, CFrame.new(20, 3, -25))
check(second_death.ok == true and session.Members["101"].Mode == "Spectating", "Death after free revive is used must enter Spectating mode.")
check(states[101].free_available == false and states[101].paid_offer.price == 9, "Second death must offer current paid tier instead of another free revive.")
check(session.WipeDecisionEndsAt == now + 30, "Solo Spectating after the free revive must open the 30-second wipe window.")

local paid_request = deaths:request_paid_revive(player)
check(paid_request.ok == false and paid_request.reason == "PaidPurchaseRequired", "Later death must expose the paid revive purchase gate.")
local paid_spawn = deaths:complete_paid_revive(player)
check(paid_spawn.ok == true, "Granted paid revive must respawn successfully.")
check(
    #spawns == 2 and spawns[2].cframe.Position == Vector3.new(5, 3, -112),
    "Paid revive must return to the active checkpoint."
)
check(session.WipeDecisionEndsAt == nil, "Successful paid revive must clear the wipe deadline.")

local third_death = deaths:on_player_died(player, CFrame.new(30, 3, -30))
check(third_death.ok == true and session.Members["101"].Mode == "Spectating", "Death after paid revive must return to Spectating and reopen the wipe window.")

now = 1029
local before_expiry = deaths:tick(now)
check(before_expiry.failed == false and session.State == "Active", "Wipe must remain active before its deadline.")
now = 1030
local expiry = deaths:tick(now)
check(expiry.failed == true and session.State == "Failed", "Wipe deadline expiry must mark the run Failed.")

-- Party safety: one Active member means the global wipe timer must not open.
session = {
    SessionId = "session-party",
    State = "Active",
    Members = {
        ["101"] = {UserId = 101, Connected = true, Mode = "Active", FreeReviveUsed = true, PaidReviveCount = 0},
        ["102"] = {UserId = 102, Connected = true, Mode = "Active", FreeReviveUsed = false, PaidReviveCount = 0},
    },
}
local party_deaths = DungeonDeathService.new(fake_sessions, fake_checkpoint, "session-party", {
    clock = function() return now end,
    schedule = schedule,
    spawn_player = spawn_player,
    emit_state = emit_state,
    paid_offer_provider = function(_user_id: number) return {price = 9, paid_number = 1} end,
})
check(party_deaths:on_player_died(player, CFrame.new()).ok == true, "Party member death must be accepted.")
check(session.WipeDecisionEndsAt == nil, "One living party member must keep encounter running without global wipe pause.")

print(string.format("[Dungeon Death/Revive Tests] PASS: %d assertions.", assertions))
