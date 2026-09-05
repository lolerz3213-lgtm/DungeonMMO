--!strict
local ClassProgressionDefinitions = {}

local DEFINITIONS = table.freeze({
    Prototype = table.freeze({
        Id = "Prototype",
        StarterSkills = table.freeze({"ShieldBash", "Mend"}),
        TeachableSkills = table.freeze({"ArcSlash"}),
    }),
})

function ClassProgressionDefinitions.get(class_id: string): any?
    return DEFINITIONS[class_id]
end

function ClassProgressionDefinitions.can_teach(class_id: string, skill_id: string): boolean
    local definition = DEFINITIONS[class_id]
    if not definition then return false end
    for _, candidate in ipairs(definition.TeachableSkills) do
        if candidate == skill_id then return true end
    end
    return false
end

return table.freeze(ClassProgressionDefinitions)
