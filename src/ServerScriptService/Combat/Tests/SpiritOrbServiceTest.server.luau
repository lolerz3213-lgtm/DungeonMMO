--!strict
local ReplicatedStorage =
    game:GetService("ReplicatedStorage")
local ServerScriptService =
    game:GetService("ServerScriptService")

local CombatConfig = require(
    ReplicatedStorage
        :WaitForChild("Combat")
        :WaitForChild("Shared")
        :WaitForChild("CombatConfig")
)
local SpiritOrbService = require(
    ServerScriptService
        :WaitForChild("Combat")
        :WaitForChild("SpiritOrbService")
)

local assertions = 0

local function check(
    value: boolean,
    message: string
)
    assertions += 1
    if not value then
        error(
            "[Spirit Orb Service Tests] "
                .. message,
            2
        )
    end
end

check(
    type(SpiritOrbService.fire)
        == "function",
    "Spirit Orb must expose authoritative projectile firing."
)
check(
    CombatConfig.SPIRIT_ORB
        .MAX_RANGE_STUDS > 0,
    "Spirit Orb must have finite server-owned range."
)
check(
    CombatConfig.SPIRIT_ORB
        .SPEED_STUDS_PER_SECOND > 0,
    "Spirit Orb must have real travel speed."
)
check(
    CombatConfig.SPIRIT_ORB
        .FINISHER_AOE_RADIUS > 0,
    "third-hit Spirit Orb must have AoE radius."
)
check(
    CombatConfig.SPIRIT_ORB
        .FINISHER_DIAMETER
        > CombatConfig.SPIRIT_ORB
            .NORMAL_DIAMETER,
    "third-hit orb must be visibly larger."
)

print(
    string.format(
        "[Spirit Orb Service Tests] PASS: %d assertions.",
        assertions
    )
)
