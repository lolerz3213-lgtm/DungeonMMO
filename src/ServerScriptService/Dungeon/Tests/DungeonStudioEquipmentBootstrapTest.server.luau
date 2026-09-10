--!strict
local ServerScriptService =
    game:GetService("ServerScriptService")

local Dungeon =
    ServerScriptService:WaitForChild("Dungeon")
local DungeonStudioEquipmentBootstrap =
    require(
        Dungeon:WaitForChild(
            "DungeonStudioEquipmentBootstrap"
        )
    )

local assertions = 0

local function check(
    condition: boolean,
    message: string
)
    assertions += 1

    if not condition then
        error(
            "[Dungeon Studio Equipment Bootstrap Tests] "
                .. message,
            2
        )
    end
end

local fighter = {
    Identity = {
        BaseClassId = "Fighter",
    },
    Equipment = {},
}

local fighter_changed =
    DungeonStudioEquipmentBootstrap.seed(
        fighter
    )

check(
    fighter_changed == 6,
    "Fighter Studio bootstrap must retain six representative slots."
)
check(
    fighter.Equipment.Weapon
        == "marauder_sword"
        and fighter.Equipment.OffHand
            == "marauder_shield",
    "Fighter representative weapon/off-hand must remain unchanged."
)

local mage = {
    Identity = {
        BaseClassId = "Mage",
    },
    Equipment = {},
}

local mage_changed =
    DungeonStudioEquipmentBootstrap.seed(
        mage
    )

check(
    mage_changed == 1,
    "Mage Studio bootstrap must only fill its Weapon slot."
)
check(
    mage.Equipment.Weapon
        == "apprentice_arcane_wand",
    "Mage representative weapon must be the Apprentice Arcane Wand."
)
check(
    mage.Equipment.OffHand == nil
        and mage.Equipment.Helmet == nil
        and mage.Equipment.Body == nil
        and mage.Equipment.Gloves == nil
        and mage.Equipment.Boots == nil,
    "Mage bootstrap must not inject Fighter armour or shield equipment."
)

local deliberate = {
    Identity = {
        BaseClassId = "Mage",
    },
    Equipment = {
        Weapon =
            "deliberate_test_weapon",
    },
}

local deliberate_changed =
    DungeonStudioEquipmentBootstrap.seed(
        deliberate
    )

check(
    deliberate_changed == 0
        and deliberate.Equipment.Weapon
            == "deliberate_test_weapon",
    "Existing deliberate Studio equipment must not be overwritten."
)

print(
    string.format(
        "[Dungeon Studio Equipment Bootstrap Tests] PASS: %d assertions.",
        assertions
    )
)
