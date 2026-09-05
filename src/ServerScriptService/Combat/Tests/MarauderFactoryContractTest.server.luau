--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local Combat = ServerScriptService:WaitForChild("Combat")
local factory_module = Combat:FindFirstChild("MarauderFactory")
if not factory_module then
    error("[Marauder Factory Tests] RED: MarauderFactory is missing.")
end
local MarauderFactory = require(factory_module)
local CombatConfig = require(ReplicatedStorage:WaitForChild("Combat"):WaitForChild("Shared"):WaitForChild("CombatConfig"))

local assertions = 0
local function check(condition: boolean, message: string)
    assertions += 1
    if not condition then
        error("[Marauder Factory Tests] " .. message, 2)
    end
end

local folder = Instance.new("Folder")
folder.Name = "MarauderFactoryContractTemp"
folder.Parent = Workspace
local model = MarauderFactory.create({
    Parent = folder,
    Name = "FactoryContractMarauder",
    SpawnCFrame = CFrame.new(0, 2, 0),
    SpawnIndex = 77,
    RespawnEnabled = false,
    ControllerEnabled = false,
    TargetEnabled = false,
})

check(model:FindFirstChild("HumanoidRootPart") ~= nil, "Factory marauder must include HumanoidRootPart.")
check(model:FindFirstChild("CollisionBody") ~= nil, "Factory marauder must include CollisionBody.")
check(model:FindFirstChild("Body") ~= nil, "Factory marauder must include Body.")
check(model:FindFirstChild("Head") ~= nil, "Factory marauder must include Head.")
check(model:FindFirstChild("RightArm") ~= nil and model:FindFirstChild("LeftArm") ~= nil, "Factory marauder must include both arms.")
check(model:FindFirstChild("TrainingBlade") ~= nil, "Factory marauder must include training blade.")
local humanoid = model:FindFirstChildOfClass("Humanoid")
check(humanoid ~= nil and humanoid.MaxHealth == CombatConfig.TRAINING_MARAUDER.MAX_HEALTH, "Factory marauder must preserve Phase 1 max health.")
check(model:GetAttribute(CombatConfig.TRAINING_MARAUDER.SPAWN_INDEX_ATTRIBUTE) == 77, "Factory marauder must preserve spawn index contract.")
check(model:GetAttribute("MarauderRespawnEnabled") == false, "Dungeon factory must be able to disable automatic respawn.")

folder:Destroy()
print(string.format("[Marauder Factory Tests] PASS: %d assertions.", assertions))
