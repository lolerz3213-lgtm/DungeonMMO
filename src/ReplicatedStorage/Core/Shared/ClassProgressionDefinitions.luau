--!strict

local ClassProgressionDefinitions = {}

local DEFINITIONS = table.freeze({
    Fighter = table.freeze({
        Id = "Fighter",
        StarterSkills = table.freeze({
            "ShieldBash",
            "Mend",
        }),
        TeachableSkills = table.freeze({
            "ArcSlash",
        }),
    }),
})

--[[
Returns one class progression definition.

Args:
    class_id (string): Stable class identifier.

Returns:
    any?: Frozen class definition, or nil when unknown.
]]
function ClassProgressionDefinitions.get(
    class_id: string
): any?
    return DEFINITIONS[class_id]
end

--[[
Checks whether a class may learn a particular teachable skill.

Args:
    class_id (string): Stable class identifier.
    skill_id (string): Stable skill identifier.

Returns:
    boolean: True when the skill is teachable by the class.
]]
function ClassProgressionDefinitions.can_teach(
    class_id: string,
    skill_id: string
): boolean
    local definition = DEFINITIONS[class_id]

    if not definition then
        return false
    end

    for _, candidate in ipairs(
        definition.TeachableSkills
    ) do
        if candidate == skill_id then
            return true
        end
    end

    return false
end

return table.freeze(ClassProgressionDefinitions)