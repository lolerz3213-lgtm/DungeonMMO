--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local shared = ReplicatedStorage:WaitForChild("Core"):WaitForChild("Shared")
local PresentationLayers = require(shared:WaitForChild("PresentationLayers"))

local assertions = 0
local function check(condition: boolean, message: string)
    assertions += 1
    if not condition then error("[Dungeon Presentation Layer Tests] " .. message, 2) end
end

check(type(PresentationLayers.PHASE1_DEFEAT) == "number", "Phase 1 defeat layer must be defined.")
check(type(PresentationLayers.DUNGEON_REVIVE) == "number", "Dungeon revive layer must be defined.")
check(PresentationLayers.DUNGEON_REVIVE > PresentationLayers.PHASE1_DEFEAT, "Revive UI must render above the defeat overlay.")

print(string.format("[Dungeon Presentation Layer Tests] PASS: %d assertions.", assertions))
