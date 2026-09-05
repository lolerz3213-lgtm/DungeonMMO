--!strict
local ServerScriptService = game:GetService("ServerScriptService")

local Core = ServerScriptService:WaitForChild("Core")
local Adapters = Core:WaitForChild("Adapters")
local Services = Core:WaitForChild("Services")

local service_module = Services:FindFirstChild("ProgressionService")
if not service_module then
    error("[Progression Service Tests] RED: ProgressionService is missing.")
end

local InMemoryProfileAdapter = require(Adapters:WaitForChild("InMemoryProfileAdapter"))
local ProfileService = require(Services:WaitForChild("ProfileService"))
local ProgressionService = require(service_module)

local assertions = 0
local function check(condition: boolean, message: string)
    assertions += 1
    if not condition then
        error("[Progression Service Tests] " .. message, 2)
    end
end

local profiles = ProfileService.new(InMemoryProfileAdapter.new())
assert(profiles:load(1001))
assert(profiles:load(1002))
local progression = ProgressionService.new(profiles)

local first = progression:grant_xp(1001, 99)
check(first.ok == true, "99 XP grant must succeed.")
local c1 = assert(profiles:get_character(1001, 1))
check(c1.Level == 1 and c1.XP == 99, "99 XP must remain Level 1 with 99 carried XP.")

local level_up = progression:grant_xp(1001, 1)
check(level_up.ok == true and level_up.levels_gained == 1, "+1 XP must trigger exactly one level-up.")
c1 = assert(profiles:get_character(1001, 1))
check(c1.Level == 2 and c1.XP == 0, "100 total XP must become Level 2 with 0 carried XP.")

local multi = progression:grant_xp(1002, 400)
check(multi.ok == true and multi.levels_gained == 2, "400 XP from Level 1 must process multiple level-ups.")
local c2 = assert(profiles:get_character(1002, 1))
check(c2.Level == 3 and c2.XP == 150, "400 XP must end at Level 3 with 150 carried XP.")

check(progression:grant_xp(1001, -1).ok == false, "Negative XP must be rejected.")
check(progression:grant_xp(1001, math.huge).ok == false, "Infinite XP must be rejected.")
local nan = 0 / 0
check(progression:grant_xp(1001, nan).ok == false, "NaN XP must be rejected.")

print(string.format("[Progression Service Tests] PASS: %d assertions.", assertions))
