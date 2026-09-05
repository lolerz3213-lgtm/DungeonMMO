--!strict
local ServerScriptService = game:GetService("ServerScriptService")

local Dungeon = ServerScriptService:WaitForChild("Dungeon")
local module = Dungeon:FindFirstChild("DungeonDeathPresentation")
if not module then
    error(
        "[Dungeon Death Presentation Tests] RED: "
            .. "DungeonDeathPresentation is missing."
    )
end
local DungeonDeathPresentation = require(module)

local attributes = {CombatViewLocked = true}
local fake_player: any = {}
function fake_player:SetAttribute(name: string, value: any)
    attributes[name] = value
end

DungeonDeathPresentation.disable_view_lock(fake_player)
assert(
    attributes.CombatViewLocked == false,
    "Dungeon death must force View Lock off immediately."
)

print("[Dungeon Death Presentation Tests] PASS")
