--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared =
    ReplicatedStorage
        :WaitForChild("Core")
        :WaitForChild("Shared")

local ClassDefinitions = require(
    Shared:WaitForChild(
        "ClassProgressionDefinitions"
    )
)
local SkillDefinitions = require(
    Shared:WaitForChild(
        "SkillProgressionDefinitions"
    )
)
local ItemDefinitions = require(
    Shared:WaitForChild("ItemDefinitions")
)
local EquipmentRules = require(
    Shared:WaitForChild("EquipmentRules")
)
local TrainerCatalogues = require(
    Shared:WaitForChild("TrainerCatalogues")
)
local AttributeConfig = require(
    Shared:WaitForChild("AttributeConfig")
)
local CombatSkillDefinitions = require(
    ReplicatedStorage
        :WaitForChild("Combat")
        :WaitForChild("Shared")
        :WaitForChild("SkillDefinitions")
)

local assertions = 0

local function check(
    value: boolean,
    message: string
)
    assertions += 1
    if not value then
        error(
            "[Mage Definitions Tests] "
                .. message,
            2
        )
    end
end

local mage =
    ClassDefinitions.get("Mage")

check(
    mage ~= nil,
    "Mage class must exist."
)
check(
    mage.StarterSkills[1] == "WindStrike"
        and mage.StarterSkills[2] == "ArcaneWard"
        and mage.StarterSkills[3] == "MageHeal",
    "Mage starter skills must be Wind Strike, Arcane Ward and Mage Heal."
)
check(
    mage.StarterEquipment.Weapon
        == "apprentice_arcane_wand",
    "Mage starter weapon must be the Apprentice Arcane Wand."
)
check(
    SkillDefinitions.get("ArcaneBolt") == nil,
    "Arcane Bolt must not replace the approved Spirit Orb basic attack."
)

local wind = CombatSkillDefinitions.get("WindStrike")
check(
    wind ~= nil
        and wind.KIND == "MagicProjectile"
        and wind.MANA_COST == 25
        and wind.COOLDOWN_SECONDS == 5.0
        and wind.WIND_UP_SECONDS == 1.0
        and wind.BASE_DAMAGE == 30
        and wind.RANGE_STUDS == 60
        and wind.MOVEMENT_SCALE.WIND_UP == 0
        and wind.MOVEMENT_SCALE.ACTIVE == 0
        and wind.MOVEMENT_SCALE.RECOVERY == 0,
    "Wind Strike must be the rooted charged Mage damage skill."
)
local wind_progression = SkillDefinitions.get("WindStrike")
check(
    wind_progression ~= nil
        and wind_progression.Kind == "Magic"
        and wind_progression.WeaponTags[1] == "ArcaneWand",
    "Wind Strike must require persistent ArcaneWand authority."
)

local ward =
    SkillDefinitions.get("ArcaneWard")
local heal =
    SkillDefinitions.get("MageHeal")

check(
    ward ~= nil
        and ward.Kind == "Support"
        and ward.WeaponTags[1] == "ArcaneWand",
    "Arcane Ward must require persistent ArcaneWand authority."
)
check(
    heal ~= nil
        and heal.Kind == "Support"
        and heal.WeaponTags[1] == "ArcaneWand",
    "Mage Heal must require persistent ArcaneWand authority."
)

local wand =
    ItemDefinitions.get(
        "apprentice_arcane_wand"
    )

check(
    wand ~= nil
        and wand.Kind == "Equipment"
        and wand.Slot == "Weapon",
    "Apprentice Arcane Wand must be Weapon equipment."
)
check(
    wand.WeaponTags[1] == "ArcaneWand"
        and wand.AllowedBaseClasses[1] == "Mage",
    "Apprentice Arcane Wand must carry Mage-only persistent weapon authority."
)

local mage_character = {
    Identity = {
        Version = 1,
        RaceId = "Human",
        BaseClassId = "Mage",
        ClassId = "Mage",
        CreationStage = "Complete",
    },
}
local fighter_character = {
    Identity = {
        Version = 1,
        RaceId = "Human",
        BaseClassId = "Fighter",
        ClassId = "Fighter",
        CreationStage = "Complete",
    },
}

check(
    EquipmentRules.validate(
        mage_character,
        wand,
        "Weapon"
    ).ok == true,
    "Mage must be eligible to equip its wand."
)
check(
    EquipmentRules.validate(
        fighter_character,
        wand,
        "Weapon"
    ).reason == "ClassRestricted",
    "Fighter must be rejected from Mage wand."
)
check(
    TrainerCatalogues.resolve_for_character(
        "MageTrainer",
        mage_character
    ).ok == true,
    "Mage must resolve MageTrainer."
)
check(
    TrainerCatalogues.resolve_for_character(
        "MageTrainer",
        fighter_character
    ).reason == "TrainerRestricted",
    "Fighter must be rejected by MageTrainer."
)

check(
    AttributeConfig.magical_multiplier(6)
        > AttributeConfig.magical_multiplier(5),
    "Intellect must increase magical damage scaling."
)
check(
    AttributeConfig.support_multiplier(6)
        > AttributeConfig.support_multiplier(5),
    "Spirit must increase support scaling."
)
check(
    AttributeConfig.max_mana(5, 6)
        > AttributeConfig.max_mana(5, 5),
    "Spirit must increase Max Mana."
)
check(
    AttributeConfig.max_mana(6, 5)
        > AttributeConfig.max_mana(5, 5),
    "Intellect must contribute secondarily to Max Mana."
)
check(
    AttributeConfig.mana_regen_per_second(6)
        > AttributeConfig.mana_regen_per_second(5),
    "Spirit must increase Mana regeneration."
)

print(
    string.format(
        "[Mage Definitions Tests] PASS: %d assertions.",
        assertions
    )
)
