--!strict

local RaceDefinitions = {}

local HUMAN_BASE_ATTRIBUTES = table.freeze({
    Strength = 5,
    Dexterity = 4,
    Vitality = 6,
    Intellect = 5,
    Spirit = 5,
})

local HUMAN_PASSIVE = table.freeze({
    Id = "HumanResolve",
    DisplayName = "Human Resolve",
    MaxHealthMultiplier = 1.08,
    BasicAttackRateMultiplier = 0.95,
    CritChanceBonus = 0,
    CritDamageBonus = 0.15,
})

local HUMAN_VISUAL = table.freeze({
    Kind = "Human",
})

local ELF_BASE_ATTRIBUTES = table.freeze({
    Strength = 5,
    Dexterity = 6,
    Vitality = 4,
    Intellect = 5,
    Spirit = 5,
})

local ELF_PASSIVE = table.freeze({
    Id = "ElvenGrace",
    DisplayName = "Elven Grace",
    MaxHealthMultiplier = 0.92,
    BasicAttackRateMultiplier = 1.08,
    CritChanceBonus = 0.05,
    CritDamageBonus = 0,
})

local ELF_VISUAL = table.freeze({
    Kind = "ElfEars",
})

local DEFINITIONS = table.freeze({
    Human = table.freeze({
        Id = "Human",
        DisplayName = "Human",
        BaseAttributes = HUMAN_BASE_ATTRIBUTES,
        Passive = HUMAN_PASSIVE,
        Visual = HUMAN_VISUAL,
    }),
    Elf = table.freeze({
        Id = "Elf",
        DisplayName = "Elf",
        BaseAttributes = ELF_BASE_ATTRIBUTES,
        Passive = ELF_PASSIVE,
        Visual = ELF_VISUAL,
    }),
})

--[[
Creates a mutable copy of an attribute baseline.

Args:
    attributes (any): Dense attribute table to copy.

Returns:
    any: New dense table containing the five attributes.
]]
local function clone_attributes(attributes: any): any
    return {
        Strength = attributes.Strength,
        Dexterity = attributes.Dexterity,
        Vitality = attributes.Vitality,
        Intellect = attributes.Intellect,
        Spirit = attributes.Spirit,
    }
end

--[[
Returns one race definition.

Args:
    race_id (string): Stable race identifier.

Returns:
    any?: Frozen race definition, or nil for an unknown race.
]]
function RaceDefinitions.get(race_id: string): any?
    return DEFINITIONS[race_id]
end

--[[
Returns all available race definitions.

Args:
    None.

Returns:
    any: Frozen race-definition table.
]]
function RaceDefinitions.all(): any
    return DEFINITIONS
end

--[[
Returns a mutable copy of a race's starting attributes.

Args:
    race_id (string): Stable race identifier.

Returns:
    any?: Dense attribute baseline, or nil for an unknown race.
]]
function RaceDefinitions.get_base_attributes(
    race_id: string
): any?
    local definition = DEFINITIONS[race_id]

    if not definition then
        return nil
    end

    return clone_attributes(definition.BaseAttributes)
end

return table.freeze(RaceDefinitions)