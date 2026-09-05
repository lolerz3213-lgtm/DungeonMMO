--!strict
local ServerScriptService = game:GetService("ServerScriptService")

local Dungeon = ServerScriptService:WaitForChild("Dungeon")
local module = Dungeon:FindFirstChild("CheckpointService")
if not module then
    error("[Checkpoint Service Tests] RED: CheckpointService is missing.")
end
local CheckpointService = require(module)

local assertions = 0
local function check(condition: boolean, message: string)
    assertions += 1
    if not condition then
        error("[Checkpoint Service Tests] " .. message, 2)
    end
end

local session = {Checkpoint = {Id = "Entrance", Sequence = 0}}
local fake_sessions: any = {}
function fake_sessions:get(_session_id: string): any
    return session
end
function fake_sessions:activate_checkpoint(
    _session_id: string,
    checkpoint_id: string,
    sequence: number
): any
    if sequence < session.Checkpoint.Sequence then
        return {ok = false, reason = "CheckpointRegression", session = session}
    end
    session.Checkpoint = {Id = checkpoint_id, Sequence = sequence}
    return {ok = true, session = session}
end

local checkpoints = CheckpointService.new(fake_sessions, "session-checkpoint")
checkpoints:register("Entrance", 0, CFrame.new(0, 3, 0))
checkpoints:register("Room1Start", 1, CFrame.new(0, 3, -18))
checkpoints:register("Room2Start", 2, CFrame.new(0, 3, -112))
checkpoints:register("BossRoomStart", 3, CFrame.new(0, 3, -284))

local initial = checkpoints:get_active_checkpoint()
check(
    initial.Id == "Entrance" and initial.Sequence == 0,
    "Entrance must be the initial fallback checkpoint."
)
check(
    checkpoints:activate("Room1Start").ok == true,
    "Entering Room 1 must move the checkpoint to Room1Start."
)
check(
    checkpoints:get_active_checkpoint().Id == "Room1Start",
    "Room1Start must become the active checkpoint."
)
check(
    checkpoints:activate("Room2Start").ok == true,
    "Unlocking Room 2 must move the checkpoint to Room2Start."
)
check(
    checkpoints:activate("BossRoomStart").ok == true,
    "Unlocking the boss must move the checkpoint to BossRoomStart."
)
local backwards = checkpoints:activate("Room1Start")
check(
    backwards.ok == false and backwards.reason == "CheckpointRegression",
    "Checkpoint activation must reject movement to an earlier room."
)
check(
    checkpoints:get_active_checkpoint().Id == "BossRoomStart",
    "Rejected regression must not move the checkpoint backwards."
)

print(string.format("[Checkpoint Service Tests] PASS: %d assertions.", assertions))
