--!strict
local Workspace = game:GetService("Workspace")

local root = Workspace:WaitForChild("DungeonRuntime", 10)
if not root then
    error("[Dungeon Builder Tests] DungeonRuntime root was not created.")
end

local assertions = 0
local function check(condition: boolean, message: string)
    assertions += 1
    if not condition then
        error("[Dungeon Builder Tests] " .. message, 2)
    end
end

for _, name in ipairs({"Entrance", "Room1", "Room2", "BossRoom"}) do
    check(
        root:FindFirstChild(name) ~= nil,
        name .. " must exist in the greybox route."
    )
end
check(
    root:FindFirstChild("Checkpoint1") == nil,
    "A standalone checkpoint room must not exist."
)
check(
    root:FindFirstChild("CompletionRoom") == nil,
    "A completion room must not exist after the Captain."
)
check(root:FindFirstChild("DungeonSpawn", true) ~= nil, "DungeonSpawn must exist.")
check(
    root:FindFirstChild("Room1StartTrigger", true) ~= nil,
    "Room1 start trigger must exist."
)
check(
    root:FindFirstChild("Room2StartTrigger", true) ~= nil,
    "Room2 start trigger must exist."
)
check(
    root:FindFirstChild("BossStartTrigger", true) ~= nil,
    "Boss start trigger must exist."
)
check(
    root:FindFirstChild("CheckpointTrigger", true) == nil,
    "The retired standalone checkpoint trigger must not exist."
)
check(
    root:FindFirstChild("BossExitGate", true) == nil,
    "No boss exit gate is needed after authoritative completion."
)
check(
    root:FindFirstChild("ReturnPortal", true) == nil,
    "Completion return is UI-driven and must not require a physical portal."
)

print(string.format("[Dungeon Builder Tests] PASS: %d assertions.", assertions))
