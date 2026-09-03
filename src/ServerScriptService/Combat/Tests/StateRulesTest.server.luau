local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared_folder = ReplicatedStorage
    :WaitForChild("Combat")
    :WaitForChild("Shared")

local CombatConfig = require(
    shared_folder:WaitForChild("CombatConfig")
)
local CombatTypes = require(
    shared_folder:WaitForChild("CombatTypes")
)
local StateRules = require(
    shared_folder:WaitForChild("StateRules")
)

local State = CombatTypes.State
local BasicAttack = CombatConfig.BASIC_ATTACK

local passed_assertions = 0


--[[
Raises an error when a test expectation is false.

Args:
    condition (boolean): Condition that must be true.
    message (string): Failure description.

Returns:
    None.
]]
local function assert_true(condition: boolean, message: string)
    if not condition then
        error("[Combat Tests] " .. message, 2)
    end

    passed_assertions += 1
end


--[[
Raises an error when two values do not match.

Args:
    actual (any): Actual value produced by the code under test.
    expected (any): Value required by the test.
    message (string): Failure description.

Returns:
    None.
]]
local function assert_equal(
    actual: any,
    expected: any,
    message: string
)
    if actual ~= expected then
        error(
            string.format(
                "[Combat Tests] %s Expected %s, received %s.",
                message,
                tostring(expected),
                tostring(actual)
            ),
            2
        )
    end

    passed_assertions += 1
end


assert_true(
    StateRules.can_transition(
        State.LOCOMOTION,
        State.WIND_UP
    ),
    "Locomotion must allow WindUp."
)
assert_true(
    StateRules.can_transition(
        State.WIND_UP,
        State.ACTIVE
    ),
    "WindUp must allow Active."
)
assert_true(
    StateRules.can_transition(
        State.ACTIVE,
        State.RECOVERY
    ),
    "Active must allow Recovery."
)
assert_true(
    StateRules.can_transition(
        State.RECOVERY,
        State.LOCOMOTION
    ),
    "Recovery must allow Locomotion."
)
assert_true(
    StateRules.can_transition(
        State.RECOVERY,
        State.WIND_UP
    ),
    "Recovery must allow buffered WindUp."
)
assert_true(
    not StateRules.can_transition(
        State.WIND_UP,
        State.LOCOMOTION
    ),
    "WindUp must not normally cancel to Locomotion."
)

local slash_1 = BasicAttack.ATTACKS.Slash1

assert_equal(
    StateRules.get_movement_scale(
        State.WIND_UP,
        slash_1
    ),
    0.65,
    "WindUp movement scale is wrong."
)
assert_equal(
    StateRules.get_movement_scale(
        State.ACTIVE,
        slash_1
    ),
    0.40,
    "Active movement scale is wrong."
)
assert_equal(
    StateRules.get_movement_scale(
        State.RECOVERY,
        slash_1
    ),
    0.75,
    "Recovery movement scale is wrong."
)
assert_equal(
    StateRules.get_movement_scale(
        State.LOCOMOTION,
        slash_1
    ),
    1,
    "Locomotion movement scale is wrong."
)

assert_equal(
    StateRules.get_next_attack_id(
        "Slash1",
        BasicAttack.ATTACK_ORDER
    ),
    "Slash2",
    "Slash1 must lead to Slash2."
)
assert_equal(
    StateRules.get_next_attack_id(
        "Slash2",
        BasicAttack.ATTACK_ORDER
    ),
    "Finisher",
    "Slash2 must lead to Finisher."
)
assert_equal(
    StateRules.get_next_attack_id(
        "Finisher",
        BasicAttack.ATTACK_ORDER
    ),
    "Slash1",
    "Finisher must loop to Slash1."
)

assert_true(
    not StateRules.is_buffer_window_open(
        0.07,
        0.28,
        BasicAttack.COMBO_BUFFER_SECONDS
    ),
    "Buffer must be closed before the late recovery window."
)
assert_true(
    StateRules.is_buffer_window_open(
        0.08,
        0.28,
        BasicAttack.COMBO_BUFFER_SECONDS
    ),
    "Buffer must open for the final 0.20 seconds of recovery."
)
assert_true(
    StateRules.should_reset_combo(
        0.85,
        BasicAttack.COMBO_RESET_SECONDS
    ),
    "Combo must reset at the configured timeout."
)

print(
    string.format(
        "[Combat Tests] PASS: %d StateRules assertions.",
        passed_assertions
    )
)
