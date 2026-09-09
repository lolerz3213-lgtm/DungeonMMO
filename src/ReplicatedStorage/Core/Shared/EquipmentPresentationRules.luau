--!strict
-- Pure representative equipment-to-prototype-presentation decisions.

local EquipmentPresentationRules = {}

EquipmentPresentationRules.WEAPON_ITEM_ATTRIBUTE =
    "DungeonMMOEquippedWeaponItemId"
EquipmentPresentationRules.OFFHAND_ITEM_ATTRIBUTE =
    "DungeonMMOEquippedOffHandItemId"

local SWORD_ITEM_ID = "marauder_sword"
local SHIELD_ITEM_ID = "marauder_shield"

--[[
Determines whether the accepted prototype sword should be presented.

Args:
    item_id (any): Server-owned equipped Weapon item ID.

Returns:
    boolean: True only for the representative Marauder Sword.
]]
function EquipmentPresentationRules.show_sword(item_id: any): boolean
    return item_id == SWORD_ITEM_ID
end

--[[
Determines whether the accepted prototype shield should be presented.

Args:
    item_id (any): Server-owned equipped OffHand item ID.

Returns:
    boolean: True only for the representative Marauder Shield.
]]
function EquipmentPresentationRules.show_shield(item_id: any): boolean
    return item_id == SHIELD_ITEM_ID
end

return table.freeze(EquipmentPresentationRules)
