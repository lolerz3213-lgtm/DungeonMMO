--!strict
-- Studio-only representative equipment seeding for standalone Dungeon tests.

local DungeonStudioEquipmentBootstrap = {}

local REPRESENTATIVE_LOADOUT = table.freeze({
    Weapon = "marauder_sword",
    OffHand = "marauder_shield",
    Helmet = "marauder_helmet",
    Body = "marauder_armor",
    Gloves = "marauder_gloves",
    Boots = "marauder_boots",
})

--[[
Seeds missing representative equipment into one in-memory Studio character.

Existing slot values are preserved so deliberate test setup can override the
bootstrap. This helper is invoked only behind RunService:IsStudio() and never
owns production equipment mutation.

Args:
    character (any): Loaded in-memory Studio character table.

Returns:
    number: Number of previously empty slots populated.
]]
function DungeonStudioEquipmentBootstrap.seed(character: any): number
    if type(character) ~= "table" then
        return 0
    end

    if type(character.Equipment) ~= "table" then
        character.Equipment = {}
    end

    local changed = 0

    for slot, item_id in pairs(REPRESENTATIVE_LOADOUT) do
        if character.Equipment[slot] == nil then
            character.Equipment[slot] = item_id
            changed += 1
        end
    end

    return changed
end

return table.freeze(DungeonStudioEquipmentBootstrap)
