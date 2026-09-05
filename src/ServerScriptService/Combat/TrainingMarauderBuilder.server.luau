--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local CombatConfig = require(
    ReplicatedStorage:WaitForChild("Combat"):WaitForChild("Shared"):WaitForChild("CombatConfig")
)
local MarauderFactory = require(script.Parent:WaitForChild("MarauderFactory"))
local MarauderConfig = CombatConfig.TRAINING_MARAUDER

for index, model_name in MarauderConfig.MODEL_NAMES do
    local existing = Workspace:FindFirstChild(model_name)
    if existing then
        existing:Destroy()
    end

    MarauderFactory.create({
        Parent = Workspace,
        Name = model_name,
        SpawnCFrame = CFrame.new(MarauderConfig.SPAWN_POSITIONS[index]),
        SpawnIndex = index,
        RespawnEnabled = true,
        ControllerEnabled = true,
    })
end

print(string.format("[Combat Prototype] %d jointed Training Marauders created.", #MarauderConfig.MODEL_NAMES))
