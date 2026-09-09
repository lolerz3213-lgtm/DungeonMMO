--!strict
-- Pure equipment eligibility. Inventory ownership and mutation are server-side.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage
    :WaitForChild("Core")
    :WaitForChild("Shared")

local CharacterIdentityRules = require(
    Shared:WaitForChild("CharacterIdentityRules")
)

local EquipmentSlots = require(
    Shared:WaitForChild("EquipmentSlots")
)

local EquipmentRules = {}

local function result(ok: boolean, reason: string?): any
    return {
        ok = ok,
        reason = reason,
    }
end

local function allowed(whitelist: any, value: any): boolean
    if whitelist == nil then
        return true
    end

    if type(whitelist) ~= "table" then
        return false
    end

    for _, candidate in ipairs(whitelist) do
        if candidate == value then
            return true
        end
    end

    return false
end

function EquipmentRules.validate(
    character: any,
    item: any,
    requested_slot: any
): any
    if not EquipmentSlots.is_valid(requested_slot) then
        return result(false, "UnknownEquipmentSlot")
    end

    if (
        type(character) ~= "table"
        or not CharacterIdentityRules.is_complete(character)
    ) then
        return result(false, "IdentityIncomplete")
    end

    if type(item) ~= "table" then
        return result(false, "UnknownItem")
    end

    if item.Kind ~= "Equipment" then
        return result(false, "NotEquipment")
    end

    if item.Slot ~= requested_slot then
        return result(false, "WrongSlot")
    end

    local identity = character.Identity

    if not allowed(item.AllowedRaces, identity.RaceId) then
        return result(false, "RaceRestricted")
    end

    if not allowed(item.AllowedBaseClasses, identity.BaseClassId) then
        return result(false, "ClassRestricted")
    end

    if not allowed(item.AllowedClasses, identity.ClassId) then
        return result(false, "ClassRestricted")
    end

    return result(true, nil)
end

return table.freeze(EquipmentRules)
