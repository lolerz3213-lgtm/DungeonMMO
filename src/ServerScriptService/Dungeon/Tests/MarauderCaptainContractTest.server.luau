--!strict
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Dungeon = ServerScriptService:WaitForChild("Dungeon")
local module = Dungeon:FindFirstChild("MarauderCaptainFactory")
if not module then error("[Marauder Captain Contract Tests] RED: MarauderCaptainFactory is missing.") end
local Factory = require(module)
local CombatConfig = require(ReplicatedStorage:WaitForChild("Combat"):WaitForChild("Shared"):WaitForChild("CombatConfig"))

local assertions = 0
local function check(condition: boolean, message: string)
    assertions += 1
    if not condition then error("[Marauder Captain Contract Tests] " .. message, 2) end
end

local holder = Instance.new("Folder")
local captain = Factory.create({Parent = holder, SpawnCFrame = CFrame.new(0, 3, 0)})
local humanoid = captain:FindFirstChildOfClass("Humanoid")
check(humanoid ~= nil, "Captain must have a Humanoid.")
check(captain:FindFirstChild("HumanoidRootPart") ~= nil, "Captain must have a HumanoidRootPart.")
check(captain:GetAttribute("Boss") == true, "Captain must be marked Boss=true.")
check(captain:GetAttribute("BossId") == "MarauderCaptain", "Captain BossId must be MarauderCaptain.")
check(CollectionService:HasTag(captain, "DungeonMarauderCaptain"), "Captain must be tagged for its dedicated server controller.")
check(Dungeon:FindFirstChild("MarauderCaptainController") ~= nil, "Dedicated Captain controller script must exist.")
check(
    humanoid ~= nil and humanoid.MaxHealth == 120,
    "Captain must use the temporary 120 HP test tuning."
)
check(captain:FindFirstChild("Body") ~= nil and captain:FindFirstChild("TrainingBlade") ~= nil, "Captain must keep a visible Marauder-style rig.")
check(type(Factory.ATTACKS) == "table", "Captain attacks must be exposed as a contract table.")
local names = {"CaptainSlash", "CaptainHeavy", "CaptainShockwave"}
for _, name in ipairs(names) do
    local attack = Factory.ATTACKS[name]
    check(type(attack) == "table", name .. " must exist.")
    check(type(attack.WIND_UP_SECONDS) == "number" and attack.WIND_UP_SECONDS > 0, name .. " must have a windup.")
    check(type(attack.HEALTH_DAMAGE) == "number" and attack.HEALTH_DAMAGE > 0, name .. " must have health damage.")
    check(type(attack.STAMINA_DAMAGE) == "number" and attack.STAMINA_DAMAGE >= 0, name .. " must have stamina damage.")
end
holder:Destroy()
print(string.format("[Marauder Captain Contract Tests] PASS: %d assertions.", assertions))
