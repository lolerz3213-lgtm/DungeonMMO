local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared_folder = ReplicatedStorage
    :WaitForChild("Combat")
    :WaitForChild("Shared")

local CombatTypes = require(shared_folder:WaitForChild("CombatTypes"))
local StateRules = require(shared_folder:WaitForChild("StateRules"))

local State = CombatTypes.State
local assertion_count = 0


local function assert_true(condition: boolean, message: string)
    assertion_count += 1

    if not condition then
        error("[Combat Lifecycle State Tests] " .. message, 2)
    end
end


assert_true(State.DEAD == "Dead", "Dead state is missing.")

local live_states = {
    State.LOCOMOTION,
    State.WIND_UP,
    State.ACTIVE,
    State.RECOVERY,
    State.BLOCKING,
    State.DODGING,
    State.GUARD_BREAK,
    State.MENDING,
}

for _, state_name in live_states do
    assert_true(
        StateRules.can_transition(state_name, State.DEAD),
        string.format("%s must be able to terminate into Dead.", state_name)
    )
end

for _, state_name in live_states do
    assert_true(
        not StateRules.can_transition(State.DEAD, state_name),
        string.format("Dead must not transition back into %s.", state_name)
    )
end

print(
    string.format(
        "[Combat Lifecycle State Tests] PASS: %d assertions.",
        assertion_count
    )
)
