--!strict
-- Minimal functional Phase 2A Base shell. Final art/UI is deliberately deferred.
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

if Workspace:FindFirstChild("BasePrototype") then
    return
end

local root = Instance.new("Folder")
root.Name = "BasePrototype"
root.Parent = Workspace

local floor = Instance.new("Part")
floor.Name = "BaseFloor"
floor.Size = Vector3.new(80, 1, 80)
floor.Anchored = true
floor.Position = Vector3.new(0, -0.5, 0)
floor.Material = Enum.Material.Slate
floor.Parent = root

local spawn = Instance.new("SpawnLocation")
spawn.Name = "BaseSpawn"
spawn.Size = Vector3.new(8, 1, 8)
spawn.Anchored = true
spawn.Neutral = true
spawn.Position = Vector3.new(0, 0.5, 18)
spawn.Parent = root

local portal = Instance.new("Part")
portal.Name = "TestDungeonPortal"
portal.Size = Vector3.new(8, 10, 2)
portal.Anchored = true
portal.CanCollide = true
portal.Position = Vector3.new(0, 5, -20)
portal.Material = Enum.Material.Neon
portal:SetAttribute("DungeonId", "TestDungeon")
portal.Parent = root

local prompt = Instance.new("ProximityPrompt")
prompt.Name = "DungeonEntryPrompt"
prompt.ActionText = if RunService:IsStudio() then "Published teleport required" else "Enter Dungeon"
prompt.ObjectText = "Marauder Training Dungeon"
prompt.HoldDuration = 0.35
prompt.MaxActivationDistance = 12
prompt.RequiresLineOfSight = false
prompt.Parent = portal

local trainer = Instance.new("Part")
trainer.Name = "ProgressionTrainer"
trainer.Size = Vector3.new(6, 7, 4)
trainer.Anchored = true
trainer.Position = Vector3.new(18, 3.5, 6)
trainer.Material = Enum.Material.SmoothPlastic
trainer.Parent = root

local trainer_prompt = Instance.new("ProximityPrompt")
trainer_prompt.Name = "ProgressionTrainerPrompt"
trainer_prompt.ActionText = "Train"
trainer_prompt.ObjectText = "Progression Trainer"
trainer_prompt.HoldDuration = 0.15
trainer_prompt.MaxActivationDistance = 10
trainer_prompt.RequiresLineOfSight = false
trainer_prompt.Parent = trainer

local trainer_billboard = Instance.new("BillboardGui")
trainer_billboard.Name = "TrainerLabel"
trainer_billboard.Size = UDim2.fromOffset(220, 48)
trainer_billboard.StudsOffset = Vector3.new(0, 5, 0)
trainer_billboard.AlwaysOnTop = true
trainer_billboard.Parent = trainer
local trainer_label = Instance.new("TextLabel")
trainer_label.Size = UDim2.fromScale(1, 1)
trainer_label.BackgroundTransparency = 0.25
trainer_label.TextScaled = true
trainer_label.Text = "PROGRESSION TRAINER"
trainer_label.Parent = trainer_billboard

local billboard = Instance.new("BillboardGui")
billboard.Name = "DungeonLabel"
billboard.Size = UDim2.fromOffset(280, 72)
billboard.StudsOffset = Vector3.new(0, 7, 0)
billboard.AlwaysOnTop = true
billboard.Parent = portal

local label = Instance.new("TextLabel")
label.Size = UDim2.fromScale(1, 1)
label.BackgroundTransparency = 0.2
label.TextScaled = true
label.TextWrapped = true
label.Text = if RunService:IsStudio()
    then "TEST DUNGEON\nPublished teleport required"
    else "TEST DUNGEON\nMarauder Training Dungeon"
label.Parent = billboard

print("[Base Prototype] Functional Base shell created.")
