--!strict
-- Keeps death presentation lifecycle separate from combat camera internals.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CombatConfig = require(
    ReplicatedStorage:WaitForChild("Combat")
        :WaitForChild("Shared")
        :WaitForChild("CombatConfig")
)

local DungeonDeathPresentation = {}

function DungeonDeathPresentation.disable_view_lock(player: any)
    -- CameraController already listens to this attribute and immediately
    -- restores normal mouse/camera behaviour when it becomes false.
    player:SetAttribute(
        CombatConfig.VIEW_LOCK.STATE_ATTRIBUTE,
        false
    )
end

return table.freeze(DungeonDeathPresentation)
