--!strict
-- Pure generic equipment-slot reservation rules.

local EquipmentSlots = require(
    script.Parent:WaitForChild("EquipmentSlots")
)
local ItemDefinitions = require(
    script.Parent:WaitForChild("ItemDefinitions")
)

local EquipmentReservationRules = {}

--[[
Resolves an equipped item only when it is valid for the supplied slot.

Args:
    equipment (any): Candidate six-slot Equipment table.
    slot (string): Canonical equipment slot.

Returns:
    any?: Valid equipment definition, otherwise nil.
]]
local function equipped_definition(
    equipment: any,
    slot: string
): any?
    if type(equipment) ~= "table" then
        return nil
    end

    local item_id = equipment[slot]

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
Returns valid slot reservations created by currently equipped items.

Malformed and wrong-slot entries do not create reservations. When multiple
valid items reserve the same slot, the first item in canonical slot order wins
so resolution is deterministic.

Args:
    equipment (any): Candidate six-slot Equipment table.
    ignored_slot (string?): Optional source slot to ignore while replacing it.

Returns:
    {[string]: string}: Reserved-slot to reserving-item-ID map.
]]
function EquipmentReservationRules.resolve(
    equipment: any,
    ignored_slot: string?
): {[string]: string}
    local reservations: {[string]: string} = {}

    for _, source_slot in ipairs(EquipmentSlots.ORDER) do
        if source_slot == ignored_slot then
            continue
        end

        local definition = equipped_definition(
            equipment,
            source_slot
        )

        if not definition then
            continue
        end

        local reserved_slots = definition.ReservedSlots

        if type(reserved_slots) ~= "table" then
            continue
        end

        for _, reserved_slot in ipairs(reserved_slots) do
            if EquipmentSlots.is_valid(reserved_slot)
                and reservations[reserved_slot] == nil
            then
                reservations[reserved_slot] = definition.Id
            end
        end
    end

    return reservations
end

--[[
Checks cross-slot reservation constraints for one equip candidate.

Args:
    equipment (any): Current persistent Equipment table.
    item (any): Valid equipment definition being considered.
    requested_slot (string): Canonical destination slot.

Returns:
    boolean: True when cross-slot reservations allow the equip.
    string?: Stable rejection reason when blocked.
]]
function EquipmentReservationRules.can_equip(
    equipment: any,
    item: any,
    requested_slot: string
): (boolean, string?)
    if type(item) ~= "table" then
        return false, "UnknownItem"
    end

    local existing_reservations =
        EquipmentReservationRules.resolve(
            equipment,
            requested_slot
        )

    if existing_reservations[requested_slot] ~= nil then
        return false, "SlotReserved"
    end

    local reserved_slots = item.ReservedSlots

    if type(reserved_slots) ~= "table" then
        return true, nil
    end

    local source = if type(equipment) == "table" then equipment else {}

    for _, reserved_slot in ipairs(reserved_slots) do
        if EquipmentSlots.is_valid(reserved_slot)
            and reserved_slot ~= requested_slot
            and type(source[reserved_slot]) == "string"
        then
            return false, "ReservedSlotOccupied"
        end
    end

    return true, nil
end

return table.freeze(EquipmentReservationRules)
