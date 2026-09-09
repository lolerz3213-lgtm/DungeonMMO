--!strict
-- Pure Phase 2C.C equipment-to-combat-stat resolver.

local EquipmentSlots = require(script.Parent:WaitForChild("EquipmentSlots"))
local ItemDefinitions = require(script.Parent:WaitForChild("ItemDefinitions"))

local EquipmentStatResolver = {}

local SUPPORTED_MODIFIERS = table.freeze({
    PhysicalDamageBonus = true,
    MaxHealthFlat = true,
    CriticalChanceBonus = true,
})

--[[
Returns a finite numeric value or nil for malformed input.

Args:
    value (any): Candidate modifier value.

Returns:
    number?: Finite number when valid, otherwise nil.
]]
local function finite_number(value: any): number?
    if type(value) ~= "number" then
        return nil
    end

    if value ~= value or value <= -math.huge or value >= math.huge then
        return nil
    end

    return value
end

--[[
Resolves an equipment definition only when it belongs to the supplied slot.

Args:
    slot (string): Canonical equipment slot being resolved.
    item_id (any): Candidate persistent item identifier.

Returns:
    any?: Valid equipment definition, otherwise nil.
]]
local function valid_definition(slot: string, item_id: any): any?
    if type(item_id) ~= "string" then
        return nil
    end

    local definition = ItemDefinitions.get(item_id)

    if not definition
        or definition.Kind ~= "Equipment"
        or definition.Slot ~= slot
    then
        return nil
    end

    return definition
end

--[[
Adds supported combat modifiers from one valid equipment definition.

Args:
    result (any): Mutable aggregate resolution table.
    definition (any): Valid equipment definition.

Returns:
    None.
]]
local function add_modifiers(result: any, definition: any)
    local modifiers = definition.CombatModifiers

    if type(modifiers) ~= "table" then
        return
    end

    for key in pairs(SUPPORTED_MODIFIERS) do
        local value = finite_number(modifiers[key])

        if value then
            result[key] += value
        end
    end
end

--[[
Adds valid authoritative weapon tags from one weapon definition.

Args:
    result (any): Mutable aggregate resolution table.
    definition (any): Valid Weapon-slot equipment definition.

Returns:
    None.
]]
local function add_weapon_tags(result: any, definition: any)
    local tags = definition.WeaponTags

    if type(tags) ~= "table" then
        return
    end

    for _, tag in ipairs(tags) do
        if type(tag) == "string" and tag ~= "" then
            result.WeaponTags[tag] = true
        end
    end
end

--[[
Resolves one six-slot Equipment table into authoritative combat effects.

Malformed, unknown, wrong-slot and non-equipment entries are ignored so the
runtime fails neutral rather than inventing authority.

Args:
    equipment (any): Persistent or candidate Equipment table.

Returns:
    any: Frozen aggregate effects, weapon tags and representative item IDs.
]]
function EquipmentStatResolver.resolve(equipment: any): any
    local result = {
        PhysicalDamageBonus = 0,
        MaxHealthFlat = 0,
        CriticalChanceBonus = 0,
        WeaponTags = {},
        WeaponItemId = nil,
        OffHandItemId = nil,
    }

    local source = if type(equipment) == "table" then equipment else {}

    for _, slot in ipairs(EquipmentSlots.ORDER) do
        local item_id = source[slot]
        local definition = valid_definition(slot, item_id)

        if definition then
            add_modifiers(result, definition)

            if slot == "Weapon" then
                result.WeaponItemId = item_id
                add_weapon_tags(result, definition)
            elseif slot == "OffHand" then
                result.OffHandItemId = item_id
            end
        end
    end

    result.WeaponTags = table.freeze(result.WeaponTags)
    return table.freeze(result)
end

--[[
Creates a canonical candidate Equipment table with one slot replaced.

The source table is not mutated. Passing nil clears the candidate slot.

Args:
    equipment (any): Existing Equipment table to copy.
    slot (string): Canonical slot to replace.
    item_id (string?): Candidate item ID, or nil to clear the slot.

Returns:
    any: New mutable Equipment table containing only canonical slot values.
]]
function EquipmentStatResolver.with_slot(
    equipment: any,
    slot: string,
    item_id: string?
): any
    local result = {}
    local source = if type(equipment) == "table" then equipment else {}

    for _, known_slot in ipairs(EquipmentSlots.ORDER) do
        local source_item = source[known_slot]

        if type(source_item) == "string" then
            result[known_slot] = source_item
        end
    end

    if EquipmentSlots.is_valid(slot) then
        result[slot] = if type(item_id) == "string" then item_id else nil
    end

    return result
end

return table.freeze(EquipmentStatResolver)
