--!strict

local CriticalHitRules = {}

local function finite(
    value: any
): boolean
    return type(value) == "number"
        and value == value
        and value > -math.huge
        and value < math.huge
end

local function normalize_chance(
    chance: any
): number
    if not finite(chance) then
        return 0
    end

    return math.clamp(
        chance,
        0,
        1
    )
end

local function normalize_multiplier(
    multiplier: any
): number
    if (
        not finite(multiplier)
        or multiplier <= 0
    ) then
        return 1
    end

    return multiplier
end

local function normalize_roll(
    roll: any
): number
    if not finite(roll) then
        return 1
    end

    return math.clamp(
        roll,
        0,
        1
    )
end

function CriticalHitRules.resolve(
    chance: number,
    crit_multiplier: number,
    roll: number
): any
    local safe_chance =
        normalize_chance(chance)

    local safe_multiplier =
        normalize_multiplier(
            crit_multiplier
        )

    local safe_roll =
        normalize_roll(roll)

    local is_critical =
        safe_roll < safe_chance

    return {
        is_critical = is_critical,

        multiplier =
            if is_critical
                then safe_multiplier
                else 1,
    }
end

return table.freeze(
    CriticalHitRules
)