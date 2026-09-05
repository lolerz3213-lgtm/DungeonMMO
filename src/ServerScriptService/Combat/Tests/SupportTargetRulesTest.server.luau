local ServerScriptService = game:GetService("ServerScriptService")

local combat_folder = ServerScriptService:WaitForChild("Combat")
local rules_module = combat_folder:FindFirstChild("SupportTargetRules")

if not rules_module then
    error("[Support Target Rules Tests] RED: SupportTargetRules is missing.")
end

local SupportTargetRules = require(rules_module)
local assertion_count = 0


local function assert_true(condition: boolean, message: string)
    assertion_count += 1

    if not condition then
        error("[Support Target Rules Tests] " .. message, 2)
    end
end


local function candidate(
    key: string,
    is_self: boolean,
    distance: number,
    health: number,
    max_health: number
)
    return {
        key = key,
        is_self = is_self,
        distance = distance,
        health = health,
        max_health = max_health,
    }
end


local target = SupportTargetRules.choose_mend_target({
    candidate("self", true, 0, 40, 100),
    candidate("ally", false, 8, 70, 100),
}, 12)

assert_true(
    target == "ally",
    "Mend must prefer an injured nearby ally over the caster."
)

local most_injured = SupportTargetRules.choose_mend_target({
    candidate("self", true, 0, 30, 100),
    candidate("ally_a", false, 6, 70, 100),
    candidate("ally_b", false, 10, 25, 100),
}, 12)

assert_true(
    most_injured == "ally_b",
    "Mend must prefer the lowest-health-percentage nearby ally."
)

local nearest_tie = SupportTargetRules.choose_mend_target({
    candidate("ally_far", false, 10, 50, 100),
    candidate("ally_near", false, 5, 50, 100),
}, 12)

assert_true(
    nearest_tie == "ally_near",
    "Equal-health allies must resolve deterministically to the nearest."
)

local self_fallback = SupportTargetRules.choose_mend_target({
    candidate("self", true, 0, 60, 100),
    candidate("ally_full", false, 4, 100, 100),
    candidate("ally_far", false, 13, 10, 100),
}, 12)

assert_true(
    self_fallback == "self",
    "Mend must fall back to an injured caster when no valid ally exists."
)

local nobody = SupportTargetRules.choose_mend_target({
    candidate("self", true, 0, 100, 100),
    candidate("ally_full", false, 3, 100, 100),
}, 12)

assert_true(
    nobody == nil,
    "Mend must return nil when nobody needs healing."
)

print(
    string.format(
        "[Support Target Rules Tests] PASS: %d assertions.",
        assertion_count
    )
)
