local ServerScriptService = game:GetService("ServerScriptService")

local MarauderAttackRules = require(
    ServerScriptService
        :WaitForChild("Combat")
        :WaitForChild("MarauderAttackRules")
)

local assertions = 0
local function assert_equal(actual: any, expected: any, message: string)
    if actual ~= expected then
        error(string.format("[Marauder Attack Rules Tests] %s Expected %s, got %s.", message, tostring(expected), tostring(actual)), 2)
    end
    assertions += 1
end

assert_equal(MarauderAttackRules.get_attack_name(1), "Normal", "First attack must be Normal.")
assert_equal(MarauderAttackRules.get_attack_name(2), "Normal", "Second attack must be Normal.")
assert_equal(MarauderAttackRules.get_attack_name(3), "Heavy", "Third attack must be Heavy.")
assert_equal(MarauderAttackRules.get_next_pattern_index(3), 1, "Pattern must wrap after Heavy.")

local heavy = MarauderAttackRules.get_attack_definition("Heavy")
assert_equal(heavy.WIND_UP_SECONDS, 0.75, "Heavy wind-up mismatch.")
assert_equal(heavy.HEALTH_DAMAGE, 32, "Heavy HP damage mismatch.")
assert_equal(heavy.STAMINA_DAMAGE, 45, "Heavy Stamina damage mismatch.")
assert_equal(heavy.ATTACK_ARC_DEGREES, 55, "Heavy arc mismatch.")

print(string.format("[Marauder Attack Rules Tests] PASS: %d assertions.", assertions))
