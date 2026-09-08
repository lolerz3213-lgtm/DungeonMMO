--!strict

local BasicAttackTimingRules = {}

local TIMING_FIELDS = {
    "WIND_UP_SECONDS",
    "ACTIVE_SECONDS",
    "RECOVERY_SECONDS",
}

local function finite(
    value: any
): boolean
    return type(value) == "number"
        and value == value
        and value > -math.huge
        and value < math.huge
end

function BasicAttackTimingRules.get_safe_rate(
    rate: any
): number
    if (
        not finite(rate)
        or rate <= 0
    ) then
        return 1
    end

    return rate
end

function BasicAttackTimingRules.scale_definition(
    definition: any,
    rate: any
): any
    if type(definition) ~= "table" then
        return definition
    end

    local safe_rate =
        BasicAttackTimingRules
            .get_safe_rate(rate)

    local scaled = {}

    for key, value in pairs(definition) do
        scaled[key] = value
    end

    for _, field in ipairs(
        TIMING_FIELDS
    ) do
        local duration =
            definition[field]

        if finite(duration) then
            scaled[field] =
                duration / safe_rate
        end
    end

    return scaled
end

return table.freeze(
    BasicAttackTimingRules
)