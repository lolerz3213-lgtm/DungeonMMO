--!strict
-- Dungeon-only wrapper that keeps temporary test HP out of Phase 1 combat.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Combat = ServerScriptService:WaitForChild("Combat")
local MarauderFactory = require(Combat:WaitForChild("MarauderFactory"))
local DungeonDefinitions = require(
    ReplicatedStorage:WaitForChild("Core")
        :WaitForChild("Shared")
        :WaitForChild("DungeonDefinitions")
)

local DungeonMarauderFactory = {}

function DungeonMarauderFactory.create(options: any): Model
    local marauder = MarauderFactory.create(options)
    local humanoid = marauder:FindFirstChildOfClass("Humanoid")
    assert(humanoid ~= nil, "Dungeon Marauder requires a Humanoid")

    local max_health =
        DungeonDefinitions.TEST_DUNGEON.StandardMarauderMaxHealth
    humanoid.MaxHealth = max_health
    humanoid.Health = max_health

    return marauder
end

return table.freeze(DungeonMarauderFactory)
