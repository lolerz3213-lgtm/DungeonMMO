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
Asserts that an offensive state may be interrupted immediately by Block.

Args:
    current_state (string): Offensive state being interrupted.

Returns:
    None.
]]
local function assert_block_interrupt(current_state: string)
    if not StateRules.can_transition(current_state, State.BLOCKING) then
        error(
            string.format(
                "[Block Priority State Tests] %s must transition to Blocking.",
                current_state
            ),
            2
        )
    end

    assertion_count += 1
end


assert_block_interrupt(State.WIND_UP)
assert_block_interrupt(State.ACTIVE)
assert_block_interrupt(State.RECOVERY)

if StateRules.can_transition(State.DODGING, State.BLOCKING) then
    error(
        "[Block Priority State Tests] Dodge must not cancel into Block."
    )
end
assertion_count += 1

if StateRules.can_transition(State.GUARD_BREAK, State.BLOCKING) then
    error(
        "[Block Priority State Tests] Guard Break must still forbid Block."
    )
end
assertion_count += 1

print(
    string.format(
        "[Block Priority State Tests] PASS: %d assertions.",
        assertion_count
    )
)
