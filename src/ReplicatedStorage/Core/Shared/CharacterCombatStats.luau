--!strict

local ReplicatedStorage = game:GetService(
    "ReplicatedStorage"
)

local Shared = ReplicatedStorage
    :WaitForChild("Core")
    :WaitForChild("Shared")

local AttributeConfig = require(
    Shared:WaitForChild(
        "AttributeConfig"
    )
)

local RaceDefinitions = require(
    Shared:WaitForChild(
        "RaceDefinitions"
    )
)

local CharacterCombatStats = {}

CharacterCombatStats.BASE_CRITICAL_CHANCE = 0.05
CharacterCombatStats.BASE_CRITICAL_DAMAGE_MULTIPLIER = 1.50

local function numeric_attribute(
    attributes: any,
    name: string
): number
    if type(attributes) ~= "table" then
        return AttributeConfig.BASE_VALUE
    end

    local value = attributes[name]

    if (
        type(value) ~= "number"
        or value ~= value
        or value <= -math.huge
        or value >= math.huge
    ) then
        return AttributeConfig.BASE_VALUE
    end

    return value
end

local function race_definition(
    race_id: string?
): any?
    if type(race_id) ~= "string" then
        return nil
    end

    return RaceDefinitions.get(race_id)
end

local function modifier_sources(
    definition: any
): {any}
    if type(definition) ~= "table" then
        return {}
    end

    local sources = {}

    local passive = definition.Passive

    if type(passive) == "table" then
        table.insert(sources, passive)

        if type(passive.Modifiers) == "table" then
            table.insert(
                sources,
                passive.Modifiers
            )
        end
    end

    local innate = definition.InnatePassive

    if type(innate) == "table" then
        table.insert(sources, innate)

        if type(innate.Modifiers) == "table" then
            table.insert(
                sources,
                innate.Modifiers
            )
        end
    end

    if type(definition.Modifiers) == "table" then
        table.insert(
            sources,
            definition.Modifiers
        )
    end

    table.insert(sources, definition)

    return sources
end

local function modifier(
    race_id: string?,
    keys: {string},
    fallback: number
): number
    local definition =
        race_definition(race_id)

    for _, source in ipairs(
        modifier_sources(definition)
    ) do
        for _, key in ipairs(keys) do
            local value = source[key]

            if (
                type(value) == "number"
                and value == value
                and value > -math.huge
                and value < math.huge
            ) then
                return value
            end
        end
    end

    return fallback
end

function CharacterCombatStats.critical_chance(
    attributes: any,
    race_id: string?
): number
    local dexterity =
        numeric_attribute(
            attributes,
            "Dexterity"
        )

    local dexterity_bonus =
        (
            dexterity
            - AttributeConfig.BASE_VALUE
        )
        * 0.005

    local racial_bonus =
        modifier(
            race_id,
            {
                "CriticalChanceBonus",
                "CritChanceBonus",
            },
            0
        )

    return math.clamp(
        CharacterCombatStats
            .BASE_CRITICAL_CHANCE
            + dexterity_bonus
            + racial_bonus,
        0,
        1
    )
end

function CharacterCombatStats
    .critical_damage_multiplier(
        race_id: string?
    ): number

    local racial_bonus =
        modifier(
            race_id,
            {
                "CriticalDamageBonus",
                "CritDamageBonus",
                "CriticalDamageMultiplierBonus",
            },
            0
        )

    return math.max(
        0,
        CharacterCombatStats
            .BASE_CRITICAL_DAMAGE_MULTIPLIER
            + racial_bonus
    )
end

function CharacterCombatStats.max_health(
    attributes: any,
    race_id: string?
): number
    local vitality =
        numeric_attribute(
            attributes,
            "Vitality"
        )

    local raw_health =
        AttributeConfig.max_health(
            vitality
        )

    local racial_multiplier =
        modifier(
            race_id,
            {
                "MaxHealthMultiplier",
                "HealthMultiplier",
            },
            1
        )

    if racial_multiplier <= 0 then
        racial_multiplier = 1
    end

    return raw_health
        * racial_multiplier
end

function CharacterCombatStats.basic_attack_rate(
    race_id: string?
): number
    local rate =
        modifier(
            race_id,
            {
                "BasicAttackRateMultiplier",
                "BasicAttackRate",
                "AttackRateMultiplier",
            },
            1
        )

    if rate <= 0 then
        return 1
    end

    return rate
end

return table.freeze(
    CharacterCombatStats
)