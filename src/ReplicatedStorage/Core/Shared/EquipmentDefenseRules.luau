--!strict
-- Pure equipment-to-defence capability rules.

local ItemDefinitions = require(
    script.Parent:WaitForChild("ItemDefinitions")
)

local EquipmentDefenseRules = {}

--[[
Returns whether the current authoritative weapon permits Block.

Unknown and empty weapon IDs preserve the accepted pre-Ranger behaviour.
Weapons may opt out explicitly with CanBlock = false.

Args:
    weapon_item_id (any): Equipped persistent Weapon item ID.

Returns:
    boolean: False only when the equipped weapon explicitly disables Block.
]]
function EquipmentDefenseRules.can_block_with_weapon(
    weapon_item_id: any
): boolean
    if type(weapon_item_id) ~= "string" then
        return true
    end

    local definition = ItemDefinitions.get(weapon_item_id)

    if not definition
        or definition.Kind ~= "Equipment"
        or definition.Slot ~= "Weapon"
    then
        return true
    end

    return definition.CanBlock ~= false
end

return table.freeze(EquipmentDefenseRules)
