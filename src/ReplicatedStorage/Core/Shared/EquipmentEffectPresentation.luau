--!strict
-- Client-safe formatting for server-resolved equipment effect summaries.

local EquipmentEffectPresentation = {}

local EPSILON = 0.000001

--[[
Reads one numeric effect value while treating malformed data as neutral.

Args:
    effects (any): Server-supplied effect summary.
    key (string): Effect field to read.

Returns:
    number: Numeric effect value, or zero when missing/malformed.
]]
local function numeric(effects: any, key: string): number
    if type(effects) ~= "table" then
        return 0
    end

    local value = effects[key]
    return if type(value) == "number" then value else 0
end

--[[
Builds readable display fragments from already resolved effect values.

Args:
    effects (any): Server-supplied effect or delta summary.

Returns:
    {string}: Ordered human-readable effect fragments.
]]
local function build_parts(effects: any): {string}
    local parts = {}
    local physical = numeric(effects, "PhysicalDamageBonus")
    local health = numeric(effects, "MaxHealthFlat")
    local critical = numeric(effects, "CriticalChanceBonus")

    if math.abs(physical) > EPSILON then
        table.insert(
            parts,
            string.format("%+.0f%% Physical Damage", physical * 100)
        )
    end

    if math.abs(health) > EPSILON then
        table.insert(parts, string.format("%+.0f Max Health", health))
    end

    if math.abs(critical) > EPSILON then
        table.insert(
            parts,
            string.format("%+.0f%% Critical Chance", critical * 100)
        )
    end

    return parts
end

--[[
Formats an equipment-effect summary for Base UI display.

Args:
    effects (any): Server-resolved effect summary.

Returns:
    string: Readable effect text or a neutral fallback label.
]]
function EquipmentEffectPresentation.format_effects(effects: any): string
    local parts = build_parts(effects)

    if #parts == 0 then
        return "No combat effect"
    end

    return table.concat(parts, "  •  ")
end

--[[
Formats a server-computed equipment delta for Base UI display.

Args:
    effects (any): Server-resolved delta summary.

Returns:
    string: Readable stat-change text or a neutral fallback label.
]]
function EquipmentEffectPresentation.format_delta(effects: any): string
    local parts = build_parts(effects)

    if #parts == 0 then
        return "No stat change"
    end

    return table.concat(parts, "  •  ")
end

return table.freeze(EquipmentEffectPresentation)
