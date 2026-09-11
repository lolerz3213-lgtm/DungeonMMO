--!strict
-- Pure equipment-to-prototype-presentation decisions.

local EquipmentPresentationRules = {}

EquipmentPresentationRules.WEAPON_ITEM_ATTRIBUTE =
    "DungeonMMOEquippedWeaponItemId"
EquipmentPresentationRules.OFFHAND_ITEM_ATTRIBUTE =
    "DungeonMMOEquippedOffHandItemId"

local SWORD_ITEM_ID = "marauder_sword"
local WAND_ITEM_ID = "apprentice_arcane_wand"
local LONGBOW_ITEM_ID = "apprentice_longbow"
local SHIELD_ITEM_ID = "marauder_shield"

function EquipmentPresentationRules.show_sword(item_id: any): boolean
    return item_id == SWORD_ITEM_ID
end

function EquipmentPresentationRules.show_wand(item_id: any): boolean
    return item_id == WAND_ITEM_ID
end

function EquipmentPresentationRules.show_longbow(item_id: any): boolean
    return item_id == LONGBOW_ITEM_ID
end

function EquipmentPresentationRules.show_shield(item_id: any): boolean
    return item_id == SHIELD_ITEM_ID
end

return table.freeze(EquipmentPresentationRules)
