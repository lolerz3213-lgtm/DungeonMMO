--!strict

local AttributeConfig = {}

AttributeConfig.BASE_VALUE = 5
AttributeConfig.BASE_MAX_HEALTH = 100

AttributeConfig.PHYSICAL_PER_EFFECTIVE_POINT = 0.02
AttributeConfig.RANGED_PHYSICAL_PER_EFFECTIVE_POINT = 0.02
AttributeConfig.HEAL_PER_EFFECTIVE_POINT = 0.02
AttributeConfig.MAGICAL_PER_EFFECTIVE_POINT = 0.02
AttributeConfig.SUPPORT_PER_EFFECTIVE_POINT = 0.02
AttributeConfig.HEALTH_PER_EFFECTIVE_POINT = 5

AttributeConfig.BASE_MAX_MANA = 100
AttributeConfig.MAX_MANA_PER_EFFECTIVE_SPIRIT = 6
AttributeConfig.MAX_MANA_PER_EFFECTIVE_INTELLECT = 2
AttributeConfig.BASE_MANA_REGEN_PER_SECOND = 8
AttributeConfig.MANA_REGEN_PER_EFFECTIVE_SPIRIT = 0.5

AttributeConfig.SOFT_CAP_INVESTED_POINTS = 15

local ATTRIBUTE_NAMES = table.freeze({
    "Strength",
    "Dexterity",
    "Vitality",
    "Intellect",
    "Spirit",
})

function AttributeConfig.get_names(): {string}
    return ATTRIBUTE_NAMES
end

function AttributeConfig.effective_investment(
    points: number
): number
    local safe = math.max(0, points)

    if safe <= AttributeConfig.SOFT_CAP_INVESTED_POINTS then
        return safe
    end

    local overflow =
        safe - AttributeConfig.SOFT_CAP_INVESTED_POINTS

    return AttributeConfig.SOFT_CAP_INVESTED_POINTS
        + overflow / (1 + overflow / 20)
end

function AttributeConfig.signed_effective_delta(
    value: number
): number
    local raw_delta =
        value - AttributeConfig.BASE_VALUE

    if raw_delta < 0 then
        return raw_delta
    end

    return AttributeConfig.effective_investment(
        raw_delta
    )
end

function AttributeConfig.physical_multiplier(
    strength: number
): number
    return 1
        + AttributeConfig.signed_effective_delta(
            strength
        )
        * AttributeConfig.PHYSICAL_PER_EFFECTIVE_POINT
end

--[[
Returns Dexterity-led physical ranged damage using the accepted effective
investment curve.

Args:
    dexterity (number): Authoritative Dexterity attribute.

Returns:
    number: Non-negative ranged physical damage multiplier.
]]
function AttributeConfig.ranged_physical_multiplier(
    dexterity: number
): number
    return 1
        + AttributeConfig.signed_effective_delta(
            dexterity
        )
        * AttributeConfig.RANGED_PHYSICAL_PER_EFFECTIVE_POINT
end

function AttributeConfig.heal_multiplier(
    spirit: number
): number
    return 1
        + AttributeConfig.signed_effective_delta(
            spirit
        )
        * AttributeConfig.HEAL_PER_EFFECTIVE_POINT
end

function AttributeConfig.magical_multiplier(
    intellect: number
): number
    return 1
        + AttributeConfig.signed_effective_delta(
            intellect
        )
        * AttributeConfig.MAGICAL_PER_EFFECTIVE_POINT
end

function AttributeConfig.support_multiplier(
    spirit: number
): number
    return 1
        + AttributeConfig.signed_effective_delta(
            spirit
        )
        * AttributeConfig.SUPPORT_PER_EFFECTIVE_POINT
end

function AttributeConfig.max_health(
    vitality: number
): number
    return AttributeConfig.BASE_MAX_HEALTH
        + AttributeConfig.signed_effective_delta(
            vitality
        )
        * AttributeConfig.HEALTH_PER_EFFECTIVE_POINT
end

function AttributeConfig.max_mana(
    intellect: number,
    spirit: number
): number
    local spirit_delta =
        AttributeConfig.signed_effective_delta(spirit)
    local intellect_delta =
        AttributeConfig.signed_effective_delta(intellect)

    return math.max(
        25,
        AttributeConfig.BASE_MAX_MANA
            + spirit_delta
                * AttributeConfig.MAX_MANA_PER_EFFECTIVE_SPIRIT
            + intellect_delta
                * AttributeConfig.MAX_MANA_PER_EFFECTIVE_INTELLECT
    )
end

function AttributeConfig.mana_regen_per_second(
    spirit: number
): number
    return math.max(
        1,
        AttributeConfig.BASE_MANA_REGEN_PER_SECOND
            + AttributeConfig.signed_effective_delta(spirit)
                * AttributeConfig.MANA_REGEN_PER_EFFECTIVE_SPIRIT
    )
end

return table.freeze(AttributeConfig)
