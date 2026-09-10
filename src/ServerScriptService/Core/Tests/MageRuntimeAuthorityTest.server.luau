--!strict
local ServerScriptService =
    game:GetService("ServerScriptService")

local ProgressionRuntimeState = require(
    ServerScriptService
        :WaitForChild("Core")
        :WaitForChild("Services")
        :WaitForChild(
            "ProgressionRuntimeState"
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
            "[Mage Runtime Authority Tests] "
                .. message,
            2
        )
    end
end

local user_id = 7421

local function character(
    equipment: any
): any
    return {
        Identity = {
            Version = 1,
            RaceId = "Human",
            BaseClassId = "Mage",
            ClassId = "Mage",
            CreationStage = "Complete",
        },
        Equipment = equipment,
        Progression = {
            Attributes = {
                Strength = 5,
                Dexterity = 5,
                Vitality = 6,
                Intellect = 7,
                Spirit = 8,
            },
            Skills = {
                ArcaneWard = {
                    Known = true,
                    PurchasedRank = 1,
                },
                MageHeal = {
                    Known = true,
                    PurchasedRank = 1,
                },
            },
            Loadout = {
                [1] = "ArcaneWard",
                [2] = "MageHeal",
            },
        },
    }
end

ProgressionRuntimeState.set_character(
    user_id,
    character({})
)

local usable, reason =
    ProgressionRuntimeState
        .is_skill_usable(
            user_id,
            "ArcaneWard",
            {ArcaneWand = true}
        )

check(
    usable == false
        and reason == "WrongWeapon",
    "caller-observed fake Wand must not grant Arcane Ward"
)

ProgressionRuntimeState.set_character(
    user_id,
    character({
        Weapon =
            "apprentice_arcane_wand",
    })
)

usable, reason =
    ProgressionRuntimeState
        .is_skill_usable(
            user_id,
            "ArcaneWard",
            {}
        )

check(
    usable == true and reason == nil,
    "persistent Apprentice Wand must authorize Arcane Ward"
)

usable, reason =
    ProgressionRuntimeState
        .is_skill_usable(
            user_id,
            "MageHeal",
            {}
        )

check(
    usable == true and reason == nil,
    "persistent Apprentice Wand must authorize Mage Heal"
)
check(
    ProgressionRuntimeState
        .get_weapon_tags(user_id)
        .ArcaneWand == true,
    "runtime equipment must expose ArcaneWand basic-attack authority"
)
check(
    ProgressionRuntimeState
        .get_magical_multiplier(user_id)
        > 1,
    "Intellect must raise runtime magic multiplier"
)
check(
    ProgressionRuntimeState
        .get_support_multiplier(user_id)
        > 1,
    "Spirit must raise runtime support multiplier"
)
check(
    ProgressionRuntimeState
        .get_max_mana(user_id)
        > 100,
    "Mage INT/SPI investment must increase Max Mana"
)
check(
    ProgressionRuntimeState
        .get_mana_regen_per_second(user_id)
        > 8,
    "Mage Spirit investment must increase Mana regeneration"
)

ProgressionRuntimeState.clear_character(
    user_id
)

print(
    string.format(
        "[Mage Runtime Authority Tests] PASS: %d assertions.",
        assertions
    )
)
