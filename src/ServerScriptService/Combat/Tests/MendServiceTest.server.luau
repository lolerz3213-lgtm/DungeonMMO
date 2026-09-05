local ServerScriptService = game:GetService("ServerScriptService")

local combat_folder = ServerScriptService:WaitForChild("Combat")
local service_module = combat_folder:FindFirstChild("MendService")

if not service_module then
    error("[Mend Service Tests] RED: MendService is missing.")
end

local MendService = require(service_module)
local assertion_count = 0


local function assert_true(condition: boolean, message: string)
    assertion_count += 1

    if not condition then
        error("[Mend Service Tests] " .. message, 2)
    end
end



assert_true(
    type(MendService.start_channel) == "function",
    "MendService must expose channel start ownership."
)
assert_true(
    type(MendService.apply_channel_pulse) == "function",
    "MendService must expose authoritative pulse healing."
)
assert_true(
    type(MendService.cancel_channel) == "function",
    "MendService must expose channel cancellation cleanup."
)

local humanoid = Instance.new("Humanoid")
humanoid.MaxHealth = 100
humanoid.Health = 50

local healed = MendService.apply_heal(humanoid, 25)

assert_true(healed == 25, "Mend must report the amount actually restored.")
assert_true(humanoid.Health == 75, "Mend must restore the requested health.")

humanoid.Health = 90
local clamped = MendService.apply_heal(humanoid, 25)

assert_true(clamped == 10, "Mend healing must clamp at MaxHealth.")
assert_true(humanoid.Health == 100, "Mend must never exceed MaxHealth.")

local full = MendService.apply_heal(humanoid, 25)
assert_true(full == 0, "Mend must not heal a full-health target.")

humanoid.Health = 0
local dead = MendService.apply_heal(humanoid, 25)
assert_true(dead == 0, "Mend must not heal a dead target.")

humanoid:Destroy()

print(
    string.format(
        "[Mend Service Tests] PASS: %d assertions.",
        assertion_count
    )
)
