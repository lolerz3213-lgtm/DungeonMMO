--!strict
-- Studio-only representative equipment seeding for standalone Dungeon tests.

local DungeonStudioEquipmentBootstrap = {}

local FIGHTER_LOADOUT = table.freeze({
    Weapon = "marauder_sword",
    OffHand = "marauder_shield",
    Helmet = "marauder_helmet",
    Body = "marauder_armor",
    Gloves = "marauder_gloves",
    Boots = "marauder_boots",
})

local MAGE_LOADOUT = table.freeze({
    Weapon = "apprentice_arcane_wand",
})

local function loadout_for(character: any): any
    local class_id =
        type(character) == "table"
        and type(character.Identity) == "table"
        and character.Identity.BaseClassId
        or nil

    if class_id == "Mage" then
        return MAGE_LOADOUT
    end

    return FIGHTER_LOADOUT
end

function DungeonStudioEquipmentBootstrap.seed(
    character: any
): number
    if type(character) ~= "table" then
        return 0
    end

    if type(character.Equipment) ~= "table" then
        character.Equipment = {}
    end

    local changed = 0

    for slot, item_id in pairs(
        loadout_for(character)
    ) do
        if character.Equipment[slot] == nil then
            character.Equipment[slot] = item_id
            changed += 1
        end
    end

    return changed
end

return table.freeze(
    DungeonStudioEquipmentBootstrap
)
