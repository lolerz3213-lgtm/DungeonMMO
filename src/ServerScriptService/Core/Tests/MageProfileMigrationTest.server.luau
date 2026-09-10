--!strict
local ReplicatedStorage =
    game:GetService("ReplicatedStorage")
local ServerScriptService =
    game:GetService("ServerScriptService")

local Shared =
    ReplicatedStorage
        :WaitForChild("Core")
        :WaitForChild("Shared")
local Services =
    ServerScriptService
        :WaitForChild("Core")
        :WaitForChild("Services")

local ProfileSchema = require(
    Shared:WaitForChild("ProfileSchema")
)
local ProfileMigration = require(
    Services:WaitForChild(
        "ProfileMigration"
    )
)

local assertions = 0

local function check(
    value: boolean,
    message: string
)
    assertions += 1
    if not value then
        error(
            "[Mage Profile Migration Tests] "
                .. message,
            2
        )
    end
end

local profile =
    ProfileSchema.create_default(7441)
local character =
    profile.Characters.Slot1

character.Identity = {
    Version = 1,
    RaceId = "Human",
    BaseClassId = "Mage",
    ClassId = "Mage",
    CreationStage = "Complete",
}
character.Progression.Attributes = {
    Strength = 5,
    Dexterity = 4,
    Vitality = 6,
    Intellect = 8,
    Spirit = 7,
}
character.Progression.Skills = {
    ArcaneWard = {
        Known = true,
        StarterGranted = true,
        PurchasedRank = 1,
        Proficiency = 22,
    },
    MageHeal = {
        Known = true,
        StarterGranted = true,
        PurchasedRank = 1,
        Proficiency = 35,
    },
}
character.Progression.Loadout = {
    [1] = "ArcaneWard",
    [2] = "MageHeal",
}
character.Inventory = {
    {
        ItemId =
            "apprentice_arcane_wand",
        Quantity = 1,
    },
}
character.Equipment = {
    Weapon =
        "apprentice_arcane_wand",
}

local migrated =
    ProfileMigration.migrate(profile)
local migrated_character =
    migrated.Characters.Slot1

check(
    migrated_character.Identity.RaceId
        == "Human"
        and migrated_character.Identity
            .BaseClassId == "Mage"
        and migrated_character.Identity
            .ClassId == "Mage"
        and migrated_character.Identity
            .CreationStage == "Complete",
    "schema-v5 Mage identity must survive reload sanitization."
)
check(
    migrated_character.Progression
        .Attributes.Intellect == 8
        and migrated_character.Progression
            .Attributes.Spirit == 7,
    "Mage attribute allocation must survive reload sanitization."
)
check(
    migrated_character.Progression.Skills
        .ArcaneWard.Known == true
        and migrated_character.Progression
            .Skills.ArcaneWard
            .Proficiency == 22,
    "Arcane Ward state must survive reload sanitization."
)
check(
    migrated_character.Progression.Skills
        .MageHeal.Known == true
        and migrated_character.Progression
            .Skills.MageHeal
            .Proficiency == 35,
    "Mage Heal state must survive reload sanitization."
)
check(
    migrated_character.Progression
        .Loadout[1] == "ArcaneWard"
        and migrated_character.Progression
            .Loadout[2] == "MageHeal",
    "Mage starter loadout must survive reload sanitization."
)
check(
    migrated_character.Equipment.Weapon
        == "apprentice_arcane_wand",
    "persistent Apprentice Arcane Wand equipment must survive reload sanitization."
)
check(
    migrated_character.Inventory[1]
        .ItemId
        == "apprentice_arcane_wand"
        and migrated_character.Inventory[1]
            .Quantity == 1,
    "Mage starter Wand inventory entry must survive reload sanitization."
)

print(
    string.format(
        "[Mage Profile Migration Tests] PASS: %d assertions.",
        assertions
    )
)
