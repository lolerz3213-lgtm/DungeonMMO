--!strict
local ServerScriptService = game:GetService("ServerScriptService")

local Adapters = ServerScriptService:WaitForChild("Core"):WaitForChild("Adapters")
local RobloxTeleportAdapter = require(Adapters:WaitForChild("RobloxTeleportAdapter"))

local adapter = RobloxTeleportAdapter.new({
    force_teleport_failure = true,
    failure_reason = "TEST_ForcedTeleportFailure",
})

local ok, reason = adapter:teleport(1, {}, nil, {SessionId = "test"})
assert(ok == false, "Forced adapter must return a failed teleport result.")
assert(reason == "TEST_ForcedTeleportFailure", "Forced adapter must return the configured TEST reason.")

print("[Roblox Teleport Adapter Failure Tests] PASS: 2 assertions.")
