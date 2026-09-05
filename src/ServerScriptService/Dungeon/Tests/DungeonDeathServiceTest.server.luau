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
function fake_sessions:consume_free_revive(_session_id: string, user_id: number): any
    local member = session.Members[tostring(user_id)]
    if member.FreeReviveUsed then return {ok = false, reason = "FreeReviveAlreadyUsed", session = session} end
    if member.Mode ~= "Dead" and member.Mode ~= "Spectating" then return {ok = false, reason = "MemberNotDead", session = session} end
    member.FreeReviveUsed = true
    member.Mode = "Active"
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

local player: any = {UserId = 101, Name = "Solo"}
local deaths = DungeonDeathService.new(
    fake_sessions,
    fake_checkpoint,
    "session-death",
    {
        clock = function() return now end,
        spawn_player = spawn_player,
        emit_state = emit_state,
        paid_offer_provider = function(_user_id: number) return {price = 9, paid_number = 1} end,
    }
)

local died = deaths:on_player_died(player, CFrame.new(12, 3, -20))
check(died.ok == true, "First death must be accepted.")
check(session.Members["101"].Mode == "Dead", "First death with free revive remaining must enter Dead mode.")
check(session.WipeDecisionEndsAt == now + 30, "Solo death must open exactly a 30-second wipe window.")
check(states[101].free_available == true, "First death state must offer the free revive.")

now = 1029
local free = deaths:request_free_revive(player)
check(free.ok == true, "Free revive at second 29 must succeed.")
check(session.Members["101"].FreeReviveUsed == true, "Free revive must be consumed exactly once.")
check(session.Members["101"].Mode == "Active", "Successful free revive must restore Active mode.")
check(
    #spawns == 1
        and spawns[1].cframe.Position == Vector3.new(5, 3, -112),
    "Free revive must return to the active checkpoint."
)
check(session.WipeDecisionEndsAt == nil, "A successful revive must clear the wipe deadline.")

local second_death = deaths:on_player_died(player, CFrame.new(20, 3, -25))
check(second_death.ok == true and session.Members["101"].Mode == "Spectating", "Death after free revive is used must enter Spectating mode.")
check(states[101].free_available == false and states[101].paid_offer.price == 9, "Second death must offer current paid tier instead of another free revive.")

-- Product/Robux revives follow the same checkpoint rule as free revives.
session.Members["101"].Mode = "Active"
local paid_spawn = deaths:complete_paid_revive(player)
check(paid_spawn.ok == true, "Granted paid revive must respawn successfully.")
check(
    #spawns == 2
        and spawns[2].cframe.Position == Vector3.new(5, 3, -112),
    "Paid revive must return to the active checkpoint."
)
local third_death = deaths:on_player_died(player, CFrame.new(30, 3, -30))
check(third_death.ok == true and session.Members["101"].Mode == "Spectating", "Death after paid revive must return to Spectating and reopen the wipe window.")

now = 1058
local before_expiry = deaths:tick(now)
check(before_expiry.failed == false and session.State == "Active", "Wipe must remain active at second 29.")
now = 1059
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
    spawn_player = spawn_player,
    emit_state = emit_state,
    paid_offer_provider = function(_user_id: number) return {price = 9, paid_number = 1} end,
})
check(party_deaths:on_player_died(player, CFrame.new()).ok == true, "Party member death must be accepted.")
check(session.WipeDecisionEndsAt == nil, "One living party member must keep encounter running without global wipe pause.")

print(string.format("[Dungeon Death/Revive Tests] PASS: %d assertions.", assertions))
