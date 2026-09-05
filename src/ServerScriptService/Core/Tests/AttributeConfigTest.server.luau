--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local shared = ReplicatedStorage:WaitForChild("Core"):WaitForChild("Shared")
local module = shared:FindFirstChild("AttributeConfig")
if not module then error("[Attribute Config Tests] RED: AttributeConfig is missing.") end
local AttributeConfig = require(module)
local n=0
local function check(v:boolean,m:string) n+=1 if not v then error("[Attribute Config Tests] "..m,2) end end
check(AttributeConfig.BASE_VALUE == 5, "base value must be 5")
check(AttributeConfig.physical_multiplier(5) == 1, "Strength 5 must be neutral")
check(AttributeConfig.heal_multiplier(5) == 1, "Spirit 5 must be neutral")
check(AttributeConfig.max_health(5) == 100, "Vitality 5 must yield 100 HP")
check(AttributeConfig.effective_investment(20) > 15 and AttributeConfig.effective_investment(20) < 20, "soft cap must diminish after 15 invested points")
check(AttributeConfig.physical_multiplier(6) > 1, "Strength 6 must increase physical damage")
check(AttributeConfig.heal_multiplier(6) > 1, "Spirit 6 must increase healing")
check(AttributeConfig.max_health(6) > 100, "Vitality 6 must increase max health")
print(string.format("[Attribute Config Tests] PASS: %d assertions.", n))
