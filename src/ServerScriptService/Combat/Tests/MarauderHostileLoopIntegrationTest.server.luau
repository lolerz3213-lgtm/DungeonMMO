local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local shared_folder = ReplicatedStorage
    :WaitForChild("Combat")
    :WaitForChild("Shared")
local server_combat_folder = ServerScriptService
    :WaitForChild("Combat")

local CombatConfig = require(
    shared_folder:WaitForChild("CombatConfig")
)

local MarauderConfig = CombatConfig.TRAINING_MARAUDER
local assertion_count = 0


--[[
Asserts one boolean condition for the hostile-loop integration suite.

Args:
    condition (boolean): Condition that must be true.
    message (string): Failure explanation.

Returns:
    None.
]]
local function assert_true(condition: boolean, message: string)
    if not condition then
        error("[Marauder Hostile Loop Tests] " .. message, 2)
    end

    assertion_count += 1
end


assert_true(
    server_combat_folder:FindFirstChild("MarauderBehaviorRules") ~= nil,
    "MarauderBehaviorRules is missing."
)
assert_true(
    server_combat_folder:FindFirstChild("TrainingMarauderController") ~= nil,
    "TrainingMarauderController is missing."
)
assert_true(
    MarauderConfig.ROOM_WIDE_AGGRO == true,
    "Prototype arena must retain room-wide aggro."
)
assert_true(
    MarauderConfig.CHASE_SPEED_STUDS_PER_SECOND == 14,
    "Hostile-loop chase speed must be 14 studs per second."
)
assert_true(
    MarauderConfig.WIND_UP_SECONDS == 0.45,
    "Hostile-loop basic wind-up must be 0.45 seconds."
)
assert_true(
    MarauderConfig.ATTACK_INTERVAL_SECONDS == 1.6,
    "Hostile-loop attack interval must be 1.6 seconds."
)
assert_true(
    MarauderConfig.CHASE_STOP_RANGE_STUDS == 4.75,
    "Chase stop range must remain 4.75 studs."
)

local deadline = os.clock() + 2
local marauder = Workspace:FindFirstChild(MarauderConfig.MODEL_NAME)

while not marauder and os.clock() < deadline do
    task.wait(0.05)
    marauder = Workspace:FindFirstChild(MarauderConfig.MODEL_NAME)
end

assert_true(marauder ~= nil, "Training Marauder runtime model is missing.")

if not marauder then
    error("[Marauder Hostile Loop Tests] Runtime Marauder unavailable.")
end

while marauder:GetAttribute(MarauderConfig.AI_STATE_ATTRIBUTE) == nil
    and os.clock() < deadline do
    task.wait(0.05)
end

local state = marauder:GetAttribute(MarauderConfig.AI_STATE_ATTRIBUTE)
local aggro_target = marauder:GetAttribute(
    MarauderConfig.AGGRO_TARGET_ATTRIBUTE
)
local valid_states = {
    Idle = true,
    Chasing = true,
    Ready = true,
    Attacking = true,
    Staggered = true,
    Dead = true,
}

assert_true(
    type(state) == "string" and valid_states[state] == true,
    "Runtime Marauder must expose a recognised AI state."
)
assert_true(
    type(aggro_target) == "number",
    "Runtime Marauder must expose a numeric aggro target user ID."
)

print(
    string.format(
        "[Marauder Hostile Loop Tests] PASS: %d assertions.",
        assertion_count
    )
)
