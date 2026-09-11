--!strict
-- Focused Ranger slow integration contract for normal Marauder chase movement.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local CombatConfig = require(
    ReplicatedStorage
        :WaitForChild("Combat")
        :WaitForChild("Shared")
        :WaitForChild("CombatConfig")
)
local MarauderBehaviorRules = require(
    ServerScriptService
        :WaitForChild("Combat")
        :WaitForChild("MarauderBehaviorRules")
)

local config = CombatConfig.TRAINING_MARAUDER
local distance = config.CHASE_STOP_RANGE_STUDS + 50
local delta_seconds = 0.25
local normal = MarauderBehaviorRules.get_chase_step(
    distance,
    delta_seconds
)
local slowed = MarauderBehaviorRules.get_chase_step(
    distance,
    delta_seconds,
    0.60
)

assert(
    math.abs(
        normal
            - config.CHASE_SPEED_STUDS_PER_SECOND * delta_seconds
    ) < 0.001,
    "Existing Marauder movement must remain unchanged without a modifier."
)
assert(
    math.abs(slowed - normal * 0.60) < 0.001,
    "Ranger slow multiplier must reduce manual chase movement exactly once."
)
assert(
    MarauderBehaviorRules.get_chase_step(
        distance,
        delta_seconds,
        nil
    ) == normal,
    "Missing speed multiplier must fail neutral."
)

print("[Ranger] Marauder slow movement rules passed.")
