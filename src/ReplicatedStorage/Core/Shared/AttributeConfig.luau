--!strict

local AttributeConfig = {}

AttributeConfig.BASE_VALUE = 5
AttributeConfig.BASE_MAX_HEALTH = 100

AttributeConfig.PHYSICAL_PER_EFFECTIVE_POINT = 0.02
AttributeConfig.HEAL_PER_EFFECTIVE_POINT = 0.02
AttributeConfig.HEALTH_PER_EFFECTIVE_POINT = 5

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

function AttributeConfig.heal_multiplier(
    spirit: number
): number
    return 1
        + AttributeConfig.signed_effective_delta(
            spirit
        )
        * AttributeConfig.HEAL_PER_EFFECTIVE_POINT
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

return table.freeze(AttributeConfig)