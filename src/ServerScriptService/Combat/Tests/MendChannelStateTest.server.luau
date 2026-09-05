local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared_folder = ReplicatedStorage
    :WaitForChild("Combat")
    :WaitForChild("Shared")

local CombatTypes = require(shared_folder:WaitForChild("CombatTypes"))
local StateRules = require(shared_folder:WaitForChild("StateRules"))
local SkillDefinitions = require(shared_folder:WaitForChild("SkillDefinitions"))

local State = CombatTypes.State
local assertion_count = 0


local function assert_true(condition: boolean, message: string)
    assertion_count += 1

    if not condition then
        error("[Mend Channel State Tests] " .. message, 2)
    end
end


assert_true(State.MENDING == "Mending", "Mending state is missing.")
assert_true(
    StateRules.can_transition(State.LOCOMOTION, State.MENDING),
    "Locomotion must be able to start Mending."
)
assert_true(
    StateRules.can_transition(State.MENDING, State.BLOCKING),
    "Block must be able to cancel Mending."
)
assert_true(
    StateRules.can_transition(State.MENDING, State.DODGING),
    "Dodge must be able to cancel Mending."
)
assert_true(
    StateRules.can_transition(State.MENDING, State.LOCOMOTION),
    "Mend completion must return to Locomotion."
)
assert_true(
    not StateRules.can_transition(State.MENDING, State.WIND_UP),
    "Mending must not cancel directly into an attack/skill wind-up."
)

local mend = SkillDefinitions.get("Mend")

assert_true(mend ~= nil, "Mend definition is missing.")
assert_true(mend.CHANNEL_SECONDS == 2.0, "Mend channel must last 2 seconds.")
assert_true(mend.PULSE_COUNT == 5, "Mend must use five healing pulses.")
assert_true(mend.PULSE_HEAL == 5, "Each Mend pulse must restore 5 HP.")
assert_true(
    mend.PULSE_INTERVAL_SECONDS == 0.4,
    "Mend pulses must occur every 0.4 seconds."
)
assert_true(
    mend.PULSE_HEAL * mend.PULSE_COUNT == mend.HEAL_AMOUNT,
    "Mend pulse total must equal the advertised heal amount."
)

print(
    string.format(
        "[Mend Channel State Tests] PASS: %d assertions.",
        assertion_count
    )
)
