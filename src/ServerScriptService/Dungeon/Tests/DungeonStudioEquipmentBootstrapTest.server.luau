--!strict
local ServerScriptService = game:GetService("ServerScriptService")

local Dungeon = ServerScriptService:WaitForChild("Dungeon")
local Bootstrap = require(
    Dungeon:WaitForChild("DungeonStudioEquipmentBootstrap")
)

local assertions = 0

local function check(condition: boolean, message: string)
    assertions += 1

    if not condition then
        error("[Dungeon Studio Equipment Bootstrap Tests] " .. message, 2)
    end
end

local character = {
    Equipment = {},
}
local changed = Bootstrap.seed(character)

check(changed == 6, "fresh Studio character must receive six slots")
check(
    character.Equipment.Weapon == "marauder_sword",
    "Studio Weapon must be the representative sword"
)
check(
    character.Equipment.OffHand == "marauder_shield",
    "Studio OffHand must be the representative shield"
)
check(
    character.Equipment.Helmet == "marauder_helmet",
    "Studio Helmet must be representative"
)
check(
    character.Equipment.Body == "marauder_armor",
    "Studio Body must be representative"
)
check(
    character.Equipment.Gloves == "marauder_gloves",
    "Studio Gloves must be representative"
)
check(
    character.Equipment.Boots == "marauder_boots",
    "Studio Boots must be representative"
)

character.Equipment.Weapon = "custom_test_weapon"
local second_changed = Bootstrap.seed(character)

check(second_changed == 0, "filled slots must not be overwritten")
check(
    character.Equipment.Weapon == "custom_test_weapon",
    "deliberate Studio setup must be preserved"
)

print(
    string.format(
        "[Dungeon Studio Equipment Bootstrap Tests] PASS: %d assertions.",
        assertions
    )
)
