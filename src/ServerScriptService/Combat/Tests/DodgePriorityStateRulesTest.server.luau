local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared_folder = ReplicatedStorage
    :WaitForChild("Combat")
    :WaitForChild("Shared")

local CombatTypes = require(
    shared_folder:WaitForChild("CombatTypes")
)
local StateRules = require(
    shared_folder:WaitForChild("StateRules")
)

local State = CombatTypes.State
local assertion_count = 0


--[[
Asserts one dodge-priority state transition.

Args:
    current_state (string): Offensive state being interrupted.

Returns:
    None.
]]
local function assert_dodge_interrupt(current_state: string)
    if not StateRules.can_transition(current_state, State.DODGING) then
        error(
            string.format(
                "[Dodge Priority State Tests] %s must transition to Dodging.",
                current_state
            ),
            2
        )
    end

    assertion_count += 1
end


assert_dodge_interrupt(State.WIND_UP)
assert_dodge_interrupt(State.ACTIVE)
assert_dodge_interrupt(State.RECOVERY)

if StateRules.can_transition(State.BLOCKING, State.DODGING) then
    error(
        "[Dodge Priority State Tests] Blocking must not cancel into Dodge."
    )
end
assertion_count += 1

if StateRules.can_transition(State.GUARD_BREAK, State.DODGING) then
    error(
        "[Dodge Priority State Tests] Guard Break must still forbid Dodge."
    )
end
assertion_count += 1

print(
    string.format(
        "[Dodge Priority State Tests] PASS: %d assertions.",
        assertion_count
    )
)
