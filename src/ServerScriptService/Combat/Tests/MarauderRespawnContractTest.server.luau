local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CombatConfig = require(
    ReplicatedStorage
        :WaitForChild("Combat")
        :WaitForChild("Shared")
        :WaitForChild("CombatConfig")
)

local MarauderConfig = CombatConfig.TRAINING_MARAUDER
local assertions = 0

local function assert_equal(actual: any, expected: any, message: string)
    if actual ~= expected then
        error(string.format("[Marauder Respawn Contract Tests] %s Expected %s, got %s.", message, tostring(expected), tostring(actual)), 2)
    end
    assertions += 1
end

assert_equal(MarauderConfig.MAX_HEALTH, 200, "Respawn health contract changed.")
assert_equal(MarauderConfig.RESPAWN_SECONDS, 3, "Respawn delay mismatch.")
assert_equal(MarauderConfig.RESPAWN_ATTACK_DELAY_SECONDS, 1.0, "Respawn attack grace mismatch.")
assert_equal(MarauderConfig.ATTACK_PATTERN[1], "Normal", "Respawn must restart on Normal.")

print(string.format("[Marauder Respawn Contract Tests] PASS: %d assertions.", assertions))
