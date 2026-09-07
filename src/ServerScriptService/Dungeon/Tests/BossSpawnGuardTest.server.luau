--!strict
local ServerScriptService = game:GetService("ServerScriptService")

local Dungeon = ServerScriptService:WaitForChild("Dungeon")
local module = Dungeon:FindFirstChild("DungeonBossSpawnGuard")

if not module then
    error(
        "[Boss Spawn Guard Tests] RED: DungeonBossSpawnGuard is missing.",
        2
    )
end

local DungeonBossSpawnGuard = require(module)
local assertions = 0

local function check(condition: boolean, message: string)
    assertions += 1
    if not condition then
        error("[Boss Spawn Guard Tests] " .. message, 2)
    end
end

local root = Instance.new("Folder")

check(
    DungeonBossSpawnGuard.claim(root, "session-a") == true,
    "first claim for a session must succeed."
)
check(
    DungeonBossSpawnGuard.claim(root, "session-a") == false,
    "repeat claim for the same session must be rejected."
)
check(
    DungeonBossSpawnGuard.claim(root, "session-b") == true,
    "a different session may replace a stale session claim."
)
check(
    DungeonBossSpawnGuard.claim(root, "session-b") == false,
    "new session must also remain idempotent after claiming."
)

root:Destroy()

print(string.format(
    "[Boss Spawn Guard Tests] PASS: %d assertions.",
    assertions
))
