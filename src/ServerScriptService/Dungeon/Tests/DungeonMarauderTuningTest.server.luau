--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Dungeon = ServerScriptService:WaitForChild("Dungeon")
local module = Dungeon:FindFirstChild("DungeonMarauderFactory")
if not module then
    error(
        "[Dungeon Marauder Tuning Tests] RED: "
            .. "DungeonMarauderFactory is missing."
    )
end
local DungeonMarauderFactory = require(module)
local CombatConfig = require(
    ReplicatedStorage:WaitForChild("Combat")
        :WaitForChild("Shared")
        :WaitForChild("CombatConfig")
)

local holder = Instance.new("Folder")
local marauder = DungeonMarauderFactory.create({
    Parent = holder,
    Name = "DungeonTuningTarget",
    SpawnCFrame = CFrame.new(0, 3, 0),
    SpawnIndex = 1,
    RespawnEnabled = false,
    ControllerEnabled = false,
})
local humanoid = marauder:FindFirstChildOfClass("Humanoid")
assert(humanoid ~= nil, "Dungeon Marauder must have a Humanoid.")
assert(
    humanoid ~= nil and humanoid.MaxHealth == 40 and humanoid.Health == 40,
    "Dungeon test Marauders must use the temporary 40 HP tuning."
)
assert(
    CombatConfig.TRAINING_MARAUDER.MAX_HEALTH ~= 40,
    "Dungeon tuning must not alter the accepted Phase 1 training Marauder HP."
)
holder:Destroy()

print("[Dungeon Marauder Tuning Tests] PASS")
