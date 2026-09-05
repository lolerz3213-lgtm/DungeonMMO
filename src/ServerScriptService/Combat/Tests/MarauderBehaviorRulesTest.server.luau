local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local shared_folder = ReplicatedStorage
    :WaitForChild("Combat")
    :WaitForChild("Shared")
local server_combat_folder = ServerScriptService
    :WaitForChild("Combat")

local CombatConfig = require(
    shared_folder:WaitForChild("CombatConfig")
)
local MarauderBehaviorRules = require(
    server_combat_folder:WaitForChild("MarauderBehaviorRules")
)

local MarauderConfig = CombatConfig.TRAINING_MARAUDER
local assertion_count = 0


--[[
Asserts one boolean condition for the Marauder pressure rules.

Args:
    condition (boolean): Condition that must be true.
    message (string): Failure explanation.

Returns:
    None.
]]
local function assert_true(condition: boolean, message: string)
    if not condition then
        error("[Marauder Behavior Rules Tests] " .. message, 2)
    end

    assertion_count += 1
end


--[[
Asserts two numeric values are equal within a small tolerance.

Args:
    actual (number): Actual numeric value.
    expected (number): Expected numeric value.
    message (string): Failure explanation.

Returns:
    None.
]]
local function assert_near(
    actual: number,
    expected: number,
    message: string
)
    if math.abs(actual - expected) > 1e-6 then
        error(
            string.format(
                "[Marauder Behavior Rules Tests] %s Expected %.4f, got %.4f.",
                message,
                expected,
                actual
            ),
            2
        )
    end

    assertion_count += 1
end


assert_true(
    MarauderConfig.ROOM_WIDE_AGGRO == true,
    "Prototype arena must use room-wide aggro."
)
assert_true(
    MarauderConfig.CHASE_SPEED_STUDS_PER_SECOND == 14,
    "Chase speed must be 14 studs per second."
)
assert_near(
    MarauderConfig.CHASE_STOP_RANGE_STUDS,
    4.75,
    "Chase stop range must remain 4.75 studs."
)
assert_near(
    MarauderConfig.WIND_UP_SECONDS,
    0.45,
    "Basic strike wind-up must be 0.45 seconds."
)
assert_near(
    MarauderConfig.ATTACK_LOCK_SECONDS,
    0.12,
    "Strike direction lock must be 0.12 seconds."
)
assert_near(
    MarauderConfig.ATTACK_INTERVAL_SECONDS,
    1.6,
    "Basic strike interval must be 1.6 seconds."
)

assert_true(
    MarauderBehaviorRules.can_acquire(10000),
    "A living player anywhere in the prototype room must be acquirable."
)
assert_true(
    MarauderBehaviorRules.can_retain(10000),
    "Distance must not release a living retained room target."
)
assert_true(
    not MarauderBehaviorRules.can_acquire(-0.01),
    "Negative distance must remain invalid."
)
assert_true(
    not MarauderBehaviorRules.can_retain(-0.01),
    "Negative retained distance must remain invalid."
)
assert_true(
    MarauderBehaviorRules.get_range_state(4.75) == "Ready",
    "A target at stop distance must be attack-ready."
)
assert_true(
    MarauderBehaviorRules.get_range_state(4.76) == "Chasing",
    "A target beyond stop distance must be chased."
)
assert_near(
    MarauderBehaviorRules.get_chase_step(10, 0.10),
    1.4,
    "Movement must use the fixed 14-stud-per-second Marauder speed."
)
assert_near(
    MarauderBehaviorRules.get_chase_step(5.0, 0.10),
    0.25,
    "Movement must still stop at the configured stop distance."
)
assert_near(
    MarauderBehaviorRules.get_chase_step(4.75, 0.10),
    0,
    "Movement at stop range must be zero."
)

print(
    string.format(
        "[Marauder Behavior Rules Tests] PASS: %d assertions.",
        assertion_count
    )
)
