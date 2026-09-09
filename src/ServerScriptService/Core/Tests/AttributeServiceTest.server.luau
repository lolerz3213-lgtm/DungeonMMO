--!strict

local ServerScriptService = game:GetService(
    "ServerScriptService"
)

local Core = ServerScriptService
    :WaitForChild("Core")

local Adapters =
    Core:WaitForChild("Adapters")

local Services =
    Core:WaitForChild("Services")

local InMemoryProfileAdapter = require(
    Adapters:WaitForChild(
        "InMemoryProfileAdapter"
    )
)

local ProfileService = require(
    Services:WaitForChild(
        "ProfileService"
    )
)

local AttributeService = require(
    Services:WaitForChild(
        "AttributeService"
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
            "[Attribute Service Tests] "
                .. message,
            2
        )
    end
end

local function human_baseline(): any
    return {
        Strength = 5,
        Dexterity = 4,
        Vitality = 6,
        Intellect = 5,
        Spirit = 5,
    }
end

local function elf_baseline(): any
    return {
        Strength = 5,
        Dexterity = 6,
        Vitality = 4,
        Intellect = 5,
        Spirit = 5,
    }
end

local function completed_service(
    user_id: number,
    race_id: string,
    attributes: any,
    entitlement: number
): (any, any)
    local profiles =
        ProfileService.new(
            InMemoryProfileAdapter.new()
        )

    local loaded, load_error =
        profiles:load(user_id)

    check(
        loaded ~= nil
            and load_error == nil,
        "test profile must load."
    )

    local seeded, seed_error =
        profiles:mutate(
            user_id,
            function(profile: any)
                local character =
                    profile.Characters.Slot1

                character.Identity = {
                    Version = 1,
                    RaceId = race_id,
                    BaseClassId = "Fighter",
                    ClassId = "Fighter",
                    CreationStage = "Complete",
                }

                character
                    .Progression
                    .Attributes = {
                    Strength =
                        attributes.Strength,

                    Dexterity =
                        attributes.Dexterity,

                    Vitality =
                        attributes.Vitality,

                    Intellect =
                        attributes.Intellect,

                    Spirit =
                        attributes.Spirit,
                }

                character
                    .Progression
                    .AttributePointEntitlement =
                    entitlement
            end
        )

    check(
        seeded == true
            and seed_error == nil,
        "completed identity fixture must seed."
    )

    return profiles, AttributeService.new(profiles)
end

-- ------------------------------------------------------------
-- Unresolved identity
-- ------------------------------------------------------------

do
    local user_id = 9401

    local profiles =
        ProfileService.new(
            InMemoryProfileAdapter.new()
        )

    local loaded =
        profiles:load(user_id)

    check(
        loaded ~= nil,
        "unresolved profile must load."
    )

    local service =
        AttributeService.new(profiles)

    local character = assert(
        profiles:get_character(
            user_id,
            1
        )
    )

    check(
        AttributeService
            .get_available_points(
                character
            )
            == 0,
        "unresolved identity must expose zero available AP."
    )

    local desired = {
        Strength = 5,
        Dexterity = 5,
        Vitality = 5,
        Intellect = 5,
        Spirit = 5,
    }

    local preview =
        service:preview(
            user_id,
            desired
        )

    check(
        preview.ok == false
            and preview.reason
                == "IdentityIncomplete",
        "unresolved preview must return IdentityIncomplete."
    )

    local commit =
        service:commit(
            user_id,
            desired
        )

    check(
        commit.ok == false
            and commit.reason
                == "IdentityIncomplete",
        "unresolved commit must return IdentityIncomplete."
    )

    local respec =
        service:respec(user_id)

    check(
        respec.ok == false
            and respec.reason
                == "IdentityIncomplete",
        "unresolved respec must return IdentityIncomplete."
    )

    local unchanged = assert(
        profiles:get_character(
            user_id,
            1
        )
    )

    check(
        unchanged
            .Progression
            .RespecCounters
            .Attributes
            == 0,
        "rejected unresolved respec must not increment counter."
    )
end

-- ------------------------------------------------------------
-- Human racial baseline:
-- 5 / 4 / 6 / 5 / 5
-- ------------------------------------------------------------

local human_user_id = 9402

local human_profiles,
    human_service =
    completed_service(
        human_user_id,
        "Human",
        human_baseline(),
        4
    )

local human_initial = assert(
    human_profiles:get_character(
        human_user_id,
        1
    )
)

check(
    AttributeService
        .get_available_points(
            human_initial
        )
        == 4,
    "Human racial baseline must cost zero AP."
)

local human_baseline_preview =
    human_service:preview(
        human_user_id,
        human_baseline()
    )

check(
    human_baseline_preview.ok == true
        and human_baseline_preview.spent_points
            == 0
        and human_baseline_preview.available_points
            == 4,
    "Human baseline must preview as zero spent AP."
)

local human_dex_five = {
    Strength = 5,
    Dexterity = 5,
    Vitality = 6,
    Intellect = 5,
    Spirit = 5,
}

local dex_commit =
    human_service:commit(
        human_user_id,
        human_dex_five
    )

check(
    dex_commit.ok == true
        and dex_commit.spent_points == 1
        and dex_commit.available_points == 3,
    "Human Dexterity 5 must cost exactly 1 AP."
)

local human_after_dex = assert(
    human_profiles:get_character(
        human_user_id,
        1
    )
)

check(
    human_after_dex
        .Progression
        .Attributes
        .Dexterity
        == 5,
    "Human Dexterity spend must persist."
)

local below_human_vitality = {
    Strength = 5,
    Dexterity = 5,
    Vitality = 5,
    Intellect = 5,
    Spirit = 5,
}

local invalid_vitality =
    human_service:commit(
        human_user_id,
        below_human_vitality
    )

check(
    invalid_vitality.ok == false
        and invalid_vitality.reason
            == "InvalidAttributeValue",
    "Human Vitality may not fall below racial baseline 6."
)

local strength_seven = {
    Strength = 7,
    Dexterity = 5,
    Vitality = 6,
    Intellect = 5,
    Spirit = 5,
}

local strength_commit =
    human_service:commit(
        human_user_id,
        strength_seven
    )

check(
    strength_commit.ok == true
        and strength_commit.spent_points == 3
        and strength_commit.available_points == 1,
    "racial baseline spend must count only invested AP."
)

local strength_six = {
    Strength = 6,
    Dexterity = 5,
    Vitality = 6,
    Intellect = 5,
    Spirit = 5,
}

local normal_decrease =
    human_service:commit(
        human_user_id,
        strength_six
    )

check(
    normal_decrease.ok == false
        and normal_decrease.reason
            == "DecreaseRequiresRespec",
    "normal commit must still reject allocated decreases."
)

local overspend = {
    Strength = 99,
    Dexterity = 5,
    Vitality = 6,
    Intellect = 5,
    Spirit = 5,
}

local overspend_result =
    human_service:commit(
        human_user_id,
        overspend
    )

check(
    overspend_result.ok == false
        and overspend_result.reason
            == "InsufficientAttributePoints",
    "racial-baseline overspend must reject."
)

local human_after_rejections = assert(
    human_profiles:get_character(
        human_user_id,
        1
    )
)

check(
    human_after_rejections
        .Progression
        .Attributes
        .Strength
        == 7,
    "rejected spends must not partially mutate attributes."
)

local human_respec =
    human_service:respec(
        human_user_id
    )

check(
    human_respec.ok == true
        and human_respec.available_points
            == 4
        and human_respec.respec_count
            == 1,
    "Human respec must restore all entitled AP."
)

local human_reset = assert(
    human_profiles:get_character(
        human_user_id,
        1
    )
)

local human_reset_attributes =
    human_reset.Progression.Attributes

check(
    human_reset_attributes.Strength == 5
        and human_reset_attributes.Dexterity == 4
        and human_reset_attributes.Vitality == 6
        and human_reset_attributes.Intellect == 5
        and human_reset_attributes.Spirit == 5,
    "Human respec must return exactly to 5/4/6/5/5."
)

check(
    human_reset
        .Progression
        .RespecCounters
        .Attributes
        == 1,
    "Human respec must increment only attribute respec counter."
)

check(
    human_reset
        .Progression
        .RespecCounters
        .Skills
        == 0,
    "attribute respec must not increment skill respec counter."
)

check(
    AttributeService
        .get_available_points(
            human_reset
        )
        == 4,
    "Human respec baseline must again cost zero AP."
)

-- ------------------------------------------------------------
-- Elf racial baseline:
-- 5 / 6 / 4 / 5 / 5
-- ------------------------------------------------------------

local elf_user_id = 9403

local elf_profiles,
    elf_service =
    completed_service(
        elf_user_id,
        "Elf",
        elf_baseline(),
        4
    )

local elf_initial = assert(
    elf_profiles:get_character(
        elf_user_id,
        1
    )
)

check(
    AttributeService
        .get_available_points(
            elf_initial
        )
        == 4,
    "Elf racial baseline must cost zero AP."
)

local elf_dex_eight = {
    Strength = 5,
    Dexterity = 8,
    Vitality = 4,
    Intellect = 5,
    Spirit = 5,
}

local elf_dex_commit =
    elf_service:commit(
        elf_user_id,
        elf_dex_eight
    )

check(
    elf_dex_commit.ok == true
        and elf_dex_commit.spent_points
            == 2
        and elf_dex_commit.available_points
            == 2,
    "Elf Dexterity 8 must cost exactly 2 AP."
)

local elf_after_spend = assert(
    elf_profiles:get_character(
        elf_user_id,
        1
    )
)

check(
    elf_after_spend
        .Progression
        .Attributes
        .Vitality
        == 4,
    "Elf Vitality 4 racial baseline must remain valid."
)

local elf_respec =
    elf_service:respec(
        elf_user_id
    )

check(
    elf_respec.ok == true
        and elf_respec.available_points
            == 4,
    "Elf respec must restore all entitled AP."
)

local elf_reset = assert(
    elf_profiles:get_character(
        elf_user_id,
        1
    )
)

local elf_reset_attributes =
    elf_reset.Progression.Attributes

check(
    elf_reset_attributes.Strength == 5
        and elf_reset_attributes.Dexterity == 6
        and elf_reset_attributes.Vitality == 4
        and elf_reset_attributes.Intellect == 5
        and elf_reset_attributes.Spirit == 5,
    "Elf respec must return exactly to 5/6/4/5/5."
)

check(
    AttributeService
        .get_available_points(
            elf_reset
        )
        == 4,
    "Elf respec baseline must again cost zero AP."
)

print(
    string.format(
        "[Attribute Service Tests] PASS: %d assertions.",
        assertions
    )
)