--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local SkillDefinitions = require(
    ReplicatedStorage:WaitForChild("Combat"):WaitForChild("Shared"):WaitForChild("SkillDefinitions")
)
local WindStrikeService = require(
    ServerScriptService:WaitForChild("Combat"):WaitForChild("WindStrikeService")
)

local assertions = 0
local function check(value: boolean, message: string)
    assertions += 1
    if not value then
        error("[Wind Strike Service Tests] " .. message, 2)
    end
end

local wind = SkillDefinitions.get("WindStrike")
check(type(WindStrikeService.fire) == "function", "Wind Strike must expose server projectile firing.")
check(wind ~= nil, "Wind Strike definition must exist.")
check(wind.KIND == "MagicProjectile", "Wind Strike must use MagicProjectile routing.")
check(wind.RANGE_STUDS == 60, "Wind Strike must have finite 60-stud range.")
check(wind.PROJECTILE_SPEED > 0, "Wind Strike must travel rather than resolve instantly.")
check(wind.WIND_UP_SECONDS == 1.0, "Wind Strike must charge for one second.")
check(wind.MOVEMENT_SCALE.WIND_UP == 0, "Wind Strike charge must root the caster.")

print(string.format("[Wind Strike Service Tests] PASS: %d assertions.", assertions))
