--!strict

local ReplicatedStorage = game:GetService(
    "ReplicatedStorage"
)

local ServerScriptService = game:GetService(
    "ServerScriptService"
)

local Shared = ReplicatedStorage
    :WaitForChild("Core")
    :WaitForChild("Shared")

local Core = ServerScriptService
    :WaitForChild("Core")

local Adapters =
    Core:WaitForChild("Adapters")

local Services =
    Core:WaitForChild("Services")

local ProfileSchema = require(
    Shared:WaitForChild("ProfileSchema")
)

local ProfileService = require(
    Services:WaitForChild("ProfileService")
)

local IdentityService = require(
    Services:WaitForChild("IdentityService")
)

local InMemoryProfileAdapter = require(
    Adapters:WaitForChild(
        "InMemoryProfileAdapter"
    )
)

local assertion_count = 0

local function check(
    condition: boolean,
    message: string
)
    assertion_count += 1

    if not condition then
        error(
            "[Phase 2C.A Identity Service Tests] "
                .. message,
            2
        )
    end
end

local function deep_equal(
    left: any,
    right: any
): boolean
    if type(left) ~= type(right) then
        return false
    end

    if type(left) ~= "table" then
        return left == right
    end

    for key, value in pairs(left) do
        if not deep_equal(
            value,
            right[key]
        ) then
            return false
        end
    end

    for key in pairs(right) do
        if left[key] == nil then
            return false
        end
    end

    return true
end

local function loaded_identity_service(
    user_id: number,
    stored_profile: any?
): (any, any, () -> number)
    local initial_data = nil

    if stored_profile ~= nil then
        initial_data = {
            [user_id] =
                stored_profile,
        }
    end

    local profiles = ProfileService.new(
        InMemoryProfileAdapter.new(
            initial_data
        )
    )

    local loaded, load_error =
        profiles:load(user_id)

    check(
        loaded ~= nil
            and load_error == nil,
        "Test profile must load."
    )

    local mutation_count = 0
    local proxy = {}

    function proxy:get_character(
        target_user_id: number,
        slot: number?
    ): any?
        return profiles:get_character(
            target_user_id,
            slot
        )
    end

    function proxy:mutate(
        target_user_id: number,
        mutator: (any) -> ()
    ): (boolean, string?)
        mutation_count += 1

        return profiles:mutate(
            target_user_id,
            mutator
        )
    end

    local identity =
        IdentityService.new(proxy)

    local function get_mutation_count(): number
        return mutation_count
    end

    return profiles, identity, get_mutation_count
end

-- ------------------------------------------------------------
-- Profile-not-loaded contract
-- ------------------------------------------------------------

do
    local profiles = ProfileService.new(
        InMemoryProfileAdapter.new()
    )

    local identity =
        IdentityService.new(profiles)

    local race_result =
        identity:select_race(
            7301,
            "Human"
        )

    check(
        race_result.ok == false
            and race_result.reason
                == "ProfileNotLoaded",
        "Unloaded race selection must return ProfileNotLoaded."
    )

    local class_result =
        identity:select_base_class(
            7301,
            "Fighter"
        )

    check(
        class_result.ok == false
            and class_result.reason
                == "ProfileNotLoaded",
        "Unloaded class selection must return ProfileNotLoaded."
    )
end

-- ------------------------------------------------------------
-- Fresh:
-- RaceSelection -> Elf -> ClassSelection
-- ------------------------------------------------------------

local fresh_user_id = 7302

local fresh_profiles,
    fresh_identity,
    fresh_mutations =
    loaded_identity_service(
        fresh_user_id,
        nil
    )

local fresh_before = assert(
    fresh_profiles:get_character(
        fresh_user_id,
        1
    )
)

check(
    fresh_before.Identity.CreationStage
        == "RaceSelection",
    "Fresh character must begin in RaceSelection."
)

check(
    next(
        fresh_before.Progression.Skills
    ) == nil,
    "Fresh character must not already have Fighter skills."
)

check(
    next(
        fresh_before.Progression.Loadout
    ) == nil,
    "Fresh character must not already have Fighter loadout."
)

local class_too_early =
    fresh_identity:select_base_class(
        fresh_user_id,
        "Fighter"
    )

check(
    class_too_early.ok == false
        and class_too_early.reason
            == "ClassSelectionNotAllowed",
    "Fighter cannot be chosen before race."
)

check(
    fresh_mutations() == 0,
    "Rejected class-before-race must not mutate."
)

local fresh_snapshot =
    ProfileSchema.deep_clone(
        fresh_before
    )

local unknown_race =
    fresh_identity:select_race(
        fresh_user_id,
        "Orc"
    )

check(
    unknown_race.ok == false
        and unknown_race.reason
            == "UnknownRace",
    "Unknown race must reject with UnknownRace."
)

check(
    fresh_mutations() == 0,
    "Unknown race must not mutate."
)

check(
    deep_equal(
        fresh_snapshot,
        fresh_profiles:get_character(
            fresh_user_id,
            1
        )
    ),
    "Rejected race selection must be atomic."
)

local elf_result =
    fresh_identity:select_race(
        fresh_user_id,
        "Elf"
    )

check(
    elf_result.ok == true,
    "Fresh Elf selection must succeed."
)

check(
    fresh_mutations() == 1,
    "Successful race selection must use exactly one mutation."
)

local elf_selected = assert(
    fresh_profiles:get_character(
        fresh_user_id,
        1
    )
)

check(
    elf_selected.Identity.RaceId
        == "Elf",
    "Elf selection must persist RaceId."
)

check(
    elf_selected.Identity.BaseClassId
        == nil,
    "Base class must remain unresolved after fresh race choice."
)

check(
    elf_selected.Identity.ClassId
        == nil,
    "Current class must remain unresolved after fresh race choice."
)

check(
    elf_selected.Identity.CreationStage
        == "ClassSelection",
    "Fresh race choice must advance to ClassSelection."
)

local elf_attributes =
    elf_selected.Progression.Attributes

check(
    elf_attributes.Strength == 5
        and elf_attributes.Dexterity == 6
        and elf_attributes.Vitality == 4
        and elf_attributes.Intellect == 5
        and elf_attributes.Spirit == 5,
    "Fresh Elf must receive exact 5/6/4/5/5 baseline."
)

check(
    next(
        elf_selected.Progression.Skills
    ) == nil,
    "Race selection alone must not grant Fighter skills."
)

check(
    next(
        elf_selected.Progression.Loadout
    ) == nil,
    "Race selection alone must not grant Fighter loadout."
)

local after_race =
    ProfileSchema.deep_clone(
        elf_selected
    )

local second_race =
    fresh_identity:select_race(
        fresh_user_id,
        "Human"
    )

check(
    second_race.ok == false
        and second_race.reason
            == "RaceSelectionNotAllowed",
    "Second race selection must reject."
)

check(
    fresh_mutations() == 1,
    "Rejected second race must not mutate."
)

check(
    deep_equal(
        after_race,
        fresh_profiles:get_character(
            fresh_user_id,
            1
        )
    ),
    "Rejected second race must leave identity unchanged."
)

-- ------------------------------------------------------------
-- Fresh:
-- ClassSelection -> Fighter -> Complete
-- ------------------------------------------------------------

local unknown_class =
    fresh_identity:select_base_class(
        fresh_user_id,
        "Ranger"
    )

check(
    unknown_class.ok == false
        and unknown_class.reason
            == "UnknownClass",
    "Unknown class must reject with UnknownClass."
)

check(
    fresh_mutations() == 1,
    "Unknown class must not mutate."
)

local fighter_result =
    fresh_identity:select_base_class(
        fresh_user_id,
        "Fighter"
    )

check(
    fighter_result.ok == true,
    "Fighter selection must succeed."
)

check(
    fresh_mutations() == 2,
    "Successful class selection must use exactly one mutation."
)

local completed_elf = assert(
    fresh_profiles:get_character(
        fresh_user_id,
        1
    )
)

check(
    completed_elf.Identity.RaceId
        == "Elf",
    "Fighter selection must preserve Elf."
)

check(
    completed_elf.Identity.BaseClassId
        == "Fighter",
    "Fighter must become BaseClassId."
)

check(
    completed_elf.Identity.ClassId
        == "Fighter",
    "Fighter must become ClassId."
)

check(
    completed_elf.Identity.CreationStage
        == "Complete",
    "Fighter selection must complete character creation."
)

local shield_bash =
    completed_elf
        .Progression
        .Skills
        .ShieldBash

local mend =
    completed_elf
        .Progression
        .Skills
        .Mend

check(
    shield_bash ~= nil
        and shield_bash.Known == true
        and shield_bash.StarterGranted == true
        and shield_bash.PurchasedRank == 1
        and shield_bash.Proficiency == 0,
    "Fighter must grant exact Shield Bash starter state."
)

check(
    mend ~= nil
        and mend.Known == true
        and mend.StarterGranted == true
        and mend.PurchasedRank == 1
        and mend.Proficiency == 0,
    "Fighter must grant exact Mend starter state."
)

check(
    completed_elf.Progression.Loadout[1]
        == "ShieldBash"
        and completed_elf.Progression.Loadout[2]
            == "Mend",
    "Fighter must initialize loadout slots 1 and 2."
)

local completed_snapshot =
    ProfileSchema.deep_clone(
        completed_elf
    )

local duplicate_class =
    fresh_identity:select_base_class(
        fresh_user_id,
        "Fighter"
    )

check(
    duplicate_class.ok == false
        and duplicate_class.reason
            == "ClassSelectionNotAllowed",
    "Second Fighter selection must reject."
)

check(
    fresh_mutations() == 2,
    "Rejected duplicate Fighter selection must not mutate."
)

check(
    deep_equal(
        completed_snapshot,
        fresh_profiles:get_character(
            fresh_user_id,
            1
        )
    ),
    "Rejected duplicate Fighter selection must not duplicate grants."
)

-- ------------------------------------------------------------
-- Legacy source fixture
-- ------------------------------------------------------------

local legacy_v3 = {
    SchemaVersion = 3,

    Account = {
        SelectedCharacterSlot = 1,
    },

    Characters = {
        Slot1 = {
            Level = 8,
            XP = 345,
            Gold = 777,

            Inventory = {},

            DungeonProgress = {},

            RewardHistory = {
                Completion = {},
                Monster = {},
            },

            Progression = {
                Attributes = {
                    Strength = 7,
                    Dexterity = 5,
                    Vitality = 6,
                    Intellect = 5,
                    Spirit = 5,
                },

                AttributePointEntitlement = 12,
                SkillPointEntitlement = 13,

                Skills = {
                    ShieldBash = {
                        Known = true,
                        StarterGranted = true,
                        PurchasedRank = 1,
                        Proficiency = 20,
                    },

                    Mend = {
                        Known = true,
                        StarterGranted = true,
                        PurchasedRank = 1,
                        Proficiency = 30,
                    },

                    ArcSlash = {
                        Known = true,
                        StarterGranted = false,
                        PurchasedRank = 2,
                        Proficiency = 420,
                    },
                },

                Loadout = {
                    [1] = "Mend",
                    [3] = "ArcSlash",
                    [6] = "ShieldBash",
                },

                RespecCounters = {
                    Attributes = 2,
                    Skills = 3,
                },

                OneTimeRewards = {
                    ArcSlashFirstClear = true,
                },

                ArchivedSkillKnowledge = {},
            },
        },
    },
}

-- ------------------------------------------------------------
-- Legacy -> Human -> Complete
--
-- old:   7/5/6/5/5
-- delta: 2/0/1/0/0
-- Human: 5/4/6/5/5
-- new:   7/4/7/5/5
-- ------------------------------------------------------------

local human_user_id = 7303

local human_profiles,
    human_identity,
    human_mutations =
    loaded_identity_service(
        human_user_id,
        ProfileSchema.deep_clone(
            legacy_v3
        )
    )

local human_before = assert(
    human_profiles:get_character(
        human_user_id,
        1
    )
)

check(
    human_before.Identity.CreationStage
        == "LegacyRaceSelection",
    "Migrated pre-v4 character must require legacy race selection."
)

local human_result =
    human_identity:select_race(
        human_user_id,
        "Human"
    )

check(
    human_result.ok == true,
    "Legacy Human selection must succeed."
)

check(
    human_mutations() == 1,
    "Legacy Human selection must use one mutation."
)

local human_after = assert(
    human_profiles:get_character(
        human_user_id,
        1
    )
)

check(
    human_after.Identity.RaceId
        == "Human"
        and human_after.Identity.BaseClassId
            == "Fighter"
        and human_after.Identity.ClassId
            == "Fighter"
        and human_after.Identity.CreationStage
            == "Complete",
    "Legacy Human must become a complete Fighter."
)

local human_attributes =
    human_after.Progression.Attributes

check(
    human_attributes.Strength == 7
        and human_attributes.Dexterity == 4
        and human_attributes.Vitality == 7
        and human_attributes.Intellect == 5
        and human_attributes.Spirit == 5,
    "Legacy Human translation must be exactly 7/4/7/5/5."
)

check(
    human_after.Level == 8
        and human_after.XP == 345
        and human_after.Gold == 777,
    "Legacy race selection must preserve Level, XP and Gold."
)

check(
    human_after.Progression.AttributePointEntitlement
        == 12
        and human_after.Progression.SkillPointEntitlement
            == 13,
    "Legacy race selection must not mint or remove AP/SP."
)

check(
    human_after.Progression.Skills.ArcSlash
        .PurchasedRank == 2
        and human_after.Progression.Skills.ArcSlash
            .Proficiency == 420,
    "Legacy Arc Slash progression must survive race selection."
)

check(
    human_after.Progression.Skills.ShieldBash
        .Proficiency == 20
        and human_after.Progression.Skills.Mend
            .Proficiency == 30,
    "Legacy starter proficiency must survive race selection."
)

check(
    human_after.Progression.Loadout[1]
        == "Mend"
        and human_after.Progression.Loadout[3]
            == "ArcSlash"
        and human_after.Progression.Loadout[6]
            == "ShieldBash",
    "Legacy sparse loadout must survive race selection."
)

check(
    human_after.Progression.OneTimeRewards
        .ArcSlashFirstClear == true,
    "Legacy reward history must survive race selection."
)

local human_snapshot =
    ProfileSchema.deep_clone(
        human_after
    )

local human_second_choice =
    human_identity:select_race(
        human_user_id,
        "Elf"
    )

check(
    human_second_choice.ok == false
        and human_second_choice.reason
            == "RaceSelectionNotAllowed",
    "Legacy race choice must be one-time only."
)

check(
    human_mutations() == 1,
    "Rejected second legacy race must not mutate."
)

check(
    deep_equal(
        human_snapshot,
        human_profiles:get_character(
            human_user_id,
            1
        )
    ),
    "Rejected second legacy race must not translate twice."
)

-- ------------------------------------------------------------
-- Approved legacy Elf example
--
-- old 7/5/6/5/5 -> Elf 7/6/5/5/5
-- ------------------------------------------------------------

local elf_legacy_user_id = 7304

local elf_legacy_profiles,
    elf_legacy_identity,
    elf_legacy_mutations =
    loaded_identity_service(
        elf_legacy_user_id,
        ProfileSchema.deep_clone(
            legacy_v3
        )
    )

local elf_legacy_result =
    elf_legacy_identity:select_race(
        elf_legacy_user_id,
        "Elf"
    )

check(
    elf_legacy_result.ok == true,
    "Legacy Elf selection must succeed."
)

check(
    elf_legacy_mutations() == 1,
    "Legacy Elf selection must use one mutation."
)

local translated_elf = assert(
    elf_legacy_profiles:get_character(
        elf_legacy_user_id,
        1
    )
)

local translated_attributes =
    translated_elf.Progression.Attributes

check(
    translated_attributes.Strength == 7
        and translated_attributes.Dexterity == 6
        and translated_attributes.Vitality == 5
        and translated_attributes.Intellect == 5
        and translated_attributes.Spirit == 5,
    "Approved legacy Elf translation must be exactly 7/6/5/5/5."
)

check(
    translated_elf.Identity.RaceId
        == "Elf"
        and translated_elf.Identity.BaseClassId
            == "Fighter"
        and translated_elf.Identity.ClassId
            == "Fighter"
        and translated_elf.Identity.CreationStage
            == "Complete",
    "Legacy Elf must remain Fighter and become Complete."
)

check(
    translated_elf.Level == 8
        and translated_elf.XP == 345
        and translated_elf.Gold == 777,
    "Legacy Elf translation must preserve progression."
)

print(
    string.format(
        "[Phase 2C.A Identity Service Tests] PASS: %d assertions.",
        assertion_count
    )
)