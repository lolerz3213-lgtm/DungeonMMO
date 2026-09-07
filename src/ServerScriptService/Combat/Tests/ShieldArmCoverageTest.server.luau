--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CombatConfig = require(
    ReplicatedStorage
        :WaitForChild("Combat")
        :WaitForChild("Shared")
        :WaitForChild("CombatConfig")
)

local ShieldConfig = CombatConfig.PROTOTYPE_SHIELD
local assertions = 0

local function check(condition: boolean, message: string)
    assertions += 1

    if not condition then
        error("[Shield Arm Coverage Tests] " .. message, 2)
    end
end

local block_depth_gap =
    ShieldConfig.BLOCK_FORWARD_STUDS
    - ShieldConfig.BLOCK_HAND_FORWARD_STUDS

local bash_depth_gap =
    ShieldConfig.BASH_FORWARD_STUDS
    - ShieldConfig.BASH_HAND_FORWARD_STUDS

local block_lateral_gap = math.abs(
    ShieldConfig.BLOCK_LEFT_STUDS
    - ShieldConfig.BLOCK_HAND_LEFT_STUDS
)

local bash_lateral_gap = math.abs(
    ShieldConfig.BASH_LEFT_STUDS
    - ShieldConfig.BASH_HAND_LEFT_STUDS
)

check(
    block_depth_gap >= 0.55,
    "blocking hand must sit at least 0.55 studs behind the shield centre."
)
check(
    bash_depth_gap >= 0.55,
    "bash hand must remain at least 0.55 studs behind the shield centre."
)
check(
    block_lateral_gap <= 0.12,
    "blocking hand must stay close to the shield centreline instead of protruding around its side."
)
check(
    bash_lateral_gap <= 0.12,
    "bash hand must stay close to the shield centreline."
)
check(
    ShieldConfig.BLOCK_POLE_FORWARD_STUDS
        < ShieldConfig.BLOCK_HAND_FORWARD_STUDS,
    "blocking elbow pole must remain behind the hand."
)
check(
    ShieldConfig.BASH_POLE_FORWARD_STUDS
        < ShieldConfig.BASH_HAND_FORWARD_STUDS,
    "bash elbow pole must remain behind the hand."
)

print(string.format(
    "[Shield Arm Coverage Tests] PASS: %d assertions.",
    assertions
))
