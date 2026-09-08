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

local InventoryService = require(
    Services:WaitForChild(
        "InventoryService"
    )
)

local LoadoutService = require(
    Services:WaitForChild(
        "LoadoutService"
    )
)

local SkillProgressionService = require(
    Services:WaitForChild(
        "SkillProgressionService"
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
            "[Skill Progression Service Tests] "
                .. message,
            2
        )
    end
end

local function seed_human_fighter(
    profiles: any,
    user_id: number,
    entitlement: number
)
    local ok, err =
        profiles:mutate(
            user_id,
            function(profile: any)
                local character =
                    profile.Characters.Slot1

                character.Identity = {
                    Version = 1,
                    RaceId = "Human",
                    BaseClassId = "Fighter",
                    ClassId = "Fighter",
                    CreationStage = "Complete",
                }

                character.Progression.Attributes = {
                    Strength = 5,
                    Dexterity = 4,
                    Vitality = 6,
                    Intellect = 5,
                    Spirit = 5,
                }

                character
                    .Progression
                    .SkillPointEntitlement =
                    entitlement

                character.Progression.Skills = {
                    ShieldBash = {
                        Known = true,
                        StarterGranted = true,
                        PurchasedRank = 1,
                        Proficiency = 0,
                    },

                    Mend = {
                        Known = true,
                        StarterGranted = true,
                        PurchasedRank = 1,
                        Proficiency = 0,
                    },
                }

                character.Progression.Loadout = {
                    [1] = "ShieldBash",
                    [2] = "Mend",
                }
            end
        )

    check(
        ok == true and err == nil,
        "completed Human Fighter fixture must seed."
    )
end

-- ------------------------------------------------------------
-- Unresolved identity gates
-- ------------------------------------------------------------

do
    local profiles =
        ProfileService.new(
            InMemoryProfileAdapter.new()
        )

    assert(profiles:load(9300))

    assert(
        profiles:mutate(
            9300,
            function(profile: any)
                profile
                    .Characters
                    .Slot1
                    .Progression
                    .SkillPointEntitlement =
                    9
            end
        )
    )

    local inventory =
        InventoryService.new(profiles)

    local loadout =
        LoadoutService.new(profiles)

    local skills =
        SkillProgressionService.new(
            profiles,
            inventory,
            loadout
        )

    check(
        skills:get_available_sp(9300)
            == 0,
        "unresolved identity must expose zero usable SP."
    )

    local rank =
        skills:purchase_rank(
            9300,
            "Mend"
        )

    check(
        rank.ok == false
            and rank.reason
                == "IdentityIncomplete",
        "unresolved rank purchase must be blocked."
    )

    local respec =
        skills:respec_skills(
            9300
        )

    check(
        respec.ok == false
            and respec.reason
                == "IdentityIncomplete",
        "unresolved skill respec must be blocked."
    )

    check(
        inventory:add_item(
            9300,
            "arc_slash_book_bound",
            1
        ).ok,
        "unresolved fixture may receive its test book."
    )

    local learn =
        skills:learn_skill(
            9300,
            "ArcSlash",
            "arc_slash_book_bound"
        )

    check(
        learn.ok == false
            and learn.reason
                == "IdentityIncomplete",
        "unresolved Arc Slash learning must be blocked."
    )
end

-- ------------------------------------------------------------
-- Completed Human Fighter regression
-- ------------------------------------------------------------

local profiles =
    ProfileService.new(
        InMemoryProfileAdapter.new()
    )

assert(profiles:load(9301))

seed_human_fighter(
    profiles,
    9301,
    9
)

local inventory =
    InventoryService.new(profiles)

local loadout =
    LoadoutService.new(profiles)

local skills =
    SkillProgressionService.new(
        profiles,
        inventory,
        loadout
    )

check(
    skills:get_available_sp(9301)
        == 9,
    "free Fighter starter ranks must cost zero SP."
)

local mend_rank_two =
    skills:purchase_rank(
        9301,
        "Mend"
    )

check(
    mend_rank_two.ok == false
        and mend_rank_two.reason
            == "ProficiencyThresholdNotMet",
    "rank purchase must require proficiency threshold."
)

assert(
    profiles:mutate(
        9301,
        function(profile: any)
            profile
                .Characters
                .Slot1
                .Progression
                .Skills
                .Mend
                .Proficiency =
                100
        end
    )
)

mend_rank_two =
    skills:purchase_rank(
        9301,
        "Mend"
    )

check(
    mend_rank_two.ok == true
        and skills:get_available_sp(
            9301
        ) == 8,
    "Mend Rank 2 must cost one SP."
)

check(
    inventory:add_item(
        9301,
        "arc_slash_book_bound",
        1
    ).ok,
    "Arc Slash test book must be addable."
)

local learned =
    skills:learn_skill(
        9301,
        "ArcSlash",
        "arc_slash_book_bound"
    )

check(
    learned.ok == true
        and skills:get_available_sp(
            9301
        ) == 5,
    "Fighter Arc Slash Rank 1 must consume book and 3 SP."
)

local character = assert(
    profiles:get_character(
        9301,
        1
    )
)

check(
    character
        .Progression
        .Skills
        .ArcSlash
        .Known
        == true,
    "Arc Slash knowledge must persist."
)

local before =
    skills:get_available_sp(
        9301
    )

local respec =
    skills:respec_skills(
        9301
    )

local after =
    skills:get_available_sp(
        9301
    )

character = assert(
    profiles:get_character(
        9301,
        1
    )
)

check(
    respec.ok == true
        and after <= 9
        and after > before,
    "respec may refund allocation without exceeding entitlement."
)

check(
    character
        .Progression
        .Skills
        .Mend
        .PurchasedRank
        == 1
        and character
            .Progression
            .Skills
            .ShieldBash
            .PurchasedRank
            == 1,
    "free Fighter starter Rank 1 skills must survive respec."
)

check(
    character
        .Progression
        .Skills
        .ArcSlash
        .Known
        == true
        and character
            .Progression
            .Skills
            .ArcSlash
            .PurchasedRank
            == 0,
    "book knowledge survives while refunded Arc Slash becomes inactive."
)

check(
    character
        .Progression
        .RespecCounters
        .Skills
        == 1
        and character
            .Progression
            .RespecCounters
            .Attributes
            == 0,
    "skill respec must increment only its own counter."
)

local again =
    skills:respec_skills(
        9301
    )

check(
    again.ok == true
        and skills:get_available_sp(
            9301
        ) == 9,
    "repeated respec cannot mint SP."
)

print(
    string.format(
        "[Skill Progression Service Tests] PASS: %d assertions.",
        assertions
    )
)