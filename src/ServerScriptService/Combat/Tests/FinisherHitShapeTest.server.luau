local ReplicatedStorage = game:GetService(
    "ReplicatedStorage"
)

local shared_folder = ReplicatedStorage
    :WaitForChild("Combat")
    :WaitForChild("Shared")

local CombatConfig = require(
    shared_folder:WaitForChild("CombatConfig")
)

local assertion_count = 0


--[[
Raises an error when a finisher-shape assertion fails.

Args:
    condition (boolean): Required test condition.
    message (string): Failure explanation.

Returns:
    None.
]]
local function assert_true(
    condition: boolean,
    message: string
)
    assertion_count += 1

    if not condition then
        error(
            "[Finisher Hit Shape Tests] " .. message
        )
    end
end


local attacks =
    CombatConfig.BASIC_ATTACK.ATTACKS

local slash_two = attacks.Slash2
local finisher = attacks.Finisher

assert_true(
    finisher.ARC_DEGREES < slash_two.ARC_DEGREES,
    "Finisher must be narrower than Slash2."
)

assert_true(
    finisher.REACH_STUDS > slash_two.REACH_STUDS,
    "Finisher must reach farther forward than Slash2."
)

assert_true(
    finisher.HITBOX.SIZE.X
        < slash_two.HITBOX.SIZE.X,
    "Finisher broad-phase box must be narrower than Slash2."
)

assert_true(
    finisher.HITBOX.SIZE.Z
        > slash_two.HITBOX.SIZE.Z,
    "Finisher broad-phase box must extend farther forward."
)

assert_true(
    finisher.HITBOX.FORWARD_OFFSET
        > slash_two.HITBOX.FORWARD_OFFSET,
    "Finisher hitbox center must sit farther forward."
)

assert_true(
    finisher.POWER_MULTIPLIER == 1.35,
    "Finisher damage multiplier must remain unchanged."
)

assert_true(
    finisher.HITBOX.SAMPLE_COUNT == 4,
    "Finisher must retain swept Active-window sampling."
)

print(
    string.format(
        "[Finisher Hit Shape Tests] PASS: %d assertions.",
        assertion_count
    )
)
