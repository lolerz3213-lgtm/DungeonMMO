--!strict
local ReplicatedStorage =
    game:GetService("ReplicatedStorage")
local ServerScriptService =
    game:GetService("ServerScriptService")

local Core =
    ServerScriptService:WaitForChild("Core")
local ProfileService = require(
    Core:WaitForChild("Services")
        :WaitForChild("ProfileService")
)
local IdentityService = require(
    Core:WaitForChild("Services")
        :WaitForChild("IdentityService")
)
local InMemoryProfileAdapter = require(
    Core:WaitForChild("Adapters")
        :WaitForChild("InMemoryProfileAdapter")
)

local assertions = 0

local function check(
    value: boolean,
    message: string
)
    assertions += 1
    if not value then
        error(
            "[Mage Identity Tests] "
                .. message,
            2
        )
    end
end

local function run(
    race_id: string,
    user_id: number
)
    local profiles =
        ProfileService.new(
            InMemoryProfileAdapter.new()
        )
    local loaded, err =
        profiles:load(user_id)

    check(
        loaded ~= nil and err == nil,
        "profile must load"
    )

    local identity =
        IdentityService.new(profiles)

    check(
        identity:select_race(
            user_id,
            race_id
        ).ok == true,
        race_id
            .. " race selection must succeed"
    )
    check(
        identity:select_base_class(
            user_id,
            "Mage"
        ).ok == true,
        race_id
            .. " Mage selection must succeed"
    )

    local character =
        assert(
            profiles:get_character(
                user_id,
                1
            )
        )

    check(
        character.Identity.RaceId == race_id
            and character.Identity.BaseClassId
                == "Mage"
            and character.Identity.ClassId
                == "Mage"
            and character.Identity.CreationStage
                == "Complete",
        "Mage identity must complete"
    )
    check(
        character.Progression.Skills
            .WindStrike.Known == true
            and character.Progression.Skills
                .WindStrike.StarterGranted
                == true
            and character.Progression.Skills
                .WindStrike.PurchasedRank
                == 1,
        "Wind Strike exact starter state"
    )    check(
        character.Progression.Skills
            .ArcaneWard.Known == true
            and character.Progression.Skills
                .ArcaneWard.StarterGranted
                == true
            and character.Progression.Skills
                .ArcaneWard.PurchasedRank
                == 1,
        "Arcane Ward exact starter state"
    )
    check(
        character.Progression.Skills
            .MageHeal.Known == true
            and character.Progression.Skills
                .MageHeal.StarterGranted
                == true
            and character.Progression.Skills
                .MageHeal.PurchasedRank
                == 1,
        "Mage Heal exact starter state"
    )
    check(
        character.Progression.Skills
            .ArcaneBolt == nil,
        "Mage must not receive Arcane Bolt"
    )
    check(
        character.Progression.Loadout[1]
            == "WindStrike"
            and character.Progression.Loadout[2]
                == "ArcaneWard"
            and character.Progression.Loadout[3]
                == "MageHeal",
        "Mage loadout must initialize Wind Strike/Ward/Heal in slots 1/2/3"
    )
    check(
        character.Equipment.Weapon
            == "apprentice_arcane_wand",
        "Mage wand must be persistently equipped"
    )

    local count = 0
    for _, entry in ipairs(
        character.Inventory
    ) do
        if entry.ItemId
            == "apprentice_arcane_wand"
        then
            count += tonumber(entry.Quantity)
                or 0
        end
    end

    check(
        count == 1,
        "Mage must receive exactly one Apprentice Arcane Wand"
    )

    local duplicate =
        identity:select_base_class(
            user_id,
            "Mage"
        )
    check(
        duplicate.ok == false
            and duplicate.reason
                == "ClassSelectionNotAllowed",
        "duplicate class selection must reject"
    )

    local count_after = 0
    for _, entry in ipairs(
        character.Inventory
    ) do
        if entry.ItemId
            == "apprentice_arcane_wand"
        then
            count_after +=
                tonumber(entry.Quantity)
                or 0
        end
    end

    check(
        count_after == 1,
        "duplicate selection must not duplicate wand"
    )
end

run("Human", 7411)
run("Elf", 7412)

print(
    string.format(
        "[Mage Identity Tests] PASS: %d assertions.",
        assertions
    )
)
