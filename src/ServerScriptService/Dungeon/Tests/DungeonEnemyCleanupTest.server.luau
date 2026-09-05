--!strict
local ServerScriptService = game:GetService("ServerScriptService")
local Dungeon = ServerScriptService:WaitForChild("Dungeon")
local DungeonEnemyCleanup = require(Dungeon:WaitForChild("DungeonEnemyCleanup"))

local assertions = 0
local function check(condition: boolean, message: string)
    assertions += 1
    if not condition then error("[Dungeon Enemy Cleanup Tests] " .. message, 2) end
end

local model = Instance.new("Model")
model.Name = "CleanupTestEnemy"
local root = Instance.new("Part")
root.Name = "HumanoidRootPart"
root.CanCollide = true
root.CanTouch = true
root.CanQuery = true
root.Transparency = 0
root.Parent = model
local body = Instance.new("Part")
body.Name = "Body"
body.CanCollide = true
body.Transparency = 0
body.Parent = model
local emitter = Instance.new("ParticleEmitter")
emitter.Enabled = true
emitter.Parent = body
model.Parent = workspace

local first = DungeonEnemyCleanup.retire(model, 10)
check(first == true, "First retirement must be accepted.")
check(model:GetAttribute("DungeonEnemyRetired") == true, "Retired marker must be set.")
check(root.Transparency == 1 and body.Transparency == 1, "All enemy parts must become invisible immediately.")
check(root.CanCollide == false and root.CanTouch == false and root.CanQuery == false, "Retired enemy collision/query must be disabled.")
check(emitter.Enabled == false, "Retired enemy effects must be disabled.")
check(DungeonEnemyCleanup.retire(model, 10) == false, "Retirement must be idempotent.")
model:Destroy()

print(string.format("[Dungeon Enemy Cleanup Tests] PASS: %d assertions.", assertions))
