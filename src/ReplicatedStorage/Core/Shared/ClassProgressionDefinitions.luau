--!strict
local ClassProgressionDefinitions = {}

local HUMAN_ELF = table.freeze({"Human", "Elf"})

local DEFINITIONS = table.freeze({
    Fighter = table.freeze({
        Id = "Fighter",
        AllowedRaces = HUMAN_ELF,
        StarterSkills = table.freeze({
            "ShieldBash",
            "Mend",
        }),
        StarterEquipment = table.freeze({}),
        TeachableSkills = table.freeze({
            "ArcSlash",
        }),
    }),

    Mage = table.freeze({
        Id = "Mage",
        AllowedRaces = HUMAN_ELF,
        StarterSkills = table.freeze({
            "WindStrike",
            "ArcaneWard",
            "MageHeal",
        }),
        StarterEquipment = table.freeze({
            Weapon = "apprentice_arcane_wand",
        }),
        TeachableSkills = table.freeze({}),
    }),

    Ranger = table.freeze({
        Id = "Ranger",
        AllowedRaces = HUMAN_ELF,
        StarterSkills = table.freeze({
            "PiercingShot",
            "CripplingShot",
            "Volley",
        }),
        StarterEquipment = table.freeze({
            Weapon = "apprentice_longbow",
        }),
        TeachableSkills = table.freeze({}),
    }),
})

function ClassProgressionDefinitions.get(
    class_id: string
): any?
    return DEFINITIONS[class_id]
end

function ClassProgressionDefinitions.can_teach(
    class_id: string,
    skill_id: string
): boolean
    local definition = DEFINITIONS[class_id]

    if not definition then
        return false
    end

    for _, allowed_skill in ipairs(
        definition.TeachableSkills
    ) do
        if allowed_skill == skill_id then
            return true
        end
    end

    return false
end

return table.freeze(
    ClassProgressionDefinitions
)
