local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CombatConfig = require(
    ReplicatedStorage
        :WaitForChild("Combat")
        :WaitForChild("Shared")
        :WaitForChild("CombatConfig")
)

local MarauderConfig = CombatConfig.TRAINING_MARAUDER
local MarauderAttackRules = {}


--[[
Returns the configured attack name at one pattern position.

Args:
    pattern_index (number): One-based index into the Marauder attack pattern.

Returns:
    string: Configured attack name.
]]
function MarauderAttackRules.get_attack_name(pattern_index: number): string
    local pattern = MarauderConfig.ATTACK_PATTERN
    local clamped_index = math.clamp(pattern_index, 1, #pattern)

    return pattern[clamped_index]
end


--[[
Returns one immutable configured Marauder attack definition.

Args:
    attack_name (string): Name from the configured attack pattern.

Returns:
    table: Attack definition table.
]]
function MarauderAttackRules.get_attack_definition(attack_name: string): any
    local attack_definition = MarauderConfig.ATTACKS[attack_name]

    assert(attack_definition ~= nil, "Unknown Marauder attack: " .. attack_name)

    return attack_definition
end


--[[
Advances one pattern index and wraps back to the first attack.

Args:
    pattern_index (number): Current one-based pattern position.

Returns:
    number: Next one-based pattern position.
]]
function MarauderAttackRules.get_next_pattern_index(pattern_index: number): number
    local next_index = pattern_index + 1

    if next_index > #MarauderConfig.ATTACK_PATTERN then
        return 1
    end

    return next_index
end


return table.freeze(MarauderAttackRules)
