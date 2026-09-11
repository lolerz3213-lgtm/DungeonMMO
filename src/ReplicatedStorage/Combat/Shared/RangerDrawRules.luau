--!strict
-- Pure Longbow draw classification for the Ranger foundation.

local RangerDrawRules = {}

RangerDrawRules.PRECISION_SECONDS = 0.45
RangerDrawRules.FULL_DRAW_SECONDS = 0.80
RangerDrawRules.DRAW_MOVEMENT_SCALE = 0.60

local NORMAL = table.freeze({
    Tier = "Normal",
    DamageMultiplier = 1.00,
    CriticalChanceBonus = 0,
})

local PRECISION = table.freeze({
    Tier = "Precision",
    DamageMultiplier = 1.25,
    CriticalChanceBonus = 0.05,
})

local FULL_DRAW = table.freeze({
    Tier = "FullDraw",
    DamageMultiplier = 1.50,
    CriticalChanceBonus = 0.10,
})

--[[
Classifies a server-observed Longbow draw duration.

Args:
    elapsed_seconds (number): Server-measured time since DrawStart.

Returns:
    any: Frozen draw-tier definition containing damage and crit bonuses.
]]
function RangerDrawRules.classify(elapsed_seconds: number): any
    local elapsed = math.max(0, tonumber(elapsed_seconds) or 0)

    if elapsed >= RangerDrawRules.FULL_DRAW_SECONDS then
        return FULL_DRAW
    end

    if elapsed >= RangerDrawRules.PRECISION_SECONDS then
        return PRECISION
    end

    return NORMAL
end

return table.freeze(RangerDrawRules)
