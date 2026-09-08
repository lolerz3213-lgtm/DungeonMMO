--!strict

local RaceDefinitions = require(script.Parent.RaceDefinitions)
local ClassProgressionDefinitions = require(
    script.Parent.ClassProgressionDefinitions
)

local CharacterIdentityRules = {}

local STAGES = table.freeze({
    RaceSelection = "RaceSelection",
    ClassSelection = "ClassSelection",
    LegacyRaceSelection = "LegacyRaceSelection",
    Complete = "Complete",
})

CharacterIdentityRules.Stages = STAGES

--[[
Returns a character's identity table when its shape is usable.

Args:
    character (any): Persistent character state.

Returns:
    any?: Identity table, or nil when unavailable.
]]
local function get_identity(character: any): any?
    if type(character) ~= "table" then
        return nil
    end

    local identity = character.Identity

    if type(identity) ~= "table" then
        return nil
    end

    return identity
end

--[[
Returns the resolved known race identifier.

Args:
    character (any): Persistent character state.

Returns:
    string?: Known RaceId, or nil when unresolved/invalid.
]]
function CharacterIdentityRules.get_race_id(
    character: any
): string?
    local identity = get_identity(character)

    if not identity then
        return nil
    end

    local race_id = identity.RaceId

    if type(race_id) ~= "string" then
        return nil
    end

    if not RaceDefinitions.get(race_id) then
        return nil
    end

    return race_id
end

--[[
Returns the resolved known current class identifier.

Args:
    character (any): Persistent character state.

Returns:
    string?: Known ClassId, or nil when unresolved/invalid.
]]
function CharacterIdentityRules.get_class_id(
    character: any
): string?
    local identity = get_identity(character)

    if not identity then
        return nil
    end

    local class_id = identity.ClassId

    if type(class_id) ~= "string" then
        return nil
    end

    if not ClassProgressionDefinitions.get(class_id) then
        return nil
    end

    return class_id
end

--[[
Returns the selected race's mutable attribute baseline.

Args:
    character (any): Persistent character state.

Returns:
    any?: Dense racial baseline, or nil when race is unresolved.
]]
function CharacterIdentityRules.get_attribute_baseline(
    character: any
): any?
    local race_id = CharacterIdentityRules.get_race_id(
        character
    )

    if not race_id then
        return nil
    end

    return RaceDefinitions.get_base_attributes(race_id)
end

--[[
Checks whether normal gameplay identity is fully resolved.

Args:
    character (any): Persistent character state.

Returns:
    boolean: True only for a valid Complete identity.
]]
function CharacterIdentityRules.is_complete(
    character: any
): boolean
    local identity = get_identity(character)

    if not identity then
        return false
    end

    if identity.CreationStage ~= STAGES.Complete then
        return false
    end

    if not CharacterIdentityRules.get_race_id(character) then
        return false
    end

    local base_class_id = identity.BaseClassId

    if type(base_class_id) ~= "string" then
        return false
    end

    if not ClassProgressionDefinitions.get(base_class_id) then
        return false
    end

    return (
        CharacterIdentityRules.get_class_id(character) ~= nil
    )
end

return table.freeze(CharacterIdentityRules)