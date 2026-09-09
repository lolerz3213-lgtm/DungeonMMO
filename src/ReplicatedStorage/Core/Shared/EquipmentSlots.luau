--!strict
-- Canonical Phase 2C.B persistent equipment-slot contract.

local ORDER = table.freeze({
    "Weapon",
    "OffHand",
    "Helmet",
    "Body",
    "Gloves",
    "Boots",
})

local VALID = table.freeze({
    Weapon = true,
    OffHand = true,
    Helmet = true,
    Body = true,
    Gloves = true,
    Boots = true,
})

local EquipmentSlots = {
    ORDER = ORDER,
}

function EquipmentSlots.is_valid(slot: any): boolean
    return type(slot) == "string"
        and VALID[slot] == true
end

function EquipmentSlots.empty(): any
    -- Nil values are represented by absent keys. ORDER is authoritative.
    return {}
end

return table.freeze(EquipmentSlots)
